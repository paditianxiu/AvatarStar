using AvatarStar.Server;
using Serilog;

namespace AvatarStar.Server.Game;

internal sealed partial class PracticeRoomChannelProtocol
{
    private bool _gameScoreSnapshotSent;
    private PracticeRoomManager.GameMatchResult? _endedMatch;

    // Native scoreboard fields are signed shorts; saturate rather than wrapping negative.
    private static short GameScoreShort(int score) => (short)Math.Clamp(score, 0, short.MaxValue);

    private static void WriteGameKillScore(PacketWriter writer, PracticeRoomManager.GameKillScore score)
    {
        writer.WriteShort(GameScoreShort(score.AttackerKills));
        writer.WriteShort(GameScoreShort(score.VictimDeaths));
    }

    internal Task SendPacket165TeamScoreAsync(PracticeRoomManager.GameTeamScore score, string trigger = "kill-score")
    {
        using var writer = new PacketWriter();
        writer.WriteShort(165);
        // Native 0x5C3610 -> 0x805790: kill limit, red kills, blue kills. Team modes
        // 4/5 render UI+0x1C32/+0x1C34, NOT packet139's objective-score fields.
        writer.WriteShort(PracticeRoomManager.TeamKillLimit);
        writer.WriteShort(GameScoreShort(score.RedKills));
        writer.WriteShort(GameScoreShort(score.BlueKills));
        Log.Information("Channel packet165 -> {Remote}: team kills red={RedKills} blue={BlueKills} limit=100 trigger={Trigger}",
            _remoteLabel, score.RedKills, score.BlueKills, trigger);
        return SendPacketAsync(writer);
    }

    internal async Task SendGameEndAsync(PracticeRoomManager.PracticeRoomSession room, PracticeRoomManager.GameMatchResult result)
    {
        if (!ReferenceEquals(_currentGameRoom, room) || ReferenceEquals(_endedMatch, result)) return;
        _endedMatch = result;
        StopGameMatchTimerLoop();
        StopKnifeAutoRearmLoop();
        StopHealingBeaconLoops();
        StopBossStateLoop();
        _playerEnteringClearRetriesRemaining = _silentLoadoutHudRefreshRetriesRemaining = 0;
        unchecked { _gameInitSpawnHandshakeGeneration++; }
        await SendPacket165TeamScoreAsync(result.Teams, "match-end-final-score");
        using var writer = new PacketWriter();
        // Native ParseGameEnd (0x5C49F0) reads winner then reason. Reason 0 is a
        // normal result; winner 0/1 selects the red/blue win/lose banner and audio.
        writer.WriteShort(131);
        writer.WriteByte(result.WinningTeam);
        writer.WriteByte(0);
        await SendPacketAsync(writer);
        Log.Information("Channel packet131 -> {Remote}: match ended winner={Winner} reason=0", _remoteLabel, result.WinningTeam);
    }

    internal async Task ReturnToRoomAfterMatchAsync(PracticeRoomManager.PracticeRoomSession room, PracticeRoomManager.GameMatchResult result)
    {
        if (!ReferenceEquals(_currentGameRoom, room) || !ReferenceEquals(_endedMatch, result)) return;
        await CleanupGameStateAsync(resetMemberState: true, trigger: "match-ended");
        _state = _currentRoomId == 0 ? ChannelState.AwaitRoomEnter : ChannelState.InRoom;
        await SendPacket12GameLeaveNotifyAsync();
    }

    private Task SendCurrentGameTeamScoreAsync(string trigger)
    {
        var roomId = _currentGameRoom?.RoomId ?? _currentRoomId;
        return SendPacket165TeamScoreAsync(_practiceRoomManager.GetGameTeamScore(roomId), trigger);
    }

    internal Task SendPacket112GameScoreAsync(byte uid, PracticeRoomManager.GamePlayerScore score)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(112);
        writer.WriteByte(uid);
        writer.WriteShort(GameScoreShort(score.Kills));
        writer.WriteShort(GameScoreShort(score.Deaths));
        writer.WriteInt(0); // Mode score is separate from kills/deaths.
        writer.WriteShort(0); // Current streak.
        writer.WriteShort(0); // Maximum streak.
        writer.WriteShort(0); // Assists.
        writer.WriteByte(0); // Initial actor state; only used when entering the match.
        for (var i = 0; i < 162; i++) writer.WriteByte(0); // No ability changes.
        return SendPacketAsync(writer);
    }
}
