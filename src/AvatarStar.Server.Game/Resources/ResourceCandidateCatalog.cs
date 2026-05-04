using System.Globalization;
using System.Text.Json;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Persistence;

namespace AvatarStar.Server.Game.Resources;

internal static class ResourceCandidateCatalog
{
    internal sealed record ResourceCandidate(
        string Resource,
        int ShopType,
        int Subtype,
        string Category,
        string DisplayKey,
        string DisplayText,
        string Source,
        int Sid);

    private const string DefaultCategory = "\u672A\u5206\u7C7B";

    private sealed class CandidateEntry
    {
        public string Resource { get; set; } = string.Empty;
        public int ShopType { get; set; }
        public int Subtype { get; set; }
        public string Category { get; set; } = DefaultCategory;
        public string DisplayKey { get; set; } = string.Empty;
        public string DisplayText { get; set; } = string.Empty;
        public int Sid { get; set; }
        public HashSet<string> Sources { get; } = new(StringComparer.OrdinalIgnoreCase);

        public ResourceCandidate ToCandidate() => new(
            Resource,
            ShopType,
            Subtype,
            string.IsNullOrWhiteSpace(Category) ? DefaultCategory : Category,
            DisplayKey,
            string.IsNullOrWhiteSpace(DisplayText) ? Resource : DisplayText,
            string.Join(",", Sources.OrderBy(x => x, StringComparer.OrdinalIgnoreCase)),
            Sid);
    }

    private sealed class ItemCandidateRoot
    {
        public ItemCandidateItem[]? Items { get; set; }
    }

    private sealed class ItemCandidateItem
    {
        public string? Resource { get; set; }
        public int Type { get; set; }
        public string? Category { get; set; }
    }

    private sealed record OfficialWeaponInfo(string Resource, int Subtype, string DisplayKey);

    public static IReadOnlyList<ResourceCandidate> GetCandidates(SysAvatarPayloadConfig? avatarConfig)
    {
        var entries = new Dictionary<string, CandidateEntry>(StringComparer.OrdinalIgnoreCase);
        var officialWeapons = (avatarConfig?.OfficialCatalog?.Professions ?? Enumerable.Empty<OfficialProfession>())
            .SelectMany(p => p.Weapons ?? Enumerable.Empty<OfficialWeapon>())
            .Where(w => !string.IsNullOrWhiteSpace(w.Resource))
            .Select(w => new OfficialWeaponInfo(
                w.Resource,
                int.TryParse(w.SubType, NumberStyles.Integer, CultureInfo.InvariantCulture, out var subtype) ? subtype : 0,
                w.DisplayName ?? string.Empty))
            .GroupBy(w => w.Resource, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);

        foreach (var shopItem in ShopItemDatabase.GetAllShopItems().Values.Where(x => !string.IsNullOrWhiteSpace(x.Resource)))
        {
            var entry = GetOrCreate(entries, shopItem.Resource);
            entry.ShopType = (int)shopItem.Type;
            entry.Subtype = shopItem.Subtype;
            entry.Category = NormalizeCategory(shopItem.Category);
            entry.DisplayKey = shopItem.Display ?? string.Empty;
            entry.DisplayText = ResolveDisplayText(shopItem.Resource, entry.DisplayKey);
            entry.Sid = shopItem.Sid;
            entry.Sources.Add("shop");
        }

        foreach (var raw in LoadRawCandidates())
        {
            if (string.IsNullOrWhiteSpace(raw.Resource))
            {
                continue;
            }

            var entry = GetOrCreate(entries, raw.Resource!);
            if (entry.ShopType == 0)
            {
                entry.ShopType = MapToShopType(raw.Type, raw.Category);
            }

            if (entry.Subtype == 0 && officialWeapons.TryGetValue(raw.Resource!, out var official))
            {
                entry.Subtype = official.Subtype;
            }

            if (string.IsNullOrWhiteSpace(entry.DisplayKey) && officialWeapons.TryGetValue(raw.Resource!, out var weapon))
            {
                entry.DisplayKey = weapon.DisplayKey;
            }

            if (string.IsNullOrWhiteSpace(entry.DisplayText))
            {
                entry.DisplayText = ResolveDisplayText(raw.Resource!, entry.DisplayKey);
            }

            if (entry.Category == DefaultCategory)
            {
                entry.Category = NormalizeCategory(raw.Category);
            }

            entry.Sources.Add("item_candidates");
        }

        foreach (var official in officialWeapons.Values)
        {
            var entry = GetOrCreate(entries, official.Resource);
            if (entry.ShopType == 0)
            {
                entry.ShopType = 2;
            }

            if (entry.Subtype == 0)
            {
                entry.Subtype = official.Subtype;
            }

            if (entry.Category == DefaultCategory)
            {
                entry.Category = "Weapons";
            }

            if (string.IsNullOrWhiteSpace(entry.DisplayKey))
            {
                entry.DisplayKey = official.DisplayKey;
            }

            if (string.IsNullOrWhiteSpace(entry.DisplayText))
            {
                entry.DisplayText = ResolveDisplayText(official.Resource, official.DisplayKey);
            }

            entry.Sources.Add("avatar_config");
        }

        return entries.Values
            .Select(entry => entry.ToCandidate())
            .OrderBy(x => x.ShopType)
            .ThenBy(x => x.Category, StringComparer.OrdinalIgnoreCase)
            .ThenBy(x => x.DisplayText, StringComparer.OrdinalIgnoreCase)
            .ThenBy(x => x.Resource, StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static CandidateEntry GetOrCreate(IDictionary<string, CandidateEntry> entries, string resource)
    {
        if (entries.TryGetValue(resource, out var existing))
        {
            return existing;
        }

        var created = new CandidateEntry
        {
            Resource = resource
        };
        entries[resource] = created;
        return created;
    }

    private static IEnumerable<ItemCandidateItem> LoadRawCandidates()
    {
        try
        {
            var json = new ConfigRepository().GetConfigDocumentBySuffix("item_candidates.json");
            if (!string.IsNullOrWhiteSpace(json))
            {
                var dbRoot = JsonSerializer.Deserialize<ItemCandidateRoot>(json, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                });
                return dbRoot?.Items ?? Enumerable.Empty<ItemCandidateItem>();
            }
        }
        catch
        {
            // File fallback below keeps development workflow tolerant.
        }

        var path = FindCandidatePath();
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
        {
            return Enumerable.Empty<ItemCandidateItem>();
        }

        try
        {
            var json = File.ReadAllText(path);
            var root = JsonSerializer.Deserialize<ItemCandidateRoot>(json, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });
            return root?.Items ?? Enumerable.Empty<ItemCandidateItem>();
        }
        catch
        {
            return Enumerable.Empty<ItemCandidateItem>();
        }
    }

