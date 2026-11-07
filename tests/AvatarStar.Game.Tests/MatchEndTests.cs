using System.Collections.Concurrent;
using System.Net;
using System.Reflection;
using AvatarStar.Server;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Utilities;

internal static class MatchEndTests
{
    private const BindingFlags PrivateInstance = BindingFlags.Instance | BindingFlags.NonPublic;

    internal static async Task Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        foreach (byte winner in new byte[] { 0, 1 })
        {
            var manager = new PracticeRoomManager();
            var room = manager.CreateOrReplaceRoom(new(1, "red", "match-end", "LEVEL53", false, "", 400022, 4, 16, 3,
                true, false, 1, false, 0, 30, 0, 0, 0, 0));
            manager.TryEnterRoom(room.RoomId, "", new(2, "blue", 30, 0, 0, 0, 0), out _, out _);
            manager.TryEnterRoom(room.RoomId, "", new(3, "spectator", 30, 0, 0, 0, 0), out _, out _);
            room.Members.Single(m => m.CharacterId == 2).SlotIndex = 9;
            room.Members.Single(m => m.CharacterId == 3).SlotIndex = 17;
            check(manager.TryStartGame(room.RoomId, out _, out _), "100-kill match starts");
            var frames = new List<ConcurrentQueue<byte[]>>();
            PracticeRoomChannelProtocol Channel(long id, byte team, out byte uid)
            {
                var sent = new ConcurrentQueue<byte[]>(); frames.Add(sent); uint decodeState = 0;
                var channel = new PracticeRoomChannelProtocol(manager, new PlayerStore(), p =>
                {
                    var bytes = p.ToArray(); XorNetworkCodec.DecodeInPlace(bytes, ref decodeState);
                    sent.Enqueue(bytes); return Task.CompletedTask;
                }, IPAddress.Loopback, "match-end-test");
                uid = manager.RegisterGameChannel(room.RoomId, channel, id, "player");
                manager.RegisterRoomChannel(room.RoomId, channel, id);
                foreach (var (name, value) in new (string, object)[] { ("_currentGameRoom", room), ("_currentRoomId", room.RoomId),
                    ("_currentCharacterId", id), ("_localGameUid", uid) })
                    typeof(PracticeRoomChannelProtocol).GetField(name, PrivateInstance)!.SetValue(channel, value);
                var stateField = typeof(PracticeRoomChannelProtocol).GetField("_state", PrivateInstance)!;
                stateField.SetValue(channel, Enum.Parse(stateField.FieldType, "InGame"));
                manager.UpdateGamePlayerState(room.RoomId, uid, team, 1000);
                manager.UpdateGamePosition(room.RoomId, uid, new(0, 0, (short)(id * -256), 0, 0, 0, DateTimeOffset.UtcNow));
                return channel;
            }
            var red = Channel(1, 0, out var redUid);
            var blue = Channel(2, 1, out var blueUid);
            var spectator = Channel(3, 2, out _);
            var source = winner == 0 ? red : blue;
            var killer = winner == 0 ? redUid : blueUid;
            var victim = winner == 0 ? blueUid : redUid;
            var oldGeneration = room.Scores.Generation;
            room.Scores.Teams = winner == 0 ? new(98, 99) : new(99, 98);
            var preWin = await manager.BroadcastGameDamageAsync(room.RoomId, source, killer, 1000, clientTargetUid: victim);
            check(preWin.Killed && room.Scores.Result is null && frames.All(p => p.All(f => BitConverter.ToInt16(f) != 131)),
                "99 kills does not end the match");
            manager.TrySetGamePlayerHealth(room.RoomId, victim, 1000, out _);
            foreach (var queue in frames) queue.Clear();
            var win = await manager.BroadcastGameDamageAsync(room.RoomId, source, killer, 1000, clientTargetUid: victim);
            var result = room.Scores.Result!;
            check(win.Killed && result is not null && result.WinningTeam == winner && manager.IsGameFinished(room.RoomId),
                "100th kill atomically locks the correct winner");
            check(result!.Teams == (winner == 0 ? new PracticeRoomManager.GameTeamScore(100, 99) : new(99, 100)),
                "final scoreboard stops at the winning kill");
            check(frames.All(p => p.Count(f => BitConverter.ToInt16(f) == 131) == 1 &&
                p.Single(f => BitConverter.ToInt16(f) == 131).SequenceEqual(new byte[] { 131, 0, winner, 0 })),
                "winner, loser and spectator receive native winner/reason exactly once");
            check(frames.All(p =>
            {
                var f = p.ToArray(); var end = Array.FindIndex(f, p => BitConverter.ToInt16(p) == 131);
                return end > 0 && BitConverter.ToInt16(f[end - 1]) == 165 &&
                    BitConverter.ToInt16(f[end - 1], 4) == result.Teams.RedKills && BitConverter.ToInt16(f[end - 1], 6) == result.Teams.BlueKills;
            }), "final HUD is sent immediately before the victory message");
            var blocked = await manager.BroadcastGameDamageAsync(room.RoomId, source, killer, 1000, clientTargetUid: victim);
            check(!blocked.Applied && blocked.Reason == "match-ended" && manager.GetGameTeamScore(room.RoomId) == result.Teams,
                "late weapon or projectile cannot add a 101st kill");
            var heal = await manager.HealGamePlayersAsync(room.RoomId, killer, 500, 10, true, "after-end");
            check(!heal.Applied, "healing stops after the result");
            var respawn = typeof(PracticeRoomManager).GetMethod("RespawnGamePlayerAsync", PrivateInstance)!;
            check(await (Task<int>)respawn.Invoke(manager, new object[] { room.RoomId, victim, "after-end" })! == 0,
                "respawn cannot revive a player after victory");
            check(!manager.TryEnterGame(room.RoomId, 1, out _, out _) && !manager.TryStartGame(room.RoomId, out _, out _),
                "ending match rejects entry and premature restart");
            var before = frames.Sum(p => p.Count);
            var handle = typeof(PracticeRoomChannelProtocol).GetMethod("HandleDecodedAsync", PrivateInstance)!;
            foreach (short opcode in new short[] { 100, 106, 136, 141, 157, 162 })
                await (Task)handle.Invoke(source, new object[] { new PacketReader(BitConverter.GetBytes(opcode)) })!;
            check(frames.Sum(p => p.Count) == before, "late client attack, skill, spawn and initialization packets are ignored");
            await source.SendGameEndAsync(room, result);
            check(frames.Sum(p => p.Count) == before, "duplicate result cannot replay victory");

            // Exercise the real automatic timer once; other cases call its same completion
            // body directly to cover lifecycle without sleeping for every winner.
            var returnToRoom = typeof(PracticeRoomManager).GetMethod("ReturnEndedMatchToRoomAsync", PrivateInstance)!;
            if (winner == 0)
            {
                await Task.Delay(PracticeRoomManager.MatchEndDisplayMilliseconds + 500);
                check(frames.All(p => p.All(f => BitConverter.ToInt16(f) != 111)), "old respawn timer cannot interrupt the result display");
            }
            else await (Task)returnToRoom.Invoke(manager, new object[] { room, result })!;
            check(room.RoomState == 1 && room.Scores.ReturnCompleted && room.Members.All(m => !m.InGame && !m.Ready),
                "result display returns room to ready state with human ready flags cleared");
            check(frames.All(p => p.Count(f => BitConverter.ToInt16(f) == 12) == 1), "all connected players receive one return-to-room notification");
            check(typeof(PracticeRoomChannelProtocol).GetField("_state", PrivateInstance)!.GetValue(source)!.ToString() == "InRoom",
                "channel accepts room commands after the match");
            check(manager.TryStartGame(room.RoomId, out _, out _) && room.Scores.Result is null &&
                room.Scores.Generation > oldGeneration && manager.GetGameTeamScore(room.RoomId) == default,
                "same room starts a clean second match");
            var afterRestart = frames.Sum(p => p.Count);
            await (Task)returnToRoom.Invoke(manager, new object[] { room, result })!;
            var oldBatch = new PracticeRoomManager.SamuraiCombatBatch { Generation = oldGeneration, MatchResult = result };
            check(await manager.BroadcastSamuraiCombatAsync(room.RoomId, oldBatch) == 0 &&
                room.RoomState == 2 && frames.Sum(p => p.Count) == afterRestart, "stale return and combat cannot end the next match");
            manager.RemoveRoom(room.RoomId);
        }

