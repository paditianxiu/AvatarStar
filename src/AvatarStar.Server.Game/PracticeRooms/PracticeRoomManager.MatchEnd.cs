using Serilog;

namespace AvatarStar.Server.Game;

internal sealed partial class PracticeRoomManager
{
    private async Task AnnounceMatchEndAsync(PracticeRoomSession room, GameMatchResult result)
    {
        PracticeRoomChannelProtocol[] targets;
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(room.RoomId, out var current) || !ReferenceEquals(current, room) ||
                !ReferenceEquals(room.Scores.Result, result) || room.Scores.EndAnnounced) return;
            room.Scores.EndAnnounced = true;
            StopBotsNoLock(room.RoomId);
            RemoveRecentProjectileDamageNoLock(room.RoomId);
            if (_gamePlayersByRoomId.TryGetValue(room.RoomId, out var players))
                foreach (var player in players.Values) player.Samurai.Clear();
            targets = _gameChannelsByRoomId.GetValueOrDefault(room.RoomId)?.Keys.ToArray() ?? [];
        }
        Log.Information("Match ended: roomId={RoomId} generation={Generation} winner={WinningTeam} red={RedKills} blue={BlueKills} limit={Limit}",
            room.RoomId, result.Generation, result.WinningTeam, result.Teams.RedKills, result.Teams.BlueKills, TeamKillLimit);
        foreach (var target in targets)
        {
            try { await target.SendGameEndAsync(room, result); }
            catch (Exception ex)
            {
                Log.Debug(ex, "Match result send failed in room {RoomId}", room.RoomId);
                UnregisterGameChannel(room.RoomId, target, out _);
            }
        }
        _ = ReturnEndedMatchAfterDelayAsync(room, result);
    }

    private async Task ReturnEndedMatchAfterDelayAsync(PracticeRoomSession room, GameMatchResult result)
    {
        try
        {
            await Task.Delay(MatchEndDisplayMilliseconds);
            await ReturnEndedMatchToRoomAsync(room, result);
        }
        catch (Exception ex) { Log.Error(ex, "Match return failed in room {RoomId}", room.RoomId); }
    }

    private async Task ReturnEndedMatchToRoomAsync(PracticeRoomSession room, GameMatchResult result)
    {
        PracticeRoomChannelProtocol[] targets;
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(room.RoomId, out var current) || !ReferenceEquals(current, room) ||
                !ReferenceEquals(room.Scores.Result, result) || room.Scores.ReturnStarted) return;
            room.Scores.ReturnStarted = true;
            targets = _gameChannelsByRoomId.GetValueOrDefault(room.RoomId)?.Keys.ToArray() ?? [];
        }
        foreach (var target in targets)
        {
            try { await target.ReturnToRoomAfterMatchAsync(room, result); }
            catch (Exception ex)
            {
                Log.Debug(ex, "Match return send failed in room {RoomId}", room.RoomId);
                UnregisterGameChannel(room.RoomId, target, out _);
            }
        }
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(room.RoomId, out var current) || !ReferenceEquals(current, room) ||
                !ReferenceEquals(room.Scores.Result, result)) return;
            room.Scores.ReturnCompleted = true;
            room.RoomState = 1;
            foreach (var member in room.Members)
            {
                member.InGame = false;
                member.Ready = _botPlayers.ContainsKey(member.CharacterId);
            }
            _gamePlayersByRoomId.Remove(room.RoomId);
            _gameMovementByRoomId.Remove(room.RoomId);
            _retiredGameUidsByRoomId.Remove(room.RoomId);
            room.RefreshCurrentClientNum();
        }
        await BroadcastRoomSnapshotAsync(room.RoomId);
    }
}
