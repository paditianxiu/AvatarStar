namespace AvatarStar.Server.Game;

internal sealed partial class PracticeRoomManager
{
    internal const int TeamKillLimit = 100;
    internal const int MatchEndDisplayMilliseconds = 8000;
    internal readonly record struct GamePlayerScore(int Kills, int Deaths);
    internal readonly record struct GameTeamScore(int RedKills, int BlueKills);
    internal readonly record struct GameKillScore(int AttackerKills, int VictimDeaths, GameTeamScore Teams);
    internal sealed record GameMatchResult(long Generation, byte WinningTeam, GameTeamScore Teams);

    // Match-owned, keyed by character rather than connection UID: a reconnect must not erase
    // a player's record, and a departure must not subtract kills from the team's total.
    internal sealed class GameMatchScores
    {
        internal Dictionary<long, GamePlayerScore> Players { get; } = [];
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
        dead = dead with { Deaths = dead.Deaths + 1 };
        scores.Players[victim.CharacterId] = dead;
        var killer = scores.Players.GetValueOrDefault(attacker.CharacterId);
        var team = ResolveGamePlayerTeamId(room, attacker);
        if (attacker.Uid != victim.Uid && IsEnemyTeam(team, ResolveGamePlayerTeamId(room, victim)))
        {
            killer = killer with { Kills = killer.Kills + 1 };
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
        return new(killer.Kills, dead.Deaths, scores.Teams);
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
}
