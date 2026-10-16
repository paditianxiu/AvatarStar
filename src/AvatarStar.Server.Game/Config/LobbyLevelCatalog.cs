using System.Text;
using System.Text.Json;
using Serilog;

namespace AvatarStar.Server.Game;

/// <summary>
/// 大厅关卡表（客户端 packet30 里那条 LevelInfo 列表）。
/// 数据来自官方服务端抓包还原的 Config/lobby_levels.json：
/// 「远征模式.txt」的 packet30 共 69 条，其中 gameType = 9（kBoss，见 CreateRoom.lua 的
/// gameType_key）的 8 条就是「冒险远征」模式可选的地图。
/// 大厅建房、房间列表、局内 packet102 的关卡码都从这里取，缺了这张表客户端远征界面就没有图可选。
/// </summary>
internal static class LobbyLevelCatalog
{
    /// <summary>CreateRoom.lua: kGameTypeBoss = 9。</summary>
    internal const byte BossGameType = 9;

    internal readonly record struct Entry(
        long Id,
        string Name,
        byte GameType,
        string ShowName,
        string Description,
        int Difficulty,
        int Group);

    private const string ConfigFileName = "lobby_levels.json";

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
    };

    private static readonly Lazy<IReadOnlyList<Entry>> LevelsLazy = new(LoadLevels, LazyThreadSafetyMode.ExecutionAndPublication);

    internal static IReadOnlyList<Entry> Levels => LevelsLazy.Value;

    internal static bool HasLevels => Levels.Count > 0;

    /// <summary>关卡 id → 关卡码（packet102 的 levelCode，例如 10001 / 20001 都映射到 LEVEL10001）。</summary>
    internal static string? ResolveLevelCode(long levelId)
    {
        if (levelId <= 0)
        {
            return null;
        }

        foreach (var level in Levels)
        {
            if (level.Id == levelId)
            {
                return level.Name;
            }
        }

        return null;
    }

    /// <summary>关卡 id → 地图显示名（房间信息里的 MapName）。</summary>
    internal static string? ResolveMapShowName(long levelId)
    {
        if (levelId <= 0)
        {
            return null;
        }

        foreach (var level in Levels)
        {
            if (level.Id == levelId)
            {
                return level.ShowName;
            }
        }

        return null;
    }

    private static IReadOnlyList<Entry> LoadLevels()
    {
        var path = ResolveConfigPath();
        if (string.IsNullOrWhiteSpace(path))
        {
            return Array.Empty<Entry>();
        }

        try
        {
            var root = JsonSerializer.Deserialize<LevelCatalogRoot>(File.ReadAllText(path, Encoding.UTF8), JsonOptions);
            var levels = root?.Levels;
            if (levels is not { Count: > 0 })
            {
                Log.Warning("Lobby level catalog is empty: {Path}", path);
                return Array.Empty<Entry>();
            }

            var entries = new List<Entry>(levels.Count);
            foreach (var level in levels)
            {
                if (level is null || level.Id <= 0 || string.IsNullOrWhiteSpace(level.Name))
                {
                    continue;
                }

                entries.Add(new Entry(
                    level.Id,
                    level.Name,
                    level.GameType,
                    level.ShowName ?? string.Empty,
                    level.Description ?? string.Empty,
                    level.Difficulty,
                    level.Group));
            }

            Log.Information(
                "Lobby level catalog loaded: {Path} levels={Count} bossLevels={BossLevels}",
                path,
                entries.Count,
                entries.Count(entry => entry.GameType == BossGameType));
            return entries;
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load lobby level catalog from {Path}", path);
            return Array.Empty<Entry>();
        }
    }

    private static string? ResolveConfigPath()
    {
        var envPath = Environment.GetEnvironmentVariable("AS_LOBBY_LEVELS_PATH");
        if (!string.IsNullOrWhiteSpace(envPath) && File.Exists(envPath))
        {
            return envPath;
        }

        string[] candidates =
        [
            Path.Combine(AppContext.BaseDirectory, "Config", ConfigFileName),
            Path.Combine(AppContext.BaseDirectory, ConfigFileName),
            Path.Combine(Directory.GetCurrentDirectory(), "Config", ConfigFileName),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Config", ConfigFileName),
        ];

        return candidates.FirstOrDefault(File.Exists);
    }

    private sealed class LevelCatalogRoot
    {
        public List<LevelEntry>? Levels { get; set; }
    }

    private sealed class LevelEntry
    {
        public long Id { get; set; }
        public string? Name { get; set; }
        public byte GameType { get; set; }
        public string? ShowName { get; set; }
        public string? Description { get; set; }
        public int Difficulty { get; set; }
        public int Group { get; set; }
    }
}