using System.Text.Json;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;

internal static class AiFillTests
{
    internal static void Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        static PracticeRoomManager.PracticeRoomSession Room(PracticeRoomManager manager, byte capacity = 16) =>
            manager.CreateOrReplaceRoom(new(1, "host", "fill", "LEVEL53", false, "", 400022, 4, capacity, 3,
                true, false, 0, false, 0, 30, 0, 0, 0, 0));
        static int Red(PracticeRoomManager.PracticeRoomSession room) => room.Members.Count(m => m.SlotIndex is >= 1 and <= 8);
        static int Blue(PracticeRoomManager.PracticeRoomSession room) => room.Members.Count(m => m.SlotIndex is >= 9 and <= 16);

        var manager = new PracticeRoomManager();
        var room = Room(manager);
        check(!manager.FillRoomWithBots(int.MaxValue, 1, config, out _), "fill rejects unknown room");
        check(!manager.FillRoomWithBots(room.RoomId, 2, config, out _) && room.Members.Count == 1,
            "only host can fill room");
        room.RoomState = 2;
        check(!manager.FillRoomWithBots(room.RoomId, 1, config, out _), "fill rejects running match");
        room.RoomState = 1;
        room.GameType = LobbyLevelCatalog.BossGameType;
        check(!manager.FillRoomWithBots(room.RoomId, 1, config, out _), "fill rejects expedition");
        room.GameType = 4;
        room.LevelId = -1;
        check(!manager.FillRoomWithBots(room.RoomId, 1, config, out _), "fill requires map navigation");
        room.LevelId = 400022;
        check(!manager.FillRoomWithBots(room.RoomId, 1, new(), out _) && room.Members.Count == 1,
            "invalid configuration leaves room untouched");
        check(manager.FillRoomWithBots(room.RoomId, 1, config, out _), "fill accepts native room id");
        check(room.Members.Count == 16 && room.CurrentClientNum == 16 && Red(room) == 8 && Blue(room) == 8,
            "one click fills sixteen-player room into two full teams");
        var botIds = room.Members.Where(m => !m.Host).Select(m => m.CharacterId).ToArray();
        var bots = botIds.Select(id => manager.GetBotPlayer(id)!).ToArray();
        check(botIds.Length == 15 && bots.All(p => p is not null), "fill creates fifteen ephemeral AI players");
        check(bots.All(p => p.Character.Occupation is >= 0 and <= 4), "random careers stay within five playable professions");
        check(room.Members.Where(m => !m.Host).All(m => m.Ready), "filled AI players are ready");
        check(bots.All(p => p.GetGameLoadoutItems().Count(w => w.ItemType == 2 && w.Slot <= 3) == 3),
            "each random AI receives three equipped weapons");
        check(bots.All(p => p.GetGameLoadoutItems().Where(w => w.ItemType == 2 && w.Slot <= 3)
            .All(w => ShopItemDatabase.TryGetShopItemByResource(w.Resource, out _))), "random fill weapons exist in shop catalog");
        var cards = ShopItemDatabase.GetAllShopItems().Values
            .Where(c => c.Type == ShopItemDatabase.ItemType.AvatarCard && c.Category == ShopItemDatabase.AvatarCardCategory)
            .Select(c => JsonSerializer.SerializeToElement(c.Avatar)).ToArray();
        check(bots.All(p =>
        {
            var avatar = JsonSerializer.SerializeToElement(p.Character.EquipAvatar);
            return cards.Any(card => card.EnumerateObject().Where(part => part.Name != "avatarId").All(part =>
                avatar.TryGetProperty(part.Name, out var actual) && actual.GetString() ==
                (string.IsNullOrWhiteSpace(part.Value.GetString()) ? "{}" : part.Value.GetString())));
        }), "random fill uses complete shop outfits");
        var fullMembers = JsonSerializer.Serialize(room.Members);
        var fullPlayers = bots.Select(p => JsonSerializer.Serialize(p.ToSnapshot())).ToArray();
        check(manager.FillRoomWithBots(room.RoomUid, 1, config, out _) && JsonSerializer.Serialize(room.Members) == fullMembers,
            "packed room uid and repeated fill preserve all members");
        check(botIds.Select(id => JsonSerializer.Serialize(manager.GetBotPlayer(id)!.ToSnapshot())).SequenceEqual(fullPlayers),
            "repeated fill keeps existing AI appearance and equipment");
        manager.RemoveRoom(room.RoomId);
        check(botIds.All(id => manager.GetBotPlayer(id) is null), "filled bots are removed with room");

