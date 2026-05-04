using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.Linq;
using System.Text.Json;
using System.Threading;
using AvatarStar.Server.Persistence;

namespace AvatarStar.Server.Game.Resources;

/// <summary>
/// 商城商品定义和管理
/// 包含所有可购买的物品：武器、皮肤、物品、宠物、装饰品等
/// </summary>
public class ShopItemDatabase
{
    // 商品类型 (对应客户端t参数)
    public enum ItemType
    {
        /// <summary>技能 (不售卖)</summary>
        Skill = 1,
        
        /// <summary>装备 (武器、盔甲等)</summary>
        Equipment = 2,
        
        /// <summary>物品 (消耗品、材料等)</summary>
        Item = 3,
        
        /// <summary>姿态 (emote/gesture)</summary>
        Gesture = 4,
        
        /// <summary>角色卡片</summary>
        AvatarCard = 5,
        
        /// <summary>皮肤卡片</summary>
        SkinCard = 6
    }

    /// <summary>货币类型</summary>
    public enum CurrencyType
    {
        /// <summary>金币 (游戏币)</summary>
        Gold = 1,
        
        /// <summary>钻石 (付费货币)</summary>
        Diamond = 2,

        /// <summary>浠ｅ竵/鍒稿埜 (client 常见 currency=4)</summary>
        Ticket = 4
    }

    /// <summary>单个商品定义</summary>
    public sealed class ShopItem
    {
        /// <summary>商品ID (唯一)</summary>
        public int Sid { get; set; }

        /// <summary>商品类型</summary>
        public ItemType Type { get; set; }

        /// <summary>瀛愮被鍨? (client: subtype / st 过滤)</summary>
        public int Subtype { get; set; }

        /// <summary>资源ID (对应mesh/model)</summary>
        public string Resource { get; set; } = string.Empty;

        /// <summary>UI显示文本ID (i18n key)</summary>
        public string Display { get; set; } = string.Empty;

        /// <summary>闇€瑕佺瓑绾? (client: item.level, NA 判断)</summary>
        public int Level { get; set; }

        /// <summary>鑱屼笟闄愬埗 (-1 表示不限)</summary>
        public int Occupation { get; set; } = -1;

        /// <summary>价格等级 (1=普通, 2=稀有, 3=传奇)</summary>
        public int Grade { get; set; }

        /// <summary>商品描述文本ID</summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>瑙掕壊鍗＄墖数据 (client: item.avatar)</summary>
        public object? Avatar { get; set; }

        /// <summary>瑙掕壊鍗＄墖等级 (client: item.avatarLevel)</summary>
        public int? AvatarLevel { get; set; }

        /// <summary>价格信息 (支持多种货币)</summary>
        public object? Tip { get; set; }

        public ShopPrice[] Prices { get; set; } = Array.Empty<ShopPrice>();

        /// <summary>是否限售</summary>
        public bool IsLimited { get; set; }

        /// <summary>数量 (可堆叠物品)</summary>
        public int Quantity { get; set; } = 1;

        /// <summary>分类标签 (用于UI显示分类)</summary>
        public string Category { get; set; } = string.Empty;
    }

    /// <summary>商品价格定义</summary>
    public sealed class ShopPrice
    {
        /// <summary>价格ID (1-based index)</summary>
        public int PriceId { get; set; }

        /// <summary>货币类型</summary>
        public CurrencyType Currency { get; set; }

        /// <summary>价格</summary>
        public int Price { get; set; }

        /// <summary>折扣价 (client: rebatePrice)</summary>
        public int RebatePrice { get; set; }

        /// <summary>售卖标签 (client: sellState)</summary>
        public int SellState { get; set; }

        /// <summary>单位类型 (client: unitType)</summary>
        public int UnitType { get; set; } = 1;

        /// <summary>单位数值 (client: unit)</summary>
        public int Unit { get; set; } = 1;

        /// <summary>刷新周期 (client: repeatDuration)</summary>
        public int RepeatDuration { get; set; } = 1;

        /// <summary>限购总次数 (client: accomplishCount; 0=不限)</summary>
        public int AccomplishCount { get; set; }

        /// <summary>是否可续费 (client: isRenew)</summary>
        public bool IsRenew { get; set; }

        /// <summary>是否卡价 (client: isCardPrice)</summary>
        public bool IsCardPrice { get; set; }

        /// <summary>是否可赠送 (client: isGive)</summary>
        public bool IsGive { get; set; }

        /// <summary>VIP等级限制 (client: vipLevel)</summary>
        public int VipLevel { get; set; }

        /// <summary>开始时间(ms) (client: startDateTime)</summary>
        public long StartDateTime { get; set; }

        /// <summary>结束时间(ms) (client: endDateTime)</summary>
        public long EndDateTime { get; set; }
    }

    // ===== 商品数据库 =====
    // Hot-reload safe: swap dictionary instances on reload (no in-place mutation at runtime).
    private static Dictionary<int, ShopItem> Items = new();
    private static Dictionary<string, ShopItem> ItemsByResource = new(StringComparer.OrdinalIgnoreCase);

    private const int IndependentBackDeviceSubtype = 102;
    private static readonly Lazy<Dictionary<string, string>> WingTemplateClientResources = new(
        LoadWingTemplateClientResources,
        LazyThreadSafetyMode.ExecutionAndPublication);

    private static long _configRevision;

