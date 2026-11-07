using System.Buffers.Binary;
using System.Net;
using System.Numerics;
using System.Reflection;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Utilities;

internal static class KillFeedTests
{
    internal static async Task Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        var manager = new PracticeRoomManager();
        var room = manager.CreateOrReplaceRoom(new(1, "host", "kill-feed", "LEVEL53", false, "", 400022, 4, 16, 3,
            true, false, 0, false, 0, 30, 0, 0, 0, 0));
        var frames = new List<List<byte[]>>();
        PracticeRoomChannelProtocol Channel(long id, byte team, out byte uid)
        {
            var packets = new List<byte[]>(); frames.Add(packets);
            uint decodeState = 0;
            var channel = new PracticeRoomChannelProtocol(manager, new PlayerStore(), p =>
            {
                var bytes = p.ToArray(); XorNetworkCodec.DecodeInPlace(bytes, ref decodeState);
                packets.Add(bytes); return Task.CompletedTask;
            }, IPAddress.Loopback, "kill-feed-test");
            uid = manager.RegisterGameChannel(room.RoomId, channel, id, "player");
            manager.UpdateGamePlayerState(room.RoomId, uid, team, 1000);
            manager.UpdateGamePosition(room.RoomId, uid, new(0, 0, (short)(team == 0 ? 0 : -1024), 0, 0, 0, DateTimeOffset.UtcNow));
            return channel;
        }
        var shooter = Channel(1, 0, out var attacker);
        var victimChannel = Channel(2, 1, out var victim);
        _ = Channel(3, 2, out _);
        void Clear() { foreach (var list in frames) list.Clear(); }
        static int Flags(byte[] packet) => BinaryPrimitives.ReadInt32BigEndian(packet.AsSpan(2));
        PracticeRoomManager.GameShootAction Shot(byte slot) => new(attacker, 0, slot, 0, 256, 0, 0, 0, 0, 0, -1, DateTimeOffset.UtcNow);
        var hitRule = new PracticeRoomManager.GameDamageHitRule(false, false, 1, 100, 0, 0, false);
        for (byte slot = 1; slot <= 3; slot++)
        {
            manager.TrySetGamePlayerHealth(room.RoomId, victim, 1000, out _);
            foreach (var amount in new[] { 400, 600 })
            {
                Clear();
                var (_, hit) = await manager.BroadcastGameShotDamageAsync(room.RoomId, shooter, Shot(slot), amount, hitRule, victim);
                check(hit.Applied && hit.Killed == (amount == 600), "weapon hit preserves damage and lethal state");
                check(frames.All(p => p.Count == (hit.Killed ? 2 : 1) && BitConverter.ToInt16(p[0]) == 113),
                    "one combined weapon shot/hit reaches owner, victim and spectator without Spurt packet");
                check(frames.All(p => Flags(p[0]) == (hit.Killed ? 0x00F03C0F : 0x00F0000F) && p[0].Length == (hit.Killed ? 38 : 30) &&
                    p[0][6] == attacker && p[0][7] == victim && p[0][8] == slot && p[0][9] == 1 &&
                    BitConverter.ToInt32(p[0], hit.Killed ? 18 : 10) == hit.VictimHealth), "native weapon-hit layout carries correct slot and victim health at bit 20");
                if (hit.Killed)
                    check(frames.All(p => BitConverter.ToInt16(p[0], 10) == slot && BitConverter.ToInt16(p[0], 12) == slot &&
                        BitConverter.ToInt16(p[0], 14) == slot && BitConverter.ToInt16(p[0], 16) == slot &&
                        BitConverter.ToInt16(p[1]) == 165 && BitConverter.ToInt16(p[1], 4) == slot && BitConverter.ToInt16(p[1], 6) == 0),
                        "lethal weapon delta and team HUD carry cumulative authoritative scores");
            }
        }
        Clear();
        var (_, miss) = await manager.BroadcastGameShotDamageAsync(room.RoomId, shooter, Shot(2), 100, hitRule, 255);
        check(!miss.Applied && frames[0].Count == 0 && frames.Skip(1).All(p => p.Count == 1 &&
            Flags(p[0]) == 0x00E0002D && p[0][9] == 0xFE), "miss broadcasts one ordinary shot to peers");

