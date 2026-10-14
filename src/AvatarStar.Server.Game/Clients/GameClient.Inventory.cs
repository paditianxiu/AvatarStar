using System.Globalization;
using AvatarStar.Server.Game.Resources;

namespace AvatarStar.Server.Game;

internal partial class GameClient
{
    private sealed record StorageListResult(object[] Items, int CurrentPage, int TotalPages);

    private StorageListResult GetStorageItems(
        int storageType,
        int page,
        int pageSize,
        IReadOnlySet<int>? subtypeFilter = null,
        IReadOnlySet<int>? gradeFilter = null,
        bool pageBySlot = true,
        string? excludePid = null)
    {
        var player = GetActivePlayerStateOrDefault();
        player.EnsureStarterInventory();

        if (!player.Storages.TryGetValue(storageType, out var slots) || slots.Count == 0)
        {
            return new StorageListResult(Array.Empty<object>(), CurrentPage: 1, TotalPages: 1);
        }

        pageSize = pageSize <= 0 ? 24 : pageSize;

        var query = slots
            .OrderBy(x => x.Key)
            .Select(x =>
            {
                var item = x.Value;
                // Trust dictionary key as canonical slot to avoid legacy saved data
                // with mismatched item.Slot causing client UI indexing issues.
                return item.Slot == x.Key ? item : item with { Slot = x.Key };
            })
            .AsEnumerable();

        if (subtypeFilter is { Count: > 0 })
        {
            query = query.Where(x => subtypeFilter.Contains(x.Subtype) || subtypeFilter.Contains(x.SubType));
        }

        if (!string.IsNullOrWhiteSpace(excludePid))
        {
            // 强化武器面板会把「被强化的武器」pid 传进来（refitFilterItemId），
            // 官方服务端会把它从可选材料列表里剔除。
            query = query.Where(x => !string.Equals(x.Pid, excludePid, StringComparison.Ordinal));
        }

        if (gradeFilter is { Count: > 0 })
        {
            query = query.Where(x => gradeFilter.Contains(x.Grade));
        }

        var filtered = query.ToList();

        int totalPages;
        int currentPage;
        int pageSlotStart;
        int pageSlotEnd;

        if (pageBySlot)
        {
            // PersonalInfo UI treats `slot` as the on-page slot index (1..pageSize) and will
            // index UI controls by it (weapon_p_1..weapon_p_24, person_card_p_1..10, etc).
            // Therefore we must page by absolute storage slot ranges, not by item count.
            var defaultCapacity = storageType switch
            {
                5 => 10, // avatar cards in PersonalInfo
                _ => 36
            };
            var capacity = Math.Max(Math.Max(defaultCapacity, pageSize), filtered.Max(x => x.Slot));
            totalPages = Math.Max(1, (int)Math.Ceiling(capacity / (double)pageSize));
            currentPage = Math.Clamp(page <= 0 ? 1 : page, 1, totalPages);
            pageSlotStart = (currentPage - 1) * pageSize + 1;
            pageSlotEnd = pageSlotStart + pageSize - 1;
        }
        else
        {
            totalPages = Math.Max(1, (int)Math.Ceiling(filtered.Count / (double)pageSize));
            currentPage = Math.Clamp(page <= 0 ? 1 : page, 1, totalPages);
            pageSlotStart = (currentPage - 1) * pageSize + 1;
            pageSlotEnd = int.MaxValue;
        }

        var pageOffset = (currentPage - 1) * pageSize;

        var items = filtered
            .Where(x => !pageBySlot || (x.Slot >= pageSlotStart && x.Slot <= pageSlotEnd))
            .OrderBy(x => x.Slot)
            .Select(x =>
            {
                var shopItem = ShopItemDatabase.GetShopItem(x.Sid);
                var effectiveSubType = x.SubType > 0 ? x.SubType : x.Subtype;
                var payloadSubtype = x.Subtype;
                var payloadSubType = effectiveSubType;
                var payloadCategory = x.Category;
                if (TryResolveBoxInventoryIdentity(x, out var boxSubtype, out var boxCategory))
                {
                    payloadSubtype = boxSubtype;
                    payloadSubType = boxSubtype;
                    payloadCategory = boxCategory;
                }
                var clientResource = ShopItemDatabase.GetClientResource(
                    shopItem,
                    x.Resource,
                    x.Type,
                    payloadSubType);
                // In tooltip/storage Lua, occupation=0 means "all classes"; negative values are shop-only config syntax.
                var occupation = shopItem?.Occupation ?? 0;
                if (occupation < 0)
                {
                    occupation = 0;
                }

                return (object)new
                {
                    pid = int.TryParse(x.Pid, NumberStyles.Integer, CultureInfo.InvariantCulture, out var pidNum) ? pidNum : 0,
                    // Normalize to on-page slot index (1..pageSize) so Lua UI doesn't index missing controls.
                    slot = pageBySlot ? (x.Slot - pageOffset) : x.Slot,
                    storageSlot = x.Slot,
                    resource = clientResource,
                    subtype = payloadSubtype,
                    subType = payloadSubType, // several client helpers read camel-case subType even for equipment
                    grade = x.Grade,
                    level = shopItem?.Level ?? 0,
                    occupation,
                    avatarLevel = shopItem?.AvatarLevel ?? 0,
                    quantity = x.Quantity,
                    unitType = x.UnitType,
                    unit = x.Unit,
                    remain = x.Remain,
                    isRenew = x.IsRenew,
                    category = payloadCategory,
                    isBind = string.IsNullOrWhiteSpace(x.IsBind) ? "N" : x.IsBind,
                    isEquip = string.IsNullOrWhiteSpace(x.IsEquip) ? "N" : x.IsEquip,
                    // Keep storage item shape close to `tip_player_item` to avoid client nil-index crashes.
                    bindType = 0,
                    canEquip = "Y",
                    // Client menus expect these fields for enabling operations; nil can disable "equip/unequip" paths.
                    isLock = 0,
                    canUnbind = "N",
                    canAdvanced = false,
                    // Reinforce/insert UI assumes `pluses` exists when inspecting items.
                    pluses = new
                    {
                        stamina = 0,
                        cureQuantity = 0,
                        armor = 0,
                        recovery = 0
                    },
                    // 强化武器 (refit) 进度：官方客户端在物品列表里同时下发 plusLevel/refitTotalExp/refitLevel。
                    plusLevel = x.PlusLevel,
                    refitTotalExp = x.RefitTotalExp,
                    refitLevel = x.RefitLevel,
                    sid = x.Sid,
                    type = x.Type,
                    avatar = LuaSerializer.NormalizeJsonElement(x.Avatar),
                    position = x.Position,
                    display = x.Display,
                    designer = x.Designer,
                    description = x.Description
                };
            })
            .ToArray();

        return new StorageListResult(items, currentPage, totalPages);
    }

