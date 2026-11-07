using System.Text.Json;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;

internal static class WeaponQualityTests
{
    internal static void Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        var weapons = ShopItemDatabase.GetAllShopItems().Values
            .Where(x => (int)x.Type == 2 && x.Subtype is >= 1 and <= 16).ToArray();
        check(weapons.Length >= 968 && weapons.All(x => x.Grade == 5), "all native and imported shop weapons are orange");
        var orangeSids = new HashSet<int>();
        for (var page = 1; ; page++)
        {
            var payload = ShopItemProvider.GetShopItemListWithPaging(2, page, 100);
            foreach (var item in payload.items)
                if (Convert.ToInt32(item["grade"]) == 5) orangeSids.Add(Convert.ToInt32(item["sid"]));
            if (page >= payload.totalPages) break;
        }
        check(weapons.All(x => orangeSids.Contains(x.Sid)), "all weapon shop pages carry orange grade");

        // Grade may precede type/subtype in old JSON. Its effective value must
        // remain orange after deserialization, record copies and persistence.
        var old = JsonSerializer.Deserialize<InventoryItem>("""
            {"Grade":2,"Pid":"777123","Slot":20,"Type":2,"Subtype":1,"SubType":1,
             "Resource":"smg_01","Sid":20001,"Quantity":1,"UnitType":1,"Unit":1,
             "Remain":1,"RefitLevel":7,"RefitTotalExp":12345,"PlusLevel":7}
            """)!;
        check(old.Grade == 5 && (old with { Grade = 3 }).Grade == 5, "legacy weapon and record copy resolve orange rarity");
        var restored = JsonSerializer.Deserialize<InventoryItem>(JsonSerializer.Serialize(old))!;
        check(restored.Grade == 5 && restored.Pid == old.Pid && restored.RefitTotalExp == 12345 && restored.PlusLevel == 7,
            "orange rarity preserves existing item identity and enhancement progress");
        check((old with { Subtype = 101, SubType = 101 }).Grade == 2, "badges retain their quality");
        check((old with { Subtype = 102, SubType = 102 }).Grade == 2, "back equipment retains its quality");
        check((old with { Type = 5 }).Grade == 2, "costume cards retain their quality");
        check((old with { Subtype = 0, SubType = 6 }).Grade == 5, "legacy subType alias resolves weapon quality");

        var player = new PlayerStore().CreateCharacter(98234, "Orange weapon test", 0, config);
        player.Storages[2][20] = old;
        check(player.TrySetHotKeySlot(1, old.Pid), "legacy orange weapon equips");
        var saved = player.ToSnapshot();
        var loaded = PlayerStore.PlayerState.FromSnapshot(JsonSerializer.Deserialize<PlayerStateSnapshot>(JsonSerializer.Serialize(saved))!);
        check(loaded.Storages[2][20].Grade == 5 && loaded.Storages[2][20].Pid == old.Pid, "old owned weapon stays orange after player save/load");
        check(loaded.GetGameLoadoutItems().Any(x => x.Resource == "smg_01" && x.Grade == 5), "battle equipment carries orange grade");
        var hotkeys = JsonSerializer.SerializeToElement(loaded.GetHotKeySlots());
        check(hotkeys.EnumerateArray().Any(x => x.TryGetProperty("grade", out var g) && g.GetInt32() == 5),
            "lobby hotbar carries orange grade");
    }
}
