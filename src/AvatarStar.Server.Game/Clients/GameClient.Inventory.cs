using System.Globalization;
using AvatarStar.Server.Game.Resources;

namespace AvatarStar.Server.Game;

internal partial class GameClient
{
    private sealed record StorageListResult(object[] Items, int CurrentPage, int TotalPages);

    // 仓库每个页签固定 5 页（官方抓包 t=2 s=24 pages=5）。
    private const int DepotPageCount = 5;

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
            // 空仓库同样要把 5 页报给客户端的翻页条（槽位网格）；过滤列表按件数分页，空即 1 页。
            return new StorageListResult(
                Array.Empty<object>(),
                CurrentPage: 1,
                TotalPages: pageBySlot ? DepotPageCount : 1);
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
            // 仓库是「槽位网格」：客户端 DealDepotList 用 dptDt[v.slot] 索引页内图标
            // （weapon_p_1..weapon_p_{pageSize}），页数直接取服务端下发的 pages，所以页数由槽位
            // 容量决定。官方抓包（t=2, s=24）是 pages=5，即每个仓库固定 5 页；槽位超出容量
            // （发放/扩容）时再按已用槽位扩容。
            var maxUsedSlot = filtered.Count == 0 ? 0 : filtered.Max(x => x.Slot);
            var capacity = Math.Max(Math.Max(pageSize * DepotPageCount, pageSize), maxUsedSlot);
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

        // 强化武器/材料列表（storage_item_filter, t=2）官方按 grade 降序 → 槽位升序下发
        // （抓包 page1 顺序：槽位 1,2,3,10,13,18,19,20[3 级] → 8,22[2 级] → 6,9[1 级]）；
        // 道具/宝石列表（t=3）与仓库列表一样是槽位升序。
        var ordered = !pageBySlot && storageType == 2
            ? filtered.OrderByDescending(x => x.Grade).ThenBy(x => x.Slot)
            : filtered.OrderBy(x => x.Slot);

        var items = ordered
            .Where(x => !pageBySlot || (x.Slot >= pageSlotStart && x.Slot <= pageSlotEnd))
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
                    // 官方下发的 slot 是「绝对槽位 - 页偏移」（抓包：过滤列表第 2 页出现 -1/0/16），
                    // 仓库列表里它正好等于页内槽位 1..pageSize，Lua 侧用 dptDt[v.slot] 索引图标。
                    slot = x.Slot - pageOffset,
                    storageSlot = x.Slot,
                    resource = clientResource,
                    subtype = payloadSubtype,
                    subType = payloadSubType, // several client helpers read camel-case subType even for equipment
                    grade = x.Grade,
                    // 客户端的「传承」加成预览会拿 menDt/menDt2.baseRank 比较（personalInfo.lua:1893），
                    // 官方列表里每件装备都带这个字段，缺了 Lua 会拿 nil 比数字直接报错。
                    baseRank = ResolveBaseRank(x),
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
