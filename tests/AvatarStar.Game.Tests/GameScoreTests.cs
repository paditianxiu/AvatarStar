using System.Buffers.Binary;
using System.Net;
using System.Reflection;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Utilities;

internal static class GameScoreTests
{
    internal static async Task Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        var manager = new PracticeRoomManager();
        var store = new PlayerStore();
        var samurai = store.CreateCharacter(1, "score-host", 4, config);
        samurai.SetSkillLevel(80, 3);
        samurai.SetSkillLevel(83, 3);
        var room = manager.CreateOrReplaceRoom(new(1, "score-host", "scores", "LEVEL53", false, "", 400022, 4, 16, 3,
            true, false, 0, false, 0, 30, 4, 0, 0, 0));
        foreach (var id in new[] { 2, 3 })
        {
            check(manager.TryEnterRoom(room.RoomId, "", new(id, "enemy", 30, 0, 0, 0, 0), out _, out _), "score enemy joins room");
            room.Members.Single(m => m.CharacterId == id).SlotIndex = (byte)(id + 7);
        }
        check(manager.TryStartGame(room.RoomId, out _, out _), "score match starts");
        var packets = new Dictionary<byte, List<byte[]>>();
        PracticeRoomChannelProtocol Channel(long id, byte team, out byte uid)
        {
            var sent = new List<byte[]>(); uint decodeState = 0;
            var channel = new PracticeRoomChannelProtocol(manager, store, p =>
            {
                var bytes = p.ToArray(); XorNetworkCodec.DecodeInPlace(bytes, ref decodeState);
                sent.Add(bytes); return Task.CompletedTask;
            }, IPAddress.Loopback, "score-test");
            uid = manager.RegisterGameChannel(room.RoomId, channel, id, "score-player");
            packets[uid] = sent;
            typeof(PracticeRoomChannelProtocol).GetField("_currentGameRoom", BindingFlags.Instance | BindingFlags.NonPublic)!.SetValue(channel, room);
            typeof(PracticeRoomChannelProtocol).GetField("_localGameUid", BindingFlags.Instance | BindingFlags.NonPublic)!.SetValue(channel, uid);
            manager.UpdateGamePlayerState(room.RoomId, uid, team, 2000);
            manager.UpdateGamePosition(room.RoomId, uid, new(0, 0, (short)(id == 1 ? 0 : -id * 256), 0, 0, 0, DateTimeOffset.UtcNow));
            return channel;
        }
        var host = Channel(1, 0, out var hostUid);
        var enemy = Channel(2, 1, out var enemyUid);
        var other = Channel(3, 1, out var otherUid);
        manager.TrySetGamePlayerHealth(room.RoomId, enemyUid, 1, out _);
        manager.TrySetGamePlayerHealth(room.RoomId, otherUid, 1, out _);
        check(manager.TryActivateSamurai(room.RoomId, host, hostUid, samurai, 80, 3, out var slash), "lethal area skill accepted");
        check(slash.Damage.Count == 2 && slash.Damage.All(d => d.Killed), "one area skill kills two living enemies");
        await manager.BroadcastSamuraiCombatAsync(room.RoomId, slash);
        check(manager.GetGamePlayerScore(room.RoomId, 1) == new PracticeRoomManager.GamePlayerScore(2, 0, 2, 2) &&
            manager.GetGameTeamScore(room.RoomId) == new PracticeRoomManager.GameTeamScore(2, 0), "area kill counts each victim once");
        var fatal = packets[hostUid].Where(p => BitConverter.ToInt16(p) == 184).ToArray();
        check(fatal.Length == 2 && fatal.All(p => p.Length == 20 && BinaryPrimitives.ReadInt32BigEndian(p.AsSpan(2)) == 0x5E03 &&
            BitConverter.ToInt16(p, 10) == 1 && BitConverter.ToInt32(p, 16) == 0 &&
            BitConverter.ToInt16(p, 12) == BitConverter.ToInt16(p, 8) && BitConverter.ToInt16(p, 14) == BitConverter.ToInt16(p, 8)) &&
            fatal.Select(p => BitConverter.ToInt16(p, 8)).SequenceEqual(new short[] { 1, 2 }), "skill delta uses its native kills/deaths bits before health");
        var duplicate = await manager.BroadcastGameDamageAsync(room.RoomId, host, hostUid, 9999, clientTargetUid: enemyUid);
        check(!duplicate.Applied && manager.GetGamePlayerScore(room.RoomId, 2).Deaths == 1 &&
            manager.GetGameTeamScore(room.RoomId).RedKills == 2, "repeated damage to corpses cannot add deaths or kills");
        check(!manager.TryStartGame(room.RoomId, out _, out _) && manager.GetGameTeamScore(room.RoomId).RedKills == 2,
            "duplicate start cannot reset an active match");

