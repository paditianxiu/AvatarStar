namespace AvatarStar.Server.Game;

internal sealed partial class PracticeRoomManager
{
    internal const int TeamKillLimit = 100;
    internal const int MatchEndDisplayMilliseconds = 8000;
    internal readonly record struct GamePlayerScore(int Kills, int Deaths, int Streak = 0, int BestStreak = 0);
    internal readonly record struct GameTeamScore(int RedKills, int BlueKills);
    internal readonly record struct GameKillScore(int AttackerKills, int VictimDeaths, GameTeamScore Teams,
        int Streak = 0, int BestStreak = 0, bool Revenge = false);
    internal sealed record GameMatchResult(long Generation, byte WinningTeam, GameTeamScore Teams);

    // Match-owned, keyed by character rather than connection UID: a reconnect must not erase
    // a player's record, and a departure must not subtract kills from the team's total.
    internal sealed class GameMatchScores
    {
        internal Dictionary<long, GamePlayerScore> Players { get; } = [];
        internal Dictionary<long, long> LastKiller { get; } = [];
        internal GameTeamScore Teams { get; set; }
        internal long Generation { get; private set; }
        internal GameMatchResult? Result { get; set; }
        internal bool EndAnnounced { get; set; }
        internal bool ReturnStarted { get; set; }
        internal bool ReturnCompleted { get; set; }
        internal SemaphoreSlim BroadcastGate { get; } = new(1, 1);

        internal void Reset()
        {
            Players.Clear();
            LastKiller.Clear();
            Teams = default;
            Generation++;
            Result = null;
            EndAnnounced = ReturnStarted = ReturnCompleted = false;
        }
    }

    public GamePlayerScore GetGamePlayerScore(int roomId, long characterId)
    {
        lock (_lock)
            return _roomsById.TryGetValue(roomId, out var room)
                ? room.Scores.Players.GetValueOrDefault(characterId) : default;
    }

    public GameTeamScore GetGameTeamScore(int roomId)
    {
        lock (_lock)
            return _roomsById.TryGetValue(roomId, out var room) ? room.Scores.Teams : default;
    }

    public bool IsGameFinished(int roomId)
    {
        lock (_lock)
            return _roomsById.TryGetValue(roomId, out var room) && room.Scores.Result is not null;
    }

    private static GameKillScore RecordGameDeathNoLock(PracticeRoomSession room,
        GamePlayerRuntime attacker, GamePlayerRuntime victim)
    {
        var scores = room.Scores;
        var dead = scores.Players.GetValueOrDefault(victim.CharacterId);
        dead = dead with { Deaths = dead.Deaths + 1, Streak = 0 };
        scores.Players[victim.CharacterId] = dead;
        var killer = scores.Players.GetValueOrDefault(attacker.CharacterId);
        var team = ResolveGamePlayerTeamId(room, attacker);
        var revenge = false;
        if (attacker.Uid != victim.Uid && IsEnemyTeam(team, ResolveGamePlayerTeamId(room, victim)))
        {
            revenge = scores.LastKiller.GetValueOrDefault(attacker.CharacterId) == victim.CharacterId;
            if (revenge) scores.LastKiller.Remove(attacker.CharacterId);
            scores.LastKiller[victim.CharacterId] = attacker.CharacterId;
            var streak = attacker.CurrentHealth > 0 ? killer.Streak + 1 : 0;
            killer = killer with { Kills = killer.Kills + 1, Streak = streak, BestStreak = Math.Max(killer.BestStreak, streak) };
            scores.Players[attacker.CharacterId] = killer;
            scores.Teams = team == GameTeamBlue
                ? scores.Teams with { BlueKills = scores.Teams.BlueKills + 1 }
                : scores.Teams with { RedKills = scores.Teams.RedKills + 1 };
            // These modes render the native 100-kill HUD. Objective/PVE modes have
            // different win conditions and must not end on this counter.
            if (room.GameType is 4 or 5 && scores.Result is null &&
                (scores.Teams.RedKills >= TeamKillLimit || scores.Teams.BlueKills >= TeamKillLimit))
                scores.Result = new(scores.Generation, team, scores.Teams);
        }
        else scores.LastKiller.Remove(victim.CharacterId);
        return new(killer.Kills, dead.Deaths, scores.Teams, killer.Streak, killer.BestStreak, revenge);
    }

    public async Task SendGameScoreSnapshotAsync(int roomId, PracticeRoomChannelProtocol channel)
    {
        (byte Uid, GamePlayerScore Score)[] players;
        GameTeamScore teams;
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out var room) ||
                !_gameChannelsByRoomId.TryGetValue(roomId, out var channels) || !channels.ContainsKey(channel)) return;
            players = ListGamePlayers(roomId).Select(p =>
                (p.Uid, room.Scores.Players.GetValueOrDefault(p.CharacterId))).ToArray();
            teams = room.Scores.Teams;
        }
        // Only during entry, after the actors exist. Normal combat uses the narrow delta
        // fields so a score update cannot overwrite a live actor's ability state or buffs.
        foreach (var (uid, score) in players) await channel.SendPacket112GameScoreAsync(uid, score);
        await channel.SendPacket165TeamScoreAsync(teams, "entry-snapshot");
    }

    private async Task SendFiveKillFeedbackAsync(int roomId, SamuraiCombatBatch batch)
    {
        foreach (var action in batch.Damage.Where(a => a.KillScore is { Streak: 5 }))
        {
            GameClient? client;
            lock (_lock)
            {
                if (!_roomsById.TryGetValue(roomId, out var room) || room.Scores.Generation != batch.Generation ||
                    !_gamePlayersByRoomId.TryGetValue(roomId, out var players) ||
                    !players.TryGetValue(action.AttackerUid, out var killer)) return;
                client = _gameClientsByCharacterId.GetValueOrDefault(killer.CharacterId);
            }
            if (client is null) continue; // AI has no local audio listener.
            try { await client.SendFiveKillFeedbackAsync(roomId, batch.Generation, action.KillScore!.Value.AttackerKills); }
            catch (Exception ex) { Serilog.Log.Debug(ex, "Five-kill feedback send failed in room {RoomId}", roomId); }
        }
    }
}
