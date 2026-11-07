using System.Collections.Concurrent;
using System.Net;
using System.Numerics;
using System.Reflection;
using System.Text.Json;
using AvatarStar.Server;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;
using AvatarStar.Server.Utilities;

internal static class AiTests
{
    internal static async Task Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        var graph = new AiNavigation(
            [[0, 0, 0, 1], [0, 0, 2, 0, 2], [2, 0, 2, 1, 3], [2, 0, 0, 2], [10, 0, 0]],
            [[1, 0, -1, 1, 3, -1, 1, 3, 1], [1, 0, -1, 1, 3, 1, 1, 0, 1]]);
        check(graph.Path(0, 3).SequenceEqual(new[] { 0, 1, 2, 3 }), "AI path goes around wall");
        check(graph.Path(0, 4).Count == 0, "AI cannot cross disconnected floors");
        check(!graph.Visible(new(0, 1, 0), new(2, 1, 0)), "wall blocks bullets");
        check(graph.Visible(new(0, 1, 2), new(2, 1, 2)), "clear sight line permits bullets");
        foreach (var level in new long[] { 400013, 400020, 400021, 400022 })
        {
            var map = AiNavigation.ForLevel(level)!;
            check(map is not null && map.Points.Length > 1000, $"map {level} collision navigation loads");
            check(map!.Path(map.Spawn(0, 0), map.Spawn(1, 0)).Count > 10, $"map {level} team spawns connected");
        }
        for (var career = 0; career < 5; career++)
        {
            var variants = new HashSet<string>();
            for (var seed = 0; seed < 12; seed++)
            {
                var player = AiPlayerFactory.Create(1500000100 + seed, career, config, new Random(seed));
                var weapons = player.GetGameLoadoutItems().Where(w => w.ItemType == 2 && w.Slot <= 3).ToArray();
                check(weapons.Length == 3 && weapons.Select(w => w.Slot).Distinct().Count() == 3, "AI has three equipped weapons");
                check(weapons.All(w => ShopItemDatabase.TryGetShopItemByResource(w.Resource, out _)), "AI weapons exist in catalog");
                check(player.Character.Occupation == career && JsonSerializer.Serialize(player.Character.EquipAvatar).Contains("outerwear"), "AI full profession appearance");
                variants.Add(string.Join(',', weapons.Select(w => w.Resource)));
            }
            check(variants.Count > 1, $"profession {career} weapon selection varies");
        }