        manager.TrySetGamePlayerHealth(room.RoomId, victim, 1000, out _);
        var projectileRule = new PracticeRoomManager.GameDamageHitRule(false, false, 1, 100, 9, 5, true);
        var launch = Shot(2);
        var (_, pending) = await manager.BroadcastGameShotDamageAsync(room.RoomId, shooter, launch, 1000, projectileRule, 0);
        check(!pending.Applied && pending.Reason == "await-projectile-confirm", "projectile waits for impact confirmation");
        await manager.BroadcastGameShootAsync(room.RoomId, shooter, Shot(1));
        check(!manager.TryGetRecentProjectileDamage(room.RoomId, attacker, 3, out _, out _, out _), "wrong projectile slot rejected");
        check(manager.TryGetRecentProjectileDamage(room.RoomId, attacker, 2, out var damage, out var rule, out var originalShot) &&
            originalShot == launch, "projectile keeps original weapon after owner changes guns");
        Clear();
        var impact = await manager.BroadcastGameDamageAsync(room.RoomId, victimChannel, attacker, damage, rule, victim,
            new(originalShot, PlayShot: false, Projectile: true));
        check(impact.Killed && frames.All(p => BitConverter.ToInt16(p[0]) == 121 && Flags(p[0]) == 0x00703C07 &&
            p[0][6] == attacker && p[0][7] == victim && p[0][8] == 2 && BitConverter.ToInt32(p[0], 17) == 0),
            "projectile impact resolves original equipment slot for kill icon");
        check(frames.All(p => p.All(f => BitConverter.ToInt16(f) is not (113 or 184))), "impact does not replay shooting or use Spurt hit");
        check(frames.All(p => BitConverter.ToInt16(p[0], 9) == 4 && BitConverter.ToInt16(p[0], 11) == 4 &&
            BitConverter.ToInt16(p[0], 13) == 4 && BitConverter.ToInt16(p[0], 15) == 4 &&
            BitConverter.ToInt16(p[1], 4) == 4), "projectile uses its own native kill/death/streak delta bits");
        manager.RemoveRoom(room.RoomId);

