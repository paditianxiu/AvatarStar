using System.Buffers;
using System.Net;
using System.Net.Sockets;
using AvatarStar.Server.Game;
using AvatarStar.Server.Utilities;

namespace AvatarStar.Server.Game.Udp;

internal sealed class UdpReliableSession : IDisposable
{
    private const int DatagramMaxLen = 512;
    private const int HeaderLen = 3;
    private const int PayloadMaxLen = DatagramMaxLen - HeaderLen; // 509
    private const int WindowSize = 32;

    // Tunables (legacy client has its own RTO/flow control; we keep it simple server-side).
    private static readonly TimeSpan RetransmitInterval = TimeSpan.FromMilliseconds(250);
    private static readonly TimeSpan KeepAliveInterval = TimeSpan.FromMilliseconds(500);
    private static readonly TimeSpan AckOnlyMinInterval = TimeSpan.FromMilliseconds(50);

    private readonly object _sync = new();

    private readonly GameClientBuffer _framer = new();

    // Outgoing byte-stream (already VLE framed per message); we slice into <=509B datagrams.
    private ArrayBufferWriter<byte> _outgoingStream = new(4096);
    private int _outgoingReadPos;

    private readonly SendFrame?[] _sendWindow = new SendFrame?[WindowSize];
    private readonly RecvFrame?[] _recvWindow = new RecvFrame?[WindowSize];

    private DateTime _lastSendAtUtc = DateTime.MinValue;
    private DateTime _lastAckOnlyAtUtc = DateTime.MinValue;
    private byte _lastAckAdvertised;

    private bool _ackDirty;

    public UdpReliableSession(IPEndPoint remoteEndPoint)
    {
        RemoteEndPoint = remoteEndPoint;

        // Server-side starts in "listen" state (2) per client state machine.
        State = 2;

        SendBase = 1;
        SendNext = 1;

        RecvBase = 1;
        RecvWindowEnd = unchecked((byte)(RecvBase + WindowSize)); // 33

        _lastAckAdvertised = unchecked((byte)(RecvBase - 1));
    }

    public IPEndPoint RemoteEndPoint { get; }

    // Reliable-UDP "state" is also used as the first byte of every datagram.
    public byte State { get; private set; }

    public byte SendBase { get; private set; }
    public byte SendNext { get; private set; }

    public byte RecvBase { get; private set; }
    public byte RecvWindowEnd { get; private set; }

    public DateTime LastRecvAtUtc { get; private set; } = DateTime.MinValue;

    public void EnqueueVleMessage(ReadOnlySpan<byte> payload)
    {
        // Mirror server TCP logic: prefix payload with VLE length.
        Span<byte> lenBuf = stackalloc byte[4];
        var lenSize = VLE.Encode(payload.Length, lenBuf);

        lock (_sync)
        {
            WriteToOutgoingStream(lenBuf.Slice(0, lenSize));
            WriteToOutgoingStream(payload);
        }
    }

