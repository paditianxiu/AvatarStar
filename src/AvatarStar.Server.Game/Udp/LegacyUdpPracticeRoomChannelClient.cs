namespace AvatarStar.Server.Game.Udp;

internal sealed class LegacyUdpPracticeRoomChannelClient
{
    private readonly UdpReliableSession _session;
    private readonly PracticeRoomChannelProtocol _protocol;

    public LegacyUdpPracticeRoomChannelClient(
        UdpReliableSession session,
        PracticeRoomManager practiceRoomManager,
        PlayerStore playerStore)
    {
        _session = session;
        _protocol = new PracticeRoomChannelProtocol(
            practiceRoomManager,
            playerStore,
            SendPayloadAsync,
            session.RemoteEndPoint.ToString());
    }

    public Task HandleAsync(PacketReader reader)
    {
        return _protocol.HandleAsync(reader);
    }

    private Task SendPayloadAsync(byte[] payload)
    {
        _session.EnqueueVleMessage(payload);
        return Task.CompletedTask;
    }
}