    // SID生成器

    static ShopItemDatabase()
    {
        var loaded = TryLoadFromDatabaseConfig() || TryLoadFromJsonConfig();
        if (!loaded)
        {
            InitializeWeapons();
            InitializeAvatarSkins();
            InitializeConsumables();
            InitializeDecorations();
            InitializePets();
            InitializeEnhancementMaterials();
            RebuildIndexes();
            BumpConfigRevision();
        }
    }

    private static object CreateDefaultEquipAvatar()
    {
        // Provide a stable avatar table shape expected by ComFuc.SetPersonCardData / DealAvatarEquip.
        // Client scripts treat these as strings (e.g. "{}" or "{'onecolor_skin',...}").
        return new Dictionary<string, string>
        {
            // Keep a default avatarId so avatar-room previews don't choke on missing fields.
            // Real avatarId will be injected from player state when purchasing / creating starter cards.
            ["avatarId"] = "0",
            ["skin"] = "{}",
            ["eye"] = "{}",
            ["mouth"] = "{}",
            ["nose"] = "{}",
            ["ear"] = "{}",
            ["beard"] = "{}",
            ["hair"] = "{}",
            ["helmet"] = "{}",
            ["underwear"] = "{}",
            ["outerwear"] = "{}",
            ["trousers"] = "{}",
            ["glove"] = "{}",
            ["shoes"] = "{}",
            ["decal"] = "{}",
            ["movable"] = "{}",
            ["immobile"] = "{}",
            ["immobileUp"] = "{}",
            ["immobileDown"] = "{}"
        };
    }

    private static object? NormalizeAvatar(object? avatar)
    {
        if (avatar is null) return null;

        // System.Text.Json will deserialize object-typed properties as JsonElement.
        if (avatar is JsonElement el)
        {
            if (el.ValueKind == JsonValueKind.Object)
            {
                var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                foreach (var prop in el.EnumerateObject())
                {
                    dict[prop.Name] = prop.Value.ValueKind == JsonValueKind.String
                        ? prop.Value.GetString() ?? string.Empty
                        : prop.Value.GetRawText();
                }
                return dict;
            }

            return el.ValueKind == JsonValueKind.String ? el.GetString() : el.GetRawText();
        }

        return avatar;
    }

    private static object? NormalizeAnyJson(object? value)
    {
        if (value is null) return null;
        if (value is not JsonElement el) return value;

        object? Convert(JsonElement e)
        {
            return e.ValueKind switch
            {
                JsonValueKind.Object => e.EnumerateObject()
                    .ToDictionary(p => p.Name, p => Convert(p.Value), StringComparer.OrdinalIgnoreCase),
                JsonValueKind.Array => e.EnumerateArray().Select(Convert).ToList(),
                JsonValueKind.String => e.GetString(),
                JsonValueKind.Number => e.TryGetInt64(out var l) ? l : e.GetDouble(),
                JsonValueKind.True => true,
                JsonValueKind.False => false,
                _ => null
            };
        }

        return Convert(el);
    }

    public static string GetClientResource(ShopItem item)
    {
        return GetClientResource(item, item.Resource, (int)item.Type, item.Subtype);
    }

    public static string GetClientResource(
        ShopItem? item,
        string? fallbackResource,
        int fallbackType,
        int fallbackSubtype)
    {
        var resource = string.IsNullOrWhiteSpace(fallbackResource) ? item?.Resource ?? string.Empty : fallbackResource!;
        var itemType = item?.Type ?? (ItemType)fallbackType;
        var subtype = item?.Subtype > 0 ? item.Subtype : fallbackSubtype;

        if (!IsIndependentBackDevice(itemType, subtype))
        {
            return resource;
        }

        if (TryGetNestedString(item?.Tip, out var capturedResource, "templateSource", "identity", "resource") ||
            TryGetNestedString(item?.Tip, out capturedResource, "__source", "identity", "resource"))
        {
            return capturedResource;
        }

        if (TryGetWingTemplateClientResource(resource, out capturedResource))
        {
            return capturedResource;
        }

        return BuildBackDeviceClientResource(resource);
    }

    private static bool IsIndependentBackDevice(ItemType type, int subtype)
    {
        return type == ItemType.Equipment && subtype == IndependentBackDeviceSubtype;
    }

    private static string BuildBackDeviceClientResource(string resource)
    {
        var trimmed = resource.Trim();
        if (trimmed.Length == 0 || trimmed.Contains(',', StringComparison.Ordinal))
        {
            return trimmed;
        }

        const string indieSuffix = "_indie";
        if (!trimmed.EndsWith(indieSuffix, StringComparison.OrdinalIgnoreCase))
        {
            return trimmed;
        }

        var modelResource = trimmed[..^indieSuffix.Length];
        return string.IsNullOrWhiteSpace(modelResource)
            ? trimmed
            : $"'{trimmed}','{modelResource}','{modelResource}'";
    }

    private static bool TryGetWingTemplateClientResource(string resource, out string clientResource)
    {
        return WingTemplateClientResources.Value.TryGetValue(GetResourceLookupKey(resource), out clientResource!);
    }

    private static Dictionary<string, string> LoadWingTemplateClientResources()
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var path = GetWingTemplatePath();
        if (path is null)
        {
            return result;
        }