        foreach (byte capacity in new byte[] { 0, 1, 2, 7, 8, 15, 24 })
        {
            manager = new(); room = Room(manager, capacity);
            check(manager.FillRoomWithBots(room.RoomId, 1, config, out _), $"fill accepts capacity {capacity}");
            var expected = capacity == 0 ? 16 : Math.Min((int)capacity, 16);
            check(room.Members.Count == expected && room.Members.Select(m => m.SlotIndex).Distinct().Count() == expected &&
                room.Members.All(m => m.SlotIndex is >= 1 and <= 16), $"capacity {capacity} respected without filling spectator slots");
            check(Math.Abs(Red(room) - Blue(room)) <= 1, $"capacity {capacity} balanced across teams");
            manager.RemoveRoom(room.RoomId);
        }

        manager = new(); room = Room(manager, 8);
        check(room.TryUpsertMember(new(2, "existing human", 10, 3, 0, 0, 0), out var human), "second human joins fill test");
        human.SlotIndex = 12; human.Ready = true;
        check(manager.ManageBots(room.RoomId, 1, 0, 4, 2, false, config, out _), "selected bots can precede random fill");
        var before = room.Members.ToDictionary(m => m.CharacterId, m => JsonSerializer.Serialize(m));
        var previousBots = room.Members.Where(m => manager.GetBotPlayer(m.CharacterId) is not null)
            .ToDictionary(m => m.CharacterId, m => manager.GetBotPlayer(m.CharacterId));
        check(manager.FillRoomWithBots(room.RoomId, 1, config, out _) && Red(room) == 4 && Blue(room) == 4,
            "fill balances a partially populated smaller room");
        check(before.All(p => JsonSerializer.Serialize(room.Members.Single(m => m.CharacterId == p.Key)) == p.Value) &&
            previousBots.All(p => ReferenceEquals(p.Value, manager.GetBotPlayer(p.Key))), "existing humans and bots keep slots and state");
        manager.RemoveRoom(room.RoomId);

        manager = new(); room = Room(manager);
        check(manager.ManageBots(room.RoomId, 1, 1, 2, 8, false, config, out _), "one team starts full");
        check(manager.FillRoomWithBots(room.RoomId, 1, config, out _) && Red(room) == 8 && Blue(room) == 8,
            "fill completes remaining team when other team is full");
        manager.RemoveRoom(room.RoomId);

        manager = new(); room = Room(manager, 8);
        check(room.TryUpsertMember(new(2, "spectator", 1, 0, 0, 0, 0), out var spectator), "spectator joins fill test");
        spectator.SlotIndex = 17;
        check(manager.FillRoomWithBots(room.RoomId, 1, config, out _) && room.Members.Count == 8 && spectator.SlotIndex == 17 &&
            Red(room) + Blue(room) == 7 && Math.Abs(Red(room) - Blue(room)) == 1,
            "spectator counts toward capacity and retains spectator slot");
        manager.RemoveRoom(room.RoomId);

        manager = new(); room = Room(manager);
        var attempts = new bool[4];
        Parallel.For(0, attempts.Length, i => attempts[i] = manager.FillRoomWithBots(room.RoomId, 1, config, out _));
        check(attempts.All(ok => ok) && room.Members.Count == 16 && room.Members.Select(m => m.CharacterId).Distinct().Count() == 16,
            "concurrent repeated fills cannot overfill or duplicate players");
        manager.RemoveRoom(room.RoomId);
    }
}