        var respawn = typeof(PracticeRoomManager).GetMethod("RespawnGamePlayerAsync", BindingFlags.Instance | BindingFlags.NonPublic)!;
        await (Task<int>)respawn.Invoke(manager, new object[] { room.RoomId, enemyUid, "score-test" })!;
        check(manager.GetGamePlayerScore(room.RoomId, 2).Deaths == 1, "normal respawn retains deaths");
        manager.TrySetGamePlayerHealth(room.RoomId, enemyUid, 1, out _);
        manager.UpdateGamePosition(room.RoomId, enemyUid, new(0, 0, -512, 0, 0, 0, DateTimeOffset.UtcNow));
        check(manager.TryActivateSamurai(room.RoomId, host, hostUid, samurai, 83, 3, out _), "guard starts for counter score test");
        await manager.BroadcastGameDamageAsync(room.RoomId, enemy, enemyUid, 100, clientTargetUid: hostUid);
        check(manager.GetGamePlayerScore(room.RoomId, 1).Kills == 3 && manager.GetGamePlayerScore(room.RoomId, 2).Deaths == 2 &&
            manager.GetGameTeamScore(room.RoomId).RedKills == 3, "guard retaliation uses the same kill accounting");

        await (Task<int>)respawn.Invoke(manager, new object[] { room.RoomId, otherUid, "score-test" })!;
        await manager.BroadcastGameDamageAsync(room.RoomId, other, otherUid, 2000, clientTargetUid: hostUid);
        check(manager.GetGamePlayerScore(room.RoomId, 1) == new PracticeRoomManager.GamePlayerScore(3, 1, 0, 3) &&
            manager.GetGamePlayerScore(room.RoomId, 3) == new PracticeRoomManager.GamePlayerScore(1, 1, 1, 1) &&
            manager.GetGameTeamScore(room.RoomId) == new PracticeRoomManager.GameTeamScore(3, 1), "opposing team kill increments blue and preserves prior records");
        check(packets.Values.All(frames => frames.Last(p => BitConverter.ToInt16(p) == 165)
                .SequenceEqual(new byte[] { 165, 0, 100, 0, 3, 0, 1, 0 })) &&
            packets.Values.All(frames => frames.All(p => BitConverter.ToInt16(p) != 139)),
            "all clients receive mode 4's native kill HUD packet instead of another mode's objective scores");

        manager.UnregisterGameChannel(room.RoomId, host, out _);
        check(manager.GetGameTeamScore(room.RoomId).RedKills == 3, "departure never subtracts the departed player's kills");
        var returning = Channel(1, 0, out var returningUid);
        check(returningUid != hostUid && manager.GetGamePlayerScore(room.RoomId, 1).Kills == 3, "reconnect restores scores across a changed UID");
        await manager.SendGameScoreSnapshotAsync(room.RoomId, returning);
        var snapshot = packets[returningUid].Single(p => BitConverter.ToInt16(p) == 112 && p[2] == returningUid);
        check(snapshot.Length == 180 && BitConverter.ToInt16(snapshot, 3) == 3 && BitConverter.ToInt16(snapshot, 5) == 1 &&
            snapshot.AsSpan(17).ToArray().All(b => b == 0), "entry snapshot has native scoreboard layout and empty initial ability state");
        check(packets[returningUid].Count(p => BitConverter.ToInt16(p) == 112) == 3 &&
            packets[returningUid].Last().SequenceEqual(new byte[] { 165, 0, 100, 0, 3, 0, 1, 0 }), "joining client receives every player and current red/blue totals");
        var bootstrapScore = typeof(PracticeRoomChannelProtocol).GetMethod("SendCurrentGameTeamScoreAsync", BindingFlags.Instance | BindingFlags.NonPublic)!;
        packets[returningUid].Clear();
        await (Task)bootstrapScore.Invoke(returning, new object[] { "late-join" })!;
        await (Task)bootstrapScore.Invoke(returning, new object[] { "bootstrap-retry" })!;
        check(packets[returningUid].Count == 2 && packets[returningUid].All(p =>
                p.SequenceEqual(new byte[] { 165, 0, 100, 0, 3, 0, 1, 0 })),
            "late entry and bootstrap retry cannot reset an ongoing match's visible kill totals");
        packets[otherUid].Clear();
        await returning.SendPacket165TeamScoreAsync(new(40000, int.MaxValue));
        check(BitConverter.ToInt16(packets[returningUid].Last(), 4) == short.MaxValue &&
            BitConverter.ToInt16(packets[returningUid].Last(), 6) == short.MaxValue, "wire counters saturate instead of becoming negative");
        room.RoomState = 1;
        check(manager.TryStartGame(room.RoomId, out _, out _) && manager.GetGameTeamScore(room.RoomId) == default &&
            manager.GetGamePlayerScore(room.RoomId, 1) == default && manager.GetGamePlayerScore(room.RoomId, 2) == default,
            "new match resets personal and team scores together");
        await (Task)bootstrapScore.Invoke(returning, new object[] { "new-match" })!;
        check(packets[returningUid].Last().SequenceEqual(new byte[] { 165, 0, 100, 0, 0, 0, 0, 0 }),
            "fresh match initializes kill HUD to zero with the existing 100-kill limit");
        manager.RemoveRoom(room.RoomId);
        check(manager.GetGameTeamScore(room.RoomId) == default, "room deletion releases match scores");
    }
}