        try
        {
            using var doc = JsonDocument.Parse(File.ReadAllText(path));
            if (!doc.RootElement.TryGetProperty("templates", out var templates) ||
                templates.ValueKind != JsonValueKind.Array)
            {
                return result;
            }

            foreach (var template in templates.EnumerateArray())
            {
                if (!template.TryGetProperty("identity", out var identity) ||
                    !identity.TryGetProperty("resource", out var resourceElement) ||
                    resourceElement.ValueKind != JsonValueKind.String)
                {
                    continue;
                }

                var clientResource = resourceElement.GetString()?.Trim();
                if (string.IsNullOrWhiteSpace(clientResource))
                {
                    continue;
                }

                result[GetResourceLookupKey(clientResource)] = clientResource;
            }
        }
        catch
        {
            result.Clear();
        }

        return result;
    }

    private static string? GetWingTemplatePath()
    {
        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Resources", "templates", "weapon_detail_wing_templates.json"),
            Path.Combine(AppContext.BaseDirectory, "templates", "weapon_detail_wing_templates.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "Resources", "templates", "weapon_detail_wing_templates.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Resources", "templates", "weapon_detail_wing_templates.json"),
        };

        return candidates.FirstOrDefault(File.Exists);
    }

    private static string GetResourceLookupKey(string resource)
    {
        var trimmed = resource.Trim();
        if (trimmed.Length == 0 || !trimmed.Contains(',', StringComparison.Ordinal))
        {
            return trimmed.Trim('\'', '"');
        }

        var firstComma = trimmed.IndexOf(',');
        return trimmed[..firstComma].Trim().Trim('\'', '"');
    }

    private static bool TryGetNestedString(object? root, out string value, params string[] path)
    {
        value = string.Empty;
        object? current = root;

        foreach (var segment in path)
        {
            if (!TryGetDictionaryValue(current, segment, out current))
            {
                return false;
            }
        }

        if (current is string s && !string.IsNullOrWhiteSpace(s))
        {
            value = s.Trim();
            return true;
        }

        if (current is JsonElement el && el.ValueKind == JsonValueKind.String)
        {
            var text = el.GetString();
            if (!string.IsNullOrWhiteSpace(text))
            {
                value = text.Trim();
                return true;
            }
        }

        return false;
    }

    private static bool TryGetDictionaryValue(object? value, string key, out object? child)
    {
        if (value is IReadOnlyDictionary<string, object?> dict && dict.TryGetValue(key, out child))
        {
            return true;
        }

        if (value is JsonElement el && el.ValueKind == JsonValueKind.Object && el.TryGetProperty(key, out var prop))
        {
            child = prop;
            return true;
        }

        child = null;
        return false;
    }

    public static string GetActiveConfigPath()
    {
        var overridePath =
            Environment.GetEnvironmentVariable("AVATARSTAR_SHOP_CONFIG")
            ?? Environment.GetEnvironmentVariable("AS_SHOP_CONFIG")
            ?? string.Empty;

        if (!string.IsNullOrWhiteSpace(overridePath))
        {
            return overridePath;
        }

        var candidates = new List<string>
        {
            Path.Combine(AppContext.BaseDirectory, "Resources", "shop_config.json"),
            Path.Combine(AppContext.BaseDirectory, "shop_config.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "Config", "shop_config.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Resources", "shop_config.json"),
        };

        return candidates.FirstOrDefault(File.Exists) ?? candidates.First();
    }

    public static bool ReloadFromJsonConfig()
    {
        // TryLoadFromJsonConfig swaps dictionaries only on success, so current config stays intact on failure.
        return TryLoadFromDatabaseConfig() || TryLoadFromJsonConfig();
    }

    public static bool ReloadFromDatabaseConfig()
    {
        return TryLoadFromDatabaseConfig();
    }

    public static long GetConfigRevision() => Interlocked.Read(ref _configRevision);

    public static int AllocateSid()
    {
        var max = Items.Count == 0 ? 10000 : Items.Keys.Max();
        return max + 1;
    }

    public static string ExportConfigJson(bool indented = true)
    {
        var grouped = Items.Values
            .GroupBy(i => string.IsNullOrWhiteSpace(i.Category) ? "未分类" : i.Category)
            .OrderBy(g => g.Key, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                g => g.Key,
                g => new
                {
                     items = g.OrderBy(x => x.Sid).Select(x => new
                     {
                         sid = x.Sid,
                         type = (int)x.Type,
                         subtype = x.Subtype,
                         resource = x.Resource,
                         display = x.Display,
                         description = x.Description,
                         level = x.Level,
                         occupation = x.Occupation,
                         avatar = x.Avatar,
                         avatarLevel = x.AvatarLevel,
                         grade = x.Grade,
                         quantity = x.Quantity,
                         isLimited = x.IsLimited,
                         prices = (x.Prices ?? Array.Empty<ShopPrice>()).Select(p => new
                         {
                             priceId = p.PriceId,
                             currency = (int)p.Currency,
                             price = p.Price,
                             rebatePrice = p.RebatePrice,
                             sellState = p.SellState,
                             unitType = p.UnitType,
                             unit = p.Unit,
                             repeatDuration = p.RepeatDuration,
                             accomplishCount = p.AccomplishCount,
                             isRenew = p.IsRenew,
                             isCardPrice = p.IsCardPrice,
                             isGive = p.IsGive,
                             vipLevel = p.VipLevel,
                             startDateTime = p.StartDateTime,
                             endDateTime = p.EndDateTime
                         }).ToArray()
                     }).ToList()
                 });

        var root = new { shop = new { categories = grouped } };
        return JsonSerializer.Serialize(root, new JsonSerializerOptions
        {
            WriteIndented = indented
        });
    }

    private static bool TryLoadFromJsonConfig()
    {
        try
        {
            var overridePath =
                Environment.GetEnvironmentVariable("AVATARSTAR_SHOP_CONFIG")
                ?? Environment.GetEnvironmentVariable("AS_SHOP_CONFIG")
                ?? string.Empty;

            var candidates = new List<string>();
            if (!string.IsNullOrWhiteSpace(overridePath))
            {
                candidates.Add(overridePath);
            }

            candidates.Add(Path.Combine(AppContext.BaseDirectory, "Resources", "shop_config.json"));
            candidates.Add(Path.Combine(AppContext.BaseDirectory, "shop_config.json"));
            candidates.Add(Path.Combine(Directory.GetCurrentDirectory(), "Config", "shop_config.json"));
            candidates.Add(Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Resources", "shop_config.json"));

            var path = candidates.FirstOrDefault(File.Exists);
            if (path is null) return false;

            var json = File.ReadAllText(path);
            var root = JsonSerializer.Deserialize<ShopConfigRoot>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (root?.Shop?.Categories is null || root.Shop.Categories.Count == 0)
            {
                return false;
            }

            var newItems = new Dictionary<int, ShopItem>();
            var newItemsByResource = new Dictionary<string, ShopItem>(StringComparer.OrdinalIgnoreCase);
            foreach (var (categoryName, category) in root.Shop.Categories)
            {
                if (category.Items is null) continue;
                foreach (var item in category.Items)
                {
                    if (item.Sid <= 0) continue;
                     var shopItem = new ShopItem
                     {
                         Sid = item.Sid,
                         Type = Enum.IsDefined(typeof(ItemType), item.Type) ? (ItemType)item.Type : ItemType.Item,
                         Subtype = item.Subtype,
                         Resource = item.Resource ?? string.Empty,
                         Display = item.Display ?? string.Empty,
                         Level = item.Level,
                         Occupation = item.Occupation,
                         Grade = item.Grade <= 0 ? 1 : item.Grade,
                         Description = item.Description ?? string.Empty,
                         Avatar = NormalizeAvatar(item.Avatar),
                         AvatarLevel = item.AvatarLevel,
                         Tip = NormalizeAnyJson(item.Tip),
                         Quantity = item.Quantity <= 0 ? 1 : item.Quantity,
                         IsLimited = item.IsLimited,
                         Category = categoryName,
                         Prices = (item.Prices ?? Array.Empty<ShopConfigPrice>())
                             .Select(p => new ShopPrice
                             {
                                 PriceId = p.PriceId <= 0 ? 1 : p.PriceId,
                                 Currency = Enum.IsDefined(typeof(CurrencyType), p.Currency) ? (CurrencyType)p.Currency : CurrencyType.Gold,
                                 Price = p.Price,
                                 RebatePrice = p.RebatePrice,
                                 SellState = p.SellState,
                                 UnitType = p.UnitType <= 0 ? 1 : p.UnitType,
                                 Unit = p.Unit <= 0 ? 1 : p.Unit,
                                 RepeatDuration = p.RepeatDuration <= 0 ? 1 : p.RepeatDuration,
                                 AccomplishCount = p.AccomplishCount,
                                 IsRenew = p.IsRenew,
                                 IsCardPrice = p.IsCardPrice,
                                 IsGive = p.IsGive,
                                 VipLevel = p.VipLevel,
                                 StartDateTime = p.StartDateTime,
                                 EndDateTime = p.EndDateTime
                             })
                             .ToArray()
                     };

                    if (shopItem.Type is ItemType.AvatarCard or ItemType.SkinCard && shopItem.Avatar is null)
                    {
                        shopItem.Avatar = CreateDefaultEquipAvatar();
                    }

                    if (shopItem.Prices.Length == 0)
                    {
                        shopItem.Prices = new[] { new ShopPrice { PriceId = 1, Currency = CurrencyType.Gold, Price = 0 } };
                    }

                    newItems[shopItem.Sid] = shopItem;
                    if (!string.IsNullOrWhiteSpace(shopItem.Resource))
                    {
                        newItemsByResource[shopItem.Resource] = shopItem;
                    }
                }
            }

            if (newItems.Count == 0)
            {
                return false;
            }

            // Swap dictionaries atomically (reference assignment) so readers never see a partially-built table.
            Items = newItems;
            ItemsByResource = newItemsByResource;
            BumpConfigRevision();
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static bool TryLoadFromDatabaseConfig()
    {
        try
        {
            using var db = new AvatarStarDbContext();
            var dbItems = db.ShopItems.ToArray();
            if (dbItems.Length == 0)
            {
                return false;
            }

            var pricesBySid = db.ShopPrices
                .ToArray()
                .GroupBy(x => x.Sid)
                .ToDictionary(x => x.Key, x => x.OrderBy(p => p.PriceId).ToArray());

            var newItems = new Dictionary<int, ShopItem>();
            var newItemsByResource = new Dictionary<string, ShopItem>(StringComparer.OrdinalIgnoreCase);
            foreach (var item in dbItems)
            {
                var shopItem = new ShopItem
                {
                    Sid = item.Sid,
                    Type = Enum.IsDefined(typeof(ItemType), item.Type) ? (ItemType)item.Type : ItemType.Item,
                    Subtype = item.Subtype,
                    Resource = item.Resource ?? string.Empty,
                    Display = item.Display ?? string.Empty,
                    Level = item.Level,
                    Occupation = item.Occupation,
                    Grade = item.Grade <= 0 ? 1 : item.Grade,
                    Description = item.Description ?? string.Empty,
                    Avatar = NormalizeAvatar(DeserializeConfigJson(item.AvatarJson)),
                    AvatarLevel = item.AvatarLevel,
                    Tip = NormalizeAnyJson(DeserializeConfigJson(item.TipJson)),
                    Quantity = item.Quantity <= 0 ? 1 : item.Quantity,
                    IsLimited = item.IsLimited != 0,
                    Category = item.Category ?? string.Empty,
                    Prices = pricesBySid.TryGetValue(item.Sid, out var dbPrices)
                        ? dbPrices.Select(p => new ShopPrice
                            {
                                PriceId = p.PriceId <= 0 ? 1 : p.PriceId,
                                Currency = Enum.IsDefined(typeof(CurrencyType), p.Currency) ? (CurrencyType)p.Currency : CurrencyType.Gold,
                                Price = p.Price,
                                RebatePrice = p.RebatePrice,
                                SellState = p.SellState,
                                UnitType = p.UnitType <= 0 ? 1 : p.UnitType,
                                Unit = p.Unit <= 0 ? 1 : p.Unit,
                                RepeatDuration = p.RepeatDuration <= 0 ? 1 : p.RepeatDuration,
                                AccomplishCount = p.AccomplishCount,
                                IsRenew = p.IsRenew != 0,
                                IsCardPrice = p.IsCardPrice != 0,
                                IsGive = p.IsGive != 0,
                                VipLevel = p.VipLevel,
                                StartDateTime = p.StartDateTime,
                                EndDateTime = p.EndDateTime
                            })
                            .ToArray()
                        : Array.Empty<ShopPrice>()
                };

                if (shopItem.Type is ItemType.AvatarCard or ItemType.SkinCard && shopItem.Avatar is null)
                {
                    shopItem.Avatar = CreateDefaultEquipAvatar();
                }

                if (shopItem.Prices.Length == 0)
                {
                    shopItem.Prices = new[] { new ShopPrice { PriceId = 1, Currency = CurrencyType.Gold, Price = 0 } };
                }

                newItems[shopItem.Sid] = shopItem;
                if (!string.IsNullOrWhiteSpace(shopItem.Resource))
                {
                    newItemsByResource[shopItem.Resource] = shopItem;
                }
            }

            if (newItems.Count == 0)
            {
                return false;
            }

            Items = newItems;
            ItemsByResource = newItemsByResource;
            BumpConfigRevision();
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static object? DeserializeConfigJson(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            return JsonSerializer.Deserialize<object>(json);
        }
        catch
        {
            return null;
        }
    }

    private static void BumpConfigRevision()
    {
        // Monotonic counter; used for clients/diagnostics to tell whether config changed.
        Interlocked.Increment(ref _configRevision);
    }

    private sealed class ShopConfigRoot
    {
        public ShopConfigShop? Shop { get; set; }
    }

    private sealed class ShopConfigShop
    {
        public Dictionary<string, ShopConfigCategory>? Categories { get; set; }
    }

    private sealed class ShopConfigCategory
    {
        public List<ShopConfigItem>? Items { get; set; }
    }

    private sealed class ShopConfigItem
    {
        public int Sid { get; set; }
        public string? Resource { get; set; }
        public string? Display { get; set; }
        public string? Description { get; set; }
        public int Grade { get; set; }
        public int Type { get; set; }
        public int Subtype { get; set; }
        public int Level { get; set; }
        public int Occupation { get; set; } = -1;
        public object? Avatar { get; set; }
        public int? AvatarLevel { get; set; }
        public object? Tip { get; set; }
        public int Quantity { get; set; } = 1;
        public bool IsLimited { get; set; }
        public ShopConfigPrice[]? Prices { get; set; }
    }

    private sealed class ShopConfigPrice
    {
        public int PriceId { get; set; }
        public int Currency { get; set; }
        public int Price { get; set; }

        /// <summary>鎶樻墸浠? (client: rebatePrice)</summary>
        public int RebatePrice { get; set; }

        /// <summary>鍞崠鏍囩 (client: sellState)</summary>
        public int SellState { get; set; }

        /// <summary>单位类型 (client: unitType)</summary>
        public int UnitType { get; set; } = 1;

        /// <summary>单位数值 (client: unit)</summary>
        public int Unit { get; set; } = 1;

        /// <summary>刷新周期 (client: repeatDuration)</summary>
        public int RepeatDuration { get; set; } = 1;

        /// <summary>限购总次数 (client: accomplishCount; 0=不限)</summary>
        public int AccomplishCount { get; set; }

        /// <summary>是否可续费 (client: isRenew)</summary>
        public bool IsRenew { get; set; }

        /// <summary>是否卡价 (client: isCardPrice)</summary>
        public bool IsCardPrice { get; set; }

        /// <summary>是否可赠送 (client: isGive)</summary>
        public bool IsGive { get; set; }

        /// <summary>VIP等级限制 (client: vipLevel)</summary>
        public int VipLevel { get; set; }

        /// <summary>开始时间(ms) (client: startDateTime)</summary>
        public long StartDateTime { get; set; }

        /// <summary>结束时间(ms) (client: endDateTime)</summary>
        public long EndDateTime { get; set; }
    }

    #region 武器 (类型=Equipment, SID: 20001-20999)

    private static void InitializeWeapons()
    {
        var weaponData = new[]
        {
            // 手枪
            ("smg_01", "id_datalist_AK74", 1, 0, 0),
            ("shotgun_01", "id_datalist_M37", 1, 0, 0),
            ("shield_01", "id_datalist_Buckler_Bat", 1, 0, 0),
            ("rpg_01", "id_datalist_Recoilless_Artillery", 1, 0, 0),
            ("sniperrifle_01", "id_datalist_M200", 1, 0, 0),
            ("grenadelauncher_01", "UI_weapon_weapon_m32", 1, 0, 0),
            ("sprayer_01", "UI_weapon_weapon_penwuqi", 1, 0, 0),
            ("crossbow_01", "UI_weapon_weapon_jianyiqingnu", 1, 0, 0),
            ("pistol_01", "id_datalist_Gun_01", 1, 100, 500),
            
            // 机枪
            ("machinegun_01", "id_datalist_MachineGun_01", 1, 150, 750),
            ("machinegun_02", "id_datalist_MachineGun_02", 2, 200, 1000),
            ("machinegun_03", "id_datalist_MachineGun_03", 2, 250, 1200),
            ("machinegun_04", "id_datalist_MachineGun_04", 2, 280, 1500),
            ("machinegun_05", "id_datalist_MachineGun_05", 3, 350, 2000),
            
            // 弓
            ("bow_01", "id_datalist_Bow_01", 1, 120, 600),
            ("bow_02", "id_datalist_Bow_02", 2, 180, 900),
            ("bow_03", "id_datalist_Bow_03", 3, 300, 1800),
            
            // 匕首/刀
            ("knives_01", "id_datalist_Knife_01", 1, 110, 550),
            ("knives_02", "id_datalist_Knife_02", 2, 170, 850),
            ("knives_03", "id_datalist_Knife_03", 3, 280, 1600),
            
            // 手榴弹
            ("grenade_01", "id_datalist_Grenade_01", 1, 140, 700),
            ("grenade_02", "id_datalist_Grenade_02", 2, 220, 1100),
        };

        int sid = 20001;
        foreach (var (resource, display, grade, goldPrice, diamondPrice) in weaponData)
        {
            AddItem(new ShopItem
            {
                Sid = sid++,
                Type = ItemType.Equipment,
                Resource = resource,
                Display = display,
                Grade = grade,
                Description = display + "_desc",
                Prices = new[]
                {
                    new ShopPrice { PriceId = 1, Currency = CurrencyType.Gold, Price = goldPrice },
                    new ShopPrice { PriceId = 2, Currency = CurrencyType.Diamond, Price = diamondPrice }
                },
                Category = "Weapons"
            });
        }
    }

    #endregion

    #region 角色皮肤 (类型=SkinCard, SID: 50001-50999)

    private static void InitializeAvatarSkins()
    {
        var skinData = new[]
        {
            // VIP套装
            ("skin_guardian_vip_male", "id_datalist_Guardian_VIP_Suit_Male", 2, 5000, 500),
            ("skin_guardian_vip_female", "id_datalist_Guardian_VIP_Suit_Female", 2, 5000, 500),
            ("skin_gunner_vip_male", "id_datalist_Gunner_VIP_Suit_Male", 2, 5000, 500),
            ("skin_gunner_vip_female", "id_datalist_Gunner_VIP_Suit_Female", 2, 5000, 500),
            ("skin_assassin_vip_male", "id_datalist_Assassin_VIP_Suit_Male", 2, 5000, 500),
            ("skin_assassin_vip_female", "id_datalist_Assassin_VIP_Suit_Female", 2, 5000, 500),
            
            // 主题套装
            ("skin_spring_male", "id_datalist_Spring_Menswear", 2, 3000, 300),
            ("skin_spring_female", "id_datalist_Spring_Womenswear", 2, 3000, 300),
            ("skin_valentine_male", "id_datalist_Valentines_Day_Menswear", 3, 4000, 400),
            ("skin_valentine_female", "id_datalist_Valentines_Day_Womenswear", 3, 4000, 400),
            ("skin_santa", "id_datalist_Santa_Claus", 3, 4000, 400),
            ("skin_snow_kid", "id_datalist_Snow_Kid", 2, 3000, 300),
            ("skin_red_dragon_fighter", "id_datalist_Red_Dragon_Scales_Fighter", 3, 4000, 400),
            ("skin_green_dragon_hunter", "id_datalist_Green_Dragon_Hunter", 3, 4000, 400),
        };

        int sid = 50001;
        foreach (var (resource, display, grade, goldPrice, diamondPrice) in skinData)
        {
            AddItem(new ShopItem
            {
                Sid = sid++,
                Type = ItemType.SkinCard,
                Resource = resource,
                Display = display,
                Grade = grade,
                Description = display + "_desc",
                Prices = new[]
                {
                    new ShopPrice { PriceId = 1, Currency = CurrencyType.Gold, Price = goldPrice },
                    new ShopPrice { PriceId = 2, Currency = CurrencyType.Diamond, Price = diamondPrice }
                },
                Category = "Skins"
            });
        }
    }

    #endregion

    #region 消耗品 (类型=Item, SID: 30001-30999)

    private static void InitializeConsumables()
    {
        var itemData = new[]
        {
            // 医疗用品
            ("bandage_02", "id_datalist_Bandage", 1, 100, 50, 1),
            ("leechdom_cardiac", "id_datalist_Cardiac", 2, 300, 150, 1),
            ("leechdom_blood_serum", "id_datalist_Blood_Serum", 2, 400, 200, 1),
            ("leechdom_first_aid_kit", "id_datalist_First_Aid_Kit", 3, 800, 400, 1),
            
            // 食物
            ("food_cookies", "id_datalist_Cheerie_Cookie", 1, 150, 75, 5),
            ("food_ham", "id_datalist_Ham", 1, 200, 100, 3),
            ("food_lobster", "id_datalist_Lobster_Feast", 2, 600, 300, 1),
            
            // 工具/特殊物品
            ("instrument_life", "id_datalist_Life_Detector", 3, 2000, 1000, 1),
            ("ticket_anabiosis", "id_datalist_Revival_Ticket", 3, 1500, 750, 1),
        };

        int sid = 30001;
        foreach (var (resource, display, grade, goldPrice, diamondPrice, qty) in itemData)
        {
            AddItem(new ShopItem
            {
                Sid = sid++,
                Type = ItemType.Item,
                Resource = resource,
                Display = display,
                Grade = grade,
                Description = display + "_desc",
                Prices = new[]
                {
                    new ShopPrice { PriceId = 1, Currency = CurrencyType.Gold, Price = goldPrice },
                    new ShopPrice { PriceId = 2, Currency = CurrencyType.Diamond, Price = diamondPrice }
                },
                Quantity = qty,
                Category = "Consumables"
            });
        }
    }

    #endregion

    #region 装饰品 (翅膀、珠宝等, 类型=Equipment, SID: 60001-60999)

    private static void InitializeDecorations()
    {
        var decorationData = new[]
        {
            // 翅膀
            ("deco_angel_wings", "id_datalist_Angel_Wings", 3, 3000, 1500),
            ("deco_devil_wings", "id_datalist_Devil_Wings", 3, 3000, 1500),
            ("deco_cupid_wings", "id_datalist_Cupid_Wings", 3, 3000, 1500),
            
            // 珠宝
            ("deco_sapphire_ring", "id_datalist_Sapphire_Ring", 1, 500, 250),
            ("deco_ruby_ring", "id_datalist_Ruby_Ring", 1, 500, 250),
            ("deco_emerald_ring", "id_datalist_Emerald_Ring", 1, 500, 250),
            
            // 高级珠宝
            ("deco_dazzling_ruby", "id_datalist_Dazzling_Ruby", 3, 2000, 1000),
            ("deco_dazzling_emerald", "id_datalist_Dazzling_Emerald", 3, 2000, 1000),
            ("deco_dazzling_sapphire", "id_datalist_Dazzling_Sapphire", 3, 2000, 1000),
            
            // 公会徽章
            ("deco_guild_badge_castle", "id_datalist_Guild_Badge_Castle", 2, 1000, 500),
            ("deco_guild_badge_pirate", "id_datalist_Guild_Badge_Pirate", 2, 1000, 500),
            ("deco_guild_badge_unicorn", "id_datalist_Guild_Badge_Unicorn", 2, 1000, 500),
        };

        int sid = 60001;
        foreach (var (resource, display, grade, goldPrice, diamondPrice) in decorationData)
        {
            // Client PersonalInfo logic uses `subtype` to decide how an equipment item is equipped:
            // - 102: wings/back-device (equip_type=1)
            // - 103: rings (equip_type=2/3)
            // - 101: badges (equip_type=4)
            var subtype = resource.Contains("wings", StringComparison.OrdinalIgnoreCase) ? 102
                : resource.Contains("ring", StringComparison.OrdinalIgnoreCase) || resource.Contains("dazzling", StringComparison.OrdinalIgnoreCase) ? 103
                : resource.Contains("badge", StringComparison.OrdinalIgnoreCase) ? 101
                : 0;

            AddItem(new ShopItem
            {
                Sid = sid++,
                Type = ItemType.Equipment,
                Subtype = subtype,
                Resource = resource,
                Display = display,
                Grade = grade,
                Description = display + "_desc",
                Prices = new[]
                {
                    new ShopPrice { PriceId = 1, Currency = CurrencyType.Gold, Price = goldPrice },
                    new ShopPrice { PriceId = 2, Currency = CurrencyType.Diamond, Price = diamondPrice }
                },
                Category = "Decorations"
            });
        }
    }

    #endregion

    #region 宠物 (类型=AvatarCard, SID: 70001-70999)

    private static void InitializePets()
    {
        var petData = new[]
        {
            // 飞行宠物
            ("pet_bird", "id_datalist_Bird", 1, 1000, 500),
            ("pet_bird02", "id_datalist_Bird_Advanced", 2, 2000, 1000),
            
            // 龙系宠物
            ("pet_dragon_01", "id_datalist_Dragon_01", 1, 2000, 1000),
            ("pet_dragon_02", "id_datalist_Dragon_02", 2, 3000, 1500),
            ("pet_dragon_05", "id_datalist_Dragon_05", 3, 5000, 2500),
            ("pet_dragon_10", "id_datalist_Dragon_10", 3, 8000, 4000),
            
            // 地面宠物
            ("pet_dog01", "id_datalist_Combat_Dog", 1, 1500, 750),
            ("pet_fish", "id_datalist_Fish", 1, 1000, 500),
            ("pet_monster", "id_datalist_Monster_Pet", 2, 3000, 1500),
        };

        int sid = 70001;
        foreach (var (resource, display, grade, goldPrice, diamondPrice) in petData)
        {
            AddItem(new ShopItem
            {
                Sid = sid++,
                Type = ItemType.AvatarCard,
                Resource = resource,
                Display = display,
                Grade = grade,
                Description = display + "_desc",
                Prices = new[]
                {
                    new ShopPrice { PriceId = 1, Currency = CurrencyType.Gold, Price = goldPrice },
                    new ShopPrice { PriceId = 2, Currency = CurrencyType.Diamond, Price = diamondPrice }
                },
                Category = "Pets"
            });
        }
    }

    #endregion

    #region 强化材料 (类型=Item, SID: 40001-40999)

    private static void InitializeEnhancementMaterials()
    {
        var materialData = new[]
        {
            // 基础材料
            ("material_raw_ore", "id_datalist_Raw_Ore", 1, 50, 25, 10),
            ("material_alloy", "id_datalist_Alloy", 2, 150, 75, 5),
            ("material_alloy_steel", "id_datalist_Alloy_Steel", 2, 300, 150, 3),
            
            // 宝石
            ("material_pure_ruby", "id_datalist_Pure_Ruby", 2, 200, 100, 1),
            ("material_pure_emerald", "id_datalist_Pure_Beryl", 2, 200, 100, 1),
            ("material_pure_sapphire", "id_datalist_Pure_Sapphire", 2, 200, 100, 1),
            
            // 高级宝石
            ("material_exquisite_ruby", "id_datalist_Exquisite_Bloodstone", 3, 800, 400, 1),
            ("material_exquisite_emerald", "id_datalist_Exquisite_Emerald", 3, 800, 400, 1),
            ("material_exquisite_sapphire", "id_datalist_Exquisite_Sapphire", 3, 800, 400, 1),
            
            // 特殊材料
            ("material_high_explosives", "id_datalist_High_Explosives", 2, 400, 200, 1),
            ("material_composites", "id_datalist_Composites", 2, 300, 150, 2),
        };

        int sid = 40001;
        foreach (var (resource, display, grade, goldPrice, diamondPrice, qty) in materialData)
        {
            AddItem(new ShopItem
            {
                Sid = sid++,
                Type = ItemType.Item,
                Resource = resource,
                Display = display,
                Grade = grade,
                Description = display + "_desc",
                Prices = new[]
                {
                    new ShopPrice { PriceId = 1, Currency = CurrencyType.Gold, Price = goldPrice },
                    new ShopPrice { PriceId = 2, Currency = CurrencyType.Diamond, Price = diamondPrice }
                },
                Quantity = qty,
                Category = "Materials"
            });
        }
    }

    #endregion

    /// <summary>添加商品到数据库</summary>
    private static void AddItem(ShopItem item)
    {
        Items[item.Sid] = item;
        if (!string.IsNullOrWhiteSpace(item.Resource))
        {
            ItemsByResource[item.Resource] = item;
        }
    }

    private static void RebuildIndexes()
    {
        ItemsByResource.Clear();
        foreach (var item in Items.Values)
        {
            if (!string.IsNullOrWhiteSpace(item.Resource))
            {
                ItemsByResource[item.Resource] = item;
            }
        }
    }

    public static bool TryGetShopItemByResource(string resource, [NotNullWhen(true)] out ShopItem? item)
    {
        if (string.IsNullOrWhiteSpace(resource))
        {
            item = null;
            return false;
        }

        return ItemsByResource.TryGetValue(resource, out item) ||
               ItemsByResource.TryGetValue(GetResourceLookupKey(resource), out item);
    }

    /// <summary>获取指定类型和页码的商品列表</summary>
    public static List<ShopItem> GetShopItems(int itemType, int page = 1, int pageSize = 20)
    {
        var typeEnum = (ItemType)itemType;
        
        return Items.Values
            .Where(item => item.Type == typeEnum)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();
    }

    /// <summary>按类别获取商品</summary>
    public static List<ShopItem> GetShopItemsByCategory(string category)
    {
        return Items.Values
            .Where(item => item.Category == category)
            .ToList();
    }

    /// <summary>获取商品总数</summary>
    public static int GetShopItemCount(int itemType)
    {
        var typeEnum = (ItemType)itemType;
        return Items.Values.Count(item => item.Type == typeEnum);
    }

    /// <summary>获取单个商品</summary>
    public static ShopItem? GetShopItem(int sid)
    {
        return Items.TryGetValue(sid, out var item) ? item : null;
    }

    /// <summary>获取所有商品</summary>
    public static IReadOnlyDictionary<int, ShopItem> GetAllShopItems() => Items;

    /// <summary>按类别获取分类列表</summary>
    public static IEnumerable<string> GetCategories()
    {
        return Items.Values
            .Select(item => item.Category)
            .Distinct()
            .OrderBy(x => x);
    }
}
