using System.Text.Json;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;

internal static class ImportedActorTests
{
    internal static void Run(string root, SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        using var catalog = JsonDocument.Parse(File.ReadAllText(Path.Combine(root,
            "src/AvatarStar.Server.Game/Config/finalcombat_items.json")));
        var cards = catalog.RootElement.GetProperty("cards").EnumerateArray().ToArray();
        var weapons = catalog.RootElement.GetProperty("weapons").EnumerateArray().ToArray();
        check(cards.Length > 300 && weapons.Length > 400, "complete imported actor catalog is loaded");
        var visibleCards = new HashSet<int>();
        var visibleWeapons = new HashSet<int>();
        for (var page = 1; ; page++)
        {
            var list = ShopItemProvider.GetAvatarCardListWithPaging(page, 6, "1", null, "1");
            foreach (var item in list.items) visibleCards.Add(int.Parse(item["sid"].ToString()!));
            if (page >= list.totalPages) break;
        }
        for (var page = 1; ; page++)
        {
            var list = ShopItemProvider.GetShopItemListWithPaging(2, page, 12);
            foreach (var item in list.items) visibleWeapons.Add(int.Parse(item["sid"].ToString()!));
            if (page >= list.totalPages) break;
        }
        foreach (var entry in cards.Concat(weapons))
        {
            var sid = entry.GetProperty("sid").GetInt32();
            var item = ShopItemDatabase.GetShopItem(sid);
            check(item is not null && ShopItemProvider.CanPurchaseItem(sid), $"imported item {sid} is purchasable");
            check((item!.Type == ShopItemDatabase.ItemType.AvatarCard ? visibleCards : visibleWeapons).Contains(sid),
                $"imported item {sid} is reachable through shop pagination");
            check(item.Prices.Any(p => p.Currency == ShopItemDatabase.CurrencyType.Gold && p.Price == 1),
                $"imported item {sid} has a valid gold price");
            if (item.Type == ShopItemDatabase.ItemType.Equipment)
            {
                check(ShopItemDatabase.TryGetShopItemByResource(item.Resource, out var resolved) && resolved.Sid == sid,
                    $"weapon {sid} resolves battle stats by its imported resource");
                check(ShopItemDatabase.GetClientResource(item) == entry.GetProperty("resource").GetString(),
                    $"weapon {sid} retains its client model name");
            }
        }
        for (var occupation = 0; occupation < 5; occupation++)
        {
            var player = new PlayerStore().CreateCharacter(80000 + occupation, "Imported actor test", occupation, config);
            foreach (var entry in cards.Where((_, i) => i % 23 == 0).Concat(weapons.Where((_, i) => i % 31 == 0)))
            {
                var item = ShopItemDatabase.GetShopItem(entry.GetProperty("sid").GetInt32())!;
                check(player.TryPurchaseToInventory(item, 1, item.Prices[0]), "imported item purchase creates inventory instance");
                var storage = item.Type == ShopItemDatabase.ItemType.AvatarCard ? 5 : 2;
                var bought = player.Storages[storage].Values.Single(i => i.Sid == item.Sid);
                if (storage == 5)
                {
                    check(player.EquipAvatarCard(bought.Pid), "imported costume equips on each profession");
                    check(JsonSerializer.Serialize(player.Character.EquipAvatar).Contains("fca_"), "imported costume reaches character payload");
                }
                else
                {
                    check(player.TrySetHotKeySlot(1, bought.Pid), "imported weapon equips in battle hotbar");
                    check(player.GetGameLoadoutItems().Any(i => i.Resource == item.Resource && i.Subtype == item.Subtype),
                        "imported weapon model and subtype reach battle loadout");
                }
            }
            var restored = PlayerStore.PlayerState.FromSnapshot(JsonSerializer.Deserialize<PlayerStateSnapshot>(
                JsonSerializer.Serialize(player.ToSnapshot()))!);
            check(JsonSerializer.Serialize(restored.Character.EquipAvatar).Contains("fca_"), "imported costume survives save/load");
            check(restored.GetGameLoadoutItems().Any(i => i.Resource.StartsWith("fca_")), "imported weapon survives save/load");
        }
    }
}
