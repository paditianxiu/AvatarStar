using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

namespace AvatarStar.Server.Game.Resources;

/// <summary>
/// 商城物品服务 - 按客户端Lua协议组装字段、过滤与分页
/// </summary>
public static class ShopItemProvider
{
    private const int DefaultPageSize = 12;
    private const int MaxPageSize = 100;

    public sealed record ShopListQuery(
        int? Type,
        string? St,
        int? SellState,
        int? Occupation,
        string? Currency,
        int Page,
        int PageSize);

    public static List<Dictionary<string, object>> GetShopItemList(int itemType, int page = 1, int pageSize = DefaultPageSize)
    {
        var (items, _, _) = GetShopItemListWithPaging(itemType, page, pageSize);
        return items;
    }

    public static (List<Dictionary<string, object>> items, int totalPages, int currentPage) GetShopItemListWithPaging(
        int itemType,
        int page = 1,
        int pageSize = DefaultPageSize)
    {
        return GetShopItemListWithPaging(new ShopListQuery(
            Type: itemType,
            St: null,
            SellState: null,
            Occupation: null,
            Currency: null,
            Page: page,
            PageSize: pageSize));
    }

    public static (List<Dictionary<string, object>> items, int totalPages, int currentPage) GetShopItemListWithPaging(
        ShopListQuery query,
        Func<int, int, int>? getPlayerPurchasedCount = null)
    {
        var pageSize = query.PageSize;
        if (pageSize <= 0 || pageSize > MaxPageSize) pageSize = DefaultPageSize;
        var page = query.Page;
        if (page < 1) page = 1;

        var stSet = ParseIntSet(query.St);
        var currencySet = ParseIntSet(query.Currency);

        IEnumerable<ShopItemDatabase.ShopItem> items = ShopItemDatabase.GetAllShopItems().Values;

        if (query.Type is { } t && t > 0)
        {
            items = items.Where(x => (int)x.Type == t);
        }
        else
        {
            // Recommend/mixed listing: exclude non-sellable types.
            items = items.Where(x => x.Type != ShopItemDatabase.ItemType.Skill);
        }

        if (stSet is { Count: > 0 })
        {
            items = items.Where(x => stSet.Contains(x.Subtype));
        }

        if (query.Occupation is { } occ)
        {
            items = items.Where(x => x.Occupation < 0 || x.Occupation == occ);
        }

        if (query.SellState is { } sellState && sellState > 0)
        {
            items = items.Where(x => (x.Prices ?? Array.Empty<ShopItemDatabase.ShopPrice>()).Any(p => p.SellState == sellState));
        }

        if (currencySet is { Count: > 0 })
        {
            items = items.Where(x => (x.Prices ?? Array.Empty<ShopItemDatabase.ShopPrice>()).Any(p => currencySet.Contains((int)p.Currency)));
        }

        var ordered = items.OrderBy(x => x.Sid).ToList();
        var totalCount = ordered.Count;
        var totalPages = totalCount == 0 ? 1 : (totalCount + pageSize - 1) / pageSize;
        if (page > totalPages) page = totalPages;

        var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var pageItems = ordered
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(x => ConvertToRpcFormat(x, nowMs, currencySet, getPlayerPurchasedCount))
            .Where(x => x is not null)
            .Cast<Dictionary<string, object>>()
            .ToList();

        return (pageItems, totalPages, page);
    }

    public static List<Dictionary<string, object>> GetShopItemsByCategory(string category)
    {
        var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var items = ShopItemDatabase.GetShopItemsByCategory(category);
        return items
            .Select(item => ConvertToRpcFormat(item, nowMs, currencySet: null, getPlayerPurchasedCount: null))
            .Where(x => x is not null)
            .Cast<Dictionary<string, object>>()
            .ToList();
    }

    public static (List<Dictionary<string, object>> items, int totalPages, int currentPage) GetFreshmanItemListWithPaging(
        int page = 1,
        int pageSize = 8,
        Func<int, int, int>? getPlayerPurchasedCount = null)
    {
        // 客户端“新手装备”走 get_freshman_item_list；这里优先返回装备(2)。
        return GetShopItemListWithPaging(new ShopListQuery(
            Type: (int)ShopItemDatabase.ItemType.Equipment,
            St: null,
            SellState: null,
            Occupation: null,
            Currency: null,
            Page: page,
            PageSize: pageSize), getPlayerPurchasedCount);
    }

    public static Dictionary<string, object>? GetShopItem(int sid, Func<int, int, int>? getPlayerPurchasedCount = null)
    {
        var item = ShopItemDatabase.GetShopItem(sid);
        if (item is null) return null;
        var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        return ConvertToRpcFormat(item, nowMs, currencySet: null, getPlayerPurchasedCount);
    }

