using Serilog;

namespace AvatarStar.Server.Game;

internal partial class GameClient
{
    private async Task HandlePacket38CreateRoomAsync(PacketReader reader)
    {
        if (!AvatarStarClientProtocol.TryReadLobbyCreateRoom(reader, out var createRoom))
        {
            Log.Warning("PacketId=38 CreateRoom parse failed (remaining={Remaining})", reader.Remaining);
            await SendPacket54RoomCreatedAsync(null, resultCode: 1);
            return;
        }

        var host = GetActivePlayerStateOrDefault().Character;
        var room = _practiceRoomManager.CreateOrReplaceRoom(new PracticeRoomManager.PracticeRoomCreateRequest(
            HostCharacterId: host.Id,
            HostName: host.Name,
            RoomName: createRoom.RoomName,
            MapName: ResolveLobbyMapName(createRoom.LevelId),
            UsePassword: createRoom.UsePassword,
            Password: createRoom.Password,
            LevelId: createRoom.LevelId,
            GameType: createRoom.GameType,
            MaxClientNum: createRoom.MaxClientNum,
            SpawnTime: createRoom.SpawnTime,
            JoinHalfWay: createRoom.JoinHalfWay,
            CheckBalance: createRoom.CheckBalance,
            CanBeWatched: createRoom.CanBeWatched,
            HostLevel: host.Level,
            HostOccupation: host.Occupation,
            HostRankType: 0,
            HostRankLevel: 0,
            HostVipLevel: 0));

        Log.Information(
            "Practice room created: roomUid={RoomUid} roomId={RoomId} channelToken={ChannelToken} roomName={RoomName} host={HostName} levelId={LevelId} gameType={GameType} maxClientNum={MaxClientNum}",
            room.RoomUid,
            room.RoomId,
            room.ChannelToken,
            room.RoomName,
            room.HostName,
            room.LevelId,
            room.GameType,
            room.MaxClientNum);

        await SendPacket54RoomCreatedAsync(room, resultCode: 0);
    }

    private async Task HandlePacket3RequestChannelAsync(PacketReader reader)
    {
        if (!reader.TryReadInt(out var channelToken))
        {
            Log.Warning("PacketId=3 RequestChannel parse failed (remaining={Remaining})", reader.Remaining);
            await SendPacket3ChannelConnectResultAsync(resultCode: 1, host: string.Empty, port: 0);
            return;
        }

        if (!_practiceRoomManager.TryGetByChannelToken(channelToken, out var room))
        {
            Log.Warning("PacketId=3 RequestChannel unknown token={ChannelToken}", channelToken);
            await SendPacket3ChannelConnectResultAsync(resultCode: 1, host: string.Empty, port: 0);
            return;
        }

        var host = _practiceRoomManager.ResolveChannelHost(LocalEndPoint.Address);
        await SendPacket3ChannelConnectResultAsync(resultCode: 0, host, _practiceRoomManager.ChannelPort);

        Log.Information(
            "Channel info sent: roomUid={RoomUid} token={ChannelToken} host={Host} port={Port}",
            room.RoomUid,
            channelToken,
            host,
            _practiceRoomManager.ChannelPort);
    }

    private async Task SendPacket54RoomCreatedAsync(PracticeRoomManager.PracticeRoomSession? room, int resultCode)
    {
        using var writer = new PacketWriter();
        AvatarStarClientProtocol.WriteLobbyRoomCreated(writer, room, resultCode);
        await SendAsync(writer);
    }

    private async Task SendPacket3ChannelConnectResultAsync(int resultCode, string host, int port)
    {
        using var writer = new PacketWriter();
        AvatarStarClientProtocol.WriteLobbyChannelConnectResult(writer, resultCode, host, port);
        await SendAsync(writer);
    }
}
