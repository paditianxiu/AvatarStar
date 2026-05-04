using System.Globalization;
using System.Text;
using System.Text.Json;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;
using AvatarStar.Server.Persistence;
using Serilog;

namespace AvatarStar.Server.Game;

internal partial class GameClient
{
    private sealed record SkillDefinition(
        int Id,
        int Occupation,
        string Resource,
        string DisplayBase,
        bool IsActive);

    private static readonly SkillDefinition[] SkillDefinitions =
    [
        new(0, 0, "cure", "id_datalist_Battlefield_Heal_01", true),
        new(3, 0, "shock", "id_datalist_Shockwave_01", true),
        new(6, 0, "vitals", "id_datalist_Achilles_Heel_01", false),
        new(9, 0, "rain", "id_datalist_Arrow_Shower_01", true),
        new(14, 0, "energy", "id_datalist_Healing_Beacon_01", true),
        new(76, 0, "feud", "tips_buff_langwangshichou", false),

        new(1, 1, "shield", "id_datalist_Shield_01", true),
        new(4, 1, "gallop", "id_datalist_Haste_01", true),
        new(7, 1, "tenacity", "id_datalist_Perseverance_01", false),
        new(10, 1, "heavy", "id_datalist_Blitzkrieg_01", false),
        new(12, 1, "transfer", "id_datalist_Damage_Converter_01", false),

        new(2, 2, "latent", "id_datalist_Stealth_01", true),
        new(5, 2, "piercing", "id_datalist_Fatal_Shot_01", false),
        new(8, 2, "poison", "id_datalist_Poison_Pierce_01", false),
        new(11, 2, "spurt", "id_datalist_Deadly_Sprint_01", true),
        new(13, 2, "snare", "id_datalist_Trap_01", true),

        new(38, 3, "conduction", "id_datalist_shengmingchuandao_01", true),
        new(39, 3, "suckblood", "id_datalist_shengmingchouqu_01", false),
        new(40, 3, "plague", "id_datalist_wenyichuanbo_01", false),
        new(41, 3, "gasbomb", "id_datalist_duqidan_01", false),
        new(42, 3, "overreaction", "id_datalist_guojifanying_01", true)
    ];

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
        "tip_sys_skill",
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
    private const int BoxPrizeClientPageSize = 12;
    private const int MainBoxPrizeMinimumPages = 10;
    private const int GiftBoxPrizeMinimumPages = 5;
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

    private static readonly int[] OnlineRewardEndTimes = [60, 120, 180];
    private static readonly IReadOnlyList<OnlineRewardLevelRule> DefaultOnlineRewardRules = BuildDefaultOnlineRewardRules();

    private sealed class OnlineRewardLevelRule
    {
        public int PrizeLevel { get; set; }
        public int EndTimeSeconds { get; set; }
        public List<OnlineRewardPrizeRule> Rewards { get; set; } = new();
    }

    private sealed class OnlineRewardPrizeRule
    {
        public string ItemId { get; set; } = string.Empty;
        public int Sid { get; set; }
        public int Type { get; set; } = (int)ShopItemDatabase.ItemType.Item;
        public int SubType { get; set; }
        public int Grade { get; set; } = 1;
        public string Resource { get; set; } = string.Empty;
        public int UnitType { get; set; }
        public int Unit { get; set; }
        public int Quantity { get; set; } = 1;
    }

    private readonly record struct OnlineRewardStatus(
        int CurrentPrizeLevel,
        int TimeOnline,
        bool IsGetPrize,
        bool CanClaim);

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
        var fileRules = LoadBoxRulesFromFileOrDefault();
        if (TryLoadBoxRulesFromDatabase(out var databaseRules))
        {
            return EnsureBoxRulesMinimumPrizePages(databaseRules, fileRules);
        }