    public SessionProcessResult ProcessIncomingDatagram(ReadOnlySpan<byte> datagram, DateTime nowUtc)
    {
        // Returns:
        // - outbound UDP datagrams we should send immediately
        // - decoded application packets (VLE-framed payloads)
        var outbound = new List<byte[]>(4);
        var packets = new List<PacketReader>(2);

        if (datagram.Length < HeaderLen)
        {
            return new SessionProcessResult(outbound, packets);
        }

        var type = datagram[0];
        var seq = datagram[1];
        var ack = datagram[2];

        lock (_sync)
        {
            LastRecvAtUtc = nowUtc;

            // Remote requested close.
            if (type == 5)
            {
                State = 0;
                return new SessionProcessResult(outbound, packets);
            }

            // Process ack for our sent window.
            ProcessAck(ack);

            // Store incoming (seq/payload) into receive window when in-range.
            if (IsInRange(seq, RecvBase, RecvWindowEnd))
            {
                var slot = seq & 0x1F;
                var existing = _recvWindow[slot];
                if (existing == null || existing.Seq != seq)
                {
                    _recvWindow[slot] = new RecvFrame(seq, datagram.Slice(HeaderLen).ToArray());
                }
            }

            // Consume contiguous receive window into the byte-stream framer.
            while (true)
            {
                var slot = RecvBase & 0x1F;
                var frame = _recvWindow[slot];
                if (frame == null || frame.Seq != RecvBase)
                {
                    break;
                }

                _recvWindow[slot] = null;

                if (frame.Payload.Length > 0)
                {
                    _framer.Append(frame.Payload);
                }

                RecvBase = unchecked((byte)(RecvBase + 1));
                RecvWindowEnd = unchecked((byte)(RecvWindowEnd + 1));
                _ackDirty = true;
            }

            // Handshake state machine (legacy reliable-UDP).
            if (State == 2)
            {
                // Expect type=1 from client (initial keepalive with seq advancing).
                if (type == 1)
                {
                    State = 3;
                    QueueKeepAliveFrame(outbound); // send type=3 keepalive
                }
            }
            else if (State == 3)
            {
                // Expect type=4 from client to finalize.
                if (type == 4)
                {
                    State = 4;
                    // Ack immediately so the client can proceed even if no app traffic yet.
                    _ackDirty = true;
                }
            }
            else if (State == 4)
            {
                // Established: accept type=4 (data/keepalive) only.
                // (If other types appear, we ignore them.)
            }

            // Decode any complete VLE-framed application packets.
            foreach (var reader in _framer.Process())
            {
                packets.Add(reader);
            }

            // Advertise ack if it moved and we have nothing else to send right now.
            MaybeQueueAckOnly(outbound, nowUtc);

            // Build new data frames from outgoing byte-stream (if established).
            BuildNewDataFrames(outbound, nowUtc);

            // Opportunistic retransmit.
            QueueRetransmits(outbound, nowUtc);
        }

        return new SessionProcessResult(outbound, packets);
    }

    public List<byte[]> Tick(DateTime nowUtc)
    {
        var outbound = new List<byte[]>(2);

        lock (_sync)
        {
            if (State == 0)
            {
                return outbound;
            }

            // Keepalive: when idle, send an empty seq-advancing frame so peer can ack and detect liveness.
            if (State is 1 or 3 or 4)
            {
                if (nowUtc - _lastSendAtUtc >= KeepAliveInterval && InFlightCount() == 0)
                {
                    QueueKeepAliveFrame(outbound);
                }
            }

            MaybeQueueAckOnly(outbound, nowUtc);
            BuildNewDataFrames(outbound, nowUtc);
            QueueRetransmits(outbound, nowUtc);
        }

        return outbound;
    }

    private void MaybeQueueAckOnly(List<byte[]> outbound, DateTime nowUtc)
    {
        var ackValue = unchecked((byte)(RecvBase - 1));
        if (!_ackDirty && ackValue == _lastAckAdvertised)
        {
            return;
        }

        if (nowUtc - _lastAckOnlyAtUtc < AckOnlyMinInterval)
        {
            return;
        }

        // Ack-only format mirrors client: 3 bytes [type/state, seq=send_base-1, ack=recv_base-1].
        // This does NOT advance SendNext / consume window slots.
        var ackOnly = new byte[HeaderLen];
        ackOnly[0] = State;
        ackOnly[1] = unchecked((byte)(SendBase - 1));
        ackOnly[2] = ackValue;

        outbound.Add(ackOnly);

        _lastAckOnlyAtUtc = nowUtc;
        _lastAckAdvertised = ackValue;
        _ackDirty = false;
        _lastSendAtUtc = nowUtc;
    }

    private void QueueKeepAliveFrame(List<byte[]> outbound)
    {
        // Seq-advancing empty frame (stored in send window).
        if (WindowFull())
        {
            return;
        }

        var datagram = new byte[HeaderLen];
        datagram[0] = State;
        datagram[1] = SendNext;
        datagram[2] = unchecked((byte)(RecvBase - 1));

        StoreAndAdvanceSend(datagram, SendNext);
        outbound.Add(datagram);
        _lastSendAtUtc = DateTime.UtcNow;
    }

    private void BuildNewDataFrames(List<byte[]> outbound, DateTime nowUtc)
    {
        if (State != 4)
        {
            return;
        }

        while (!WindowFull() && OutgoingAvailable() > 0)
        {
            var chunkLen = Math.Min(PayloadMaxLen, OutgoingAvailable());
            var datagram = new byte[HeaderLen + chunkLen];
            datagram[0] = State; // 4
            datagram[1] = SendNext;
            datagram[2] = unchecked((byte)(RecvBase - 1));

            var payload = datagram.AsSpan(HeaderLen, chunkLen);
            ReadOutgoing(payload);

            StoreAndAdvanceSend(datagram, SendNext);
            outbound.Add(datagram);
            _lastSendAtUtc = nowUtc;
        }
    }