        var manager = new PracticeRoomManager();
        var room = manager.CreateOrReplaceRoom(new(1, "AI-test-host", "AI-test", "LEVEL53", false, "", 400022, 4, 16, 3,
            true, false, 0, false, 0, 30, 0, 0, 0, 0));
        bool Add(long actor, int team, int career, int count) => manager.ManageBots(room.RoomId, actor, team, career, count, false, config, out _);
        check(manager.TryGetAiRoom(room.RoomId, out var channelRoom) && channelRoom == room, "native room screen RoomUid resolves channel room id");
        check(manager.TryGetAiRoom(room.RoomUid, out var lobbyRoom) && lobbyRoom == room, "packed lobby room uid also resolves");
        check(!manager.TryGetAiRoom(int.MaxValue, out _), "unknown room uid rejected");
        check(!Add(2, 1, 0, 1), "nonhost cannot add bots");
        check(!Add(1, -1, 0, 1) && !Add(1, 2, 0, 1), "invalid team rejected");
        check(!Add(1, 1, 5, 1) && !Add(1, 1, 0, 9) && !Add(1, 1, 0, 0), "invalid career/count rejected");
        check(!Add(1, 0, 0, 8) && room.Members.Count == 1, "batch overflow is atomic");
        check(Add(1, 1, 0, 8), "eight blue slots can be filled");
        check(room.Members.Count(m => m.SlotIndex is >= 9 and <= 16) == 8, "bots occupy selected blue team");
        check(!Add(1, 1, 0, 1) && room.Members.Count == 9, "full team rejected without partial add");
        check(manager.ManageBots(room.RoomUid, 1, 1, 0, 1, true, config, out _) && room.Members.Count == 1, "remove only requested AI team");
        check(Add(1, 1, 0, 1), "single opponent added");
        var botId = room.Members.Single(m => !m.Host).CharacterId;
        check(manager.TryStartGame(room.RoomId, out _, out _), "AI match starts");
        check(!Add(1, 0, 0, 1), "cannot change bots during a match");
        var bot = manager.ListGamePlayers(room.RoomId).Single(p => p.CharacterId == botId);
        var packets = new ConcurrentQueue<byte[]>(); uint decodeState = 0;
        var store = new PlayerStore();
        var channel = new PracticeRoomChannelProtocol(manager, store, p =>
        {
            var bytes = p.ToArray(); XorNetworkCodec.DecodeInPlace(bytes, ref decodeState); packets.Enqueue(bytes); return Task.CompletedTask;
        }, IPAddress.Loopback, "AI-test");
        var uid = manager.RegisterGameChannel(room.RoomId, channel, 1, "AI-test-host");
        check(uid != bot.Uid && manager.ListGamePlayers(room.RoomId).Select(p => p.Uid).Distinct().Count() == 2, "AI/human UIDs remain distinct");
        typeof(PracticeRoomChannelProtocol).GetField("_currentGameRoom", BindingFlags.NonPublic | BindingFlags.Instance)!.SetValue(channel, room);
        typeof(PracticeRoomChannelProtocol).GetField("_localGameUid", BindingFlags.NonPublic | BindingFlags.Instance)!.SetValue(channel, uid);
        var nav = AiNavigation.ForLevel(400022)!;
        var pose = bot.LastPosition!.Value;
        var origin = new Vector3(pose.XRaw / 256f, pose.YRaw / 256f, pose.ZRaw / 256f);
        var nearby = nav.Points.First(p => Vector3.Distance(p, origin) is > 3 and < 6 && Math.Abs(p.Y - origin.Y) < .5f &&
            nav.Visible(origin + Vector3.UnitY * 1.3f, p + Vector3.UnitY * 1.2f));
        manager.UpdateGamePlayerState(room.RoomId, uid, 0, 100000);
        manager.TrySetGamePlayerHealth(room.RoomId, uid, 100000, out _);
        manager.UpdateGamePosition(room.RoomId, uid, new((short)(nearby.X * 256), (short)(nearby.Y * 256), (short)(nearby.Z * 256), 0, 0, 0, DateTimeOffset.UtcNow));
        check(manager.GetBotPlayer(botId) is not null && store.ListCharacters().Count == 0, "AI identity does not enter persistent player store");
        await manager.ActivateBotsAsync(room.RoomId, channel);
        await Task.Delay(2300);
        check(packets.Any(p => BitConverter.ToInt16(p) == 111 && p[2] == bot.Uid), "bot spawn broadcast");
        check(packets.Any(p => BitConverter.ToInt16(p) == 107 && p[2] == bot.Uid), "bot enter broadcast");
        check(packets.Count(p => BitConverter.ToInt16(p) == 110) >= 10, "continuous AI movement broadcasts");
        check(packets.Any(p => BitConverter.ToInt16(p) == 113), "AI attack animation broadcasts");
        manager.TryGetGamePlayerHealth(room.RoomId, uid, out var health, out _);
        check(health < 100000, "AI attacks damage opposing human");
        check(packets.Any(p => BitConverter.ToInt16(p) == 128), "AI weapon selection broadcasts");
        var kill = await manager.BroadcastGameDamageAsync(room.RoomId, channel, uid, 100000, clientTargetUid: bot.Uid);
        check(kill.Killed, "human can kill AI through normal combat");
        var attacks = packets.Count(p => BitConverter.ToInt16(p) == 113);
        await Task.Delay(450);
        check(packets.Count(p => BitConverter.ToInt16(p) == 113) == attacks, "dead AI does not shoot");
        await Task.Delay(2850);
        manager.TryGetGamePlayerHealth(room.RoomId, bot.Uid, out var botHealth, out var botMax);
        check(botHealth == botMax && botHealth > 0, "AI respawns at full health");
        check(packets.Count(p => BitConverter.ToInt16(p) == 111 && p[2] == bot.Uid) >= 2, "AI respawn broadcasts");
        manager.TryLeaveGame(room.RoomId, 1, channel, out _, out _);
        check(room.RoomState == 1, "last human leaving resets AI room");
        var total = packets.Count; await Task.Delay(250);
        check(packets.Count == total, "no broadcasts after last human leaves");
        manager.RemoveRoom(room.RoomId);
        check(manager.GetBotPlayer(botId) is null, "room disposal clears ephemeral AI identities");
    }
}