    public static bool CanPurchaseItem(int sid)
    {
        var item = ShopItemDatabase.GetShopItem(sid);
        // Client Lua doesn't use a dedicated "isLimited" flag to block purchasing;
        // availability is controlled by price window/limit fields (start/end/accomplishCount).
        // Treat IsLimited as a server-side tag only (GM/config), not a hard block.
        return item != null && (item.Prices?.Length ?? 0) > 0;
    }

    public static (bool found, ShopItemDatabase.ShopPrice price) TryGetPriceById(int sid, int priceId)
    {
        var item = ShopItemDatabase.GetShopItem(sid);
        if (item is null) return (false, null!);
        var price = (item.Prices ?? Array.Empty<ShopItemDatabase.ShopPrice>()).FirstOrDefault(p => p.PriceId == priceId);
        return price is null ? (false, null!) : (true, price);
    }

    // Legacy: by index (0-based), kept for older tooling.
    public static (bool found, ShopItemDatabase.CurrencyType currency, int price) GetPurchasePrice(int sid, int priceIndex = 0)
    {
        var item = ShopItemDatabase.GetShopItem(sid);
        if (item == null || priceIndex >= item.Prices.Length || priceIndex < 0)
        {
            return (false, 0, 0);
        }

        var price = item.Prices[priceIndex];
        var p = price.RebatePrice > 0 ? price.RebatePrice : price.Price;
        return (true, price.Currency, p);
    }

    public static (bool found, ShopItemDatabase.CurrencyType currency, int price) GetPurchasePriceById(int sid, int priceId)
    {
        var (found, price) = TryGetPriceById(sid, priceId);
        if (!found) return (false, 0, 0);
        var p = price.RebatePrice > 0 ? price.RebatePrice : price.Price;
        return (true, price.Currency, p);
    }

    public static (bool success, int totalPrice) CalculateTotalPrice(int sid, int quantity, int priceIndex = 0)
    {
        var (found, _, unitPrice) = GetPurchasePrice(sid, priceIndex);
        if (!found) return (false, 0);
        return (true, unitPrice * Math.Max(1, quantity));
    }

    private static Dictionary<string, object>? ConvertToRpcFormat(
        ShopItemDatabase.ShopItem item,
        long nowMs,
        HashSet<int>? currencySet,
        Func<int, int, int>? getPlayerPurchasedCount)
    {
        var src = item.Prices ?? Array.Empty<ShopItemDatabase.ShopPrice>();
        IEnumerable<ShopItemDatabase.ShopPrice> prices = src;
        if (currencySet is { Count: > 0 })
        {
            prices = prices.Where(p => currencySet.Contains((int)p.Currency));
        }

        var priceArr = prices
            .OrderBy(p => p.PriceId)
            .Select(p =>
            {
                var purchased = getPlayerPurchasedCount?.Invoke(item.Sid, p.PriceId) ?? 0;
                var remaining = p.AccomplishCount <= 0 ? 0 : Math.Max(0, p.AccomplishCount - purchased);

                return new Dictionary<string, object>
                {
                    { "priceId", p.PriceId },
                    { "currency", (int)p.Currency },
                    { "price", p.Price },
                    { "rebatePrice", p.RebatePrice },
                    { "sellState", p.SellState },
                    { "unitType", p.UnitType },
                    { "unit", p.Unit },
                    { "repeatDuration", p.RepeatDuration },
                    { "accomplishCount", p.AccomplishCount },
                    { "playerAccomplishCount", remaining },
                    { "isRenew", p.IsRenew },
                    { "isCardPrice", p.IsCardPrice },
                    { "isGive", p.IsGive },
                    { "vipLevel", p.VipLevel },
                    { "startDateTime", p.StartDateTime },
                    { "endDateTime", p.EndDateTime }
                };
            })
            .ToList();

        if (priceArr.Count == 0)
        {
            return null;
        }

        return new Dictionary<string, object>
        {
            { "sid", item.Sid },
            { "display", item.Display },
            { "resource", ShopItemDatabase.GetClientResource(item) },
            { "grade", item.Grade },
            { "type", (int)item.Type },
            { "subtype", item.Subtype },
            { "description", item.Description },
            { "level", item.Level },
            { "occupation", item.Occupation },
            { "avatar", item.Avatar ?? string.Empty },
            { "avatarLevel", item.AvatarLevel ?? 0 },
            { "now", nowMs },
            { "price", priceArr },
            { "quantity", item.Quantity },
            { "category", item.Category },
            { "isLimited", item.IsLimited ? 1 : 0 }
        };
    }

    private static HashSet<int>? ParseIntSet(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw)) return null;
        var set = new HashSet<int>();
        foreach (var part in raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (int.TryParse(part, NumberStyles.Integer, CultureInfo.InvariantCulture, out var v))
            {
                set.Add(v);
            }
        }
        return set;
    }
}
