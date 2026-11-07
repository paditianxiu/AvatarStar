using System.Net;
using System.Net.Sockets;
using System.Reflection;
using AvatarStar.Server;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Utilities;

internal static class KillStreakTests
{
    private const BindingFlags Private = BindingFlags.Instance | BindingFlags.NonPublic;

    internal static async Task Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        var manager = new PracticeRoomManager();
        var store = new PlayerStore();
        store.CreateCharacter(1, "streak-red", 0, config);
        var room = manager.CreateOrReplaceRoom(new(1, "streak-red", "streak", "LEVEL53", false, "", 400022, 4, 16, 3,
            true, false, 1, false, 0, 30, 0, 0, 0, 0));
        manager.TryEnterRoom(room.RoomId, "", new(2, "streak-blue", 30, 0, 0, 0, 0), out _, out _);
        manager.TryEnterRoom(room.RoomId, "", new(3, "other-blue", 30, 0, 0, 0, 0), out _, out _);
        room.Members.Single(m => m.CharacterId == 2).SlotIndex = 9;
        room.Members.Single(m => m.CharacterId == 3).SlotIndex = 10;
        check(manager.ManageBots(room.RoomId, 1, 0, 4, 1, false, config, out _), "rank test includes an actual AI member");
        check(manager.TryStartGame(room.RoomId, out _, out _), "streak match starts");
        var frames = new Dictionary<long, List<byte[]>>();
        PracticeRoomChannelProtocol Channel(long id, byte team, out byte uid)
        {
            uint decode = 0;
            var sent = new List<byte[]>(); frames[id] = sent;
            var c = new PracticeRoomChannelProtocol(manager, store, p =>
            {
                var data = p.ToArray(); XorNetworkCodec.DecodeInPlace(data, ref decode); sent.Add(data); return Task.CompletedTask;
            }, IPAddress.Loopback, "streak-test");
            uid = manager.RegisterGameChannel(room.RoomId, c, id, "player");
            typeof(PracticeRoomChannelProtocol).GetField("_localGameUid", Private)!.SetValue(c, uid);
            typeof(PracticeRoomChannelProtocol).GetField("_currentGameRoom", Private)!.SetValue(c, room);
            manager.UpdateGamePlayerState(room.RoomId, uid, team, 1000);
            manager.UpdateGamePosition(room.RoomId, uid, new(0, 0, (short)(-256 * id), 0, 0, 0, DateTimeOffset.UtcNow));
            return c;
        }
        var red = Channel(1, 0, out var redUid);
        var blue = Channel(2, 1, out var blueUid);
        _ = Channel(3, 1, out var otherUid);
        using var listener = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
        listener.Bind(new IPEndPoint(IPAddress.Loopback, 0)); listener.Listen(1);
        using var receiver = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
        await receiver.ConnectAsync(listener.LocalEndPoint!);
        using var sender = await listener.AcceptAsync();
        using var feedbackStream = new NetworkStream(receiver, ownsSocket: false);
        var feedbackClient = new GameClient(null!, sender, null!, null!, null!, store, manager);
        manager.RegisterGameClient(1, feedbackClient);
        async Task Kill(PracticeRoomChannelProtocol source, byte killer, byte victim)
        {
            manager.TrySetGamePlayerHealth(room.RoomId, victim, 1, out _);
            foreach (var list in frames.Values) list.Clear();
            var shot = new PracticeRoomManager.GameShootAction(killer, 0, 1, 0, 256, 0, 0, 0, 0, 0, -1, DateTimeOffset.UtcNow);
            var result = await manager.BroadcastGameDamageAsync(room.RoomId, source, killer, 1000,
                clientTargetUid: victim, weaponHit: new(shot, PlayShot: true));
            check(result.Killed, "streak test awards one real death");
        }
        for (var count = 1; count <= 6; count++)
        {
            await Kill(red, redUid, blueUid);
            check(manager.GetGamePlayerScore(room.RoomId, 1) == new PracticeRoomManager.GamePlayerScore(count, 0, count, count),
                "living killer's streak increases from one through six");
            check(frames.Values.All(p => BitConverter.ToInt16(p[0]) == 113 &&
                BitConverter.ToInt16(p[0], 10) == count && BitConverter.ToInt16(p[0], 12) == count),
                "native kill HUD receives the exact streak before it plays the kill notification");
            check(frames.Values.All(p => p.All(f => BitConverter.ToInt16(f) != 189)), "ordinary kill does not show revenge");
            if (count == 5)
            {
                using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(3));
                var length = new byte[1]; await feedbackStream.ReadExactlyAsync(length, timeout.Token);
                check(length[0] < 128, "five-kill push has a complete single-byte VLE frame length");
                var payload = new byte[length[0]]; await feedbackStream.ReadExactlyAsync(payload, timeout.Token);
                uint decode = 0x57495442; XorNetworkCodec.DecodeInPlace(payload, ref decode);
                var reader = new PacketReader(payload); reader.TryReadByte(out var opcode); reader.TryReadString(out var lua);
                check(opcode == 0x20 && lua.Contains("cmd=\"kill_streak\"") && lua.Contains("kills=5") && lua.Contains("streak=5"),
                    "actual lobby connection delivers the fifth-kill sound command through encrypted push framing");
            }
            else check(receiver.Available == 0, "special fifth-kill accent is not sent for other streak counts");
        }
        manager.TrySetGamePlayerHealth(room.RoomId, blueUid, 1000, out _);
        await Kill(blue, blueUid, redUid);
        check(manager.GetGamePlayerScore(room.RoomId, 1) == new PracticeRoomManager.GamePlayerScore(6, 1, 0, 6),
            "death clears current streak and preserves lifetime-best streak within the match");
        check(frames[2].Last().SequenceEqual(new byte[] { 189, 0, redUid }) &&
            frames[1].All(p => BitConverter.ToInt16(p) != 189) && frames[3].All(p => BitConverter.ToInt16(p) != 189),
            "native revenge packet identifies the old killer and reaches only the avenger");
        manager.TrySetGamePlayerHealth(room.RoomId, redUid, 1000, out _);
        await Kill(red, redUid, otherUid);
        check(manager.GetGamePlayerScore(room.RoomId, 1).Streak == 1 && frames[1].All(p => BitConverter.ToInt16(p) != 189),
            "first kill after death starts at one and a different victim is not revenge");
        // Reconnecting the old killer must not change the character that is owed revenge.
        manager.UnregisterGameChannel(room.RoomId, blue, out _);
        var oldBlueUid = blueUid;
        blue = Channel(2, 1, out blueUid);
        await Kill(red, redUid, blueUid);
        check(blueUid != oldBlueUid && frames[1].Last().SequenceEqual(new byte[] { 189, 0, blueUid }),
            "revenge tracks character identity across changed network UIDs");
        await Kill(red, redUid, blueUid);
        check(frames[1].All(p => BitConverter.ToInt16(p) != 189), "revenge is consumed once and does not repeat on the same victim");
        await manager.SendGameScoreSnapshotAsync(room.RoomId, red);
        var snapshot = frames[1].Last(p => BitConverter.ToInt16(p) == 112 && p[2] == redUid);
        check(BitConverter.ToInt16(snapshot, 11) == 3 && BitConverter.ToInt16(snapshot, 13) == 6,
            "late entry snapshot restores current and best streak independently");

        // Test actual actor-create frames, including the AI path, against native rank field widths.
        var makePlayer = typeof(PracticeRoomChannelProtocol).GetMethod("CreateGamePacketPlayer", Private)!;
        var sendPlayer = typeof(PracticeRoomChannelProtocol).GetMethod("SendPacket103GameCharacterCreateAsync", Private)!;
        foreach (var player in manager.ListGamePlayers(room.RoomId))
        {
            var packetPlayer = makePlayer.Invoke(red, new object[] { room, player })!;
            await (Task)sendPlayer.Invoke(red, new object[] { packetPlayer, (short)103 })!;
            var r = new PacketReader(frames[1].Last());
            r.TryReadShort(out _); r.TryReadByte(out _); r.TryReadByte(out _); r.TryReadLong(out _);
            r.TryReadString(out _); r.TryReadInt(out _); r.TryReadInt(out var rank); r.TryReadByte(out var military);
            check(rank == 3 && military == 14, "actor info uses gold rank and highest military badge for every player");
        }
        room.RoomState = 1;
        check(manager.TryStartGame(room.RoomId, out _, out _) && manager.GetGamePlayerScore(room.RoomId, 1) == default &&
            room.Scores.LastKiller.Count == 0, "next match clears streak, personal best and revenge identities");
        manager.RemoveRoom(room.RoomId);
    }
}