        // Drive a real AI attack, then decode its broadcast rather than manufacturing its source.
        room = manager.CreateOrReplaceRoom(new(1, "host", "AI-kill-feed", "LEVEL53", false, "", 400022, 4, 16, 3,
            true, false, 0, false, 0, 30, 0, 0, 0, 0));
        check(manager.ManageBots(room.RoomId, 1, 1, 4, 1, false, config, out _) &&
            manager.TryStartGame(room.RoomId, out _, out _), "AI kill test starts");
        frames.Clear();
        var hostChannel = Channel(1, 0, out var hostUid);
        var bot = manager.ListGamePlayers(room.RoomId).Single(p => p.CharacterId != 1);
        var pose = bot.LastPosition!.Value;
        var origin = new Vector3(pose.XRaw / 256f, pose.YRaw / 256f, pose.ZRaw / 256f);
        var nav = AiNavigation.ForLevel(400022)!;
        var nearby = nav.Points.First(p => Vector3.Distance(p, origin) is > 3 and < 4 && Math.Abs(p.Y - origin.Y) < .5f &&
            nav.Visible(origin + Vector3.UnitY * 1.3f, p + Vector3.UnitY * 1.2f));
        manager.UpdateGamePosition(room.RoomId, hostUid, new((short)(nearby.X * 256), (short)(nearby.Y * 256), (short)(nearby.Z * 256),
            0, 0, 0, DateTimeOffset.UtcNow));
        manager.TrySetGamePlayerHealth(room.RoomId, hostUid, 1, out _);
        var ready = (HashSet<PracticeRoomChannelProtocol>)typeof(PracticeRoomManager)
            .GetField("_botReadyChannels", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(manager)!;
        ready.Add(hostChannel);
        var step = typeof(PracticeRoomManager).GetMethod("StepBotsNoLock", BindingFlags.Instance | BindingFlags.NonPublic)!;
        var combat = new PracticeRoomManager.SamuraiCombatBatch();
        var now = Environment.TickCount64;
        // Allow target acquisition and weapon-switch reaction time before expecting a shot.
        for (var tick = 0; tick < 50 && combat.Damage.Count == 0; tick++)
        {
            var frame = step.Invoke(manager, new object[] { room, now + tick * 100 })!;
            combat = (PracticeRoomManager.SamuraiCombatBatch)frame.GetType()
                .GetProperty("Combat", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(frame)!;
        }
        var kill = combat.Damage.Single();
        check(kill.Killed && kill.WeaponHit is { PlayShot: true }, "AI lethal hit retains its actual shot");
        var weapon = manager.GetBotPlayer(bot.CharacterId)!.GetGameLoadoutItems().Single(i => i.Slot == kill.WeaponHit!.Value.Shot.SlotOneBased);
        check(weapon.ItemType == 2 && weapon.Slot is >= 1 and <= 3, "AI kill source is one of its equipped weapons");
        Clear();
        await manager.BroadcastSamuraiCombatAsync(room.RoomId, combat);
        check(frames[0].Count == 2 && BitConverter.ToInt16(frames[0][0]) == 113 && frames[0][0][8] == weapon.Slot &&
            BitConverter.ToInt32(frames[0][0], 18) == 0, "AI kill broadcasts weapon icon and zero health together");
        check(manager.GetGamePlayerScore(room.RoomId, bot.CharacterId).Kills == 1 &&
            manager.GetGamePlayerScore(room.RoomId, 1).Deaths == 1 &&
            BitConverter.ToInt16(frames[0][1], 4) == 0 && BitConverter.ToInt16(frames[0][1], 6) == 1,
            "AI kill credits its blue team and human victim exactly once");
        foreach (var (name, value) in new (string, object)[] { ("_currentGameRoom", room), ("_currentRoomId", room.RoomId),
            ("_currentCharacterId", 1L), ("_localGameUid", hostUid) })
            typeof(PracticeRoomChannelProtocol).GetField(name, BindingFlags.Instance | BindingFlags.NonPublic)!.SetValue(hostChannel, value);
        room.Scores.Teams = new(42, 99);
        manager.TrySetGamePlayerHealth(room.RoomId, hostUid, 1, out _);
        object winningFrame = null!;
        for (var tick = 0; tick < 100 && room.Scores.Result is null; tick++)
            winningFrame = step.Invoke(manager, new object[] { room, now + 6000 + tick * 100 })!;
        check(room.Scores.Result is { WinningTeam: 1, Teams.BlueKills: 100 }, "real AI decision reaches the blue team's kill limit");
        Clear();
        var broadcastFrame = typeof(PracticeRoomManager).GetMethod("BroadcastBotFrameAsync", BindingFlags.Instance | BindingFlags.NonPublic)!;
        await (Task)broadcastFrame.Invoke(manager, new object[] { room.RoomId, winningFrame, new[] { hostChannel } })!;
        check(frames[0].Count(p => BitConverter.ToInt16(p) == 131) == 1 && frames[0].Last().SequenceEqual(new byte[] { 131, 0, 1, 0 }),
            "AI winning frame publishes final damage then the blue victory result");
        var afterEnd = step.Invoke(manager, new object[] { room, now + 20000 })!;
        check(((List<PracticeRoomManager.GameMovementDelta>)afterEnd.GetType().GetProperty("Moves", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(afterEnd)!).Count == 0 &&
            ((List<PracticeRoomManager.GameShootAction>)afterEnd.GetType().GetProperty("Shots", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(afterEnd)!).Count == 0,
            "AI stops both movement and attack decisions after victory");
        var endCount = frames[0].Count;
        await (Task)broadcastFrame.Invoke(manager, new object[] { room.RoomId, winningFrame, new[] { hostChannel } })!;
        check(frames[0].Count == endCount, "duplicate AI frame cannot replay damage or match end");
        var complete = typeof(PracticeRoomManager).GetMethod("ReturnEndedMatchToRoomAsync", BindingFlags.Instance | BindingFlags.NonPublic)!;
        await (Task)complete.Invoke(manager, new object[] { room, room.Scores.Result! })!;
        check(room.RoomState == 1 && room.Members.Single(m => m.CharacterId == bot.CharacterId).Ready &&
            !room.Members.Single(m => m.CharacterId == 1).Ready, "finished AI room keeps AI ready and clears human readiness");
        check(manager.TryStartGame(room.RoomId, out _, out _) && !manager.IsGameFinished(room.RoomId) &&
            manager.GetGameTeamScore(room.RoomId) == default && manager.ListGamePlayers(room.RoomId).Any(p => p.CharacterId == bot.CharacterId && p.LastPosition.HasValue),
            "same AI room can rebuild bot spawns for a second match");
        manager.RemoveRoom(room.RoomId);
    }
}
