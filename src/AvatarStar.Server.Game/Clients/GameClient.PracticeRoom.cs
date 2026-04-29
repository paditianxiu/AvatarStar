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
            MapName: string.IsNullOrWhiteSpace(createRoom.MapName)
                ? ResolveLobbyMapName(createRoom.LevelId)
                : createRoom.MapName,
            UsePassword: createRoom.UsePassword,
            Password: createRoom.Password,
            LevelId: createRoom.LevelId,
            GameType: createRoom.GameType,
            MaxClientNum: createRoom.MaxClientNum,
            SpawnTime: createRoom.SpawnTime,
            JoinHalfWay: createRoom.JoinHalfWay,
            CheckBalance: createRoom.CheckBalance,
            CanBeWatched: createRoom.CanBeWatched,
            Matching: createRoom.Matching,
            EnterLimit: createRoom.EnterLimit,
            HostLevel: host.Level,
            HostOccupation: host.Occupation,
            HostRankType: 0,
            HostRankLevel: 0,
            HostVipLevel: 0));

        Log.Information(
            "Practice room created: remote={Remote} roomUid={RoomUid} roomId={RoomId} channelToken={ChannelToken} roomName={RoomName} host={HostName} hostCharacterId={HostCharacterId} levelId={LevelId} gameType={GameType} maxClientNum={MaxClientNum} currentClientNum={CurrentClientNum} matching={Matching} enterLimit={EnterLimit}",
            RemoteEndPoint,
            room.RoomUid,
            room.RoomId,
            room.ChannelToken,
            room.RoomName,
            room.HostName,
            room.HostCharacterId,
            room.LevelId,
            room.GameType,
            room.MaxClientNum,
            room.CurrentClientNum,
            room.Matching,
            room.EnterLimit);

        await SendPacket54RoomCreatedAsync(room, resultCode: 0);
        BroadcastRoomListChanged(includeSelf: false);
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

        var character = GetActivePlayerStateOrDefault().Character;
        _practiceRoomManager.RegisterPendingChannelJoin(
            channelToken,
            RemoteEndPoint.Address,
            new PracticeRoomManager.PracticeRoomEnterRequest(
                CharacterId: character.Id,
                CharacterName: character.Name,
                Level: character.Level,
                Occupation: character.Occupation,
                RankType: 0,
                RankLevel: 0,
                VipLevel: 0));

        var host = _practiceRoomManager.ResolveChannelHost(LocalEndPoint.Address);
        await SendPacket3ChannelConnectResultAsync(resultCode: 0, host, _practiceRoomManager.ChannelPort);

        Log.Information(
            "Channel info sent: remote={Remote} roomUid={RoomUid} token={ChannelToken} host={Host} port={Port} characterId={CharacterId}",
            RemoteEndPoint,
            room.RoomUid,
            channelToken,
            host,
            _practiceRoomManager.ChannelPort,
            character.Id);
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
