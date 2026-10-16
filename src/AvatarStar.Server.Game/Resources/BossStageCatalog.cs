using System.Text;
using System.Text.Json;
using Serilog;

namespace AvatarStar.Server.Game.Resources;

/// <summary>
/// 「冒险远征」(kBoss = 9) 的 boss 实体包资源。
/// 数据来自官方服务端抓包还原的 Resources/boss_stages.json：
/// 「远征模式.txt」里服务端在开局连续下发的三条 packet104，分别是 BOSS 一阶 / 二阶 / 三阶
/// （血量 560000 / 880000 / 1200000，模型 boss_01_01..03，技能表 UI_abilities_BOSS_skill_*）。
/// 客户端拿这三条建 boss 模型并按阶段切换，所以三条都要发。
/// </summary>
internal static class BossStageCatalog
{
    internal sealed record BossStage(int Stage, string Display, int Health, byte[] Payload);

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
    };

    private static readonly Lazy<Loaded> Lazy = new(Load, System.Threading.LazyThreadSafetyMode.ExecutionAndPublication);

    /// <summary>boss 实体包的包号（官方是 104，注意与客户端上报的 ping 同号但方向相反）。</summary>
    internal static short PacketId => Lazy.Value.PacketId;

    internal static IReadOnlyList<BossStage> Stages => Lazy.Value.Stages;

    internal static bool HasStages => Stages.Count > 0;

    private static Loaded Load()
    {
        var path = ResolveConfigPath();
        if (string.IsNullOrWhiteSpace(path))
        {
            return new Loaded(104, Array.Empty<BossStage>());
        }

        try
        {
            var root = JsonSerializer.Deserialize<BossStageRoot>(File.ReadAllText(path, Encoding.UTF8), JsonOptions);
            var stages = new List<BossStage>();
            var packetId = root?.PacketId is > 0 and <= short.MaxValue ? (short)root.PacketId : (short)104;

            foreach (var entry in root?.Stages ?? [])
            {
                if (entry is null || string.IsNullOrWhiteSpace(entry.Hex))
                {
                    continue;
                }

                byte[] payload;
                try
                {
                    payload = Convert.FromHexString(entry.Hex.Replace(" ", string.Empty));
                }
                catch (FormatException ex)
                {
                    Log.Warning(ex, "Boss stage {Stage} has invalid hex in {Path}", entry.Stage, path);
                    continue;
                }

                if (payload.Length < 2 || payload[0] != (byte)(packetId & 0xFF))
                {
                    Log.Warning(
                        "Boss stage {Stage} payload does not start with packet {PacketId} in {Path}",
                        entry.Stage,
                        packetId,
                        path);
                    continue;
                }

                stages.Add(new BossStage(entry.Stage, entry.Display ?? string.Empty, entry.Health, payload));
            }

            stages.Sort((left, right) => left.Stage.CompareTo(right.Stage));
            Log.Information(
                "Boss stage catalog loaded: {Path} packetId={PacketId} stages={Stages} health={Health}",
                path,
                packetId,
                stages.Count,
                string.Join(",", stages.Select(stage => stage.Health)));
            return new Loaded(packetId, stages);
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load boss stage catalog from {Path}", path);
            return new Loaded(104, Array.Empty<BossStage>());
        }
    }

    private static string? ResolveConfigPath()
    {
        var envPath = Environment.GetEnvironmentVariable("AS_BOSS_STAGES_PATH");
        if (!string.IsNullOrWhiteSpace(envPath) && File.Exists(envPath))
        {
            return envPath;
        }

        string[] candidates =
        [
            Path.Combine(AppContext.BaseDirectory, "Resources", "boss_stages.json"),
            Path.Combine(AppContext.BaseDirectory, "boss_stages.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "Resources", "boss_stages.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Resources", "boss_stages.json"),
        ];

        return candidates.FirstOrDefault(File.Exists);
    }

    private sealed record Loaded(short PacketId, IReadOnlyList<BossStage> Stages);

    private sealed class BossStageRoot
    {
        public int PacketId { get; set; }
        public List<BossStageEntry>? Stages { get; set; }
    }

    private sealed class BossStageEntry
    {
        public int Stage { get; set; }
        public string? Display { get; set; }
        public int Health { get; set; }
        public string? Hex { get; set; }
    }
}