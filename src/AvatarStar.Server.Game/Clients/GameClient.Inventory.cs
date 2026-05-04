using System.Globalization;
using AvatarStar.Server.Game.Resources;

namespace AvatarStar.Server.Game;

internal partial class GameClient
{
    private const int StorageDefaultPageCount = 100;

    private sealed record StorageListResult(object[] Items, int CurrentPage, int TotalPages);

    private static int GetDefaultStoragePageSize(int storageType)
    {
        return storageType switch
        {
            5 => 10, // avatar cards use the card grid
            _ => 24
        };
    }

    private static int NormalizeStoragePageSize(int storageType, int pageSize)
    {
        return pageSize <= 0 ? GetDefaultStoragePageSize(storageType) : pageSize;
    }

    private static int GetDefaultStorageCapacity(int storageType, int pageSize)
    {
        return StorageDefaultPageCount * NormalizeStoragePageSize(storageType, pageSize);
    }

    private string BuildStorageListPayload(int storageType, int page, int pageSize, bool pageBySlot = true)
    {
        pageSize = NormalizeStoragePageSize(storageType, pageSize);
        var result = GetStorageItems(storageType, page, pageSize, pageBySlot: pageBySlot);
        return
            "ok = 1\n" +
            $"t = {storageType}\n" +
            $"s = {pageSize}\n" +
            $"page = {result.CurrentPage}\n" +
            $"pages = {result.TotalPages}\n" +
            "items = " + LuaSerializer.SerializeSequential(result.Items);
    }

    private StorageListResult GetStorageItems(
        int storageType,
        int page,
        int pageSize,
        IReadOnlySet<int>? subtypeFilter = null,
        IReadOnlySet<int>? gradeFilter = null,
        bool pageBySlot = true)
    {
        var player = GetActivePlayerStateOrDefault();
        player.EnsureStarterInventory();
        pageSize = NormalizeStoragePageSize(storageType, pageSize);
        var defaultCapacity = GetDefaultStorageCapacity(storageType, pageSize);

        if (!player.Storages.TryGetValue(storageType, out var slots) || slots.Count == 0)
        {
            if (!pageBySlot)
            {
                return new StorageListResult(Array.Empty<object>(), CurrentPage: 1, TotalPages: 1);
            }

            var emptyPage = Math.Clamp(page <= 0 ? 1 : page, 1, StorageDefaultPageCount);
            return new StorageListResult(Array.Empty<object>(), emptyPage, StorageDefaultPageCount);
        }

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
            var maxOccupiedSlot = filtered.Count == 0 ? 0 : filtered.Max(x => x.Slot);
            var capacity = Math.Max(defaultCapacity, maxOccupiedSlot);
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
                    // Enhancement panels probe this field (e.g. `if menDt2.refitTotalExp > 0 then ...`)
                    refitTotalExp = 0,
                    sid = x.Sid,
                    type = x.Type,
                    avatar = x.Avatar,
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

    private bool TryPurchaseToInventory(
        ShopItemDatabase.ShopItem shopItem,
        int quantity,
        ShopItemDatabase.ShopPrice? price = null)
    {
        var player = GetActivePlayerStateOrDefault();
        return player.TryPurchaseToInventory(shopItem, quantity, price);
    }
}