    private static HashSet<int> ParseIntSetArg(string? raw)
    {
        var set = new HashSet<int>();
        if (string.IsNullOrWhiteSpace(raw))
        {
            return set;
        }

        foreach (var part in raw.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            var value = part.Split(',', StringSplitOptions.TrimEntries)[0];
            if (int.TryParse(value, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed) && parsed > 0)
            {
                set.Add(parsed);
            }
        }

        return set;
    }

    /// <summary>
    /// 强化武器面板下发的 grade 是「逗号分隔 + 结尾逗号」（例如 "3,2,"），与 subType 的
    /// "id,count;" 形式不同，所以这里同时按 ';' 与 ',' 切分，才能把 2 级和 3 级武器都当成材料。
    /// </summary>
    private static HashSet<int> ParseGradeFilterArg(string? raw)
    {
        var set = new HashSet<int>();
        if (string.IsNullOrWhiteSpace(raw))
        {
            return set;
        }

        foreach (var part in raw.Split(
                     new[] { ';', ',' },
                     StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (int.TryParse(part, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed) && parsed > 0)
            {
                set.Add(parsed);
            }
        }

        return set;
    }

    private bool TryPurchaseToInventory(
        ShopItemDatabase.ShopItem shopItem,
        int quantity,
        ShopItemDatabase.ShopPrice? price = null)
    {
        var player = GetActivePlayerStateOrDefault();
        return player.TryPurchaseToInventory(shopItem, quantity, price);
    }
}
