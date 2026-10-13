using System.Buffers;
using System.Net;
using System.Net.Sockets;
using AvatarStar.Server.Utilities;
using Serilog;

namespace AvatarStar.Server.Game;

internal sealed class ChannelClient : Client, IDisconnectAwareClient
{
    private readonly PracticeRoomChannelProtocol _protocol;
    private readonly string _remoteLabel;

    // Set AS_CHANNEL_DUMP_PACKETS=1 to log the raw room/channel bytes in both directions. The
    // in-game ability packets (136/152/155/160/162/185) travel on this connection, so this is the
    // switch that lets a packet capture be diffed against the retail server byte for byte.
    private static readonly bool DumpPackets =
        (Environment.GetEnvironmentVariable("AS_CHANNEL_DUMP_PACKETS") ?? "0")
        .Equals("1", StringComparison.OrdinalIgnoreCase);

    public ChannelClient(
        ClientHandler clientHandler,
        Socket socket,
        PracticeRoomManager practiceRoomManager,
        PlayerStore playerStore) : base(clientHandler, socket)
    {
        var remoteAddress = socket.RemoteEndPoint is IPEndPoint remoteEndPoint
            ? remoteEndPoint.Address
            : IPAddress.None;

        _remoteLabel = socket.RemoteEndPoint?.ToString() ?? "<unknown>";

        _protocol = new PracticeRoomChannelProtocol(
            practiceRoomManager,
            playerStore,
            SendPacketPayloadAsync,
            remoteAddress,
            _remoteLabel);
    }

    protected override ClientBuffer CreateBuffer()
    {
        return new ChannelClientBuffer();
    }

    protected override async Task HandleAsync(PacketReader reader)
    {
        if (DumpPackets)
        {
            Log.Debug("Channel raw <- {Remote}: {Hex}", _remoteLabel, Convert.ToHexString(reader.DataSpan));
        }

        await _protocol.HandleAsync(reader);
    }

    public void OnClientDisconnected()
    {
        _protocol.OnClientDisconnected();
    }

    private async Task SendPacketPayloadAsync(byte[] payload)
    {
        const int MaxLengthSize = 3;

        if (DumpPackets)
        {
            Log.Debug("Channel raw -> {Remote}: {Hex}", _remoteLabel, Convert.ToHexString(payload));
        }

        var bufferLen = payload.Length + MaxLengthSize;
        var buffer = ArrayPool<byte>.Shared.Rent(bufferLen);

        try
        {
            var packetLengthSize = VLE.Encode(payload.Length, buffer.AsSpan());
            var actualLength = packetLengthSize + payload.Length;
            payload.CopyTo(buffer.AsSpan(packetLengthSize, payload.Length));
            await base.SendAsync(new ArraySegment<byte>(buffer, 0, actualLength));
        }
        finally
        {
            ArrayPool<byte>.Shared.Return(buffer);
        }
    }
}
