using System.Globalization;
using System.Text;
using System.Text.Json;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;
using MySqlConnector;
using Serilog;

namespace AvatarStar.Server.Game;

internal partial class GameClient
{
    private static string? ExtractAvatarId(object? equipAvatar)
    {
        if (equipAvatar is null)
        {
            return null;
        }

        static string? NormalizeAvatarId(object? value)
        {
            if (value is null)
            {
                return null;
            }

            string? text = value switch
            {
                JsonElement el when el.ValueKind == JsonValueKind.String => el.GetString(),
                JsonElement el => el.GetRawText(),
                _ => Convert.ToString(value, CultureInfo.InvariantCulture)
            };

            return string.IsNullOrWhiteSpace(text) ? null : text;
        }

        if (equipAvatar is IReadOnlyDictionary<string, object> roObjDict)
        {
            foreach (var (key, value) in roObjDict)
            {
                if (string.Equals(key, "avatarId", StringComparison.OrdinalIgnoreCase))
                {
                    return NormalizeAvatarId(value);
                }
            }
        }

        if (equipAvatar is IReadOnlyDictionary<string, string> roStrDict)
        {
            foreach (var (key, value) in roStrDict)
            {
                if (string.Equals(key, "avatarId", StringComparison.OrdinalIgnoreCase))
                {
                    return string.IsNullOrWhiteSpace(value) ? null : value;
                }
            }
        }

        if (equipAvatar is JsonElement el && el.ValueKind == JsonValueKind.Object)
        {
            foreach (var prop in el.EnumerateObject())
            {
                if (string.Equals(prop.Name, "avatarId", StringComparison.OrdinalIgnoreCase))
                {
                    return prop.Value.ValueKind == JsonValueKind.String
                        ? prop.Value.GetString()
                        : prop.Value.GetRawText();
                }
            }
        }

        foreach (var prop in equipAvatar.GetType().GetProperties())
        {
            if (prop.GetIndexParameters().Length > 0)
            {
                continue;
            }

            if (!string.Equals(prop.Name, "avatarId", StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            return NormalizeAvatarId(prop.GetValue(equipAvatar));
        }

        return null;
    }

    // This list is used to suppress "Unhandled RPC" warnings for APIs we already
    // know exist (from client lua notes / observed traffic) but haven't modeled yet.
    // For these, we return a generic empty/ok response to keep UI flows unblocked.
    private static readonly HashSet<string> KnownRpcNames = new(StringComparer.Ordinal)
    {
        "add_vip_level",
        "advanced_equip_info",
        "auction_bid",
        "auction_buy",
        "auction_cancel",
        "auction_cancel_all",
        "auction_cancel_currency",
        "auction_currency_exchange",
        "auction_currency_list",
        "auction_currency_self_list",
        "auction_currency_start",
        "auction_list",
        "auction_self_list",
        "auction_settlement_list",
        "auction_start",
        "auction_value",
        "avatar_praise",
        "avatar_slot_create",
        "blueprint_info",
        "blueprint_learn",
        "blueprint_list",
        "blueprint_make",
        "boss_skill_activate",
        "boss_skill_list",
        "box_info",
        "box_open",
        "box_prize_list",
        "create_retention",
        "facebook_success",
        "friend_search",
        "get_avatar_slot_list",
        "get_facebook_mission",
        "get_item_synthesis_info",
        "get_occupation_properties",
        "get_renew_item",
        "get_room_player_info",
        "get_team_all_list",
        "guild_item_compose",
        "guild_item_compose_show",
        "guild_member_expansion",
        "guild_member_expansion_detail",
        "guild_member_list",
        "guild_show",
        "guild_team_dismiss",
        "guild_team_expansion",
        "guild_team_expansion_detail",
        "guild_team_info_detail",
        "guild_team_list",
        "guild_team_member_requisition",
        "guild_team_show",
        "hero_avatar",
        "hero_introduction",
        "Invite_racing_member",
        "item_book_open",
        "item_info",
        "item_lock_detail",
        "item_ranking_season",
        "item_renew",
        "item_repair",
        "item_synthesize",
        "item_unbind",
        "item_unbind_detail",
        "leader_apply",
        "level_reward_list",
        "list_player_active",
        "lottery_broadcast",
        "lottery_list",
        "lottery_open",
        "lottery_prize_list",
        "mail_delete",
        "mail_detach",
        "mail_list",
        "mail_open",
        "mail_send",
        "mail_sys_detail",
        "medal_enchase",
        "medal_extirpate",
        "medal_extirpate_info",
        "name_modify",
        "player_avatar_edit",
        "player_avatar_equip",
        "player_avatar_save",
        "player_battle_force_get",
        "player_card_inherit",
        "player_card_inherit_material",
        "player_card_max",
        "player_checkin",
        "player_checkin_reward",
        "player_create",
        "player_delete",
        "player_detail",
        "player_dream_avatar_buy",
        "player_dream_avatar_delete",
        "player_equip",
        "player_freeze",
        "player_gesture_equip",
        "player_gesture_list",
        "player_gesture_unequip",
        "player_info",
        "player_item_count",
        "player_item_lock",
        "player_level_proficient",
        "player_list",
        "player_nearby_list",
        "player_ol_get_prize",
        "player_ol_prize",
        "player_pet_buy",
        "player_pet_custom_skill_list",
        "player_pet_custom_skill_update",
        "player_pet_del",
        "player_pet_expand_slot",
        "player_pet_feed",
        "player_pet_fight",
        "player_pet_list",
        "player_pet_open",
        "player_pet_placate",
        "player_pet_rename",
        "player_pet_skill",
        "player_pet_skill_upgrade",
        "player_quest_list",
        "player_report",
        "player_unequip",
        "player_unfreeze",
        "player_venture_detail",
        "player_venture_info",
        "proficient_level_info",
        "proficient_local_info",
        "proficient_property",
        "racing_kick_member",
        "racing_replacement_member",
        "racing_season_info",
        "racing_team_apply",
        "racing_team_list",
        "rank_hero_list",
        "rank_list",
        "rank_mine",
        "rank_playerinfo",
        "refit_detail",
        "refit_finish",
        "refit_need",
        "repair_price_get",
        "set_social_detail",
        "shop_buy",
        "shop_give",
        "shop_item_list",
        "skill_adjust",
        "skill_equip",
        "skill_list",
        "skill_reset",
        "skill_unequip",
        "slot_drag",
        "slot_equip",
        "slot_get",
        "slot_unequip",
        "stage_quit",
        "storage_drag",
        "storage_expand",
        "storage_expand_price",
        "storage_item_filter",
        "storage_neaten",
        "storage_remove",
        "storage_storage_list",
        "storage_storage_list_no_empty",
        "sys_avatar_part_get",
        "sys_avatar_pose_list",
        "sys_checkin_list",
        "sys_pet_list",
        "sys_quest_list",
        "sys_vip_list",
        "sysavatar_list",
        "tip_player_avatar",
        "tip_player_item",
        "tip_sys_item",
        "trial_vip",
        "update_trial_vip_tip",
        "use_card",
        "use_loudspeaker",
        "use_venture_property",
        "user_retention",
        "weapon_add_property",
        "weapon_addition_material",
        "weapon_advanced",
        "weapon_decomposition"
    };

    private const string BoxRulesConfigFileName = "box_rules.json";
    private static readonly object BoxRulesLock = new();
    private static readonly JsonSerializerOptions BoxRulesJsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };
    private static BoxRulesConfig? _boxRulesCache;
    private static string? _boxRulesCachePath;
    private static DateTime _boxRulesCacheWriteUtc;

    private sealed class BoxRulesConfig
    {
        public List<BoxCategoryRule> Categories { get; set; } = new();
    }

    private sealed class BoxCategoryRule
    {
        public int Category { get; set; }
        public int MainCategory { get; set; }
        public string BoxResource { get; set; } = string.Empty;
        public string KeyResource { get; set; } = string.Empty;
        public string BoxName { get; set; } = string.Empty;
        public string KeyName { get; set; } = string.Empty;
        public int Price { get; set; }
        public List<BoxPointRule> PointList { get; set; } = new();
        public List<BoxPrizeRule> PrizeList { get; set; } = new();
        public List<BoxPrizeRule> OpenPool { get; set; } = new();
    }

    private sealed class BoxPointRule
    {
        public int Category { get; set; }
        public int Unit { get; set; }
    }

    private sealed class BoxPrizeRule
    {
        public int PrizeId { get; set; }
        public int Sid { get; set; }
        public int Type { get; set; } = (int)ShopItemDatabase.ItemType.Item;
        public int SubType { get; set; }
        public int Grade { get; set; } = 1;
        public string Resource { get; set; } = string.Empty;
        public int UnitType { get; set; } = 1;
        public int Unit { get; set; } = 1;
        public int Quantity { get; set; } = 1;
        public int Weight { get; set; } = 1;
    }

    private const int CheckinSupplementCurrency = 4;
    private const int CheckinSupplementPrice = 1;
    private static readonly CheckinRulesConfig DefaultCheckinRules = BuildDefaultCheckinRules();

    private sealed class CheckinRulesConfig
    {
        public int SupplementCurrency { get; set; } = CheckinSupplementCurrency;
        public int SupplementPrice { get; set; } = CheckinSupplementPrice;
        public List<CheckinEntryRule> Checkins { get; set; } = new();
    }

    private sealed class CheckinEntryRule
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public int Type { get; set; }
        public int PlayerLevel { get; set; }
        public List<CheckinRewardRule> Rewards { get; set; } = new();
    }

    private sealed class CheckinRewardRule
    {
        public int Id { get; set; }
        public int Sid { get; set; }
        public string ItemId { get; set; } = string.Empty;
        public int Type { get; set; } = (int)ShopItemDatabase.ItemType.Item;
        public int SubType { get; set; }
        public int Grade { get; set; } = 1;
        public string Resource { get; set; } = string.Empty;
        public int UnitType { get; set; } = 1;
        public int Unit { get; set; } = 1;
        public int Quantity { get; set; } = 1;
    }

    private static string? ResolveBoxRulesPath()
    {
        var envPath = Environment.GetEnvironmentVariable("AS_BOX_RULES_PATH");
        if (!string.IsNullOrWhiteSpace(envPath) && File.Exists(envPath))
        {
            return envPath;
        }

        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Resources", BoxRulesConfigFileName),
            Path.Combine(Directory.GetCurrentDirectory(), "Resources", BoxRulesConfigFileName),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Resources", BoxRulesConfigFileName),
        };

        foreach (var path in candidates)
        {
            if (File.Exists(path))
            {
                return path;
            }
        }