    private static string FindCandidatePath()
    {
        foreach (var root in GetSearchRoots())
        {
            var full = Path.Combine(root, "tools", "resources", "item_candidates.json");
            if (File.Exists(full))
            {
                return full;
            }
        }

        return string.Empty;
    }

    private static IEnumerable<string> GetSearchRoots()
    {
        var repoRoot =
            Environment.GetEnvironmentVariable("AS_REPO_ROOT")
            ?? Environment.GetEnvironmentVariable("AVATARSTAR_REPO_ROOT")
            ?? string.Empty;
        if (!string.IsNullOrWhiteSpace(repoRoot) && Directory.Exists(repoRoot))
        {
            yield return repoRoot;
        }

        yield return Directory.GetCurrentDirectory();
        var dir = AppContext.BaseDirectory;
        for (var i = 0; i < 6; i++)
        {
            yield return dir;
            var parent = Directory.GetParent(dir);
            if (parent is null)
            {
                break;
            }

            dir = parent.FullName;
        }
    }

    private static int MapToShopType(int type, string? category)
    {
        var normalizedCategory = NormalizeCategory(category);
        if (normalizedCategory.Equals("Skins", StringComparison.OrdinalIgnoreCase))
        {
            return 6;
        }

        if (normalizedCategory.Equals("Pets", StringComparison.OrdinalIgnoreCase))
        {
            return 5;
        }

        return type switch
        {
            2 => 2,
            3 => 3,
            4 => 4,
            5 => 5,
            6 => 6,
            _ => 3
        };
    }

    private static string NormalizeCategory(string? category)
    {
        return string.IsNullOrWhiteSpace(category) ? DefaultCategory : category.Trim();
    }

    private static string ResolveDisplayText(string resource, string? displayKey)
    {
        var translated = GameTextDatabase.TranslateFirstKnown(
            displayKey,
            $"id_weapon_{resource}",
            $"id_weapon_weapon_{resource}",
            $"UI_weapon_weapon_{resource}",
            $"id_datalist_{resource}",
            $"UI_datalist_{resource}");
        return string.IsNullOrWhiteSpace(translated) ? resource : translated;
    }
}
