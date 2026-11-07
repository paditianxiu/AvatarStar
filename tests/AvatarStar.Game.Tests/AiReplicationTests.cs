using System.Collections;
using System.Net;
using System.Numerics;
using System.Reflection;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Utilities;

internal static class AiReplicationTests
{
    internal static async Task Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        var manager = new PracticeRoomManager();
        var room = manager.CreateOrReplaceRoom(new(1, "host", "AI replication", "LEVEL53", false, "", 400022, 4, 16, 3,
            true, false, 0, false, 0, 30, 2, 0, 0, 0));
        check(manager.ManageBots(room.RoomId, 1, 1, 2, 1, false, config, out _) &&
            manager.TryStartGame(room.RoomId, out _, out _), "AI replication room starts");
        var packets = new List<byte[]>();
        uint decodeState = 0;
        var channel = new PracticeRoomChannelProtocol(manager, new PlayerStore(), p =>
        {
            var bytes = p.ToArray(); XorNetworkCodec.DecodeInPlace(bytes, ref decodeState);
            packets.Add(bytes); return Task.CompletedTask;
        }, IPAddress.Loopback, "ai-replication");
        var hostUid = manager.RegisterGameChannel(room.RoomId, channel, 1, "host");
        typeof(PracticeRoomChannelProtocol).GetField("_localGameUid", BindingFlags.Instance | BindingFlags.NonPublic)!.SetValue(channel, hostUid);
        manager.UpdateGamePlayerState(room.RoomId, hostUid, 0, 100000);
        manager.TrySetGamePlayerHealth(room.RoomId, hostUid, 100000, out _);
        var ready = (HashSet<PracticeRoomChannelProtocol>)typeof(PracticeRoomManager)
            .GetField("_botReadyChannels", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(manager)!;
        ready.Add(channel);
        var step = typeof(PracticeRoomManager).GetMethod("StepBotsNoLock", BindingFlags.Instance | BindingFlags.NonPublic)!;
        var broadcast = typeof(PracticeRoomManager).GetMethod("BroadcastBotFrameAsync", BindingFlags.Instance | BindingFlags.NonPublic)!;
        var nav = AiNavigation.ForLevel(room.LevelId)!;
        var now = Environment.TickCount64;
        foreach (var (expectedSlot, distance) in new[] { (3, 1.8f), (1, 8f), (2, 25f) })
        {
            var bot = manager.ListGamePlayers(room.RoomId).Single(p => p.CharacterId != 1);
            var pose = bot.LastPosition!.Value;
            var origin = new Vector3(pose.XRaw / 256f, pose.YRaw / 256f, pose.ZRaw / 256f);
            var point = nav.Points.Where(p => Math.Abs(p.Y - origin.Y) < .5f)
                .MinBy(p => Math.Abs(Vector3.Distance(p, origin) - distance));
            manager.UpdateGamePosition(room.RoomId, hostUid, new((short)(point.X * 256), (short)(point.Y * 256),
                (short)(point.Z * 256), 0, 0, 0, DateTimeOffset.UtcNow));
            packets.Clear();
            var frame = step.Invoke(manager, new object[] { room, now })!;
            await (Task)broadcast.Invoke(manager, new object[] { room.RoomId, frame, new[] { channel } })!;
            var selection = packets.Single(p => BitConverter.ToInt16(p) == 128);
            check(selection.Length == 4 && selection[2] == bot.Uid && selection[3] == expectedSlot - 1,
                "AI selection uses native zero-based weapon index for all three weapons");
            var equipment = manager.GetBotPlayer(bot.CharacterId)!.GetGameLoadoutItems()
                .Single(i => i.Slot == selection[3] + 1);
            check(equipment.ItemType == 2, "native SelectWeapon resolves a weapon instead of fourth-slot stealth");
            check(packets.All(p => BitConverter.ToInt16(p) is not (160 or 162 or 185)),
                "AI switching does not send a local skill activation or effect");
            var move = packets.Single(p => BitConverter.ToInt16(p) == 110);
            check(move[2] == bot.Uid && move[3] is 25 or 26, "AI wire movement carries actor and a 100 ms duration");
            check(move[4] == 7 && (move[5] & 0x0F) == 2,
                "AI movement carries grounded direction without jump, crouch, walk modifier or bogus ping");
            now += 100;
        }
        // Pause the route between plans; a stationary bot must stand rather than keep
        // running in place or fall. Drive the same decision/broadcast path as movement.
        var bots = (IDictionary)typeof(PracticeRoomManager).GetField("_botsByRoom", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(manager)!;
        var idleBot = ((IList)bots[room.RoomId]!)[0]!;
        ((Queue<int>)idleBot.GetType().GetField("Route", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(idleBot)!).Clear();
        idleBot.GetType().GetField("NextPlan", BindingFlags.Instance | BindingFlags.NonPublic)!.SetValue(idleBot, now + 10000);
        var beforeIdle = manager.ListGamePlayers(room.RoomId).Single(p => p.CharacterId != 1).LastPosition!.Value;
        packets.Clear();
        var idleFrame = step.Invoke(manager, new object[] { room, now })!;
        await (Task)broadcast.Invoke(manager, new object[] { room.RoomId, idleFrame, new[] { channel } })!;
        var idleMove = packets.Single(p => BitConverter.ToInt16(p) == 110);
        check(idleMove[5] == 2 && BitConverter.ToInt16(idleMove, 6) == beforeIdle.XRaw &&
            BitConverter.ToInt16(idleMove, 8) == beforeIdle.YRaw && BitConverter.ToInt16(idleMove, 10) == beforeIdle.ZRaw,
            "stationary AI sends grounded idle with unchanged position");
        manager.RemoveRoom(room.RoomId);
    }
}
