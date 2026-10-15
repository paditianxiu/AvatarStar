using System.Globalization;
using System.Text;
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
            // 强化面板的物品列表（storage_item_filter，pageBySlot=false）按「件数」翻页：
            // 官方抓包 page1/2/3 分别返回 12/12/5 件（s=12），所以必须跳过前面的 pageOffset 件，
            // 否则每一页都会把第一页的内容重新发一遍，翻页按钮看起来没反应。
            // 大厅仓库（pageBySlot=true）走槽位窗口，这里不做额外截断。
            .Skip(pageBySlot ? 0 : pageOffset)
            .Take(pageBySlot ? int.MaxValue : pageSize)
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
                    // 造型卡 (t=5/6) 仓库列表官方下发 avatarLevel；缺失时客户端卡片上的
                    // 等级角标（ComFuc.ShowUpgradeLevel 用 t=5 读 avatarLevel）不显示。
                    avatarLevel = shopItem?.AvatarLevel ?? (x.Type is 5 or 6 ? 1 : 0),
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
                    description = x.Description,
                    // 造型卡（t=5）官方仓库列表额外下发这些字段，缺了会让卡片按钮/继承面板状态异常。
                    isDefault = x.Type is 5 or 6 && x.Slot == 1 ? "Y" : "N",
                    useStatus = 0,
                    avatarPurchaseStatus = 0,
                    plus = new Dictionary<string, object>(),
                    sysAvatarPlus = new Dictionary<string, object>()
                };
            })
            .ToArray();

        return new StorageListResult(items, currentPage, totalPages);
    }

    /// <summary>
    /// storage_storage_list / storage_neaten 共用的回包。官方这两个接口的回包逐字节相同
    /// （log-2026-10-15.txt：storage_neaten 与前后两次 storage_storage_list 的 body 完全一致，
    /// 都是 24 件、page=1/5），所以整理完只要重新下发当前页即可。
    /// </summary>
    private static string BuildStorageListPayload(int storageType, int pageSize, StorageListResult result)
    {
        return "ok = 1\n" +
               $"t = {storageType}\n" +
               $"s = {pageSize}\n" +
               $"page = {result.CurrentPage}\n" +
               $"pages = {result.TotalPages}\n" +
               "items = " + LuaSerializer.SerializeSequential(result.Items);
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

    /// <summary>
    /// 造型卡 (type=5/6) 的物品提示载荷。字段顺序与官方抓包（log-2026-10-15.txt 的
    /// tip_sys_avatar / tip_player_avatar）一致：客户端 Other/lobby/tip/tip.lua 的 tip_t[5] 会
    /// 直接读写这些字段，缺字段会拿到 nil 而报错（例如 math.floor(data.stamina * 10000)）。
    /// 造型卡没有等级/强化概念，所以数值字段统一给 0。
    /// </summary>
    private static string BuildAvatarCardTipPayload(
        InventoryItem? invItem,
        ShopItemDatabase.ShopItem? shopItem,
        string id,
        int subType,
        string display,
        string designer,
        string resource,
        bool isSys,
        int grade,
        int level,
        int avatarLevel,
        object? avatar,
        long nowMs)
    {
        var sb = new StringBuilder();

        sb.Append("id = ").Append(LuaEscape(id)).Append('\n');
        sb.Append("type = ").Append((int)ShopItemDatabase.ItemType.AvatarCard).Append('\n');
        sb.Append("subType = ").Append(subType).Append('\n');
        sb.Append("display = ").Append(LuaEscape(display)).Append('\n');

        if (invItem is null)
        {
            // 商城里的系统卡（tip_sys_avatar）：官方没有 isBind/isEquip/unit*。
            sb.Append("bindType = ").Append(shopItem?.BindType ?? 2).Append('\n');
            sb.Append("grade = ").Append(grade).Append('\n');
            sb.Append("isSell = ").Append(LuaEscape(shopItem?.IsSell ?? "N")).Append('\n');
            sb.Append("designer = ").Append(LuaEscape(designer)).Append('\n');
            sb.Append("isSys = ").Append(isSys ? "true" : "false").Append('\n');
            sb.Append("level = ").Append(level).Append('\n');
            sb.Append("avatarLevel = ").Append(avatarLevel).Append('\n');
            // 官方字段名就是这个拼写（ventureFroce）。
            sb.Append("ventureFroce = 0\n");
        }
        else
        {
            // 玩家拥有的卡（tip_player_avatar）：带绑定/实例/背包字段。
            sb.Append("isBind = ").Append(LuaEscape(string.IsNullOrWhiteSpace(invItem.IsBind) ? "N" : invItem.IsBind)).Append('\n');
            sb.Append("isEquip = ").Append(LuaEscape(string.IsNullOrWhiteSpace(invItem.IsEquip) ? "N" : invItem.IsEquip)).Append('\n');
            sb.Append("canEquip = \"Y\"\n");
            sb.Append("bindType = 1\n");
            sb.Append("unitType = ").Append(invItem.UnitType).Append('\n');
            sb.Append("unit = ").Append(invItem.Unit).Append('\n');
            sb.Append("remain = ").Append(invItem.Remain).Append('\n');
            sb.Append("designer = ").Append(LuaEscape(designer)).Append('\n');
            sb.Append("grade = ").Append(grade).Append('\n');
            sb.Append("quality = 1\n");
            sb.Append("popularity = 0\n");
            sb.Append("resource = ").Append(LuaEscape(resource)).Append('\n');
            sb.Append("position = ").Append(invItem.Position ?? 0).Append('\n');
            sb.Append("battleForce = 0\n");
            sb.Append("isLock = 0\n");
            sb.Append("lockExpireTime = 0\n");
            sb.Append("level = ").Append(level).Append('\n');
            sb.Append("avatarLevel = ").Append(avatarLevel).Append('\n');
            sb.Append("cardVentureForce = 0\n");
        }

        // tip.lua 用 math.floor(x * 10000) / 100 计算百分比，nil 会直接抛错，所以必须给数值。
        sb.Append("armor = 0\n");
        sb.Append("recovery = 0\n");
        sb.Append("cureQuantity = 0\n");
        sb.Append("stamina = 0\n");
        sb.Append("armorGem = 0\n");
        sb.Append("recoveryGem = 0\n");
        sb.Append("cureQuantityGem = 0\n");
        sb.Append("staminaGem = 0\n");
        sb.Append("isRenew = ").Append(invItem?.IsRenew == true ? "true" : "false").Append('\n');
        sb.Append("now = ").Append(nowMs).Append('\n');
        sb.Append("sysAvatarPlus = {}\n");
        sb.Append("avatar = ").Append(avatar is null ? "{}" : LuaSerializer.Serialize(avatar)).Append('\n');
        sb.Append("slots = ").Append(LuaSerializer.Serialize(ShopItemDatabase.AvatarCardSlotTemplate));

        return sb.ToString();
    }
}