    private void QueueRetransmits(List<byte[]> outbound, DateTime nowUtc)
    {
        if (InFlightCount() == 0)
        {
            return;
        }

        for (var i = 0; i < WindowSize; i++)
        {
            var frame = _sendWindow[i];
            if (frame == null)
            {
                continue;
            }

            if (nowUtc - frame.LastSentAtUtc < RetransmitInterval)
            {
                continue;
            }

            frame.LastSentAtUtc = nowUtc;
            frame.Retries++;
            outbound.Add(frame.Datagram);
            _lastSendAtUtc = nowUtc;
        }
    }

    private void ProcessAck(byte ack)
    {
        // If ack is within [SendBase, SendNext), advance SendBase to ack+1 and free window slots.
        if (!IsInRange(ack, SendBase, SendNext))
        {
            return;
        }

        var target = unchecked((byte)(ack + 1));
        while (SendBase != target)
        {
            var slot = SendBase & 0x1F;
            var frame = _sendWindow[slot];
            if (frame != null && frame.Seq == SendBase)
            {
                _sendWindow[slot] = null;
            }

            SendBase = unchecked((byte)(SendBase + 1));
        }
    }

    private void StoreAndAdvanceSend(byte[] datagram, byte seq)
    {
        var slot = seq & 0x1F;
        _sendWindow[slot] = new SendFrame(seq, datagram)
        {
            LastSentAtUtc = DateTime.UtcNow
        };

        SendNext = unchecked((byte)(SendNext + 1));
    }

    private int InFlightCount()
    {
        return SeqDistance(SendNext, SendBase);
    }

    private bool WindowFull()
    {
        return InFlightCount() >= WindowSize;
    }

    private int OutgoingAvailable()
    {
        return _outgoingStream.WrittenCount - _outgoingReadPos;
    }

    private void ReadOutgoing(Span<byte> destination)
    {
        _outgoingStream.WrittenSpan.Slice(_outgoingReadPos, destination.Length).CopyTo(destination);
        _outgoingReadPos += destination.Length;

        // Compact occasionally to prevent unbounded growth.
        if (_outgoingReadPos > 4096 && _outgoingReadPos > _outgoingStream.WrittenCount / 2)
        {
            var remaining = _outgoingStream.WrittenSpan.Slice(_outgoingReadPos).ToArray();
            _outgoingStream = new ArrayBufferWriter<byte>(Math.Max(remaining.Length, 4096));
            remaining.CopyTo(_outgoingStream.GetSpan(remaining.Length));
            _outgoingStream.Advance(remaining.Length);
            _outgoingReadPos = 0;
        }
    }

    private void WriteToOutgoingStream(ReadOnlySpan<byte> data)
    {
        data.CopyTo(_outgoingStream.GetSpan(data.Length));
        _outgoingStream.Advance(data.Length);
    }

    private static int SeqDistance(byte end, byte start)
    {
        return unchecked((byte)(end - start));
    }

    private static bool IsInRange(byte value, byte start, byte end)
    {
        // True if value is in [start, end) in uint8 wrap-around space.
        return SeqDistance(value, start) < SeqDistance(end, start);
    }

    public void Dispose()
    {
        // GameClientBuffer holds pooled memory; dispose it.
        _framer.Dispose();
    }

    private sealed class SendFrame
    {
        public SendFrame(byte seq, byte[] datagram)
        {
            Seq = seq;
            Datagram = datagram;
        }

        public byte Seq { get; }
        public byte[] Datagram { get; }

        public DateTime LastSentAtUtc { get; set; } = DateTime.MinValue;
        public int Retries { get; set; }
    }

    private sealed class RecvFrame
    {
        public RecvFrame(byte seq, byte[] payload)
        {
            Seq = seq;
            Payload = payload;
        }

        public byte Seq { get; }
        public byte[] Payload { get; }
    }
}

internal readonly record struct SessionProcessResult(List<byte[]> OutboundDatagrams, List<PacketReader> Packets);