        return fileRules;
    }

    private static BoxRulesConfig LoadBoxRulesFromFileOrDefault()
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

    private static BoxRulesConfig EnsureBoxRulesMinimumPrizePages(BoxRulesConfig primary, BoxRulesConfig fallback)
    {
        var normalizedPrimary = NormalizeBoxRules(primary);
        var normalizedFallback = NormalizeBoxRules(fallback);
        var fallbackByCategory = normalizedFallback.Categories
            .GroupBy(x => x.Category)
            .ToDictionary(x => x.Key, x => x.First());
        var resultByCategory = new Dictionary<int, BoxCategoryRule>();

        foreach (var category in normalizedPrimary.Categories)
        {
            fallbackByCategory.TryGetValue(category.Category, out var fallbackCategory);
            resultByCategory[category.Category] = MergeBoxCategoryRule(category, fallbackCategory);
        }

        foreach (var fallbackCategory in normalizedFallback.Categories)
        {
            if (!resultByCategory.ContainsKey(fallbackCategory.Category))
            {
                resultByCategory[fallbackCategory.Category] = MergeBoxCategoryRule(new BoxCategoryRule
                {
                    Category = fallbackCategory.Category
                }, fallbackCategory);
            }
        }

        return NormalizeBoxRules(new BoxRulesConfig
        {
            Categories = resultByCategory.Values
                .OrderBy(x => x.Category)
                .ToList()
        });
    }

    private static BoxCategoryRule MergeBoxCategoryRule(BoxCategoryRule primary, BoxCategoryRule? fallback)
    {
        var merged = new BoxCategoryRule
        {
            Category = primary.Category > 0 ? primary.Category : fallback?.Category ?? 0,
            MainCategory = primary.MainCategory > 0 ? primary.MainCategory : fallback?.MainCategory ?? 0,
            BoxResource = !string.IsNullOrWhiteSpace(primary.BoxResource) ? primary.BoxResource : fallback?.BoxResource ?? string.Empty,
            KeyResource = !string.IsNullOrWhiteSpace(primary.KeyResource) ? primary.KeyResource : fallback?.KeyResource ?? string.Empty,
            BoxName = !string.IsNullOrWhiteSpace(primary.BoxName) ? primary.BoxName : fallback?.BoxName ?? string.Empty,
            KeyName = !string.IsNullOrWhiteSpace(primary.KeyName) ? primary.KeyName : fallback?.KeyName ?? string.Empty,
            Price = primary.Price > 0 ? primary.Price : fallback?.Price ?? 0,
            PointList = primary.PointList.Count > 0
                ? primary.PointList.Select(x => new BoxPointRule { Category = x.Category, Unit = x.Unit }).ToList()
                : fallback?.PointList.Select(x => new BoxPointRule { Category = x.Category, Unit = x.Unit }).ToList() ?? new List<BoxPointRule>()
        };

        var minimumPrizeCount = GetMinimumBoxPrizeCount(merged);
        merged.PrizeList = MergeBoxPrizeList(primary.PrizeList, fallback?.PrizeList, minimumPrizeCount);
        merged.OpenPool = MergeBoxPrizeList(primary.OpenPool, fallback?.OpenPool.Count > 0 ? fallback.OpenPool : fallback?.PrizeList, minimumPrizeCount);

        return merged;
    }

    private static int GetMinimumBoxPrizeCount(BoxCategoryRule category)
    {
        if (IsBoxMainCategory(category) || category.Category is 1 or 2 or 3)
        {
            return BoxPrizeClientPageSize * MainBoxPrizeMinimumPages;
        }

        if (category.MainCategory > 0 ||
            (category.Category >= 11 && category.Category <= 15) ||
            (category.Category >= 21 && category.Category <= 25) ||
            (category.Category >= 31 && category.Category <= 35))
        {
            return BoxPrizeClientPageSize * GiftBoxPrizeMinimumPages;
        }

        return 0;
    }

    private static List<BoxPrizeRule> MergeBoxPrizeList(
        IEnumerable<BoxPrizeRule>? primary,
        IEnumerable<BoxPrizeRule>? fallback,
        int minimumCount)
    {
        var result = NormalizePrizeList(primary);
        AppendDistinctBoxPrizes(result, fallback);

        if (minimumCount <= 0 || result.Count >= minimumCount)
        {
            return result;
        }

        var seed = result.Count > 0
            ? result.Select(x => ClonePrize(x)).ToArray()
            : NormalizePrizeList(fallback).Select(x => ClonePrize(x)).ToArray();
        if (seed.Length == 0)
        {
            return result;
        }

        for (var i = 0; result.Count < minimumCount; i++)
        {
            result.Add(ClonePrize(seed[i % seed.Length]));
        }

        return result;
    }

    private static void AppendDistinctBoxPrizes(List<BoxPrizeRule> target, IEnumerable<BoxPrizeRule>? source)
    {
        if (source is null)
        {
            return;
        }

        var keys = target.Select(GetBoxPrizeMergeKey).ToHashSet(StringComparer.OrdinalIgnoreCase);
        foreach (var prize in NormalizePrizeList(source))
        {
            var key = GetBoxPrizeMergeKey(prize);
            if (keys.Add(key))
            {
                target.Add(prize);
            }
        }
    }

    private static string GetBoxPrizeMergeKey(BoxPrizeRule prize)
    {
        if (prize.PrizeId > 0)
        {
            return "prize:" + prize.PrizeId.ToString(CultureInfo.InvariantCulture);
        }

        return string.Join(
            ":",
            prize.Sid.ToString(CultureInfo.InvariantCulture),
            prize.Type.ToString(CultureInfo.InvariantCulture),
            prize.SubType.ToString(CultureInfo.InvariantCulture),
            prize.Grade.ToString(CultureInfo.InvariantCulture),
            prize.Resource,
            prize.UnitType.ToString(CultureInfo.InvariantCulture),
            prize.Unit.ToString(CultureInfo.InvariantCulture),
            prize.Quantity.ToString(CultureInfo.InvariantCulture));
    }

    private static bool TryLoadBoxRulesFromDatabase(out BoxRulesConfig rules)
    {
        rules = new BoxRulesConfig();
        try
        {
            using var db = new AvatarStarDbContext();
            var categories = db.BoxCategories.OrderBy(x => x.Category).ToArray();
            if (categories.Length == 0)
            {
                return false;
            }

            var pointRules = db.BoxPointRules.ToArray()
                .GroupBy(x => x.BoxCategory)
                .ToDictionary(x => x.Key, x => x.ToArray());
            var prizes = db.BoxPrizes.ToArray()
                .GroupBy(x => (x.Category, x.PoolType))
                .ToDictionary(x => x.Key, x => x.OrderBy(p => p.Id).ToArray());

            rules.Categories = categories.Select(category => new BoxCategoryRule
                {
                    Category = category.Category,
                    MainCategory = category.MainCategory,
                    BoxResource = category.BoxResource,
                    KeyResource = category.KeyResource,
                    BoxName = category.BoxName,
                    KeyName = category.KeyName,
                    Price = category.Price,
                    PointList = pointRules.TryGetValue(category.Category, out var points)
                        ? points.OrderBy(x => x.GiftCategory)
                            .Select(x => new BoxPointRule { Category = x.GiftCategory, Unit = x.Unit })
                            .ToList()
                        : new List<BoxPointRule>(),
                    PrizeList = prizes.TryGetValue((category.Category, "display"), out var display)
                        ? display.Select(ToBoxPrizeRule).ToList()
                        : new List<BoxPrizeRule>(),
                    OpenPool = prizes.TryGetValue((category.Category, "open"), out var open)
                        ? open.Select(ToBoxPrizeRule).ToList()
                        : new List<BoxPrizeRule>()
                })
                .ToList();

            rules = NormalizeBoxRules(rules);
            return rules.Categories.Count > 0;
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load box rules from database; falling back to JSON/defaults.");
            rules = new BoxRulesConfig();
            return false;
        }
    }

    private static BoxPrizeRule ToBoxPrizeRule(BoxPrizeEntity prize)
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
            Weight = prize.Weight
        };
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

    private static IReadOnlyList<SkillDefinition> GetOccupationSkills(int occupation)
    {
        return GetSkillDefinitions()
            .Where(skill => skill.Occupation == occupation)
            .OrderBy(skill => skill.Id)
            .ToArray();
    }

    private static bool TryGetSkillDefinition(int skillId, int occupation, out SkillDefinition definition)
    {
        var definitions = GetSkillDefinitions();
        var found = definitions.FirstOrDefault(skill => skill.Id == skillId && skill.Occupation == occupation)
            ?? definitions.FirstOrDefault(skill => skill.Id == skillId);
        definition = found ?? definitions[0];
        return found is not null;
    }

    private static IReadOnlyList<SkillDefinition> GetSkillDefinitions()
    {
        try
        {
            using var db = new AvatarStarDbContext();
            var skills = db.SkillDefinitions
                .OrderBy(x => x.Occupation)
                .ThenBy(x => x.Id)
                .Select(x => new SkillDefinition(
                    x.Id,
                    x.Occupation,
                    x.Resource,
                    x.DisplayBase,
                    x.IsActive != 0))
                .ToArray();
            return skills.Length > 0 ? skills : SkillDefinitions;
        }
        catch
        {
            return SkillDefinitions;
        }
    }

    private static string GetSkillDisplay(SkillDefinition definition, int level)
    {
        if (definition.DisplayBase.StartsWith("tips_", StringComparison.Ordinal))
        {
            return definition.DisplayBase;
        }

        var effectiveLevel = Math.Clamp(level <= 0 ? 1 : level, 1, 99);
        var marker = "_01";
        var idx = definition.DisplayBase.LastIndexOf(marker, StringComparison.Ordinal);
        return idx >= 0
            ? definition.DisplayBase[..idx] + $"_{effectiveLevel:00}"
            : definition.DisplayBase;
    }

    private static string GetSkillListPayload(PlayerStore.PlayerState player)
    {
        var occupation = player.Character.Occupation;
        var skills = GetOccupationSkills(occupation);
        var usedPoints = player.GetUsedSkillPoints();
        var skillPayload = skills.Select(skill =>
        {
            var level = player.GetSkillLevel(skill.Id);
            return new
            {
                id = skill.Id,
                display = GetSkillDisplay(skill, level),
                level,
                resource = skill.Resource,
                type = 1,
                subType = 1,
                isActive = skill.IsActive ? "Y" : "N"
            };
        }).Cast<object>().ToArray();

        var costMap = new object[]
        {
            new { currency = 2, cost = usedPoints > 0 ? 1 : 0 },
            new { currency = 1, cost = usedPoints > 0 ? 500 : 0 },
            new { currency = 4, cost = 0 }
        };

        return string.Join(
            "\r\n",
            $"leftpoints = {player.GetLeftSkillPoints()}",
            "resetMaxLevel=3",
            string.Empty,
            $"costMap={LuaSerializer.SerializeSequential(costMap)}",
            string.Empty,
            $"skills = {LuaSerializer.SerializeSequential(skillPayload)}",
            string.Empty,
            "bossList = {}");
    }

    private static string GetSkillTipPayload(PlayerStore.PlayerState player, int requestedSkillId, int requestedLevel, int requestedType)
    {
        var occupation = player.Character.Occupation;
        if (!TryGetSkillDefinition(requestedSkillId, occupation, out var definition))
        {
            var fallbackSkills = GetOccupationSkills(occupation);
            definition = fallbackSkills.Count > 0 ? fallbackSkills[0] : GetSkillDefinitions()[0];
            requestedSkillId = definition.Id;
        }

        var currentLevel = Math.Clamp(requestedLevel <= 0 ? Math.Max(1, player.GetSkillLevel(requestedSkillId)) : requestedLevel, 1, 5);
        var details = new List<object> { BuildSkillTipEntry(definition, currentLevel) };
        if (currentLevel < 5)
        {
            details.Add(BuildSkillTipEntry(definition, currentLevel + 1));
        }

        return string.Join(
            "\r\n",
            $"sid = {LuaEscape(GetSkillTipSid(definition.Id, currentLevel).ToString(CultureInfo.InvariantCulture))}",
            $"level = {currentLevel}",
            $"type = {(requestedType <= 0 ? 1 : requestedType)}",
            $"occupation = {occupation}",
            string.Empty,
            $"skills = {LuaSerializer.SerializeSequential(details)}");
    }

    private static object BuildSkillTipEntry(SkillDefinition definition, int level)
    {
        var display = GetSkillDisplay(definition, level);
        var name = GetSkillTipName(display);
        return new
        {
            id = GetSkillTipSid(definition.Id, level).ToString(CultureInfo.InvariantCulture),
            display,
            resource = definition.Resource,
            level,
            coolDown = 12.0,
            output = (object?)null,
            moveSpeed = (object?)null,
            distance = 0.0,
            criticalRate = (object?)null,
            criticalDamage = (object?)null,
            chantTime = (object?)null,
            duration = (object?)null,
            breakdown = (object?)null,
            description = string.IsNullOrWhiteSpace(name)
                ? display + "_Desc"
                : $"tips_abilities_{name}_Desc_{level:00}",
            effect = string.IsNullOrWhiteSpace(name)
                ? display + "_mode" + level.ToString(CultureInfo.InvariantCulture)
                : $"tips_abilities_{name}_mode{level}",
            upgradeCost = 1,
            isActive = definition.IsActive ? "Y" : "N"
        };
    }

    private static int GetSkillTipSid(int skillId, int level)
    {
        return Math.Max(0, skillId) * 6 + Math.Clamp(level, 1, 5);
    }

    private static string GetSkillTipName(string display)
    {
        const string prefix = "id_datalist_";
        if (!display.StartsWith(prefix, StringComparison.Ordinal))
        {
            return string.Empty;
        }

        var value = display[prefix.Length..];
        var last = value.LastIndexOf('_');
        if (last > 0 && int.TryParse(value[(last + 1)..], NumberStyles.Integer, CultureInfo.InvariantCulture, out _))
        {
            value = value[..last];
        }

        return value;
    }

    private static CheckinRulesConfig GetCheckinRules()
    {
        if (TryLoadCheckinRulesFromDatabase(out var rules))
        {
            return rules;
        }

        return DefaultCheckinRules;
    }

    private static bool TryLoadCheckinRulesFromDatabase(out CheckinRulesConfig rules)
    {
        rules = new CheckinRulesConfig();
        try
        {
            using var db = new AvatarStarDbContext();
            var entries = db.CheckinEntries
                .ToArray()
                .OrderBy(x => x.Type == 1 ? 0 : 1)
                .ThenBy(x => GetCheckinNameSortKey(x.Name))
                .ThenBy(x => x.Id)
                .ToArray();
            if (entries.Length == 0)
            {
                return false;
            }

            var config = db.CheckinConfig.Find(1);
            var rewardsByEntry = db.CheckinRewards.ToArray()
                .GroupBy(x => x.CheckinEntryId)
                .ToDictionary(x => x.Key, x => x.OrderBy(r => r.Id).ToArray());

            rules = new CheckinRulesConfig
            {
                SupplementCurrency = config?.SupplementCurrency ?? CheckinSupplementCurrency,
                SupplementPrice = config?.SupplementPrice ?? CheckinSupplementPrice,
                Checkins = entries.Select(entry => new CheckinEntryRule
                    {
                        Id = entry.Id,
                        Name = entry.Name,
                        Type = entry.Type,
                        PlayerLevel = entry.PlayerLevel,
                        Rewards = rewardsByEntry.TryGetValue(entry.Id, out var rewards)
                            ? rewards.Select(ToCheckinRewardRule).ToList()
                            : new List<CheckinRewardRule>()
                    })
                    .ToList()
            };
            return true;
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load checkin rules from database; falling back to built-in defaults.");
            rules = new CheckinRulesConfig();
            return false;
        }
    }

    private static int GetCheckinNameSortKey(string? name)
    {
        return int.TryParse(name, NumberStyles.Integer, CultureInfo.InvariantCulture, out var value)
            ? Math.Max(0, value)
            : int.MaxValue;
    }

    private static IEnumerable<CheckinEntryRule> SortCheckinEntries(IEnumerable<CheckinEntryRule> entries)
    {
        return entries
            .OrderBy(x => x.Type == 1 ? 0 : 1)
            .ThenBy(x => GetCheckinNameSortKey(x.Name))
            .ThenBy(x => x.Id);
    }

    private static CheckinRewardRule ToCheckinRewardRule(CheckinRewardEntity reward)
    {
        return NormalizeCheckinReward(new CheckinRewardRule
        {
            Id = reward.Id,
            Sid = reward.Sid,
            ItemId = reward.ItemId,
            Type = reward.Type,
            SubType = reward.SubType,
            Grade = reward.Grade,
            Resource = reward.Resource,
            UnitType = reward.UnitType,
            Unit = reward.Unit,
            Quantity = reward.Quantity
        });
    }

    private static IReadOnlyList<OnlineRewardLevelRule> GetOnlineRewardRules()
    {
        try
        {
            using var db = new AvatarStarDbContext();
            var levels = db.OnlineRewardRules.OrderBy(x => x.PrizeLevel).ToArray();
            if (levels.Length > 0)
            {
                var rewardsByLevel = db.OnlineRewardPrizes
                    .ToArray()
                    .GroupBy(x => x.PrizeLevel)
                    .ToDictionary(x => x.Key, x => x.OrderBy(p => p.Id).ToArray());
                return levels.Select(level => new OnlineRewardLevelRule
                    {
                        PrizeLevel = level.PrizeLevel,
                        EndTimeSeconds = level.EndTimeSeconds,
                        Rewards = rewardsByLevel.TryGetValue(level.PrizeLevel, out var rewards)
                            ? rewards.Select(ToOnlineRewardPrizeRule).ToList()
                            : new List<OnlineRewardPrizeRule>()
                    })
                    .ToArray();
            }
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load online reward rules from database; falling back to built-in defaults.");
        }

        return DefaultOnlineRewardRules;
    }

    private static OnlineRewardPrizeRule ToOnlineRewardPrizeRule(OnlineRewardPrizeEntity prize)
    {
        return NormalizeOnlineRewardPrize(new OnlineRewardPrizeRule
        {
            ItemId = prize.ItemId,
            Sid = prize.Sid,
            Type = prize.Type,
            SubType = prize.SubType,
            Grade = prize.Grade,
            Resource = prize.Resource,
            UnitType = prize.UnitType,
            Unit = prize.Unit,
            Quantity = prize.Quantity
        });
    }

    private static IReadOnlyList<OnlineRewardLevelRule> BuildDefaultOnlineRewardRules()
    {
        static OnlineRewardPrizeRule Reward(
            string itemId,
            int type,
            int subType,
            int quantity,
            int grade,
            int unitType,
            string resource,
            int sid = 0,
            int unit = 0)
        {
            return NormalizeOnlineRewardPrize(new OnlineRewardPrizeRule
            {
                ItemId = itemId,
                Sid = sid,
                Type = type,
                SubType = subType,
                Quantity = quantity,
                Grade = grade,
                UnitType = unitType,
                Unit = unit,
                Resource = resource
            });
        }

        return new List<OnlineRewardLevelRule>
        {
            new()
            {
                PrizeLevel = 1,
                EndTimeSeconds = OnlineRewardEndTimes[0],
                Rewards =
                [
                    Reward("548", 2, 102, 7200, 3, 4, "'wing15_indie','wing15','wing15'", 20054, 7200),
                    Reward("488", 3, 103, 7, 4, 3, "gift_sweet", 488),
                    Reward("275", 3, 100, 2, 2, 3, "loudspeaker", 20597)
                ]
            },
            new()
            {
                PrizeLevel = 2,
                EndTimeSeconds = OnlineRewardEndTimes[1],
                Rewards =
                [
                    Reward("1", 7, 0, 1000, 1, 0, string.Empty),
                    Reward("1379", 3, 304, 3, 5, 3, "piece_wing40", 20717),
                    Reward("93", 3, 102, 5, 3, 3, "leechdom_first_aid_kit", 20723)
                ]
            },
            new()
            {
                PrizeLevel = 3,
                EndTimeSeconds = OnlineRewardEndTimes[2],
                Rewards =
                [
                    Reward("637", 3, 110, 1, 3, 3, "ticket_complementarity", 637),
                    Reward("1", 7, 0, 2000, 1, 0, string.Empty),
                    Reward("92", 3, 102, 5, 2, 3, "leechdom_blood_serum", 20721)
                ]
            }
        };
    }

    private static OnlineRewardPrizeRule NormalizeOnlineRewardPrize(OnlineRewardPrizeRule reward)
    {
        var normalized = new OnlineRewardPrizeRule
        {
            ItemId = reward.ItemId?.Trim() ?? string.Empty,
            Sid = reward.Sid,
            Type = reward.Type,
            SubType = reward.SubType,
            Grade = reward.Grade,
            Resource = reward.Resource?.Trim() ?? string.Empty,
            UnitType = reward.UnitType,
            Unit = reward.Unit,
            Quantity = reward.Quantity
        };
        var keepCapturedSubtype = normalized.SubType > 0;
        var keepCapturedGrade = normalized.Grade > 0;

        ShopItemDatabase.ShopItem? item = null;
        if (normalized.Sid > 0)
        {
            item = ShopItemDatabase.GetShopItem(normalized.Sid);
        }

        if (item is null &&
            !string.IsNullOrWhiteSpace(normalized.Resource) &&
            !normalized.Resource.Contains(',', StringComparison.Ordinal) &&
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

            if (!keepCapturedSubtype)
            {
                normalized.SubType = item.Subtype;
            }

            if (!keepCapturedGrade)
            {
                normalized.Grade = item.Grade;
            }
        }

        if (normalized.Type <= 0)
        {
            normalized.Type = (int)ShopItemDatabase.ItemType.Item;
        }

        if (string.IsNullOrWhiteSpace(normalized.ItemId))
        {
            normalized.ItemId = normalized.Sid > 0
                ? normalized.Sid.ToString(CultureInfo.InvariantCulture)
                : "0";
        }

        normalized.SubType = Math.Max(0, normalized.SubType);
        normalized.Grade = Math.Max(1, normalized.Grade);
        normalized.Quantity = Math.Max(1, normalized.Quantity);
        normalized.UnitType = normalized.UnitType <= 0
            ? (normalized.Type == 7 ? 0 : 1)
            : normalized.UnitType;
        normalized.Unit = normalized.Unit <= 0 ? normalized.Quantity : normalized.Unit;
        return normalized;
    }

    private static OnlineRewardStatus GetOnlineRewardStatus(PlayerStore.PlayerState player, DateTime now, DateTime utcNow)
    {
        var rules = GetOnlineRewardRules();
        player.EnsureOnlineRewardDay(now, utcNow);

        var claimedLevel = Math.Clamp(player.OnlineRewardClaimedLevel, 0, rules.Count);
        var currentPrizeLevel = claimedLevel + 1;
        if (currentPrizeLevel > rules.Count)
        {
            return new OnlineRewardStatus(
                CurrentPrizeLevel: rules.Count + 1,
                TimeOnline: rules.Count > 0 ? rules[^1].EndTimeSeconds : 0,
                IsGetPrize: true,
                CanClaim: false);
        }

        var currentRule = rules[currentPrizeLevel - 1];
        var previousEndTime = currentPrizeLevel <= 1 ? 0 : rules[currentPrizeLevel - 2].EndTimeSeconds;
        var stageElapsed = player.GetOnlineRewardStageElapsedSeconds(now, utcNow);
        var requiredStageSeconds = Math.Max(0, currentRule.EndTimeSeconds - previousEndTime);
        var canClaim = stageElapsed >= requiredStageSeconds;
        var timeOnline = canClaim
            ? currentRule.EndTimeSeconds
            : Math.Min(currentRule.EndTimeSeconds, previousEndTime + stageElapsed);
        var isBoundaryAlreadyClaimed = claimedLevel > 0 && stageElapsed == 0;

        return new OnlineRewardStatus(
            CurrentPrizeLevel: currentPrizeLevel,
            TimeOnline: timeOnline,
            IsGetPrize: isBoundaryAlreadyClaimed,
            CanClaim: canClaim);
    }

    private static string BuildOnlineRewardPrizeListPayload(int currentPrizeLevel)
    {
        var prizeList = BuildOnlineRewardPrizeListLua(GetOnlineRewardRules());
        return $"prizeList={prizeList}\n\ncurrentPrizeLevel = {currentPrizeLevel}";
    }

    private static string BuildOnlineRewardPrizeListLua(IEnumerable<OnlineRewardLevelRule> levels)
    {
        var sb = new StringBuilder();
        sb.Append('{');
        var levelIndex = 0;
        foreach (var level in levels.OrderBy(x => x.PrizeLevel))
        {
            if (levelIndex++ > 0)
            {
                sb.Append(',');
            }

            sb.Append('{');
            sb.Append("prizeLevel=");
            sb.Append(level.PrizeLevel);

            var rewardIndex = 0;
            foreach (var reward in level.Rewards.Select(NormalizeOnlineRewardPrize).Take(3))
            {
                sb.Append(',');
                sb.Append(BuildOnlineRewardPrizeLua(reward));
                rewardIndex++;
            }

            sb.Append('}');
        }

        sb.Append('}');
        return sb.ToString();
    }

    private static string BuildOnlineRewardPrizeLua(OnlineRewardPrizeRule reward)
    {
        var normalized = NormalizeOnlineRewardPrize(reward);
        var sb = new StringBuilder();
        sb.Append('{');
        sb.Append("itemId=");
        sb.Append(LuaEscape(normalized.ItemId));
        sb.Append(",type=");
        sb.Append(normalized.Type);
        if (normalized.SubType > 0)
        {
            sb.Append(",subType=");
            sb.Append(normalized.SubType);
        }

        sb.Append(",quantity=");
        sb.Append(normalized.Quantity);
        sb.Append(",grade=");
        sb.Append(normalized.Grade);
        if (normalized.UnitType > 0)
        {
            sb.Append(",unitType=");
            sb.Append(normalized.UnitType);
        }

        if (normalized.Type != 7)
        {
            sb.Append(",resource=");
            sb.Append(LuaEscape(normalized.Resource));
        }

        sb.Append('}');
        return sb.ToString();
    }

    private static bool TryGrantOnlineRewardPrize(
        PlayerStore.PlayerState player,
        OnlineRewardPrizeRule reward,
        out string errorKey)
    {
        var normalized = NormalizeOnlineRewardPrize(reward);
        if (normalized.Type == 7)
        {
            var amount = Math.Max(1, normalized.Quantity);
            switch (normalized.ItemId)
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
                    errorKey = "id_abilities_bufuhetiaojian";
                    return false;
            }
        }

        var item = normalized.Sid > 0 ? ShopItemDatabase.GetShopItem(normalized.Sid) : null;
        if (item is null &&
            !string.IsNullOrWhiteSpace(normalized.Resource) &&
            !normalized.Resource.Contains(',', StringComparison.Ordinal) &&
            ShopItemDatabase.TryGetShopItemByResource(normalized.Resource, out var byResource))
        {
            item = byResource;
        }

        var grantResource = item?.Resource ?? normalized.Resource;
        var grantSid = normalized.Sid > 0 ? normalized.Sid : item?.Sid ?? 0;
        var grantSubtype = normalized.SubType;
        var grantGrade = normalized.Grade;
        var grantUnitType = normalized.UnitType <= 0 ? 1 : normalized.UnitType;
        var grantUnit = normalized.Unit <= 0 ? normalized.Quantity : normalized.Unit;

        var granted = player.TryGrantInventoryItem(
            type: normalized.Type,
            subtype: grantSubtype,
            grade: grantGrade,
            sid: grantSid,
            resource: grantResource,
            quantity: normalized.Quantity,
            unitType: grantUnitType,
            unit: grantUnit,
            avatar: item?.Avatar,
            position: normalized.Type is (int)ShopItemDatabase.ItemType.AvatarCard or (int)ShopItemDatabase.ItemType.SkinCard ? 1 : null,
            display: item?.Display,
            designer: normalized.Type is (int)ShopItemDatabase.ItemType.AvatarCard or (int)ShopItemDatabase.ItemType.SkinCard
                ? "msgbox_common_conditionkey_146"
                : null,
            description: item?.Description);

        errorKey = granted ? string.Empty : "msgbox_lobby_sign_001";
        return granted;
    }

    private async Task SendUpdatePlayerPushAsync(PlayerStore.PlayerState player)
    {
        using var push = new PacketWriter();
        push.WriteByte(32);
        push.WriteString(string.Join(
            "\n",
            "cmd = \"updatePlayer\"",
            $"playerId={LuaEscape(player.Character.Id.ToString(CultureInfo.InvariantCulture))}",
            $"playerName={LuaEscape(player.Character.Name)}",
            $"gp={player.Gp}",
            $"mb={player.Mb}",
            $"tb={player.Tb}",
            "tk=0",
            $"lv={player.Character.Level}",
            "exp=0",
            "expPercent=0",
            "expNextLevel=1500"));
        await SendAsync(push);
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

        var checkins = SortCheckinEntries(rules.Checkins).Select(rule =>
        {
            var canGetReward = "N";
            var isGetReward = "N";
            if (rule.Type == 2)
            {
                var targetDay = GetCheckinTargetDay(rule);
                var claimed = player.HasClaimedCheckinReward(now, rule.Id);
                isGetReward = claimed ? "Y" : "N";
                canGetReward = claimed || (targetDay > 0 && checkinCount >= targetDay) ? "Y" : "N";
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
                    unit = reward.Unit,
                    quantity = reward.Quantity,
                    sid = reward.Sid
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

        try
        {
        switch (rpcName)
        {
            case "player_list":
            {
                var characters = _playerStore.ListCharacters();
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
                var existingCount = _playerStore.ListCharacters().Count;
                var name = rpcArgs.TryGetValue("name", out var n) ? n : $"Player{existingCount + 1}";
                var jobIdStr = rpcArgs.TryGetValue("id", out var jid) ? jid : "1";
                _ = int.TryParse(jobIdStr, out var jobId);

                var occupation = Math.Clamp(jobId - 1, 0, 3);
                var cardDisplay = name;
                var cardDesigner = rpcArgs.TryGetValue("description", out var descriptionRaw) && !string.IsNullOrWhiteSpace(descriptionRaw)
                    ? descriptionRaw
                    : name;

                // Persist the appearance fields sent by select_character_d.lua SaveSuit().
                // These are strings (Lua table literals) and will be echoed back via player_list.equipAvatar.
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
                var created = _playerStore.CreateCharacter(
                    name,
                    occupation,
                    config,
                    equipAvatar,
                    avatarId,
                    starterCardDisplay: cardDisplay,
                    starterCardDesigner: cardDesigner);

                // Starter inventory: give the selected occupation's default weapons + one "appearance card".
                // storage_storage_list `t` parameter matches ShopItemDatabase.ItemType (2=equipment, 6=skin card).


                // "造型�?: the client expects `avatar` + `position` fields for type=6 items (see avatar_d.lua).

                _practiceRoomManager.UnregisterGameClient(_activeRoleId, this);
                _activeRoleId = created.Character.Id;
                _practiceRoomManager.RegisterGameClient(_activeRoleId, this);
                writer.WriteString("ok = 1\nwarning = nil");
                await SendAsync(writer);
                return;
            }

            case "player_delete":
            {
                if (rpcArgs.TryGetValue("cid", out var cidStr) && int.TryParse(cidStr, out var cid))
                {
                    _playerStore.DeleteCharacter(cid);
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

            case "player_ol_prize":
            {
                var player = GetActivePlayerStateOrDefault();
                var now = DateTime.Now;
                var status = GetOnlineRewardStatus(player, now, DateTime.UtcNow);
                writer.WriteString(BuildOnlineRewardPrizeListPayload(status.CurrentPrizeLevel));
                await SendAsync(writer);
                Log.Information(
                    "player_ol_prize: roleId={RoleId} level={Level} timeOnline={TimeOnline} canClaim={CanClaim}",
                    player.Character.Id,
                    status.CurrentPrizeLevel,
                    status.TimeOnline,
                    status.CanClaim);
                return;
            }

            case "player_ol_get_prize":
            {
                var player = GetActivePlayerStateOrDefault();
                var now = DateTime.Now;
                var utcNow = DateTime.UtcNow;
                var status = GetOnlineRewardStatus(player, now, utcNow);
                var rules = GetOnlineRewardRules();
                if (!status.CanClaim ||
                    status.CurrentPrizeLevel <= 0 ||
                    status.CurrentPrizeLevel > rules.Count)
                {
                    writer.WriteString("error = " + LuaEscape("msgbox_common_online_hortation_07"));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_ol_get_prize rejected: roleId={RoleId} level={Level} timeOnline={TimeOnline} canClaim={CanClaim}",
                        player.Character.Id,
                        status.CurrentPrizeLevel,
                        status.TimeOnline,
                        status.CanClaim);
                    return;
                }

                var rule = rules[status.CurrentPrizeLevel - 1];
                var snapshot = player.CaptureRewardGrantSnapshot();
                foreach (var reward in rule.Rewards)
                {
                    if (!TryGrantOnlineRewardPrize(player, reward, out var grantErrorKey))
                    {
                        player.RestoreRewardGrantSnapshot(snapshot);
                        writer.WriteString("error = " + LuaEscape(grantErrorKey));
                        await SendAsync(writer);
                        Log.Warning(
                            "player_ol_get_prize grant failed: roleId={RoleId} level={Level} itemId={ItemId} resource={Resource} error={Error}",
                            player.Character.Id,
                            rule.PrizeLevel,
                            reward.ItemId,
                            reward.Resource,
                            grantErrorKey);
                        return;
                    }
                }

                if (!player.TryClaimOnlineRewardLevel(now, utcNow, rule.PrizeLevel))
                {
                    player.RestoreRewardGrantSnapshot(snapshot);
                    writer.WriteString("error = " + LuaEscape("id_abilities_bufuhetiaojian"));
                    await SendAsync(writer);
                    Log.Warning(
                        "player_ol_get_prize claim state failed: roleId={RoleId} level={Level} claimed={Claimed}",
                        player.Character.Id,
                        rule.PrizeLevel,
                        player.OnlineRewardClaimedLevel);
                    return;
                }

                await SendUpdatePlayerPushAsync(player);
                writer.WriteString(" error=nil ");
                await SendAsync(writer);
                Log.Information(
                    "player_ol_get_prize success: roleId={RoleId} level={Level} rewards={Rewards} gp={Gp} mb={Mb} tb={Tb}",
                    player.Character.Id,
                    rule.PrizeLevel,
                    string.Join(",", rule.Rewards.Select(x => $"{x.ItemId}:{x.Resource}:{x.Quantity}")),
                    player.Gp,
                    player.Mb,
                    player.Tb);
                return;
            }

            case "player_detail":
            {
                var p = GetActivePlayerStateOrDefault();
                var c = p.Character;
                var now = DateTime.Now;
                var onlineRewardStatus = GetOnlineRewardStatus(p, now, DateTime.UtcNow);
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
                    $"  onlineEndTime = {LuaSerializer.SerializeSequential(OnlineRewardEndTimes.Cast<object>())},",
                    $"  timeOnline = {onlineRewardStatus.TimeOnline},",
                    $"  isGetPrize = {(onlineRewardStatus.IsGetPrize ? "true" : "false")},",
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
                writer.WriteString(" error=nil ");
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

            case "skill_list":
            {
                var playerId = GetIntArg(rpcArgs, "playerId", 0);
                var player = GetActivePlayerStateOrDefault(playerId > 0 ? playerId : null);
                writer.WriteString(GetSkillListPayload(player));
                await SendAsync(writer);
                return;
            }

            case "skill_adjust":
            {
                var player = GetActivePlayerStateOrDefault();
                var validSkillIds = GetOccupationSkills(player.Character.Occupation)
                    .Select(skill => skill.Id)
                    .ToHashSet();
                var ok = player.TryAdjustSkills(
                    rpcArgs.GetValueOrDefault("adjustSkills"),
                    validSkillIds,
                    out var errorKey);
                writer.WriteString(ok
                    ? " error=nil "
                    : "error = " + LuaEscape(errorKey ?? "id_abilities_bufuhetiaojian"));
                await SendAsync(writer);
                return;
            }

            case "skill_reset":
            {
                var player = GetActivePlayerStateOrDefault();
                player.ResetSkills();
                writer.WriteString(" error=nil ");
                await SendAsync(writer);
                return;
            }

            case "skill_equip":
            {
                var player = GetActivePlayerStateOrDefault();
                var skillId = GetIntArg(rpcArgs, "skillId", -1);
                var slot = GetIntArg(rpcArgs, "slot", 0);
                var errorKey = "id_abilities_bufuhetiaojian";
                var ok = false;
                if (TryGetSkillDefinition(skillId, player.Character.Occupation, out var skill))
                {
                    ok = player.TrySetSkillHotKeySlot(
                        slot,
                        skill.Id,
                        skill.Resource,
                        GetSkillDisplay(skill, player.GetSkillLevel(skill.Id)),
                        skill.IsActive,
                        out errorKey);
                }
                writer.WriteString(ok
                    ? " error=nil "
                    : "error = " + LuaEscape(errorKey ?? "id_abilities_bufuhetiaojian"));
                await SendAsync(writer);
                return;
            }

            case "skill_unequip":
            {
                var slot = GetIntArg(rpcArgs, "slot", GetIntArg(rpcArgs, "fromSlot", 0));
                var player = GetActivePlayerStateOrDefault();
                player.TryClearHotKeySlot(slot);
                writer.WriteString(" error=nil ");
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
                var hasPagedRequest =
                    rpcArgs.ContainsKey("p") ||
                    rpcArgs.ContainsKey("page") ||
                    rpcArgs.ContainsKey("s") ||
                    rpcArgs.ContainsKey("pageSize");
                var page = GetIntArg(rpcArgs, "p", GetIntArg(rpcArgs, "page", 1));
                var pageSize = GetIntArg(rpcArgs, "s", GetIntArg(rpcArgs, "pageSize", BoxPrizeClientPageSize));
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
                var currentPage = hasPagedRequest
                    ? Math.Clamp(page <= 0 ? 1 : page, 1, totalPages)
                    : 1;
                var responseSource = hasPagedRequest
                    ? source.Skip((currentPage - 1) * pageSize).Take(pageSize)
                    : source;
                var pageItems = responseSource
                    .Select(BuildBoxPrizePayload)
                    .Cast<object>()
                    .ToArray();

                Log.Information(
                    "box_prize_list: category={Category} page={Page}/{Pages} size={Size} total={Total} returned={Returned} paged={Paged}",
                    requestedCategory,
                    currentPage,
                    totalPages,
                    pageSize,
                    source.Count,
                    pageItems.Length,
                    hasPagedRequest);

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
                pageSize = NormalizeStoragePageSize(storageType, pageSize);
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

                var payload = BuildStorageListPayload(storageType, result.CurrentPage, pageSize);

                Log.Debug(
                    "storage_storage_list response len={Len} preview={Preview}",
                    payload.Length,
                    payload[..Math.Min(payload.Length, 300)]);

                writer.WriteString(payload);
                await SendAsync(writer);
                return;
            }

            case "storage_drag":
            {
                var storageType = GetIntArg(rpcArgs, "t", 3);
                var pageSize = GetIntArg(rpcArgs, "s", 24);
                var fromPage = GetIntArg(rpcArgs, "fromPage", GetIntArg(rpcArgs, "p", 1));
                var toPage = GetIntArg(rpcArgs, "toPage", fromPage);
                var fromSlot = GetIntArg(rpcArgs, "fromSlot", 0);
                var toSlot = GetIntArg(rpcArgs, "toSlot", 0);
                var pid = rpcArgs.GetValueOrDefault("id");
                var player = GetActivePlayerStateOrDefault();
                var ok = player.TryMoveStorageItem(
                    storageType,
                    fromPage,
                    fromSlot,
                    toPage,
                    toSlot,
                    pid,
                    out var errorKey);

                Log.Information(
                    "storage_drag: roleId={RoleId} t={T} from={FromPage}:{FromSlot} to={ToPage}:{ToSlot} pid={Pid} ok={Ok} error={Error}",
                    _activeRoleId,
                    storageType,
                    fromPage,
                    fromSlot,
                    toPage,
                    toSlot,
                    pid ?? string.Empty,
                    ok,
                    errorKey ?? string.Empty);

                writer.WriteString(ok
                    ? BuildStorageListPayload(storageType, toPage, pageSize)
                    : "ok = 0\nerror = " + LuaEscape(errorKey ?? "msgbox_common_num_1306"));
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
            case "tip_sys_skill":
            {
                var player = GetActivePlayerStateOrDefault();
                if (string.Equals(rpcName, "tip_sys_skill", StringComparison.Ordinal))
                {
                    var requestedSkillId = GetIntArg(rpcArgs, "sid", 0);
                    var requestedLevel = GetIntArg(rpcArgs, "level", 1);
                    var requestedType = GetIntArg(rpcArgs, "t", 1);
                    writer.WriteString(GetSkillTipPayload(player, requestedSkillId, requestedLevel, requestedType));
                    await SendAsync(writer);
                    return;
                }

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
        finally
        {
            if (_activeRoleId > 0)
            {
                _playerStore.SaveActiveCharacter((int)_activeRoleId);
            }
        }
    }
}