        return null;
    }

    private static BoxRulesConfig BuildDefaultBoxRules()
    {
        static BoxPrizeRule Prize(
            int prizeId,
            int sid,
            int type,
            int subType,
            int grade,
            string resource,
            int unitType,
            int unit,
            int quantity,
            int weight)
        {
            return new BoxPrizeRule
            {
                PrizeId = prizeId,
                Sid = sid,
                Type = type,
                SubType = subType,
                Grade = grade,
                Resource = resource,
                UnitType = unitType,
                Unit = unit,
                Quantity = quantity,
                Weight = weight
            };
        }

        var rules = new BoxRulesConfig
        {
            Categories = new List<BoxCategoryRule>
            {
                new()
                {
                    Category = 1,
                    BoxResource = "baoxiang_tong",
                    KeyResource = "yaoshi_tong",
                    BoxName = "id_datalist_baoxiang_tong",
                    KeyName = "id_datalist_yaoshi_tong",
                    Price = 0,
                    PointList = new List<BoxPointRule>
                    {
                        new() { Category = 11, Unit = 10 },
                        new() { Category = 12, Unit = 30 },
                        new() { Category = 13, Unit = 60 },
                        new() { Category = 14, Unit = 100 },
                        new() { Category = 15, Unit = 150 }
                    },
                    OpenPool = new List<BoxPrizeRule>
                    {
                        Prize(20001, 20001, 2, 1, 1, "smg_01", 1, 1, 1, 65),
                        Prize(20592, 20592, 3, 100, 1, "pet_food01", 1, 2, 2, 25),
                        Prize(20604, 20604, 3, 100, 1, "blueprint01", 1, 1, 1, 10)
                    }
                },
                new()
                {
                    Category = 2,
                    BoxResource = "baoxiang_yin",
                    KeyResource = "yaoshi_yin",
                    BoxName = "id_datalist_baoxiang_yin",
                    KeyName = "id_datalist_yaoshi_yin",
                    Price = 0,
                    PointList = new List<BoxPointRule>
                    {
                        new() { Category = 21, Unit = 10 },
                        new() { Category = 22, Unit = 30 },
                        new() { Category = 23, Unit = 60 },
                        new() { Category = 24, Unit = 100 },
                        new() { Category = 25, Unit = 150 }
                    },
                    OpenPool = new List<BoxPrizeRule>
                    {
                        Prize(20005, 20005, 2, 1, 3, "smg_05", 1, 1, 1, 45),
                        Prize(20009, 20009, 2, 1, 4, "smg_09", 1, 1, 1, 20),
                        Prize(20593, 20593, 3, 100, 1, "pet_food02", 1, 3, 3, 25),
                        Prize(20608, 20608, 3, 100, 1, "blueprint05", 1, 1, 1, 10)
                    }
                },
                new()
                {
                    Category = 3,
                    BoxResource = "baoxiang_jin",
                    KeyResource = "yaoshi_jin",
                    BoxName = "id_datalist_baoxiang_jin",
                    KeyName = "id_datalist_yaoshi_jin",
                    Price = 0,
                    PointList = new List<BoxPointRule>
                    {
                        new() { Category = 31, Unit = 10 },
                        new() { Category = 32, Unit = 30 },
                        new() { Category = 33, Unit = 60 },
                        new() { Category = 34, Unit = 100 },
                        new() { Category = 35, Unit = 150 }
                    },
                    OpenPool = new List<BoxPrizeRule>
                    {
                        Prize(20009, 20009, 2, 1, 4, "smg_09", 1, 1, 1, 40),
                        Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 1, 1, 25),
                        Prize(20516, 20516, 2, 10, 1, "grenade_01", 1, 2, 2, 20),
                        Prize(20720, 20720, 3, 100, 1, "piece_wing43", 1, 1, 1, 15)
                    }
                },
                new()
                {
                    Category = 11,
                    MainCategory = 1,
                    PrizeList = new List<BoxPrizeRule> { Prize(20592, 20592, 3, 100, 1, "pet_food01", 1, 2, 2, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20592, 20592, 3, 100, 1, "pet_food01", 1, 2, 2, 1) }
                },
                new()
                {
                    Category = 12,
                    MainCategory = 1,
                    PrizeList = new List<BoxPrizeRule> { Prize(20604, 20604, 3, 100, 1, "blueprint01", 1, 2, 2, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20604, 20604, 3, 100, 1, "blueprint01", 1, 2, 2, 1) }
                },
                new()
                {
                    Category = 13,
                    MainCategory = 1,
                    PrizeList = new List<BoxPrizeRule> { Prize(20005, 20005, 2, 1, 3, "smg_05", 1, 1, 1, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20005, 20005, 2, 1, 3, "smg_05", 1, 1, 1, 1) }
                },
                new()
                {
                    Category = 14,
                    MainCategory = 1,
                    PrizeList = new List<BoxPrizeRule> { Prize(20009, 20009, 2, 1, 4, "smg_09", 1, 1, 1, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20009, 20009, 2, 1, 4, "smg_09", 1, 1, 1, 1) }
                },
                new()
                {
                    Category = 15,
                    MainCategory = 1,
                    PrizeList = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 1, 1, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 1, 1, 1) }
                },
                new()
                {
                    Category = 21,
                    MainCategory = 2,
                    PrizeList = new List<BoxPrizeRule> { Prize(20593, 20593, 3, 100, 1, "pet_food02", 1, 2, 2, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20593, 20593, 3, 100, 1, "pet_food02", 1, 2, 2, 1) }
                },
                new()
                {
                    Category = 22,
                    MainCategory = 2,
                    PrizeList = new List<BoxPrizeRule> { Prize(20608, 20608, 3, 100, 1, "blueprint05", 1, 2, 2, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20608, 20608, 3, 100, 1, "blueprint05", 1, 2, 2, 1) }
                },
                new()
                {
                    Category = 23,
                    MainCategory = 2,
                    PrizeList = new List<BoxPrizeRule> { Prize(20009, 20009, 2, 1, 4, "smg_09", 1, 1, 1, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20009, 20009, 2, 1, 4, "smg_09", 1, 1, 1, 1) }
                },
                new()
                {
                    Category = 24,
                    MainCategory = 2,
                    PrizeList = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 1, 1, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 1, 1, 1) }
                },
                new()
                {
                    Category = 25,
                    MainCategory = 2,
                    PrizeList = new List<BoxPrizeRule> { Prize(20720, 20720, 3, 100, 1, "piece_wing43", 1, 2, 2, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20720, 20720, 3, 100, 1, "piece_wing43", 1, 2, 2, 1) }
                },
                new()
                {
                    Category = 31,
                    MainCategory = 3,
                    PrizeList = new List<BoxPrizeRule> { Prize(20593, 20593, 3, 100, 1, "pet_food02", 1, 3, 3, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20593, 20593, 3, 100, 1, "pet_food02", 1, 3, 3, 1) }
                },
                new()
                {
                    Category = 32,
                    MainCategory = 3,
                    PrizeList = new List<BoxPrizeRule> { Prize(20608, 20608, 3, 100, 1, "blueprint05", 1, 3, 3, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20608, 20608, 3, 100, 1, "blueprint05", 1, 3, 3, 1) }
                },
                new()
                {
                    Category = 33,
                    MainCategory = 3,
                    PrizeList = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 1, 1, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 1, 1, 1) }
                },
                new()
                {
                    Category = 34,
                    MainCategory = 3,
                    PrizeList = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 2, 2, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 2, 2, 1) }
                },
                new()
                {
                    Category = 35,
                    MainCategory = 3,
                    PrizeList = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 3, 3, 1) },
                    OpenPool = new List<BoxPrizeRule> { Prize(20019, 20019, 2, 1, 5, "smg_21", 1, 3, 3, 1) }
                }
            }
        };

        return NormalizeBoxRules(rules);
    }

    private static BoxRulesConfig NormalizeBoxRules(BoxRulesConfig? raw)
    {
        var normalized = raw ?? new BoxRulesConfig();
        if (normalized.Categories is null)
        {
            normalized.Categories = new List<BoxCategoryRule>();
        }

        var cleaned = new List<BoxCategoryRule>();
        foreach (var category in normalized.Categories)
        {
            if (category is null || category.Category <= 0)
            {
                continue;
            }

            category.BoxResource = category.BoxResource?.Trim() ?? string.Empty;
            category.KeyResource = category.KeyResource?.Trim() ?? string.Empty;
            category.BoxName = category.BoxName?.Trim() ?? string.Empty;
            category.KeyName = category.KeyName?.Trim() ?? string.Empty;
            category.Price = Math.Max(0, category.Price);
            category.PointList = (category.PointList ?? new List<BoxPointRule>())
                .Where(x => x is { Category: > 0, Unit: > 0 })
                .Select(x => new BoxPointRule
                {
                    Category = x.Category,
                    Unit = x.Unit
                })
                .ToList();

            category.PrizeList = NormalizePrizeList(category.PrizeList);
            category.OpenPool = NormalizePrizeList(category.OpenPool);
            if (category.OpenPool.Count == 0 && category.PrizeList.Count > 0)
            {
                category.OpenPool = category.PrizeList
                    .Select(x => ClonePrize(x, Math.Max(1, x.Weight)))
                    .ToList();
            }

            if (category.PrizeList.Count == 0 && category.OpenPool.Count > 0)
            {
                category.PrizeList = category.OpenPool
                    .Select(x => ClonePrize(x, Math.Max(1, x.Weight)))
                    .ToList();
            }

            cleaned.Add(category);
        }

        if (cleaned.Count == 0)
        {
            return BuildDefaultBoxRulesFallbackOnly();
        }

        normalized.Categories = cleaned;
        return normalized;
    }

    private static List<BoxPrizeRule> NormalizePrizeList(IEnumerable<BoxPrizeRule>? source)
    {
        var result = new List<BoxPrizeRule>();
        if (source is null)
        {
            return result;
        }

        foreach (var prize in source)
        {
            if (prize is null)
            {
                continue;
            }

            result.Add(NormalizePrize(prize));
        }

        return result;
    }

    private static BoxPrizeRule ClonePrize(BoxPrizeRule prize, int? weight = null)
    {
        return new BoxPrizeRule
        {
            PrizeId = prize.PrizeId,
            Sid = prize.Sid,
            Type = prize.Type,
            SubType = prize.SubType,
            Grade = prize.Grade,
            Resource = prize.Resource,
            UnitType = prize.UnitType,
            Unit = prize.Unit,
            Quantity = prize.Quantity,
            Weight = weight ?? prize.Weight
        };
    }

    private static BoxRulesConfig BuildDefaultBoxRulesFallbackOnly()
    {
        // Prevent recursive fallback loops when normalization fails.
        return new BoxRulesConfig
        {
            Categories = new List<BoxCategoryRule>
            {
                new()
                {
                    Category = 1,
                    BoxResource = "baoxiang_tong",
                    KeyResource = "yaoshi_tong",
                    BoxName = "id_datalist_baoxiang_tong",
                    KeyName = "id_datalist_yaoshi_tong",
                    PointList = new List<BoxPointRule>
                    {
                        new() { Category = 11, Unit = 10 },
                        new() { Category = 12, Unit = 30 },
                        new() { Category = 13, Unit = 60 },
                        new() { Category = 14, Unit = 100 },
                        new() { Category = 15, Unit = 150 }
                    },
                    PrizeList = new List<BoxPrizeRule>
                    {
                        NormalizePrize(new BoxPrizeRule
                        {
                            PrizeId = 20001,
                            Sid = 20001,
                            Type = 2,
                            SubType = 1,
                            Grade = 1,
                            Resource = "smg_01",
                            UnitType = 1,
                            Unit = 1,
                            Quantity = 1,
                            Weight = 1
                        })
                    },
                    OpenPool = new List<BoxPrizeRule>
                    {
                        NormalizePrize(new BoxPrizeRule
                        {
                            PrizeId = 20001,
                            Sid = 20001,
                            Type = 2,
                            SubType = 1,
                            Grade = 1,
                            Resource = "smg_01",
                            UnitType = 1,
                            Unit = 1,
                            Quantity = 1,
                            Weight = 1
                        })
                    }
                }
            }
        };
    }

    private static BoxRulesConfig GetBoxRules()
    {
        var path = ResolveBoxRulesPath();
        if (string.IsNullOrWhiteSpace(path))
        {
            return BuildDefaultBoxRules();
        }

        DateTime lastWriteUtc;
        try
        {
            lastWriteUtc = File.GetLastWriteTimeUtc(path);
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to stat box rules file at {Path}, using defaults.", path);
            return BuildDefaultBoxRules();
        }

        lock (BoxRulesLock)
        {
            if (_boxRulesCache is not null &&
                string.Equals(_boxRulesCachePath, path, StringComparison.OrdinalIgnoreCase) &&
                _boxRulesCacheWriteUtc == lastWriteUtc)
            {
                return _boxRulesCache;
            }

            try
            {
                var raw = File.ReadAllText(path, Encoding.UTF8);
                var parsed = JsonSerializer.Deserialize<BoxRulesConfig>(raw, BoxRulesJsonOptions);
                var normalized = NormalizeBoxRules(parsed);
                _boxRulesCache = normalized;
                _boxRulesCachePath = path;
                _boxRulesCacheWriteUtc = lastWriteUtc;
                return normalized;
            }
            catch (Exception ex)
            {
                Log.Warning(ex, "Failed to load box rules from {Path}, using defaults.", path);
                var fallback = BuildDefaultBoxRules();
                _boxRulesCache = fallback;
                _boxRulesCachePath = path;
                _boxRulesCacheWriteUtc = lastWriteUtc;
                return fallback;
            }
        }
    }

    private static BoxPrizeRule NormalizePrize(BoxPrizeRule prize)
    {
        var normalized = new BoxPrizeRule
        {
            PrizeId = prize.PrizeId,
            Sid = prize.Sid > 0 ? prize.Sid : prize.PrizeId,
            Type = prize.Type,
            SubType = prize.SubType,
            Grade = prize.Grade,
            Resource = prize.Resource?.Trim() ?? string.Empty,
            UnitType = prize.UnitType,
            Unit = prize.Unit,
            Quantity = prize.Quantity,
            Weight = prize.Weight
        };

        ShopItemDatabase.ShopItem? item = null;
        if (normalized.Sid > 0)
        {
            item = ShopItemDatabase.GetShopItem(normalized.Sid);
        }

        if (item is null && !string.IsNullOrWhiteSpace(normalized.Resource) &&
            ShopItemDatabase.TryGetShopItemByResource(normalized.Resource, out var byResource))
        {
            item = byResource;
            if (normalized.Sid <= 0)
            {
                normalized.Sid = byResource.Sid;
            }
        }

        if (normalized.PrizeId <= 0)
        {
            normalized.PrizeId = normalized.Sid > 0 ? normalized.Sid : 0;
        }

        if (item is not null)
        {
            if (normalized.Type <= 0)
            {
                normalized.Type = (int)item.Type;
            }

            if (normalized.SubType <= 0)
            {
                normalized.SubType = item.Subtype;
            }

            if (normalized.Grade <= 0)
            {
                normalized.Grade = item.Grade;
            }

            if (string.IsNullOrWhiteSpace(normalized.Resource))
            {
                normalized.Resource = item.Resource ?? string.Empty;
            }
        }

        if (normalized.Type <= 0)
        {
            normalized.Type = (int)ShopItemDatabase.ItemType.Item;
        }

        normalized.SubType = Math.Max(0, normalized.SubType);
        normalized.Grade = Math.Max(1, normalized.Grade);
        normalized.UnitType = normalized.UnitType <= 0 ? 1 : normalized.UnitType;
        normalized.Quantity = Math.Max(1, normalized.Quantity);
        normalized.Unit = normalized.Unit <= 0
            ? (normalized.UnitType == 1 ? normalized.Quantity : 1)
            : normalized.Unit;
        normalized.Weight = Math.Max(1, normalized.Weight);
        return normalized;
    }

    private static bool TryGetBoxCategoryRule(BoxRulesConfig rules, int category, out BoxCategoryRule rule)
    {
        rule = rules.Categories.FirstOrDefault(x => x.Category == category) ?? new BoxCategoryRule();
        return rule.Category > 0;
    }

    private static BoxCategoryRule ResolveMainBoxCategoryForInfo(BoxRulesConfig rules, int requestedCategory)
    {
        if (TryGetBoxCategoryRule(rules, requestedCategory, out var direct))
        {
            if (IsBoxMainCategory(direct))
            {
                return direct;
            }

            if (direct.MainCategory > 0 && TryGetBoxCategoryRule(rules, direct.MainCategory, out var parent) && IsBoxMainCategory(parent))
            {
                return parent;
            }

            if (TryResolvePointGiftRule(rules, direct.Category, out var mainByPoint, out _))
            {
                return mainByPoint;
            }
        }

        if (TryResolvePointGiftRule(rules, requestedCategory, out var byGift, out _))
        {
            return byGift;
        }

        return rules.Categories.FirstOrDefault(IsBoxMainCategory) ??
               rules.Categories.First();
    }

    private static bool IsBoxMainCategory(BoxCategoryRule category)
    {
        return category.Category > 0 &&
               !string.IsNullOrWhiteSpace(category.BoxResource) &&
               !string.IsNullOrWhiteSpace(category.KeyResource) &&
               category.PointList.Count > 0;
    }

    private static bool TryResolvePointGiftRule(
        BoxRulesConfig rules,
        int giftCategory,
        out BoxCategoryRule mainCategory,
        out BoxPointRule pointRule)
    {
        foreach (var category in rules.Categories)
        {
            foreach (var point in category.PointList)
            {
                if (point.Category == giftCategory)
                {
                    mainCategory = category;
                    pointRule = point;
                    return true;
                }
            }
        }

        mainCategory = new BoxCategoryRule();
        pointRule = new BoxPointRule();
        return false;
    }

    private static BoxPrizeRule RollWeightedPrize(IReadOnlyList<BoxPrizeRule> pool)
    {
        if (pool.Count == 0)
        {
            return NormalizePrize(new BoxPrizeRule());
        }

        var totalWeight = 0;
        foreach (var prize in pool)
        {
            totalWeight += Math.Max(1, prize.Weight);
        }

        var roll = Random.Shared.Next(Math.Max(1, totalWeight));
        foreach (var prize in pool)
        {
            var weight = Math.Max(1, prize.Weight);
            if (roll < weight)
            {
                return NormalizePrize(prize);
            }

            roll -= weight;
        }

        return NormalizePrize(pool[^1]);
    }

    private static object BuildBoxPrizePayload(BoxPrizeRule prize)
    {
        return new
        {
            prizeId = prize.PrizeId > 0 ? prize.PrizeId : prize.Sid,
            sid = prize.Sid,
            type = prize.Type,
            subType = prize.SubType,
            subtype = prize.SubType,
            grade = prize.Grade,
            resource = prize.Resource,
            unitType = prize.UnitType,
            unit = prize.Unit,
            quantity = prize.Quantity
        };
    }

    private static bool TryGrantBoxPrize(PlayerStore.PlayerState player, BoxPrizeRule prize)
    {
        if (prize.Sid > 0 && ShopItemDatabase.GetShopItem(prize.Sid) is { } shopItem)
        {
            var granted = player.TryPurchaseToInventory(shopItem, Math.Max(1, prize.Quantity));
            if (granted &&
                prize.Type == (int)ShopItemDatabase.ItemType.Item &&
                prize.UnitType == 1 &&
                prize.Unit > Math.Max(1, prize.Quantity))
            {
                var extraCount = prize.Unit - Math.Max(1, prize.Quantity);
                _ = player.TryGrantInventoryItem(
                    type: prize.Type,
                    subtype: prize.SubType,
                    grade: prize.Grade,
                    sid: prize.Sid,
                    resource: prize.Resource,
                    quantity: extraCount,
                    unitType: prize.UnitType,
                    unit: extraCount);
            }

            return granted;
        }

        return player.TryGrantInventoryItem(
            type: prize.Type,
            subtype: prize.SubType,
            grade: prize.Grade,
            sid: prize.Sid,
            resource: prize.Resource,
            quantity: prize.Quantity,
            unitType: prize.UnitType,
            unit: prize.Unit);
    }

    private static int GetBoxResourceCount(
        PlayerStore.PlayerState player,
        BoxCategoryRule mainCategory,
        bool key)
    {
        var resource = key ? mainCategory.KeyResource : mainCategory.BoxResource;
        var subtype = key ? 401 : 400;
        var resourceCount = player.GetStorageResourceCount(3, resource);
        if (resourceCount > 0)
        {
            return resourceCount;
        }

        return player.GetStorageCountByCategory(3, mainCategory.Category, subtype);
    }

    private static bool TryConsumeBoxResource(
        PlayerStore.PlayerState player,
        BoxCategoryRule mainCategory,
        bool key,
        int count)
    {
        var resource = key ? mainCategory.KeyResource : mainCategory.BoxResource;
        var subtype = key ? 401 : 400;
        return player.TryConsumeStorageResource(3, resource, count) ||
               player.TryConsumeStorageByCategory(3, mainCategory.Category, subtype, count);
    }

    private static bool TryResolveBoxResource(string? resource, out int subtype, out int category)
    {
        subtype = 0;
        category = 0;
        if (string.IsNullOrWhiteSpace(resource))
        {
            return false;
        }

        var rules = GetBoxRules();
        foreach (var rule in rules.Categories)
        {
            if (!string.IsNullOrWhiteSpace(rule.BoxResource) &&
                string.Equals(rule.BoxResource, resource, StringComparison.OrdinalIgnoreCase))
            {
                subtype = 400;
                category = rule.Category;
                return true;
            }

            if (!string.IsNullOrWhiteSpace(rule.KeyResource) &&
                string.Equals(rule.KeyResource, resource, StringComparison.OrdinalIgnoreCase))
            {
                subtype = 401;
                category = rule.Category;
                return true;
            }
        }

        return false;
    }

    private static bool TryResolveBoxInventoryIdentity(InventoryItem item, out int subtype, out int category)
    {
        subtype = item.SubType > 0 ? item.SubType : item.Subtype;
        category = item.Category;

        if (subtype is 400 or 401 && category > 0)
        {
            return true;
        }

        if (TryResolveBoxResource(item.Resource, out var resolvedSubtype, out var resolvedCategory))
        {
            subtype = resolvedSubtype;
            category = category > 0 ? category : resolvedCategory;
            return true;
        }

        return false;
    }

    private static CheckinRulesConfig GetCheckinRules()
    {
        return DefaultCheckinRules;
    }

    private static CheckinRulesConfig BuildDefaultCheckinRules()
    {
        static CheckinRewardRule Reward(
            int id,
            string itemId,
            int type,
            int subType,
            int grade,
            string resource,
            int unitType,
            int unit,
            int quantity,
            int sid = 0)
        {
            return NormalizeCheckinReward(new CheckinRewardRule
            {
                Id = id,
                ItemId = itemId,
                Sid = sid,
                Type = type,
                SubType = subType,
                Grade = grade,
                Resource = resource,
                UnitType = unitType,
                Unit = unit,
                Quantity = quantity
            });
        }

        static CheckinEntryRule Entry(int id, string name, int type, params CheckinRewardRule[] rewards)
        {
            return new CheckinEntryRule
            {
                Id = id,
                Name = name,
                Type = type,
                PlayerLevel = 0,
                Rewards = rewards.ToList()
            };
        }

        return new CheckinRulesConfig
        {
            SupplementCurrency = CheckinSupplementCurrency,
            SupplementPrice = CheckinSupplementPrice,
            Checkins = new List<CheckinEntryRule>
            {
                Entry(
                    5,
                    "1",
                    1,
                    Reward(1, "91", 3, 0, 3, "leechdom_cardiac", 3, 2, 2),
                    Reward(2, "90", 3, 0, 2, "bandage_02", 3, 2, 2)),
                Entry(
                    1,
                    "2",
                    2,
                    Reward(26, "90", 3, 0, 2, "bandage_02", 3, 2, 2),
                    Reward(44, "113", 3, 0, 3, "intensify_luck", 3, 1, 1)),
                Entry(
                    2,
                    "4",
                    2,
                    Reward(27, "90", 3, 0, 2, "bandage_02", 3, 4, 4),
                    Reward(28, "113", 3, 0, 3, "intensify_luck", 3, 1, 1),
                    Reward(45, "207", 3, 0, 1, "yaoshi_tong", 3, 4, 4)),
                Entry(
                    3,
                    "7",
                    2,
                    Reward(29, "91", 3, 0, 3, "leechdom_cardiac", 3, 5, 5),
                    Reward(30, "113", 3, 0, 3, "intensify_luck", 3, 1, 1),
                    Reward(31, "207", 3, 0, 1, "yaoshi_tong", 3, 5, 5),
                    Reward(60, "814", 2, 4, 5, "shotgun_21", 4, 604800, 1),
                    Reward(61, "61", 3, 0, 3, "gem_red03", 3, 1, 1)),
                Entry(
                    4,
                    "11",
                    2,
                    Reward(32, "91", 3, 0, 3, "leechdom_cardiac", 3, 5, 5),
                    Reward(33, "113", 3, 0, 3, "intensify_luck", 3, 1, 1),
                    Reward(34, "212", 3, 0, 1, "yaoshi_yin", 3, 5, 5),
                    Reward(35, "343", 3, 0, 1, "avatar_design01", 3, 10, 10),
                    Reward(62, "815", 2, 5, 5, "pistol_21", 4, 604800, 1),
                    Reward(63, "62", 3, 0, 3, "gem_yellow03", 3, 1, 1)),
                Entry(
                    6,
                    "16",
                    2,
                    Reward(36, "96", 3, 0, 4, "food_lobster", 3, 5, 5),
                    Reward(37, "113", 3, 0, 3, "intensify_luck", 3, 2, 2),
                    Reward(38, "212", 3, 0, 1, "yaoshi_yin", 3, 6, 6),
                    Reward(39, "343", 3, 0, 1, "avatar_design01", 3, 10, 10),
                    Reward(64, "819", 2, 11, 5, "rpg_21", 4, 604800, 1),
                    Reward(65, "63", 3, 0, 3, "gem_green03", 3, 1, 1)),
                Entry(
                    7,
                    "22",
                    2,
                    Reward(40, "96", 3, 0, 4, "food_lobster", 3, 5, 5),
                    Reward(41, "113", 3, 0, 3, "intensify_luck", 3, 3, 3),
                    Reward(43, "343", 3, 0, 1, "avatar_design01", 3, 10, 10),
                    Reward(59, "212", 3, 0, 1, "yaoshi_yin", 3, 8, 8),
                    Reward(66, "1154", 2, 15, 5, "sprayer_21", 4, 604800, 1),
                    Reward(67, "64", 3, 0, 3, "gem_blue03", 3, 1, 1))
            }
        };
    }

    private static CheckinRewardRule NormalizeCheckinReward(CheckinRewardRule reward)
    {
        var normalized = new CheckinRewardRule
        {
            Id = reward.Id,
            Sid = reward.Sid,
            ItemId = reward.ItemId?.Trim() ?? string.Empty,
            Type = reward.Type,
            SubType = reward.SubType,
            Grade = reward.Grade,
            Resource = reward.Resource?.Trim() ?? string.Empty,
            UnitType = reward.UnitType,
            Unit = reward.Unit,
            Quantity = reward.Quantity
        };

        ShopItemDatabase.ShopItem? item = null;
        if (normalized.Sid > 0)
        {
            item = ShopItemDatabase.GetShopItem(normalized.Sid);
        }

        if (item is null &&
            !string.IsNullOrWhiteSpace(normalized.Resource) &&
            ShopItemDatabase.TryGetShopItemByResource(normalized.Resource, out var byResource))
        {
            item = byResource;
            if (normalized.Sid <= 0)
            {
                normalized.Sid = byResource.Sid;
            }
        }

        if (item is not null)
        {
            if (normalized.Type <= 0)
            {
                normalized.Type = (int)item.Type;
            }

            if (normalized.SubType <= 0)
            {
                normalized.SubType = item.Subtype;
            }

            if (normalized.Grade <= 0)
            {
                normalized.Grade = item.Grade;
            }

            if (string.IsNullOrWhiteSpace(normalized.Resource))
            {
                normalized.Resource = item.Resource ?? string.Empty;
            }
        }

        if (normalized.Type <= 0)
        {
            normalized.Type = (int)ShopItemDatabase.ItemType.Item;
        }

        normalized.Grade = Math.Max(1, normalized.Grade);
        normalized.UnitType = normalized.UnitType <= 0 ? 1 : normalized.UnitType;
        normalized.Quantity = Math.Max(1, normalized.Quantity > 0 ? normalized.Quantity : normalized.Unit);
        normalized.Unit = normalized.Unit <= 0
            ? (normalized.UnitType == 1 ? normalized.Quantity : 1)
            : normalized.Unit;

        if (string.IsNullOrWhiteSpace(normalized.ItemId))
        {
            normalized.ItemId = normalized.Sid > 0
                ? normalized.Sid.ToString(CultureInfo.InvariantCulture)
                : "0";
        }

        return normalized;
    }

    private static bool TryGetCheckinEntryRule(int checkinId, out CheckinEntryRule rule)
    {
        rule = GetCheckinRules().Checkins.FirstOrDefault(x => x.Id == checkinId) ?? new CheckinEntryRule();
        return rule.Id > 0;
    }

    private static CheckinEntryRule GetDailyCheckinEntry()
    {
        return GetCheckinRules().Checkins.FirstOrDefault(x => x.Type == 1) ?? new CheckinEntryRule();
    }

    private static bool TryGetCheckinRewardRule(int rewardId, out CheckinRewardRule rule)
    {
        foreach (var entry in GetCheckinRules().Checkins)
        {
            var found = entry.Rewards.FirstOrDefault(x => x.Id == rewardId);
            if (found is not null)
            {
                rule = found;
                return true;
            }
        }

        rule = new CheckinRewardRule();
        return false;
    }

    private static int GetCheckinTargetDay(CheckinEntryRule rule)
    {
        return int.TryParse(rule.Name, NumberStyles.Integer, CultureInfo.InvariantCulture, out var days)
            ? Math.Max(0, days)
            : 0;
    }

    private static string BuildCheckinListPayload(PlayerStore.PlayerState player, DateTime now)
    {
        var rules = GetCheckinRules();
        player.EnsureCheckinMonth(now);

        var checkinCount = player.GetCheckinCount(now);
        var isCheckin = player.HasCheckedInToday(now) ? "Y" : "N";
        var sysItemDate = DateTimeOffset.Now.ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture);

        var checkins = rules.Checkins.Select(rule =>
        {
            var canGetReward = "N";
            var isGetReward = "N";
            if (rule.Type == 2)
            {
                var targetDay = GetCheckinTargetDay(rule);
                var claimed = player.HasClaimedCheckinReward(now, rule.Id);
                isGetReward = claimed ? "Y" : "N";
                canGetReward = !claimed && targetDay > 0 && checkinCount >= targetDay ? "Y" : "N";
            }

            return (object)new
            {
                id = rule.Id.ToString(CultureInfo.InvariantCulture),
                name = rule.Name,
                type = rule.Type,
                playerLevel = rule.PlayerLevel,
                canGetReward,
                isGetReward,
                rewards = rule.Rewards.Select(reward => new
                {
                    id = reward.Id.ToString(CultureInfo.InvariantCulture),
                    itemId = reward.ItemId,
                    type = reward.Type,
                    subType = reward.SubType,
                    grade = reward.Grade,
                    resource = reward.Resource,
                    unitType = reward.UnitType,
                    unit = reward.Unit
                }).ToArray()
            };
        }).ToArray();

        var days = player.GetCheckinDaysOfMonth(now)
            .Select(day => (object)new object[] { day })
            .ToArray();

        return string.Join(
            "\n",
            $"sysItemDate = {LuaEscape(sysItemDate)}",
            $"isCheckin = {LuaEscape(isCheckin)}",
            $"count = {checkinCount}",
            $"checkinSupplementCurrency = {rules.SupplementCurrency}",
            $"checkinSupplementPrice = {rules.SupplementPrice}",
            $"checkins = {LuaSerializer.SerializeSequential(checkins)}",
            $"days = {LuaSerializer.SerializeSequential(days)}");
    }

    private static bool TryResolveCheckinDate(
        IReadOnlyDictionary<string, string> rpcArgs,
        DateTime now,
        out DateTime checkinDate,
        out string errorKey)
    {
        errorKey = string.Empty;
        checkinDate = now.Date;

        var pattern = GetIntArg(rpcArgs, "pattern", 1);
        if (pattern != 2)
        {
            return true;
        }

        var rawDate = rpcArgs.GetValueOrDefault("date") ?? string.Empty;
        if (string.IsNullOrWhiteSpace(rawDate))
        {
            errorKey = "msgbox_lobby_sign_002";
            return false;
        }

        var formats = new[]
        {
            "yyyy-M-d",
            "yyyy-M-dd",
            "yyyy-MM-d",
            "yyyy-MM-dd"
        };

        if (!DateTime.TryParseExact(
                rawDate,
                formats,
                CultureInfo.InvariantCulture,
                DateTimeStyles.None,
                out var parsed))
        {
            errorKey = "msgbox_lobby_sign_002";
            return false;
        }

        if (parsed.Year != now.Year || parsed.Month != now.Month || parsed.Date >= now.Date)
        {
            errorKey = "msgbox_lobby_sign_002";
            return false;
        }

        checkinDate = parsed.Date;
        return true;
    }

    private static bool TryGrantCheckinRewards(
        PlayerStore.PlayerState player,
        IEnumerable<CheckinRewardRule> rewards,
        out string errorKey)
    {
        foreach (var reward in rewards)
        {
            if (!TryGrantCheckinReward(player, reward, out errorKey))
            {
                return false;
            }
        }

        errorKey = string.Empty;
        return true;
    }

    private static bool TryGrantCheckinReward(
        PlayerStore.PlayerState player,
        CheckinRewardRule reward,
        out string errorKey)
    {
        if (reward.Type == 7)
        {
            var amount = Math.Max(1, reward.Unit);
            switch (reward.ItemId)
            {
                case "1":
                    player.Gp += amount;
                    errorKey = string.Empty;
                    return true;
                case "2":
                    player.Mb += amount;
                    errorKey = string.Empty;
                    return true;
                case "4":
                    player.Tb += amount;
                    errorKey = string.Empty;
                    return true;
                default:
                    errorKey = "msgbox_lobby_sign_002";
                    return false;
            }
        }

        var item = reward.Sid > 0 ? ShopItemDatabase.GetShopItem(reward.Sid) : null;
        if (item is null &&
            !string.IsNullOrWhiteSpace(reward.Resource) &&
            ShopItemDatabase.TryGetShopItemByResource(reward.Resource, out var byResource))
        {
            item = byResource;
        }

        var grantQuantity = Math.Max(1, reward.Quantity);
        var grantUnitType = reward.Type == (int)ShopItemDatabase.ItemType.Item ? 1 : reward.UnitType;
        var grantUnit = reward.Type == (int)ShopItemDatabase.ItemType.Item
            ? grantQuantity
            : Math.Max(1, reward.Unit);

        var granted = player.TryGrantInventoryItem(
            type: reward.Type,
            subtype: reward.SubType,
            grade: reward.Grade,
            sid: reward.Sid,
            resource: reward.Resource,
            quantity: grantQuantity,
            unitType: grantUnitType,
            unit: grantUnit,
            avatar: item?.Avatar,
            position: reward.Type is (int)ShopItemDatabase.ItemType.AvatarCard or (int)ShopItemDatabase.ItemType.SkinCard ? 1 : null,
            display: item?.Display,
            designer: reward.Type is (int)ShopItemDatabase.ItemType.AvatarCard or (int)ShopItemDatabase.ItemType.SkinCard
                ? "msgbox_common_conditionkey_146"
                : null,
            description: item?.Description);

        errorKey = granted ? string.Empty : "msgbox_lobby_sign_001";
        return granted;
    }

    private static bool TryBuildCheckinRewardInventoryItem(int rewardId, out InventoryItem item)
    {
        if (!TryGetCheckinRewardRule(rewardId, out var reward))
        {
            item = default!;
            return false;
        }

        var shopItem = reward.Sid > 0 ? ShopItemDatabase.GetShopItem(reward.Sid) : null;
        if (shopItem is null &&
            !string.IsNullOrWhiteSpace(reward.Resource) &&
            ShopItemDatabase.TryGetShopItemByResource(reward.Resource, out var byResource))
        {
            shopItem = byResource;
        }

        item = new InventoryItem(
            Pid: "0",
            Slot: 0,
            Resource: reward.Resource,
            Subtype: reward.SubType,
            SubType: reward.SubType,
            Grade: reward.Grade,
            Quantity: Math.Max(1, reward.Quantity),
            UnitType: reward.UnitType <= 0 ? 1 : reward.UnitType,
            Unit: reward.Unit <= 0 ? Math.Max(1, reward.Quantity) : reward.Unit,
            Remain: 0,
            IsRenew: false,
            Category: 0,
            IsBind: "N",
            IsEquip: "N",
            Sid: reward.Sid,
            Type: reward.Type,
            Avatar: shopItem?.Avatar,
            Position: reward.Type is (int)ShopItemDatabase.ItemType.AvatarCard or (int)ShopItemDatabase.ItemType.SkinCard ? 1 : null,
            Display: shopItem?.Display ?? string.Empty,
            Designer: reward.Type is (int)ShopItemDatabase.ItemType.AvatarCard or (int)ShopItemDatabase.ItemType.SkinCard
                ? "msgbox_common_conditionkey_146"
                : string.Empty,
            Description: shopItem?.Description ?? string.Empty);
        return true;
    }

    private static string GenericOkPayload(IReadOnlyDictionary<string, string> args)
    {
        // Many lua callbacks check different fields depending on feature; include several common ones.
        // Keep it as a Lua chunk (loadstring()) rather than JSON to match existing client expectations.
        var page = args.TryGetValue("p", out var p) && int.TryParse(p, NumberStyles.Integer, CultureInfo.InvariantCulture, out var pv) ? pv : 1;
        var pageSize = args.TryGetValue("pageSize", out var ps) && int.TryParse(ps, NumberStyles.Integer, CultureInfo.InvariantCulture, out var psv) ? psv : 10;
        return
            $"ok = 1\n" +
            $"page = {page}\n" +
            $"pages = 1\n" +
            $"pageSize = {pageSize}\n" +
            "list = {}\n" +
            "items = {}\n" +
            "quests = {}\n" +
            "skills = {}\n" +
            "gestures = {}";
    }

    private static string StageQuitPayload(
        PlayerStore.PlayerState player,
        PracticeRoomManager.PracticeRoomSession? room)
    {
        var character = player.Character;
        var teamEntry = new
        {
            id = character.Id,
            name = character.Name,
            level = character.Level,
            occupation = character.Occupation,
            rankType = 1,
            rankLevel = 1,
            vipLevel = 0,
            killScore = 0,
            outPutScore = 0,
            comboKillScore = 0,
            comboWinScore = 0,
            survivalScore = 0,
            modeScore = 0,
            totalScore = 0,
            result = 1
        };
        var self = new
        {
            playerId = character.Id,
            oldLevel = character.Level,
            gainLevel = 0,
            oldExpCurrentLevelOffset = 0,
            oldExpNextLevelOffset = 100,
            newExpCurrentLevelOffset = 0,
            newExpNextLevelOffset = 100,
            oldRankLevel = 1,
            oldRankType = 1,
            currentRankLevel = 1,
            currentRankType = 1,
            totalScore = 0,
            gainExp = 0,
            demandGainExp = 0,
            randomMatchGainExp = 0,
            bufferGainExp = 0,
            vipGainExp = 0,
            weakGainExp = 0,
            gainGp = 0,
            demandGainGp = 0,
            randomMatchGainGp = 0,
            bufferGainGp = 0,
            vipGainGp = 0,
            gainSkillPoint = 0,
            longPlayModulus = 1,
            isWin = "Y",
            isRandomMatchGame = false,
            addStageQuitGpRate = 0,
            addStageQuitExpRate = 0,
            lastBattlePoint = 0,
            buffs = Array.Empty<object>()
        };
        return
            "ok = 1\n" +
            $"gameType = {room?.GameType ?? 4}\n" +
            "self = " + LuaSerializer.Serialize(self) + "\n" +
            "t1 = " + LuaSerializer.Serialize(new[] { teamEntry }) + "\n" +
            "t2 = {}\n" +
            "winnerSide = 0\n" +
            "mvp = nil\n" +
            "cardprize = nil\n" +
            "isHook = false\n" +
            "hookNum = 0\n" +
            "averageVenture = 0\n" +
            "totalStageNum = 0\n" +
            "stageNum = 0\n" +
            "timeMap = {}\n" +
            "resourceMap = {}\n" +
            "difficulty = 0\n" +
            "passScore = 0";
    }

    private async Task HandleRpcCall(PacketReader reader, uint packetId)
    {
        var rpcId = reader.ReadInt();
        var rpcName = reader.ReadString();
        var rpcArgs = new Dictionary<string, string>(StringComparer.Ordinal);

        Log.Debug("RPC: id={RpcId}, name={RpcName}, remaining={Remaining}", rpcId, rpcName, reader.Remaining);
        _practiceRoomManager.MarkGameClientRpcActivity(_activeRoleId, rpcName);

        while (reader.Remaining > 0)
        {
            var key = reader.ReadString();
            if (key == string.Empty) break;
            var value = reader.ReadString();
            rpcArgs[key] = value;
            Log.Debug("RPC arg: {Key}={Value}", key, value);
        }

        Log.Debug("RPC[{Pid}] rpcId={RpcId} rpcName={RpcName} rpcArgs={RpcArgs}", packetId, rpcId, rpcName, rpcArgs);

        var writer = new PacketWriter();
        writer.WriteByte(0);
        writer.WriteInt(rpcId);

        switch (rpcName)
        {
            case "player_list":
            {
                var characters = _accountId > 0
                    ? _playerStore.ListCharacters(_accountId)
                    : _playerStore.ListCharacters();
                var characterObjects = new object[characters.Count];
                for (var i = 0; i < characters.Count; i++)
                {
                    var c = characters[i];
                    characterObjects[i] = new
                    {
                        id = c.Id,
                        name = c.Name,
                        level = c.Level,
                        occupation = c.Occupation,
                        battleForce = c.BattleForce,
                        // Fields required by `scripts/select_character.lua` UI logic.
                        freezeTime = -1,
                        isColseRole = false,
                        beginCloseRoleTime = 0,
                        endCloseRoleTime = 0,
                        bannedReason = "",
                        equips = (object?)null,
                        equipAvatar = c.EquipAvatar
                    };
                }

                var charactersLua = LuaSerializer.Serialize(characterObjects);
                writer.WriteString(
                    "cost = 1\n" +
                    "mb = 0\n" +
                    "isAuctionClose = false\n" +
                    "isPetClose = false\n" +
                    "isColseAccount = false\n" +
                    "beginColseAccountTime = 0\n" +
                    "endColseAccountTime = 0\n" +
                    "bannedReason = \"\"\n" +
                    "sysTimeNow = 0\n" +
                    "characters = " + charactersLua + "\n" +
                    "lastPid = 0");
                await SendAsync(writer);
                return;
            }

            case "create_retention":
                writer.WriteString("ok = 1");
                await SendAsync(writer);
                return;

            case "get_occupation_properties":
            {
                var config = _sysAvatarPayloadMonitor.CurrentValue;
                string Desc(int occupation) =>
                    NormalizeDesc(config.OfficialCatalog?.Professions.FirstOrDefault(p => p.Occupation == occupation)?.Description)
                    ?? occupation switch
                    {
                        0 => "UI_profession_Guardian_desc",
                        1 => "UI_profession_Gunner_desc",
                        2 => "UI_profession_Assassin_desc",
                        3 => "UI_profession_Biochemical_desc",
                        _ => "UI_profession_Guardian_desc",
                    };

                static string? NormalizeDesc(string? v) =>
                    v == "UI_datalist_Biochemical_Quest" ? "UI_profession_Biochemical_desc" : v;

                var characterList = LuaSerializer.Serialize(new object[]
                {
                    new { description = Desc(0) },
                    new { description = Desc(1) },
                    new { description = Desc(2) },
                    new { description = Desc(3) }
                });
                writer.WriteString("characterList = " + characterList);
                await SendAsync(writer);
                return;
            }

            case "player_create":
                {
                    var config = _sysAvatarPayloadMonitor.CurrentValue;
                    var existingCount = _accountId > 0
                        ? _playerStore.ListCharacters(_accountId).Count
                        : _playerStore.ListCharacters().Count;
                    var name = rpcArgs.TryGetValue("name", out var n) ? n.Trim() : $"Player{existingCount + 1}";
                    if (string.IsNullOrWhiteSpace(name))
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("character name cannot be empty"));
                        await SendAsync(writer);
                        return;
                    }

                    if (_playerStore.CharacterNameExists(name) ||
                        await _gameDataRepository.CharacterNameExistsAsync(name))
                    {
                        Log.Information("player_create rejected: duplicate character name={Name} accountId={AccountId}", name, _accountId);
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("character name already exists"));
                        await SendAsync(writer);
                        return;
                    }

                    var jobIdStr = rpcArgs.TryGetValue("id", out var jid) ? jid : "1";
                    _ = int.TryParse(jobIdStr, out var jobId);

                    var occupation = Math.Clamp(jobId - 1, 0, 3);
                    var cardDisplay = name;
                    var cardDesigner = rpcArgs.TryGetValue("description", out var descriptionRaw) && !string.IsNullOrWhiteSpace(descriptionRaw)
                        ? descriptionRaw
                        : name;

                    string Suit(string key) => rpcArgs.TryGetValue(key, out var v) && !string.IsNullOrWhiteSpace(v) ? v : "{}";
                    var avatarId = rpcArgs.TryGetValue("avatar_id", out var aid) && !string.IsNullOrWhiteSpace(aid) ? aid : "0";
                    var equipAvatar = new
                    {
                        avatarId,
                        skin = Suit("skin"),
                        eye = Suit("eye"),
                        mouth = Suit("mouth"),
                        nose = Suit("nose"),
                        ear = Suit("ear"),
                        beard = Suit("beard"),
                        hair = Suit("hair"),
                        helmet = Suit("helmet"),
                        underwear = Suit("underwear"),
                        outerwear = Suit("outerwear"),
                        trousers = Suit("trousers"),
                        glove = Suit("glove"),
                        shoes = Suit("shoes"),
                        decal = Suit("decal"),
                        movable = Suit("movable"),
                        immobile = Suit("immobile"),
                        immobileUp = Suit("immobileUp"),
                        immobileDown = Suit("immobileDown")
                    };

                    var previousRoleId = _activeRoleId;
                    PlayerStore.PlayerState created;
                    try
                    {
                        created = _playerStore.CreateCharacter(
                            _accountId,
                            name,
                            occupation,
                            config,
                            equipAvatar,
                            avatarId,
                            starterCardDisplay: cardDisplay,
                            starterCardDesigner: cardDesigner);
                    }
                    catch (InvalidOperationException)
                    {
                        Log.Information("player_create rejected by memory store: duplicate character name={Name} accountId={AccountId}", name, _accountId);
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("character name already exists"));
                        await SendAsync(writer);
                        return;
                    }
                    catch (ArgumentException)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("character name cannot be empty"));
                        await SendAsync(writer);
                        return;
                    }

                    _practiceRoomManager.UnregisterGameClient(_activeRoleId, this);
                    _activeRoleId = created.Character.Id;
                    _practiceRoomManager.RegisterGameClient(_activeRoleId, this);

           
                    var newPlayer = GetActivePlayerStateOrDefault();
                    if (newPlayer != null)
                    {
                        // 金宝箱 - 9999个
                        newPlayer.TryGrantInventoryItem(
                            type: 3,                    
                            subtype: 400,             
                            grade: 1,
                            sid: 20550,                
                            resource: "baoxiang_jin",  
                            quantity: 99999,
                            unitType: 1,
                            unit: 99999);

                        // 金钥匙 - 9999个
                        newPlayer.TryGrantInventoryItem(
                            type: 3,                   
                            subtype: 401,             
                            grade: 1,
                            sid: 20725,
                            resource: "yaoshi_jin",    
                            quantity: 99999,
                            unitType: 1,
                            unit: 99999);
                    }

                    try
                    {
                        await SaveActiveAccountAsync();
                    }
                    catch (MySqlException ex) when (ex.Number == 1062)
                    {
                        _practiceRoomManager.UnregisterGameClient(_activeRoleId, this);
                        if (_accountId > 0)
                        {
                            _playerStore.DeleteCharacter(_accountId, created.Character.Id);
                        }
                        else
                        {
                            _playerStore.DeleteCharacter(created.Character.Id);
                        }
                        _activeRoleId = previousRoleId;
                        _practiceRoomManager.RegisterGameClient(_activeRoleId, this);

                        Log.Information(
                            "player_create rejected by database unique index: duplicate character name={Name} accountId={AccountId}",
                            name,
                            _accountId);
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("character name already exists"));
                        await SendAsync(writer);
                        return;
                    }
            

                    writer.WriteString("ok = 1\nwarning = nil");
                    await SendAsync(writer);
                    return;
                }

            case "player_delete":
            {
                if (rpcArgs.TryGetValue("cid", out var cidStr) && int.TryParse(cidStr, out var cid))
                {
                    if (_accountId > 0)
                    {
                        _playerStore.DeleteCharacter(_accountId, cid);
                    }
                    else
                    {
                        _playerStore.DeleteCharacter(cid);
                    }
                }
                writer.WriteString("ok = 1");
                await SendAsync(writer);
                return;
            }

            case "player_freeze":
            case "player_unfreeze":
            {
                // Client uses these to start/cancel a delete countdown UI.
                // We don't implement timed deletion yet; returning ok keeps the flow unblocked.
                writer.WriteString("ok = 1");
                await SendAsync(writer);
                return;
            }

            case "sysavatar_list":
            {
                var config = _sysAvatarPayloadMonitor.CurrentValue;
                var requestedAvatarId = int.TryParse(rpcArgs.GetValueOrDefault("sysCharacterId"), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsedAvatarId)
                    ? parsedAvatarId
                    : 1;

                if (config.SysAvatarListPayloads.TryGetValue(requestedAvatarId, out var rawPayload) &&
                    !string.IsNullOrWhiteSpace(rawPayload) &&
                    rawPayload.Contains("sysAvatar", StringComparison.Ordinal))
                {
                    writer.WriteString(rawPayload);
                    await SendAsync(writer);
                    return;
                }

                Log.Warning("sysavatar_list missing payload override for sysCharacterId={SysCharacterId}", requestedAvatarId);
                writer.WriteString("sysAvatar = {}\nweapons = {}");
                await SendAsync(writer);
                return;
            }

            case "sys_checkin_list":
            {
                var player = GetActivePlayerStateOrDefault();
                var now = DateTime.Now;
                var payload = BuildCheckinListPayload(player, now);
                Log.Information(
                    "sys_checkin_list: roleId={RoleId} isCheckin={IsCheckin} count={Count} days={Days}",
                    player.Character.Id,
                    player.HasCheckedInToday(now),
                    player.GetCheckinCount(now),
                    string.Join(",", player.GetCheckinDaysOfMonth(now)));
                writer.WriteString(payload);
                await SendAsync(writer);
                return;
            }

            case "player_checkin":
            {
                var player = GetActivePlayerStateOrDefault();
                var now = DateTime.Now;
                var pattern = GetIntArg(rpcArgs, "pattern", 1);
                if (!TryResolveCheckinDate(rpcArgs, now, out var checkinDate, out var resolveErrorKey))
                {
                    writer.WriteString("ok = 0\nerror = " + LuaEscape(resolveErrorKey));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_checkin rejected: roleId={RoleId} pattern={Pattern} date={Date} error={Error}",
                        player.Character.Id,
                        pattern,
                        rpcArgs.GetValueOrDefault("date") ?? string.Empty,
                        resolveErrorKey);
                    return;
                }

                if (player.HasCheckedInDay(now, checkinDate.Day))
                {
                    writer.WriteString("ok = 0\nerror = " + LuaEscape("msgbox_lobby_sign_002"));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_checkin duplicate: roleId={RoleId} pattern={Pattern} day={Day}",
                        player.Character.Id,
                        pattern,
                        checkinDate.Day);
                    return;
                }

                var rules = GetCheckinRules();
                if (pattern == 2)
                {
                    if (player.Tb < rules.SupplementPrice)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("msgbox_common_conditionkey_131"));
                        await SendAsync(writer);
                        Log.Warning(
                            "player_checkin supplement rejected: roleId={RoleId} tb={Tb} price={Price}",
                            player.Character.Id,
                            player.Tb,
                            rules.SupplementPrice);
                        return;
                    }
                }

                var dailyRule = GetDailyCheckinEntry();
                if (dailyRule.Id <= 0)
                {
                    writer.WriteString("ok = 0\nerror = " + LuaEscape("msgbox_lobby_sign_002"));
                    await SendAsync(writer);
                    Log.Warning("player_checkin missing daily rule: roleId={RoleId}", player.Character.Id);
                    return;
                }

                var snapshot = player.CaptureRewardGrantSnapshot();
                if (pattern == 2)
                {
                    player.Tb -= rules.SupplementPrice;
                }

                if (!TryGrantCheckinRewards(player, dailyRule.Rewards, out var grantErrorKey))
                {
                    player.RestoreRewardGrantSnapshot(snapshot);
                    writer.WriteString("ok = 0\nerror = " + LuaEscape(grantErrorKey));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_checkin grant failed: roleId={RoleId} pattern={Pattern} day={Day} error={Error}",
                        player.Character.Id,
                        pattern,
                        checkinDate.Day,
                        grantErrorKey);
                    return;
                }

                if (!player.TryAddCheckinDay(now, checkinDate.Day))
                {
                    player.RestoreRewardGrantSnapshot(snapshot);
                    writer.WriteString("ok = 0\nerror = " + LuaEscape("msgbox_lobby_sign_002"));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_checkin add day failed: roleId={RoleId} pattern={Pattern} day={Day}",
                        player.Character.Id,
                        pattern,
                        checkinDate.Day);
                    return;
                }

                writer.WriteString("ok = 1");
                await SendAsync(writer);
                Log.Information(
                    "player_checkin success: roleId={RoleId} pattern={Pattern} day={Day} count={Count}",
                    player.Character.Id,
                    pattern,
                    checkinDate.Day,
                    player.GetCheckinCount(now));
                return;
            }

            case "player_checkin_reward":
            {
                var player = GetActivePlayerStateOrDefault();
                var now = DateTime.Now;
                var checkinId = GetIntArg(rpcArgs, "checkinId", 0);
                if (!TryGetCheckinEntryRule(checkinId, out var rewardEntry) || rewardEntry.Type != 2)
                {
                    writer.WriteString("ok = 0\nerror = " + LuaEscape("msgbox_lobby_sign_002"));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_checkin_reward missing rule: roleId={RoleId} checkinId={CheckinId}",
                        player.Character.Id,
                        checkinId);
                    return;
                }

                var targetDay = GetCheckinTargetDay(rewardEntry);
                if (targetDay <= 0 ||
                    player.GetCheckinCount(now) < targetDay ||
                    player.HasClaimedCheckinReward(now, checkinId))
                {
                    writer.WriteString("ok = 0\nerror = " + LuaEscape("msgbox_lobby_sign_002"));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_checkin_reward rejected: roleId={RoleId} checkinId={CheckinId} count={Count} target={Target} claimed={Claimed}",
                        player.Character.Id,
                        checkinId,
                        player.GetCheckinCount(now),
                        targetDay,
                        player.HasClaimedCheckinReward(now, checkinId));
                    return;
                }

                var snapshot = player.CaptureRewardGrantSnapshot();
                if (!TryGrantCheckinRewards(player, rewardEntry.Rewards, out var grantErrorKey))
                {
                    player.RestoreRewardGrantSnapshot(snapshot);
                    writer.WriteString("ok = 0\nerror = " + LuaEscape(grantErrorKey));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_checkin_reward grant failed: roleId={RoleId} checkinId={CheckinId} error={Error}",
                        player.Character.Id,
                        checkinId,
                        grantErrorKey);
                    return;
                }

                if (!player.TryClaimCheckinReward(now, checkinId))
                {
                    player.RestoreRewardGrantSnapshot(snapshot);
                    writer.WriteString("ok = 0\nerror = " + LuaEscape("msgbox_lobby_sign_002"));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_checkin_reward claim state failed: roleId={RoleId} checkinId={CheckinId}",
                        player.Character.Id,
                        checkinId);
                    return;
                }

                writer.WriteString("ok = 1");
                await SendAsync(writer);
                Log.Information(
                    "player_checkin_reward success: roleId={RoleId} checkinId={CheckinId} count={Count}",
                    player.Character.Id,
                    checkinId,
                    player.GetCheckinCount(now));
                return;
            }

            case "player_detail":
            {
                var p = GetActivePlayerStateOrDefault();
                var c = p.Character;
                var now = DateTime.Now;
                var isCheckinToday = p.HasCheckedInToday(now);
                var nowSeconds = DateTimeOffset.Now.ToUnixTimeSeconds();

                // Keep player_detail compatible with both lobbyMain_d.lua and personalInfo_d.lua.
                // - lobbyMain needs money/vip/buffs/online/checkin/etc
                // - personalInfo expects equip avatar + equipped independent trinkets (equips)
                var equippedAvatar = p.GetEquippedAvatarItem();
                var equipAvatar = equippedAvatar?.Avatar ?? c.EquipAvatar;
                var equipAvatarLua = LuaSerializer.Serialize(equipAvatar);
                var equipsLua = LuaSerializer.Serialize(p.GetEquippedItems());
                var avatarSkillLua = LuaSerializer.Serialize(new
                {
                    skillId = 0,
                    level = 0,
                    resource = string.Empty
                });
                var avatarSubType = equippedAvatar?.SubType is > 0
                    ? equippedAvatar.SubType
                    : equippedAvatar?.Subtype ?? 1;
                var avatarPosition = equippedAvatar?.Position ?? 1;
                var avatarGrade = equippedAvatar?.Grade ?? 1;
                var avatarPid = equippedAvatar?.Pid ?? "0";
                var avatarSysId = ExtractAvatarId(equipAvatar) ?? "0";
                var avatarPidNum = int.TryParse(avatarPid, NumberStyles.Integer, CultureInfo.InvariantCulture, out var ap) ? ap : 0;
                var avatarModelIdNum = int.TryParse(avatarSysId, NumberStyles.Integer, CultureInfo.InvariantCulture, out var am) ? am : 0;

                var resultText = string.Join(
                    "\n",
                    "player = {",
                    $"  id = {c.Id},",
                    $"  name = {LuaEscape(c.Name)},",
                    $"  level = {c.Level},",
                    $"  occupation = {c.Occupation},",
                    $"  gp = {p.Gp},",
                    $"  mb = {p.Mb},",
                    $"  tb = {p.Tb},",
                    "  tk = 0,",
                    "  tutorial = 0,",
                    "  exp = 0,",
                    "  expNextLevel = 100,",
                    "  newMail = false,",
                    "  isOpenPet = \"N\",",
                    "  isInGuild = \"N\",",
                    "  isAvoidDisturb = \"N\",",
                    $"  isCheckin = {(isCheckinToday ? "true" : "false")},",
                    "  isNoSpeak = false,",
                    "  hookNum = 0,",
                    "  halfQuitNum = 0,",
                    "  rankType = 1,",
                    "  rankLevel = 1,",
                    "  configList = false,",
                    "  inviteList = {},",
                    "  inviteTeamMemberList = {},",
                    "  buffs = {},",
                    "  cureQuantity = 0,",
                    "  cureQuantity_p = 0,",
                    "  cureQuantity_v = 0,",
                    "  recoveryCapacity = 0,",
                    "  recoveryCapacity_p = 0,",
                    "  recoveryCapacity_v = 0,",
                    "  armor = 0,",
                    "  armor_p = 0,",
                    "  armor_v = 0,",
                    "  arp = 0,",
                    "  arp_p = 0,",
                    "  arp_v = 0,",
                    "  stamina = 0,",
                    "  stamina_p = 0,",
                    "  stamina_v = 0,",
                    $"  life = {c.MaxHealth},",
                    "  vipLevel = 0,",
                    "  isTrialedVip = false,",
                    "  isTrialingVip = false,",
                    "  isTrialedVipTip = false,",
                    $"  sysTimeNow = {nowSeconds},",
                    "  beginNoSpeakTime = 0,",
                    "  endNoSpeakTime = 0,",
                    "  silencedReason = \"\",",
                    "  leftpoints = nil,",
                    "  onlineEndTime = nil,",
                    "  timeOnline = 0,",
                    "  isGetPrize = false,",
                    $"  avatarId = {avatarModelIdNum},",
                    $"  avatarPid = {avatarPidNum},",
                    $"  avatarSysId = {LuaEscape(avatarSysId)},",
                    $"  position = {avatarPosition},",
                    $"  equipAvatarGrade = {avatarGrade},",
                    $"  avatarSubType = {avatarSubType},",
                    $"  avatarSkill = {avatarSkillLua},",
                    $"  equips = {equipsLua},",
                    $"  equipAvatar = {equipAvatarLua},",
                    "}",
                    "giveTime = 0");

                writer.WriteString(resultText);
                await SendAsync(writer);
                return;
            }

            case "user_retention":
                writer.WriteString("ok = 1");
                await SendAsync(writer);
                return;

            case "player_info":
            {
                var requested = GetIntArg(rpcArgs, "playerId", 0);
                var p = GetActivePlayerStateOrDefault(requested == 0 ? null : requested);
                var c = p.Character;
                var equippedAvatar = p.GetEquippedAvatarItem();
                var equipAvatar = equippedAvatar?.Avatar ?? c.EquipAvatar;
                var equipAvatarLua = LuaSerializer.Serialize(equipAvatar);
                var equipsLua = LuaSerializer.Serialize(p.GetEquippedItems());
                var avatarSkillLua = LuaSerializer.Serialize(new
                {
                    skillId = 0,
                    level = 0,
                    resource = string.Empty
                });
                var avatarSubType = equippedAvatar?.SubType is > 0
                    ? equippedAvatar.SubType
                    : equippedAvatar?.Subtype ?? 1;
                var avatarPosition = equippedAvatar?.Position ?? 1;
                var avatarGrade = equippedAvatar?.Grade ?? 1;
                var avatarPid = equippedAvatar?.Pid ?? "0";
                var avatarSysId = ExtractAvatarId(equipAvatar) ?? "0";
                var avatarPidNum = int.TryParse(avatarPid, NumberStyles.Integer, CultureInfo.InvariantCulture, out var ap) ? ap : 0;
                var avatarModelIdNum = int.TryParse(avatarSysId, NumberStyles.Integer, CultureInfo.InvariantCulture, out var am) ? am : 0;

                var resultText = string.Join(
                    "\n",
                    "player = {",
                    $"  id = {c.Id},",
                    $"  name = {LuaEscape(c.Name)},",
                    $"  level = {c.Level},",
                    $"  occupation = {c.Occupation},",
                    "  guildName = \"\",",
                    "  winNum = 0,",
                    "  killNum = 0,",
                    "  maxCombo = 0,",
                    "  totalNum = 1,",
                    "  expCurrentLevelOffset = 0,",
                    "  expNextLevelOffset = 100,",
                    "  cureQuantity = 0,",
                    "  cureQuantity_p = 0,",
                    "  cureQuantity_v = 0,",
                    "  recoveryCapacity = 0,",
                    "  recoveryCapacity_p = 0,",
                    "  recoveryCapacity_v = 0,",
                    "  armor = 0,",
                    "  armor_p = 0,",
                    "  armor_v = 0,",
                    "  arp = 0,",
                    "  arp_p = 0,",
                    "  arp_v = 0,",
                    "  stamina = 0,",
                    "  stamina_p = 0,",
                    "  stamina_v = 0,",
                    $"  life = {c.MaxHealth},",
                    // PersonalInfo / Avatar-room treat `player.avatarId` as model avatarId (e.g. 100001).
                    // Keep card pid separately for tooltip compatibility.
                    $"  avatarId = {avatarModelIdNum},",
                    $"  avatarPid = {avatarPidNum},",
                    $"  avatarSysId = {LuaEscape(avatarSysId)},",
                    $"  position = {avatarPosition},",
                    $"  equipAvatarGrade = {avatarGrade},",
                    $"  avatarSubType = {avatarSubType},",
                    $"  avatarSkill = {avatarSkillLua},",
                    $"  equips = {equipsLua},",
                    $"  equipAvatar = {equipAvatarLua},",
                    "}");

                Log.Debug(
                    "player_info: req={Req} roleId={RoleId} avatarPid={AvatarPid} avatarSysId={AvatarSysId} pos={Pos} subType={SubType} equipAvatarType={AvatarType}",
                    requested,
                    c.Id,
                    avatarPidNum,
                    avatarSysId,
                    avatarPosition,
                    avatarSubType,
                    equipAvatar?.GetType().Name ?? "null");

                writer.WriteString(resultText);
                await SendAsync(writer);
                return;
            }

            case "player_battle_force_get":
                writer.WriteString("pf = 0\nwf = 0");
                await SendAsync(writer);
                return;

            case "player_avatar_equip":
            {
                var avatarPid = rpcArgs.GetValueOrDefault("avatarId");
                var player = GetActivePlayerStateOrDefault();
                var ok = player.EquipAvatarCard(avatarPid);
                var equipped = player.GetEquippedAvatarItem();
                var equippedAvatarId = ExtractAvatarId(player.Character.EquipAvatar) ?? "0";
                Log.Debug(
                    "player_avatar_equip: reqPid={ReqPid} ok={Ok} equippedPid={EquippedPid} avatarId={AvatarId} slot={Slot}",
                    avatarPid,
                    ok,
                    equipped?.Pid ?? "0",
                    equippedAvatarId,
                    equipped?.Slot ?? 0);
                writer.WriteString(ok ? "ok = 1" : "ok = 0");
                await SendAsync(writer);
                return;
            }

            case "player_avatar_save":
            {
                var player = GetActivePlayerStateOrDefault();
                var avatarId = ExtractAvatarId(player.Character.EquipAvatar) ?? "0";
                var cardPid = rpcArgs.GetValueOrDefault("avatarId");
                var cardName = rpcArgs.GetValueOrDefault("name");
                var cardDesigner = rpcArgs.GetValueOrDefault("description");
                var poseId = GetIntArg(rpcArgs, "poseId", 1);

                string Suit(string key) => rpcArgs.TryGetValue(key, out var v) && !string.IsNullOrWhiteSpace(v) ? v : "{}";
                var savedAvatar = new
                {
                    avatarId,
                    skin = Suit("skin"),
                    eye = Suit("eye"),
                    mouth = Suit("mouth"),
                    nose = Suit("nose"),
                    ear = Suit("ear"),
                    beard = Suit("beard"),
                    hair = Suit("hair"),
                    helmet = Suit("helmet"),
                    underwear = Suit("underwear"),
                    outerwear = Suit("outerwear"),
                    trousers = Suit("trousers"),
                    glove = Suit("glove"),
                    shoes = Suit("shoes"),
                    decal = Suit("decal"),
                    movable = Suit("movable"),
                    immobile = Suit("immobile"),
                    immobileUp = Suit("immobileUp"),
                    immobileDown = Suit("immobileDown")
                };

                var ok = player.TrySaveAvatarCard(
                    avatarPid: cardPid,
                    avatar: savedAvatar,
                    display: cardName,
                    designer: cardDesigner,
                    description: cardDesigner,
                    position: poseId <= 0 ? 1 : poseId,
                    out var errorKey);

                writer.WriteString(ok
                    ? "ok = 1"
                    : "ok = 0\n" + $"error = {LuaEscape(errorKey ?? "msgbox_common_conditionkey_028")}");
                await SendAsync(writer);
                return;
            }

            case "player_equip":
            {
                var itemPid = rpcArgs.GetValueOrDefault("itemId");
                var equipType = GetIntArg(rpcArgs, "equip_type", 0);
                var player = GetActivePlayerStateOrDefault();
                var ok = equipType > 0 && player.EquipInventoryItem(itemPid, equipType);
                var equippedItem = player.FindInventoryItemByPid(itemPid);
                var gameIndependentResource = equipType == 1
                    ? player.GetGameIndependentTrinketResources().FirstOrDefault() ?? string.Empty
                    : string.Empty;
                Log.Information(
                    "player_equip: roleId={RoleId} equipType={EquipType} itemPid={ItemPid} ok={Ok} resource={Resource} gameIndependent={GameIndependent}",
                    _activeRoleId,
                    equipType,
                    itemPid ?? string.Empty,
                    ok,
                    equippedItem?.Resource ?? string.Empty,
                    gameIndependentResource);
                writer.WriteString(ok ? "ok = 1" : "ok = 0");
                await SendAsync(writer);
                return;
            }

            case "player_unequip":
            {
                var equipType = GetIntArg(rpcArgs, "equip_type", 0);
                var player = GetActivePlayerStateOrDefault();
                var ok = equipType > 0 && player.UnequipInventoryItem(equipType);
                writer.WriteString(ok ? "ok = 1" : "ok = 0");
                await SendAsync(writer);
                return;
            }

            case "slot_get":
            {
                var player = GetActivePlayerStateOrDefault();
                var slots = player.GetHotKeySlots();
                var slotsLua = LuaSerializer.Serialize(slots);
                Log.Debug(
                    "slot_get response len={Len} preview={Preview}",
                    slotsLua.Length,
                    slotsLua[..Math.Min(slotsLua.Length, 300)]);
                writer.WriteString("ok = 1\nslots = " + slotsLua);
                await SendAsync(writer);
                return;
            }

            case "slot_equip":
            {
                var slot = GetIntArg(rpcArgs, "slot", 0);
                var pid = rpcArgs.GetValueOrDefault("id");
                var player = GetActivePlayerStateOrDefault();
                var ok = player.TrySetHotKeySlot(slot, pid, out var errorKey);
                Log.Debug(
                    "slot_equip: slot={Slot} pid={Pid} ok={Ok} error={Error}",
                    slot,
                    pid,
                    ok,
                    errorKey ?? "");
                writer.WriteString(ok
                    ? "ok = 1"
                    : "ok = 0\n" + $"error = {LuaEscape(errorKey ?? "msgbox_common_num_1306")}");
                await SendAsync(writer);
                return;
            }

            case "slot_unequip":
            {
                var fromSlot = GetIntArg(rpcArgs, "fromSlot", 0);
                var player = GetActivePlayerStateOrDefault();
                var ok = player.TryClearHotKeySlot(fromSlot);
                writer.WriteString(ok ? "ok = 1" : "ok = 0");
                await SendAsync(writer);
                return;
            }

            case "slot_drag":
            {
                var fromSlot = GetIntArg(rpcArgs, "fromSlot", 0);
                var toSlot = GetIntArg(rpcArgs, "toSlot", 0);
                var player = GetActivePlayerStateOrDefault();
                var ok = player.TrySwapHotKeySlots(fromSlot, toSlot);
                writer.WriteString(ok ? "ok = 1" : "ok = 0");
                await SendAsync(writer);
                return;
            }

            case "box_info":
            {
                var requestedCategory = GetIntArg(rpcArgs, "category", 1);
                var rules = GetBoxRules();
                var mainCategory = ResolveMainBoxCategoryForInfo(rules, requestedCategory);
                var player = GetActivePlayerStateOrDefault();
                var boxNum = GetBoxResourceCount(player, mainCategory, key: false);
                var keyNum = GetBoxResourceCount(player, mainCategory, key: true);
                var pointRules = mainCategory.PointList.Count > 0
                    ? mainCategory.PointList
                    : new List<BoxPointRule>
                    {
                        new() { Category = mainCategory.Category * 10 + 1, Unit = 10 },
                        new() { Category = mainCategory.Category * 10 + 2, Unit = 30 },
                        new() { Category = mainCategory.Category * 10 + 3, Unit = 60 },
                        new() { Category = mainCategory.Category * 10 + 4, Unit = 100 },
                        new() { Category = mainCategory.Category * 10 + 5, Unit = 150 }
                    };
                var pointListPayload = pointRules
                    .Select(x => (object)new
                    {
                        category = x.Category,
                        unit = x.Unit
                    })
                    .ToArray();
                var maxPoint = Math.Max(1, pointRules.Max(x => x.Unit));
                var currentPoint = player.GetBoxPoint(mainCategory.Category);
                var boxName = string.IsNullOrWhiteSpace(mainCategory.BoxName)
                    ? $"id_datalist_{mainCategory.BoxResource}"
                    : mainCategory.BoxName;
                var keyName = string.IsNullOrWhiteSpace(mainCategory.KeyName)
                    ? $"id_datalist_{mainCategory.KeyResource}"
                    : mainCategory.KeyName;

                Log.Information(
                    "box_info: reqCategory={ReqCategory} resolvedCategory={Category} boxRes={BoxResource} keyRes={KeyResource} boxNum={BoxNum} keyNum={KeyNum} currentPoint={CurrentPoint} maxPoint={MaxPoint}",
                    requestedCategory,
                    mainCategory.Category,
                    mainCategory.BoxResource,
                    mainCategory.KeyResource,
                    boxNum,
                    keyNum,
                    currentPoint,
                    maxPoint);

                writer.WriteString(
                    "ok = 1\n" +
                    $"boxResource = {LuaEscape(mainCategory.BoxResource)}\n" +
                    $"keyResource = {LuaEscape(mainCategory.KeyResource)}\n" +
                    $"boxNum = {boxNum}\n" +
                    $"keyNum = {keyNum}\n" +
                    $"boxCategory = {mainCategory.Category}\n" +
                    $"boxName = {LuaEscape(boxName)}\n" +
                    $"keyName = {LuaEscape(keyName)}\n" +
                    $"price = {Math.Max(0, mainCategory.Price)}\n" +
                    $"currentPoint = {Math.Max(0, currentPoint)}\n" +
                    $"maxPoint = {maxPoint}\n" +
                    "pointList = " + LuaSerializer.SerializeSequential(pointListPayload));
                await SendAsync(writer);
                return;
            }

            case "box_prize_list":
            {
                var requestedCategory = GetIntArg(rpcArgs, "category", 1);
                var page = GetIntArg(rpcArgs, "p", 1);
                var pageSize = GetIntArg(rpcArgs, "s", 12);
                pageSize = pageSize <= 0 ? 12 : pageSize;

                var rules = GetBoxRules();
                if (!TryGetBoxCategoryRule(rules, requestedCategory, out var categoryRule))
                {
                    writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_bufuhetiaojian"));
                    await SendAsync(writer);
                    return;
                }

                var source = (categoryRule.PrizeList.Count > 0 ? categoryRule.PrizeList : categoryRule.OpenPool)
                    .Select(NormalizePrize)
                    .ToList();
                var totalPages = Math.Max(1, (int)Math.Ceiling(source.Count / (double)pageSize));
                var currentPage = Math.Clamp(page <= 0 ? 1 : page, 1, totalPages);
                var pageItems = source
                    .Skip((currentPage - 1) * pageSize)
                    .Take(pageSize)
                    .Select(BuildBoxPrizePayload)
                    .Cast<object>()
                    .ToArray();

                Log.Information(
                    "box_prize_list: category={Category} page={Page}/{Pages} size={Size} total={Total} returned={Returned}",
                    requestedCategory,
                    currentPage,
                    totalPages,
                    pageSize,
                    source.Count,
                    pageItems.Length);

                writer.WriteString(
                    "ok = 1\n" +
                    $"category = {requestedCategory}\n" +
                    $"page = {currentPage}\n" +
                    $"pages = {totalPages}\n" +
                    $"s = {pageSize}\n" +
                    "list = " + LuaSerializer.SerializeSequential(pageItems));
                await SendAsync(writer);
                return;
            }

            case "box_open":
            {
                var requestedCategory = GetIntArg(rpcArgs, "category", 1);
                var openType = GetIntArg(rpcArgs, "openType", 0);
                var rules = GetBoxRules();
                var player = GetActivePlayerStateOrDefault();
                var rewards = new List<BoxPrizeRule>();

                string ResolveBoxOpenMaterialErrorKey(int boxCount, int keyCount, int needCount)
                {
                    if (keyCount < needCount)
                    {
                        return "msgbox_common_conditionkey_173";
                    }

                    if (boxCount < needCount)
                    {
                        return "msgbox_common_conditionkey_174";
                    }

                    return "id_abilities_bufuhetiaojian";
                }

                void Fail(string errorKey, string reason)
                {
                    Log.Warning(
                        "box_open failed: reqCategory={ReqCategory} openType={OpenType} reason={Reason} error={Error}",
                        requestedCategory,
                        openType,
                        reason,
                        errorKey);
                    writer.WriteString("ok = 0\nerror = " + LuaEscape(errorKey));
                }

                if (openType is not 0 and not 1 and not 2)
                {
                    Fail("id_abilities_bufuhetiaojian", "unsupported openType");
                    await SendAsync(writer);
                    return;
                }

                if (openType == 2)
                {
                    if (!TryResolvePointGiftRule(rules, requestedCategory, out var mainCategory, out var pointRule))
                    {
                        Fail("id_abilities_bufuhetiaojian", "gift category not mapped by pointList");
                        await SendAsync(writer);
                        return;
                    }

                    if (!TryGetBoxCategoryRule(rules, requestedCategory, out var giftCategoryRule))
                    {
                        Fail("id_abilities_bufuhetiaojian", "gift category rule missing");
                        await SendAsync(writer);
                        return;
                    }

                    if (!player.TryConsumeBoxPoint(mainCategory.Category, pointRule.Unit, out var remainPoint))
                    {
                        Fail("id_abilities_bufuhetiaojian", "insufficient points");
                        await SendAsync(writer);
                        return;
                    }

                    player.AddBoxPointClaim(mainCategory.Category, pointRule.Unit);

                    var pool = giftCategoryRule.OpenPool.Count > 0
                        ? giftCategoryRule.OpenPool
                        : giftCategoryRule.PrizeList;
                    if (pool.Count == 0)
                    {
                        Fail("id_abilities_bufuhetiaojian", "gift pool empty");
                        await SendAsync(writer);
                        return;
                    }

                    var picked = RollWeightedPrize(pool);
                    if (!TryGrantBoxPrize(player, picked))
                    {
                        Fail("msgbox_common_conditionkey_022", "grant gift reward failed");
                        await SendAsync(writer);
                        return;
                    }

                    rewards.Add(picked);
                    Log.Information(
                        "box_open gift success: giftCategory={GiftCategory} mainCategory={MainCategory} costPoint={CostPoint} remainPoint={RemainPoint} rewardSid={RewardSid} rewardRes={RewardRes}",
                        requestedCategory,
                        mainCategory.Category,
                        pointRule.Unit,
                        remainPoint,
                        picked.Sid,
                        picked.Resource);
                }
                else
                {
                    var mainCategory = ResolveMainBoxCategoryForInfo(rules, requestedCategory);
                    var drawCount = openType == 1 ? 10 : 1;
                    var boxCountBefore = GetBoxResourceCount(player, mainCategory, key: false);
                    var keyCountBefore = GetBoxResourceCount(player, mainCategory, key: true);
                    if (boxCountBefore < drawCount || keyCountBefore < drawCount)
                    {
                        Fail(
                            ResolveBoxOpenMaterialErrorKey(boxCountBefore, keyCountBefore, drawCount),
                            $"insufficient material box={boxCountBefore} key={keyCountBefore} need={drawCount}");
                        await SendAsync(writer);
                        return;
                    }

                    if (!TryConsumeBoxResource(player, mainCategory, key: false, drawCount) ||
                        !TryConsumeBoxResource(player, mainCategory, key: true, drawCount))
                    {
                        Fail("id_abilities_bufuhetiaojian", "consume box/key failed");
                        await SendAsync(writer);
                        return;
                    }

                    var pool = mainCategory.OpenPool.Count > 0
                        ? mainCategory.OpenPool
                        : mainCategory.PrizeList;
                    if (pool.Count == 0)
                    {
                        Fail("id_abilities_bufuhetiaojian", "open pool empty");
                        await SendAsync(writer);
                        return;
                    }

                    for (var i = 0; i < drawCount; i++)
                    {
                        var picked = RollWeightedPrize(pool);
                        if (!TryGrantBoxPrize(player, picked))
                        {
                            Fail("msgbox_common_conditionkey_022", $"grant reward failed at draw={i + 1}");
                            await SendAsync(writer);
                            return;
                        }

                        rewards.Add(picked);
                    }

                    var pointAfter = player.AddBoxPoint(mainCategory.Category, drawCount);
                    var boxCountAfter = GetBoxResourceCount(player, mainCategory, key: false);
                    var keyCountAfter = GetBoxResourceCount(player, mainCategory, key: true);
                    Log.Information(
                        "box_open success: category={Category} openType={OpenType} drawCount={DrawCount} boxBefore={BoxBefore} keyBefore={KeyBefore} boxAfter={BoxAfter} keyAfter={KeyAfter} pointAfter={PointAfter}",
                        mainCategory.Category,
                        openType,
                        drawCount,
                        boxCountBefore,
                        keyCountBefore,
                        boxCountAfter,
                        keyCountAfter,
                        pointAfter);
                }

                var payloadRewards = rewards
                    .Select(BuildBoxPrizePayload)
                    .Cast<object>()
                    .ToArray();
                Log.Information(
                    "box_open rewards: category={Category} openType={OpenType} rewards={Rewards}",
                    requestedCategory,
                    openType,
                    string.Join(",", rewards.Select(x => $"{x.Sid}:{x.Resource}:{x.Quantity}")));
                writer.WriteString(
                    "ok = 1\n" +
                    "list = " + LuaSerializer.SerializeSequential(payloadRewards));
                await SendAsync(writer);
                return;
            }

            case "storage_storage_list":
            case "storage_storage_list_no_empty":
                {
                    var storageType = GetIntArg(rpcArgs, "t", 3);
                    var page = GetIntArg(rpcArgs, "p", 1);
                    var pageSize = GetIntArg(rpcArgs, "s", 24);
                    var result = GetStorageItems(storageType, page, pageSize);
                    var slotStats = result.Items
                        .Select(x =>
                        {
                            var t = x.GetType();
                            var slotProp = t.GetProperty("slot");
                            var storageSlotProp = t.GetProperty("storageSlot");
                            var slotVal = slotProp?.GetValue(x);
                            var storageSlotVal = storageSlotProp?.GetValue(x);
                            return (
                                Slot: slotVal is int si ? si : Convert.ToInt32(slotVal ?? 0, CultureInfo.InvariantCulture),
                                StorageSlot: storageSlotVal is int ssi ? ssi : Convert.ToInt32(storageSlotVal ?? 0, CultureInfo.InvariantCulture)
                            );
                        })
                        .ToArray();

                    Log.Debug(
                        "storage_storage_list: t={T} page={Page}/{Pages} size={Size} items={Count} (storageCount={StorageCount})",
                        storageType,
                        result.CurrentPage,
                        result.TotalPages,
                        pageSize,
                        result.Items.Length,
                        GetActivePlayerStateOrDefault().Storages.TryGetValue(storageType, out var slots) ? slots.Count : 0);
                    if (result.Items.Length > 0)
                    {
                        var distinctSlots = slotStats.Select(x => x.Slot).Distinct().Count();
                        var distinctStorageSlots = slotStats.Select(x => x.StorageSlot).Distinct().Count();
                        var preview = string.Join(
                            ", ",
                            slotStats
                                .Take(8)
                                .Select(x => $"({x.Slot}/{x.StorageSlot})"));
                        Log.Debug(
                            "storage_storage_list slots: distinctSlot={DistinctSlot} distinctStorageSlot={DistinctStorageSlot} preview={Preview}",
                            distinctSlots,
                            distinctStorageSlots,
                            preview);
                    }

                    var itemsLua = LuaSerializer.SerializeSequential(result.Items);
                    var payload =
                        "ok = 1\n" +
                        $"t = {storageType}\n" +
                        $"s = {pageSize}\n" +
                        $"page = {result.CurrentPage}\n" +
                        $"pages = {result.TotalPages}\n" +
                        "items = " + itemsLua;

                    Log.Debug(
                        "storage_storage_list response len={Len} preview={Preview}",
                        payload.Length,
                        payload[..Math.Min(payload.Length, 300)]);

                    writer.WriteString(payload);
                    await SendAsync(writer);
                    return;
                }


            case "storage_item_filter":
            {
                var page = GetIntArg(rpcArgs, "p", 1);
                var pageSize = GetIntArg(rpcArgs, "s", 36);
                var storageType = GetIntArg(rpcArgs, "t", 3);
                var subtypeFilter = ParseIntSetArg(rpcArgs.GetValueOrDefault("subType"));
                var gradeFilter = ParseIntSetArg(rpcArgs.GetValueOrDefault("grade"));
                var result = GetStorageItems(storageType, page, pageSize, subtypeFilter, gradeFilter, pageBySlot: false);
                writer.WriteString(
                    "ok = 1\n" +
                    $"t = {storageType}\n" +
                    $"s = {pageSize}\n" +
                    $"page = {result.CurrentPage}\n" +
                    $"pages = {result.TotalPages}\n" +
                    "items = " + LuaSerializer.SerializeSequential(result.Items));
                await SendAsync(writer);
                return;
            }

            case "shop_item_list":
            {
                _ = rpcArgs.TryGetValue("t", out var tRaw);
                _ = int.TryParse(tRaw, NumberStyles.Integer, CultureInfo.InvariantCulture, out var t);

                var sellState = GetIntArg(rpcArgs, "sellState", 0);
                var st = (rpcArgs.GetValueOrDefault("st") ?? string.Empty).Trim();
                var currency = (rpcArgs.GetValueOrDefault("currency") ?? string.Empty).Trim();

                int? occupation = null;
                if (rpcArgs.TryGetValue("occupation", out var occRaw)
                    && int.TryParse(occRaw, NumberStyles.Integer, CultureInfo.InvariantCulture, out var occ))
                {
                    occupation = occ;
                }

                var player = GetActivePlayerStateOrDefault();
                int GetPurchasedCount(int sid, int priceId) => player.GetShopPurchasedCount(sid, priceId);
                var page = GetIntArg(rpcArgs, "p", 1);
                var pageSize = GetIntArg(rpcArgs, "pageSize", 12);

                // 从商城数据库获取商品列表
                var query = new ShopItemProvider.ShopListQuery(
                    Type: t > 0 ? t : null,
                    St: t > 0 ? st : null,
                    SellState: t > 0 ? null : (sellState > 0 ? sellState : null),
                    Occupation: occupation,
                    Currency: currency,
                    Page: page,
                    PageSize: pageSize);

                var (items, totalPages, currentPage) = ShopItemProvider.GetShopItemListWithPaging(query, GetPurchasedCount);

                var respT = t > 0 ? t : 0;
                if (respT == 0 && pageSize == 1 && items.Count > 0 && items[0].TryGetValue("type", out var typeObj))
                {
                    _ = int.TryParse(Convert.ToString(typeObj, CultureInfo.InvariantCulture), out respT);
                }

                writer.WriteString(
                    "ok = 1\n" +
                    $"t = {respT}\n" +
                    $"st = {LuaEscape(st)}\n" +
                    "modulus = 0\n" +
                    $"page = {currentPage}\n" +
                    $"pages = {totalPages}\n" +
                    $"pageSize = {pageSize}\n" +
                    $"shopRev = {ShopItemDatabase.GetConfigRevision()}\n" +
                    (occupation is { } o ? $"occupation = {o}\n" : string.Empty) +
                    "items = " + LuaSerializer.Serialize(items));
                await SendAsync(writer);
                return;
            }

            case "get_freshman_item_list":
            {
                var page = GetIntArg(rpcArgs, "p", 1);
                // 获取新手推荐商品
                var pageSize = GetIntArg(rpcArgs, "pageSize", 8);

                var player = GetActivePlayerStateOrDefault();
                int GetPurchasedCount(int sid, int priceId) => player.GetShopPurchasedCount(sid, priceId);

                var (items, totalPages, currentPage) = ShopItemProvider.GetFreshmanItemListWithPaging(page, pageSize, GetPurchasedCount);

                writer.WriteString(
                    "ok = 1\n" +
                    "t = 2\n" +
                    "st = \"\"\n" +
                    "modulus = 0\n" +
                    $"page = {currentPage}\n" +
                    $"pages = {totalPages}\n" +
                    $"pageSize = {pageSize}\n" +
                    $"shopRev = {ShopItemDatabase.GetConfigRevision()}\n" +
                    "items = " + LuaSerializer.Serialize(items));
                await SendAsync(writer);
                return;
            }

            case "shop_avatar_list":
            {
                var page = GetIntArg(rpcArgs, "p", 1);
                var pageSize = GetIntArg(rpcArgs, "pageSize", 12);
                var st = (rpcArgs.GetValueOrDefault("st") ?? string.Empty).Trim();
                var currency = (rpcArgs.GetValueOrDefault("currency") ?? string.Empty).Trim();

                int? occupation = null;
                if (rpcArgs.TryGetValue("occupation", out var occRaw)
                    && int.TryParse(occRaw, NumberStyles.Integer, CultureInfo.InvariantCulture, out var occ))
                {
                    occupation = occ;
                }

                var player = GetActivePlayerStateOrDefault();
                int GetPurchasedCount(int sid, int priceId) => player.GetShopPurchasedCount(sid, priceId);

                // 获取头像卡片列表
                var query = new ShopItemProvider.ShopListQuery(
                    Type: (int)ShopItemDatabase.ItemType.AvatarCard,
                    St: st,
                    SellState: null,
                    Occupation: occupation,
                    Currency: currency,
                    Page: page,
                    PageSize: pageSize);

                var (items, totalPages, currentPage) = ShopItemProvider.GetShopItemListWithPaging(query, GetPurchasedCount);

                writer.WriteString(
                    "ok = 1\n" +
                    $"t = {(int)ShopItemDatabase.ItemType.AvatarCard}\n" +
                    $"st = {LuaEscape(st)}\n" +
                    "modulus = 0\n" +
                    $"page = {currentPage}\n" +
                    $"pages = {totalPages}\n" +
                    $"pageSize = {pageSize}\n" +
                    $"shopRev = {ShopItemDatabase.GetConfigRevision()}\n" +
                    (occupation is { } o ? $"occupation = {o}\n" : string.Empty) +
                    "items = " + LuaSerializer.Serialize(items));
                await SendAsync(writer);
                return;
            }

            case "freshman_item_buy":
            case "shop_buy":
            {
                // Client lua (shop_balance/shop_exchange/quick_buy):
                // buy="type,subtype,sid,priceId;" (quantity optional; multiple entries separated by ';')
                var buy = rpcArgs.GetValueOrDefault("buy") ?? string.Empty;
                var buyer = GetActivePlayerStateOrDefault();
                var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
                var processedAny = false;

                Log.Debug("shop_buy request: buy={Buy}", buy);

                async Task Fail(string errorKey, string? reason = null)
                {
                    if (string.IsNullOrWhiteSpace(reason))
                    {
                        Log.Warning("shop_buy failed: error={Error} buy={Buy}", errorKey, buy);
                    }
                    else
                    {
                        Log.Warning("shop_buy failed: error={Error} reason={Reason} buy={Buy}", errorKey, reason, buy);
                    }

                    writer.WriteString("ok = 0\n" + $"error = {LuaEscape(errorKey)}");
                    await SendAsync(writer);
                }

                var entries = buy.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                foreach (var entry in entries)
                {
                    var parts = entry.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                    if (parts.Length < 3)
                    {
                        Log.Debug("shop_buy: skip malformed entry={Entry}", entry);
                        continue;
                    }

                    static bool TryParse(string? s, out int v) =>
                        int.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out v);

                    static bool MatchRequestedSubtype(ShopItemDatabase.ShopItem item, int requestedSubtype)
                    {
                        if (requestedSubtype <= 0)
                        {
                            return true;
                        }

                        if (item.Subtype == requestedSubtype)
                        {
                            return true;
                        }

                        // 开箱相关购买入口会用 400(箱子)/401(钥匙) 作为客户端侧虚拟 subtype，
                        // 但商城配置中的实际 subtype 通常是 100，需要按 resource 映射兼容。
                        if ((int)item.Type == (int)ShopItemDatabase.ItemType.Item &&
                            requestedSubtype is 400 or 401 &&
                            TryResolveBoxResource(item.Resource, out var mappedSubtype, out _))
                        {
                            return mappedSubtype == requestedSubtype;
                        }

                        return false;
                    }

                    _ = TryParse(parts.ElementAtOrDefault(0), out var reqType);

                    // Prefer new format if possible: type,subtype,sid,priceId,(qty?)
                    var newSidOk = TryParse(parts.ElementAtOrDefault(2), out var newSid);
                    var oldSidOk = TryParse(parts.ElementAtOrDefault(1), out var oldSid);

                    var sid = 0;
                    var priceIdOrIndex = 0;
                    var qty = 1;
                    var reqSubtype = 0;

                    if (newSidOk && ShopItemDatabase.GetShopItem(newSid) is not null)
                    {
                        sid = newSid;
                        _ = TryParse(parts.ElementAtOrDefault(1), out reqSubtype);
                        _ = TryParse(parts.ElementAtOrDefault(3), out priceIdOrIndex);
                        if (TryParse(parts.ElementAtOrDefault(4), out var q) && q > 0) qty = q;
                    }
                    else if (oldSidOk && ShopItemDatabase.GetShopItem(oldSid) is not null)
                    {
                        // Legacy: type,sid,priceIndex,quantity
                        sid = oldSid;
                        _ = TryParse(parts.ElementAtOrDefault(2), out priceIdOrIndex);
                        if (TryParse(parts.ElementAtOrDefault(3), out var q) && q > 0) qty = q;
                    }

                    if (sid <= 0) continue;

                    Log.Debug(
                        "shop_buy parsed entry: entry={Entry} sid={Sid} reqType={ReqType} reqSubtype={ReqSubtype} priceIdOrIndex={PriceIdOrIndex} qty={Qty}",
                        entry,
                        sid,
                        reqType,
                        reqSubtype,
                        priceIdOrIndex,
                        qty);

                    var shopItem = ShopItemDatabase.GetShopItem(sid);
                    if (shopItem is null)
                    {
                        Log.Warning("shop_buy: unknown sid={Sid}. buy={Buy}", sid, buy);
                        await Fail("id_abilities_bufuhetiaojian", $"unknown sid={sid}");
                        return;
                    }
                    if (!ShopItemProvider.CanPurchaseItem(sid))
                    {
                        await Fail(
                            "id_abilities_bufuhetiaojian",
                            $"cannot purchase sid={sid} resource={shopItem.Resource} prices={(shopItem.Prices?.Length ?? 0)}");
                        return;
                    }

                    if (reqType > 0 && (int)shopItem.Type != reqType)
                    {
                        await Fail(
                            "id_abilities_bufuhetiaojian",
                            $"type mismatch sid={sid} itemType={(int)shopItem.Type} reqType={reqType}");
                        return;
                    }
                    if (!MatchRequestedSubtype(shopItem, reqSubtype))
                    {
                        Log.Warning(
                            "shop_buy subtype mismatch: sid={Sid} resource={Resource} itemSubtype={ItemSubtype} reqSubtype={ReqSubtype}",
                            sid,
                            shopItem.Resource,
                            shopItem.Subtype,
                            reqSubtype);
                        await Fail(
                            "id_abilities_bufuhetiaojian",
                            $"subtype mismatch sid={sid} resource={shopItem.Resource} itemSubtype={shopItem.Subtype} reqSubtype={reqSubtype}");
                        return;
                    }

                    ShopItemDatabase.ShopPrice? priceEntry = null;
                    if (priceIdOrIndex > 0)
                    {
                        var (found, p) = ShopItemProvider.TryGetPriceById(sid, priceIdOrIndex);
                        if (found) priceEntry = p;
                    }
                    if (priceEntry is null)
                    {
                        // Legacy index fallback (0-based)
                        var index = Math.Max(0, priceIdOrIndex);
                        if (index >= 0 && index < (shopItem.Prices?.Length ?? 0))
                        {
                            priceEntry = shopItem.Prices![index];
                        }
                    }
                    if (priceEntry is null)
                    {
                        await Fail(
                            "id_abilities_bufuhetiaojian",
                            $"price not found sid={sid} priceIdOrIndex={priceIdOrIndex}");
                        return;
                    }

                    // Time window
                    if (priceEntry.StartDateTime > 0 && nowMs < priceEntry.StartDateTime)
                    {
                        await Fail(
                            "id_abilities_guanzhuxiangoushijian",
                            $"not started sid={sid} priceId={priceEntry.PriceId} nowMs={nowMs} startMs={priceEntry.StartDateTime}");
                        return;
                    }
                    if (priceEntry.EndDateTime > 0 && nowMs >= priceEntry.EndDateTime)
                    {
                        await Fail(
                            "id_abilities_shijianyijieshu",
                            $"expired sid={sid} priceId={priceEntry.PriceId} nowMs={nowMs} endMs={priceEntry.EndDateTime}");
                        return;
                    }

                    // Purchase limit
                    if (priceEntry.AccomplishCount > 0)
                    {
                        var purchased = buyer.GetShopPurchasedCount(sid, priceEntry.PriceId);
                        var remaining = priceEntry.AccomplishCount - purchased;
                        if (remaining < qty)
                        {
                            await Fail(
                                "id_abilities_xianliangshangxian",
                                $"limit sid={sid} priceId={priceEntry.PriceId} purchased={purchased} remaining={remaining} qty={qty}");
                            return;
                        }
                    }

                    var unitPrice = priceEntry.RebatePrice > 0 ? priceEntry.RebatePrice : priceEntry.Price;
                    var totalPrice = unitPrice * Math.Max(1, qty);

                    bool hasBalance = priceEntry.Currency switch
                    {
                        ShopItemDatabase.CurrencyType.Gold => buyer.Gp >= totalPrice,
                        ShopItemDatabase.CurrencyType.Diamond => buyer.Mb >= totalPrice,
                        ShopItemDatabase.CurrencyType.Ticket => buyer.Tb >= totalPrice,
                        _ => false
                    };

                    if (!hasBalance)
                    {
                        var key = priceEntry.Currency switch
                        {
                            ShopItemDatabase.CurrencyType.Gold => "msgbox_common_conditionkey_128",
                            ShopItemDatabase.CurrencyType.Diamond => "msgbox_common_conditionkey_129",
                            ShopItemDatabase.CurrencyType.Ticket => "msgbox_common_conditionkey_195",
                            _ => "id_abilities_bufuhetiaojian"
                        };
                        await Fail(
                            key,
                            $"insufficient balance sid={sid} priceId={priceEntry.PriceId} currency={(int)priceEntry.Currency} total={totalPrice} gp={buyer.Gp} mb={buyer.Mb} tb={buyer.Tb}");
                        return;
                    }

                    var purchaseSucceeded = TryPurchaseToInventory(shopItem, Math.Max(1, qty), priceEntry);
                    if (!purchaseSucceeded)
                    {
                        await Fail(
                            "id_abilities_bufuhetiaojian",
                            $"inventory purchase failed sid={sid} resource={shopItem.Resource} qty={qty} unitType={priceEntry.UnitType} unit={priceEntry.Unit}");
                        return;
                    }
                    processedAny = true;

                    switch (priceEntry.Currency)
                    {
                        case ShopItemDatabase.CurrencyType.Gold:
                            buyer.Gp -= totalPrice;
                            break;
                        case ShopItemDatabase.CurrencyType.Diamond:
                            buyer.Mb -= totalPrice;
                            break;
                        case ShopItemDatabase.CurrencyType.Ticket:
                            buyer.Tb -= totalPrice;
                            break;
                    }

                    buyer.AddShopPurchasedCount(sid, priceEntry.PriceId, Math.Max(1, qty));

                    Log.Debug(
                        "shop_buy: ok sid={Sid} type={Type} subtype={Subtype} qty={Qty} priceId={PriceId} currency={Currency} total={Total} storages2={S2} storages3={S3} storages5={S5} storages6={S6}",
                        sid,
                        (int)shopItem.Type,
                        shopItem.Subtype,
                        qty,
                        priceEntry.PriceId,
                        (int)priceEntry.Currency,
                        totalPrice,
                        buyer.Storages.TryGetValue(2, out var s2) ? s2.Count : 0,
                        buyer.Storages.TryGetValue(3, out var s3) ? s3.Count : 0,
                        buyer.Storages.TryGetValue(5, out var s5) ? s5.Count : 0,
                        buyer.Storages.TryGetValue(6, out var s6) ? s6.Count : 0);
                }

                if (!processedAny)
                {
                    Log.Warning("shop_buy: no valid entries processed. buy={Buy}", buy);
                    await Fail("id_abilities_bufuhetiaojian", "no valid entries processed");
                    return;
                }

                writer.WriteString($"ok = 1\ngp = {buyer.Gp}\nmb = {buyer.Mb}\ntb = {buyer.Tb}");
                await SendAsync(writer);
                return;
            }

            case "tip_sys_checkin_reward":
            case "tip_player_avatar":
            case "tip_sys_avatar":
            case "tip_sys_gift":
            case "tip_player_item":
            case "tip_sys_item":
            case "tip_sys_box_prize":
            {
                var player = GetActivePlayerStateOrDefault();

                InventoryItem? invItem = null;
                if (string.Equals(rpcName, "tip_sys_checkin_reward", StringComparison.Ordinal))
                {
                    var rewardId = GetIntArg(rpcArgs, "rewardId", 0);
                    _ = TryBuildCheckinRewardInventoryItem(rewardId, out invItem);
                }
                else if (rpcName.StartsWith("tip_player_", StringComparison.Ordinal))
                {
                    var pid = rpcArgs.GetValueOrDefault("pid");
                    invItem = player.FindInventoryItemByPid(pid);
                    if (invItem is null && string.Equals(rpcName, "tip_player_avatar", StringComparison.Ordinal))
                    {
                        var aid = rpcArgs.GetValueOrDefault("aid");
                        invItem = player.FindAvatarItemByAvatarId(aid) ?? player.GetEquippedAvatarItem();
                    }
                }

                var sid = invItem?.Sid ?? GetIntArg(rpcArgs, "sid", GetIntArg(rpcArgs, "prizeId", 0));
                var item = ShopItemDatabase.GetShopItem(sid);
                if (item == null && invItem is { Resource.Length: > 0 } && ShopItemDatabase.TryGetShopItemByResource(invItem.Resource, out var byRes))
                {
                    item = byRes;
                }

                if (item == null && invItem is null)
                {
                    writer.WriteString("ok = 0");
                }
                else
                {
                    var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
                    var prices = item is null
                        ? new List<Dictionary<string, object>>()
                        : (item.Prices ?? Array.Empty<ShopItemDatabase.ShopPrice>()).Select(price =>
                    {
                        var remaining = price.AccomplishCount <= 0
                            ? 0
                            : Math.Max(0, price.AccomplishCount - player.GetShopPurchasedCount(item.Sid, price.PriceId));

                        return new Dictionary<string, object>
                        {
                            { "priceId", price.PriceId },
                            { "currency", (int)price.Currency },
                            { "price", price.Price },
                            { "rebatePrice", price.RebatePrice },
                            { "sellState", price.SellState },
                            { "unitType", price.UnitType },
                            { "unit", price.Unit },
                            { "repeatDuration", price.RepeatDuration },
                            { "accomplishCount", price.AccomplishCount },
                            { "playerAccomplishCount", remaining },
                            { "isRenew", price.IsRenew },
                            { "isCardPrice", price.IsCardPrice },
                            { "isGive", price.IsGive },
                            { "vipLevel", price.VipLevel },
                            { "startDateTime", price.StartDateTime },
                            { "endDateTime", price.EndDateTime }
                        };
                    }).ToList();

                    var avatarPayload = invItem?.Avatar ?? item?.Avatar;
                    var avatarLine = avatarPayload is null ? string.Empty : "avatar = " + LuaSerializer.Serialize(avatarPayload) + "\n";
                    var effectiveType = invItem?.Type ?? (int)(item?.Type ?? ShopItemDatabase.ItemType.Item);
                    var effectiveSubtype = invItem?.Subtype ?? item?.Subtype ?? 0;
                    var effectiveGrade = invItem?.Grade ?? item?.Grade ?? 1;
                    var effectiveQuantity = invItem?.Quantity ?? item?.Quantity ?? 1;
                    var effectiveResource = ShopItemDatabase.GetClientResource(
                        item,
                        invItem?.Resource ?? item?.Resource ?? string.Empty,
                        effectiveType,
                        effectiveSubtype);
                    var effectiveDisplay = invItem?.Display ?? item?.Display ?? string.Empty;
                    var effectiveDescription = invItem?.Description ?? item?.Description ?? string.Empty;
                    var effectiveDesigner = invItem?.Designer ?? string.Empty;
                    var effectiveLevel = item?.Level ?? 0;
                    // tip_d.lua treats 0 as "all occupations". Negative values can break bit ops.
                    var effectiveOccupation = item?.Occupation ?? 0;
                    if (effectiveOccupation < 0)
                    {
                        effectiveOccupation = 0;
                    }
                    var effectiveAvatarLevel = item?.AvatarLevel ?? 0;
                    var effectiveCategory = item?.Category ?? string.Empty;
                    var effectiveUnitType = invItem?.UnitType ?? 1;
                    var effectiveUnit = invItem?.Unit ?? effectiveQuantity;
                    var effectiveRemain = invItem?.Remain ?? 0;
                    var effectiveIsRenew = invItem?.IsRenew ?? false;
                    var effectiveIsEquip = invItem?.IsEquip ?? "N";
                    var effectiveIsBind = invItem?.IsBind ?? "N";

                    if (string.IsNullOrWhiteSpace(effectiveDisplay) && !string.IsNullOrWhiteSpace(effectiveResource))
                    {
                        var candidate = ResourceCandidateCatalog.GetCandidates(_sysAvatarPayloadMonitor.CurrentValue)
                            .FirstOrDefault(x => string.Equals(x.Resource, effectiveResource, StringComparison.OrdinalIgnoreCase));
                        if (candidate is not null)
                        {
                            effectiveDisplay = string.IsNullOrWhiteSpace(candidate.DisplayKey)
                                ? effectiveResource
                                : candidate.DisplayKey;
                            if (string.IsNullOrWhiteSpace(effectiveDescription) && !string.IsNullOrWhiteSpace(candidate.DisplayKey))
                            {
                                effectiveDescription = candidate.DisplayKey + "_desc";
                            }
                        }
                        else
                        {
                            effectiveDisplay = $"id_datalist_{effectiveResource}";
                            effectiveDescription = $"id_datalist_{effectiveResource}_desc";
                        }
                    }

                    if (effectiveType is (int)ShopItemDatabase.ItemType.AvatarCard or (int)ShopItemDatabase.ItemType.SkinCard &&
                        string.IsNullOrWhiteSpace(effectiveDesigner))
                    {
                        effectiveDesigner = "msgbox_common_conditionkey_146";
                    }

                    var effectiveIsSys =
                        effectiveDisplay.StartsWith("id_", StringComparison.Ordinal) ||
                        effectiveDisplay.StartsWith("msgbox_", StringComparison.Ordinal) ||
                        effectiveDisplay.StartsWith("tips_", StringComparison.Ordinal) ||
                        effectiveDisplay.StartsWith("UI_", StringComparison.Ordinal);

                    // Client tooltip script (Other/tip/tip_d.lua) expects extra fields for weapons/equip (type=2).
                    // If these are missing (nil), it may index nil and crash the client when hovering items.
                    // We provide safe defaults, and allow per-item overrides via ShopItemDatabase.ShopItem.Tip loaded from shop_config.json.
                    static bool TryGetTipNumber(Dictionary<string, object?> map, string key, out double value)
                    {
                        value = 0;
                        if (!map.TryGetValue(key, out var obj) || obj is null) return false;
                        switch (obj)
                        {
                            case int i: value = i; return true;
                            case long l: value = l; return true;
                            case float f: value = f; return true;
                            case double d: value = d; return true;
                            case decimal m: value = (double)m; return true;
                            case string s when double.TryParse(s, NumberStyles.Float, CultureInfo.InvariantCulture, out var dv):
                                value = dv;
                                return true;
                            default:
                                return false;
                        }
                    }

                    Dictionary<string, object?>? tipOverrides = null;
                    if (item?.Tip is Dictionary<string, object?> tipDict)
                    {
                        tipOverrides = tipDict;
                    }
                    else if (item?.Tip is Dictionary<string, object> tipDictObj)
                    {
                        tipOverrides = tipDictObj.ToDictionary(k => k.Key, v => (object?)v.Value, StringComparer.OrdinalIgnoreCase);
                    }

                    // Merge defaults + overrides into extra payload assignments.
                    var extraTipPayload = string.Empty;
                    var battleForce = 0;
                    var ventureForce = 0;
                    var ratio = 0d;
                    var refitRatio = 0d;

                    if (effectiveType == (int)ShopItemDatabase.ItemType.Equipment)
                    {
                        var tipMap = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
                        {
                            // Common arrays used by multiple weapon types. (Lua expects 1-based arrays)
                            ["output"] = new List<object?> { 0 },
                            ["criticalRate"] = new List<object?> { 0 },

                            // Tip formulas normalize fireSpeed/shootSpread against [2..] / [5..] ranges; pick safe baselines.
                            ["fireSpeed"] = new List<object?> { 2 },
                            ["shootSpread"] = new List<object?> { 5 },
                            ["ammoOneClip"] = new List<object?> { 0 },

                            // Used by grenade/bazooka/bow/etc.
                            ["distance"] = new List<object?> { 0 },
                            ["explodeTime"] = new List<object?> { 0 },
                            ["coolDown"] = new List<object?> { 0 }
                        };

                        // Guild badge (subType=101) expects a guildName string.
                        if (effectiveSubtype == 101)
                        {
                            tipMap["guildName"] = "Guild";
                        }

                        // Ring (103) expects plusMap; back (102) doesn't need it but allowing it is harmless.
                        if (effectiveSubtype is 102 or 103)
                        {
                            tipMap["plusMap"] = new List<object?>();
                        }

                        if (tipOverrides is not null)
                        {
                            foreach (var (k, v) in tipOverrides)
                            {
                                tipMap[k] = v;
                            }

                            if (TryGetTipNumber(tipOverrides, "battleForce", out var bf)) battleForce = (int)Math.Floor(bf);
                            if (TryGetTipNumber(tipOverrides, "ventureForce", out var vf)) ventureForce = (int)Math.Floor(vf);
                            if (TryGetTipNumber(tipOverrides, "ratio", out var r)) ratio = r;
                            if (TryGetTipNumber(tipOverrides, "refitRatio", out var rr)) refitRatio = rr;
                        }

                        foreach (var (k, v) in tipMap)
                        {
                            extraTipPayload += $"{k} = {LuaSerializer.Serialize(v ?? string.Empty)}\n";
                        }
                    }

                    writer.WriteString(
                        "ok = 1\n" +
                        $"sid = {sid}\n" +
                        $"type = {effectiveType}\n" +
                        // Client tip UI uses `subType` (camel) for routing and display.
                        // Keep legacy `subtype` too (some scripts use it).
                        $"subType = {effectiveSubtype}\n" +
                        $"subtype = {effectiveSubtype}\n" +
                        $"resource = {LuaEscape(effectiveResource)}\n" +
                        $"display = {LuaEscape(effectiveDisplay)}\n" +
                        $"description = {LuaEscape(effectiveDescription)}\n" +
                        $"designer = {LuaEscape(effectiveDesigner)}\n" +
                        $"isSys = {(effectiveIsSys ? "true" : "false")}\n" +
                        "effect = \"\"\n" +
                        $"level = {effectiveLevel}\n" +
                        $"occupation = {effectiveOccupation}\n" +
                        $"avatarLevel = {effectiveAvatarLevel}\n" +
                        $"now = {nowMs}\n" +
                        avatarLine +
                        $"grade = {effectiveGrade}\n" +
                        // Fields required by `Other/tip/tip_d.lua` for weapon/item tips.
                        $"battleForce = {battleForce}\n" +
                        $"refitedNum = 0\n" +
                        $"canEquip = \"Y\"\n" +
                        $"isEquip = {LuaEscape(effectiveIsEquip)}\n" +
                        $"isBind = {LuaEscape(effectiveIsBind)}\n" +
                        "bindType = 0\n" +
                        $"unitType = {effectiveUnitType}\n" +
                        $"unit = {effectiveUnit}\n" +
                        $"remain = {effectiveRemain}\n" +
                        "isLock = 0\n" +
                        "lockExpireTime = 0\n" +
                        "lockTime = { lockTime = 0 }\n" +
                        $"isRenew = {(effectiveIsRenew ? "true" : "false")}\n" +
                        "canUnbind = false\n" +
                        $"ventureForce = {ventureForce}\n" +
                        $"ratio = {ratio.ToString(CultureInfo.InvariantCulture)}\n" +
                        $"refitRatio = {refitRatio.ToString(CultureInfo.InvariantCulture)}\n" +
                        extraTipPayload +
                        "price = " + LuaSerializer.Serialize(prices) + "\n" +
                        $"quantity = {effectiveQuantity}\n" +
                        $"category = {LuaEscape(effectiveCategory)}"
                    );
                }
                await SendAsync(writer);
                return;
            }

            case "shop_give":
            {
                var receiverId = GetIntArg(rpcArgs, "receiverId", 0);
                var give = rpcArgs.GetValueOrDefault("give") ?? string.Empty;
                if (receiverId <= 0)
                {
                    writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_bufuhetiaojian"));
                    await SendAsync(writer);
                    return;
                }

                var buyer = GetActivePlayerStateOrDefault();
                var receiver = GetActivePlayerStateOrDefault(receiverId);
                var nowMs = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

                var entries = give.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                foreach (var entry in entries)
                {
                    var parts = entry.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                    if (parts.Length < 4) continue;

                    static bool TryParse(string? s, out int v) =>
                        int.TryParse(s, NumberStyles.Integer, CultureInfo.InvariantCulture, out v);

                    _ = TryParse(parts.ElementAtOrDefault(0), out var reqType);
                    _ = TryParse(parts.ElementAtOrDefault(1), out var reqSubtype);
                    _ = TryParse(parts.ElementAtOrDefault(2), out var sid);
                    _ = TryParse(parts.ElementAtOrDefault(3), out var priceId);

                    if (sid <= 0 || priceId <= 0) continue;

                    var shopItem = ShopItemDatabase.GetShopItem(sid);
                    if (shopItem is null || !ShopItemProvider.CanPurchaseItem(sid))
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_bufuhetiaojian"));
                        await SendAsync(writer);
                        return;
                    }
                    if (reqType > 0 && (int)shopItem.Type != reqType)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_bufuhetiaojian"));
                        await SendAsync(writer);
                        return;
                    }
                    if (reqSubtype > 0 && shopItem.Subtype != reqSubtype)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_bufuhetiaojian"));
                        await SendAsync(writer);
                        return;
                    }

                    var (found, priceEntry) = ShopItemProvider.TryGetPriceById(sid, priceId);
                    if (!found)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_bufuhetiaojian"));
                        await SendAsync(writer);
                        return;
                    }

                    if (priceEntry.StartDateTime > 0 && nowMs < priceEntry.StartDateTime)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_guanzhuxiangoushijian"));
                        await SendAsync(writer);
                        return;
                    }
                    if (priceEntry.EndDateTime > 0 && nowMs >= priceEntry.EndDateTime)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_shijianyijieshu"));
                        await SendAsync(writer);
                        return;
                    }

                    if (!priceEntry.IsGive || priceEntry.Currency != ShopItemDatabase.CurrencyType.Diamond)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_bukezengsong"));
                        await SendAsync(writer);
                        return;
                    }

                    if (priceEntry.AccomplishCount > 0)
                    {
                        var purchased = buyer.GetShopPurchasedCount(sid, priceEntry.PriceId);
                        var remaining = priceEntry.AccomplishCount - purchased;
                        if (remaining < 1)
                        {
                            writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_xianliangshangxian"));
                            await SendAsync(writer);
                            return;
                        }
                    }

                    var unitPrice = priceEntry.RebatePrice > 0 ? priceEntry.RebatePrice : priceEntry.Price;
                    var totalPrice = unitPrice;

                    bool hasBalance = priceEntry.Currency switch
                    {
                        ShopItemDatabase.CurrencyType.Gold => buyer.Gp >= totalPrice,
                        ShopItemDatabase.CurrencyType.Diamond => buyer.Mb >= totalPrice,
                        ShopItemDatabase.CurrencyType.Ticket => buyer.Tb >= totalPrice,
                        _ => false
                    };

                    if (!hasBalance)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("msgbox_common_conditionkey_129"));
                        await SendAsync(writer);
                        return;
                    }

                    var giveSucceeded = receiver.TryPurchaseToInventory(shopItem, 1, priceEntry);
                    if (!giveSucceeded)
                    {
                        writer.WriteString("ok = 0\nerror = " + LuaEscape("id_abilities_bufuhetiaojian"));
                        await SendAsync(writer);
                        return;
                    }

                    switch (priceEntry.Currency)
                    {
                        case ShopItemDatabase.CurrencyType.Gold:
                            buyer.Gp -= totalPrice;
                            break;
                        case ShopItemDatabase.CurrencyType.Diamond:
                            buyer.Mb -= totalPrice;
                            break;
                        case ShopItemDatabase.CurrencyType.Ticket:
                            buyer.Tb -= totalPrice;
                            break;
                    }

                    buyer.AddShopPurchasedCount(sid, priceEntry.PriceId, 1);
                }

                writer.WriteString("ok = 1");
                await SendAsync(writer);
                return;
            }

            case "sys_avatar_pose_list":
            {
                var list = LuaSerializer.Serialize(new[]
                {
                    new { poseId = 1, position = "idlea" }
                });
                writer.WriteString("price = {}\nlist = " + list);
                await SendAsync(writer);
                return;
            }

            case "stage_quit":
            {
                var roomUid = GetIntArg(rpcArgs, "roomId", 0);
                _practiceRoomManager.TryGetByRoomUid(roomUid, out var room);
                var player = GetActivePlayerStateOrDefault();
                writer.WriteString(StageQuitPayload(player, room));
                await SendAsync(writer);
                Log.Information(
                    "RPC stage_quit response sent: roleId={RoleId} roomUid={RoomUid} roomFound={RoomFound}",
                    player.Character.Id,
                    roomUid,
                    room is not null);
                return;
            }

            case "sys_avatar_part_get":
                writer.WriteString(GenericOkPayload(rpcArgs));
                await SendAsync(writer);
                return;
        }

        if (KnownRpcNames.Contains(rpcName))
        {
            writer.WriteString(GenericOkPayload(rpcArgs));
            await SendAsync(writer);
            return;
        }

        Log.Warning("Unhandled RPC name={RpcName} (id={RpcId}) args={Args}", rpcName, rpcId, rpcArgs);
        writer.WriteString("ok = 1");
        await SendAsync(writer);
    }
}