        // One area skill with two victims at 99 kills must stop after its first death.
        var areaManager = new PracticeRoomManager();
        var areaStore = new PlayerStore();
        var samurai = areaStore.CreateCharacter(1, "samurai", 4, config); samurai.SetSkillLevel(80, 3);
        var areaRoom = areaManager.CreateOrReplaceRoom(new(1, "samurai", "area-end", "LEVEL53", false, "", 400022, 4, 16, 3,
            true, false, 0, false, 0, 30, 4, 0, 0, 0));
        areaManager.TryStartGame(areaRoom.RoomId, out _, out _);
        var casterChannel = new PracticeRoomChannelProtocol(areaManager, areaStore, _ => Task.CompletedTask, IPAddress.Loopback, "area-end");
        var caster = areaManager.RegisterGameChannel(areaRoom.RoomId, casterChannel, 1, "samurai");
        areaManager.UpdateGamePosition(areaRoom.RoomId, caster, new(0, 0, 0, 0, 0, 0, DateTimeOffset.UtcNow));
        PracticeRoomChannelProtocol blueChannel = null!;
        byte blueActor = 0;
        foreach (var id in new[] { 2, 3 })
        {
            var c = new PracticeRoomChannelProtocol(areaManager, areaStore, _ => Task.CompletedTask, IPAddress.Loopback, "area-victim");
            var uid = areaManager.RegisterGameChannel(areaRoom.RoomId, c, id, "enemy");
            if (id == 2) { blueChannel = c; blueActor = uid; }
            areaManager.UpdateGamePlayerState(areaRoom.RoomId, uid, 1, 100);
            areaManager.UpdateGamePosition(areaRoom.RoomId, uid, new(0, 0, (short)(-id * 256), 0, 0, 0, DateTimeOffset.UtcNow));
        }
        areaRoom.Scores.Teams = new(99, 99);
        check(areaManager.TryActivateSamurai(areaRoom.RoomId, casterChannel, caster, samurai, 80, 3, out var area) &&
            area.Damage.Count == 1 && area.Damage[0].Killed && areaRoom.Scores.Teams == new PracticeRoomManager.GameTeamScore(100, 99),
            "area skill stops after the winning victim instead of awarding 101 kills");
        check(!areaManager.TryActivateSamurai(areaRoom.RoomId, casterChannel, caster, samurai, 80, 3, out _),
            "ended match blocks skill activation at the authoritative manager");
        areaRoom.Scores.Reset();
        areaRoom.Scores.Teams = new(99, 99);
        areaManager.TrySetGamePlayerHealth(areaRoom.RoomId, caster, 1000, out _);
        areaManager.TrySetGamePlayerHealth(areaRoom.RoomId, blueActor, 100, out _);
        var go = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        var redAttack = Task.Run(async () => { await go.Task; return await areaManager.BroadcastGameDamageAsync(areaRoom.RoomId, casterChannel, caster, 2000, clientTargetUid: blueActor); });
        var blueAttack = Task.Run(async () => { await go.Task; return await areaManager.BroadcastGameDamageAsync(areaRoom.RoomId, blueChannel, blueActor, 2000, clientTargetUid: caster); });
        go.SetResult();
        var concurrent = await Task.WhenAll(redAttack, blueAttack);
        check(concurrent.Count(r => r.Killed) == 1 && concurrent.Count(r => r.Reason == "match-ended") == 1 &&
            areaRoom.Scores.Teams.RedKills + areaRoom.Scores.Teams.BlueKills == 199,
            "simultaneous 99-99 attacks choose exactly one winner under the match lock");
        check(await areaManager.BroadcastSamuraiCombatAsync(areaRoom.RoomId, area) == 0,
            "old area-skill batch cannot replay into another match generation");
        areaRoom.Scores.Reset();
        areaRoom.GameType = 1;
        areaRoom.Scores.Teams = new(99, 0);
        areaManager.TrySetGamePlayerHealth(areaRoom.RoomId, caster, 1000, out _);
        areaManager.TrySetGamePlayerHealth(areaRoom.RoomId, blueActor, 100, out _);
        await areaManager.BroadcastGameDamageAsync(areaRoom.RoomId, casterChannel, caster, 2000, clientTargetUid: blueActor);
        check(areaRoom.Scores.Teams.RedKills == 100 && areaRoom.Scores.Result is null,
            "objective modes do not inherit team-deathmatch's kill-limit ending");
        areaManager.RemoveRoom(areaRoom.RoomId);
    }
}
