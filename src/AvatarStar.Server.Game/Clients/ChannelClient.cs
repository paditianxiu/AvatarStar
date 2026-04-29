using System.Buffers;
using System.Net.Sockets;
using AvatarStar.Server.Utilities;

namespace AvatarStar.Server.Game;

internal sealed class ChannelClient : Client
{
    private readonly PracticeRoomChannelProtocol _protocol;

    public ChannelClient(
        ClientHandler clientHandler,
        Socket socket,
        PracticeRoomManager practiceRoomManager,
        PlayerStore playerStore) : base(clientHandler, socket)
    {
        _protocol = new PracticeRoomChannelProtocol(
            practiceRoomManager,
            playerStore,
            SendPacketPayloadAsync,
            socket.RemoteEndPoint?.ToString() ?? "<unknown>");
    }

    protected override ClientBuffer CreateBuffer()
    {
        return new ChannelClientBuffer();
    }

    protected override async Task HandleAsync(PacketReader reader)
    {
        await _protocol.HandleAsync(reader);
    }

    private async Task SendPacketPayloadAsync(byte[] payload)
    {
        const int MaxLengthSize = 3;

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
