using System.Text;
using System.Text.Json;
using Serilog;

namespace AvatarStar.Server.Game.Resources;

/// <summary>
/// 冒险远征（kBoss = 9）的局内战斗帧资源。
/// 数据来自官方服务端抓包「远征模式.txt」18:54:12–19:01:10（LEVEL10001，一局完整的 boss 战），
/// 由 Resources/boss_combat.json 提供整包 hex。
///
/// 开局时序（官方抓包）：
///   packet9 / 100 / 102 / 103(玩家与装备) / 112 ×3 / 105 → packet104 ×3（三个阶段实体）
///   → packet212 → 客户端 103 请求 → packet106（30 字节最小包，不带玩家列表）
///   → packet151（float = 倒计时 10 秒，客户端还在加载大 boss 场景）
///   → 之后每 200ms 一条 packet198（boss 状态：阶段、朝向、当前血量）+ packet199（本阶段剩余时间）
///   → 10 秒后才 packet151(0.0) + packet146 + packet231 + packet111（本地出生）。
///
/// 动作（packet198）的结构（本机客户端据此播动作，官方 18:54:13–19:01:10 共 37750 条）：
///   offset  3       阶段索引（0/1/2）
///   offset  7..8    boss 实体 id 2046（fe 07）
///   offset 11..14   float 相位计数器（动作播放进度）
///   offset 15..18   float 动作计时器（一阶段 8.0 → 0 时播转身）
///   offset 19..22   float 朝向（度）
///   offset 23..34   12 字节动作块 = 6 个 i16（小端），除以 256 就是
///                   「相位 / 计时器 / 朝向」三个量的每秒变化率。
///                   例如 0006 0000 0000 0000 0000 0000 = 相位 +6/秒，
///                   fa 00 … f6 00 = 相位 -6/秒、朝向 -10/秒。
///   官方每段动作的实测（速率 × 时长 = 端点差值）与 Resources/boss_combat.json 里的
///   stateTracks 完全一致：一阶段循环 14 秒、二阶段 20 秒、三阶段 22 秒。
///
/// 关键点：boss 图的场景很大，官方在 106 之后用 151 的 10 秒倒计时把「出生」推后；
/// 之前本地服务端 106 之后立刻发 111/146/231，客户端场景没加载完就收到出生帧，
/// 表现为进房 1 秒后「网络异常」掉线。
/// </summary>
internal static class BossCombatCatalog
{
    /// <summary>packet198 里「当前血量」是第 37 字节起的 float（560000 / 880000 / 1200000）。</summary>
    internal const int BossHealthFieldOffset = 37;

    /// <summary>packet106 / packet112 里的本地玩家 uid 在第 3 个字节。</summary>
    internal const int LocalUidFieldOffset = 2;

    /// <summary>packet198 里「动作相位计数器」是第 11 字节起的 float。</summary>
    internal const int BossPhaseFieldOffset = 11;

    /// <summary>packet198 里「动作计时器」是第 15 字节起的 float（一阶段开场 8.0 → 0 的转身动画）。</summary>
    internal const int BossTimerFieldOffset = 15;

    /// <summary>packet198 里「朝向（度）」是第 19 字节起的 float。</summary>
    internal const int BossYawFieldOffset = 19;

    /// <summary>packet198 里「动作状态字节」是第 23 字节起的 12 字节。</summary>
    internal const int BossActionFieldOffset = 23;

    internal const int BossActionFieldLength = 12;

    internal sealed record SpawnTransform(float ActorFloat, float X, float Y, float Z, float Yaw);

    internal sealed record BossStage(int Stage, int Health, double TimeLimitSeconds, byte[] StatePacket, byte[] TimerPacket);

    /// <summary>
    /// packet198 的一段动作：12 字节动作块 + 持续时长 + 相位计数器 / 动作计时器 / 朝向的起止值。
    /// 数据取自官方拓包「远征模式.txt」里 boss 每个阶段实测的动作段（速率 × 时长 = 端点差值）。
    /// </summary>
    internal sealed record BossStateSegment(
        byte[] Action,
        int DurationMilliseconds,
        float PhaseStart,
        float PhaseEnd,
        float TimerStart,
        float TimerEnd,
        float YawStart,
        float YawEnd);

    /// <summary>
    /// boss 某个阶段的动作轨道（按 packet198 实际发送时间推进）：
    /// 前 <see cref="EntryMilliseconds"/> 毫秒是入场段（只播一次，例如一阶段开场的转身），
    /// 之后的 <see cref="CycleMilliseconds"/> 毫秒循环播放。
    /// </summary>
    internal sealed record BossStateTrack(
        int EntryMilliseconds,
        int CycleMilliseconds,
        IReadOnlyList<BossStateSegment> Segments);

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true,
    };

    private static readonly Lazy<Loaded> Lazy = new(Load, System.Threading.LazyThreadSafetyMode.ExecutionAndPublication);

    internal static bool HasData => Lazy.Value.HasData;

    internal static float LoadingCountdownSeconds => Lazy.Value.LoadingCountdownSeconds;

    internal static double BossSpawnDelaySeconds => Lazy.Value.BossSpawnDelaySeconds;

    internal static int StateIntervalMilliseconds => Lazy.Value.StateIntervalMilliseconds;

    internal static int PlayerStateRepeatCount => Lazy.Value.PlayerStateRepeatCount;

    internal static SpawnTransform Spawn => Lazy.Value.Spawn;

    internal static IReadOnlyList<BossStage> Stages => Lazy.Value.Stages;

    internal static byte[] PreludePacket => Lazy.Value.PreludePacket;

    internal static IReadOnlyList<BossStateTrack> StateTracks => Lazy.Value.StateTracks;

    /// <summary>packet106：官方 boss 图上是 30 字节的空玩家列表最小包，uid 字节改写成本地 uid。</summary>
    internal static byte[] GameInitPacket106(byte localUid) => WithLocalUid(Lazy.Value.GameInitPacket106, localUid);

    /// <summary>packet112：180 字节的玩家局内状态帧，uid 字节改写成本地 uid。</summary>
    internal static byte[] GameInitPlayerStatePacket(byte localUid) => WithLocalUid(Lazy.Value.GameInitPlayerState, localUid);

    private static byte[] WithLocalUid(byte[] payload, byte localUid)
    {
        if (payload.Length <= LocalUidFieldOffset || payload[LocalUidFieldOffset] == localUid)
        {
            return payload;
        }

        var copy = (byte[])payload.Clone();
        copy[LocalUidFieldOffset] = localUid;
        return copy;
    }

    /// <summary>取某一阶段的 packet198 模板，并把当前血量写进血量字段。</summary>
    internal static byte[] BossStatePacket(int stageIndex, float health)
    {
        var stages = Lazy.Value.Stages;
        if (stageIndex < 0 || stageIndex >= stages.Count)
        {
            return Array.Empty<byte>();
        }

        var payload = (byte[])stages[stageIndex].StatePacket.Clone();
        if (payload.Length >= BossHealthFieldOffset + sizeof(float))
        {
            BitConverter.TryWriteBytes(payload.AsSpan(BossHealthFieldOffset), health);
        }

        return payload;
    }

    /// <summary>当前阶段剩余时间（packet199 的 float，取整到 0.01 秒省带宽）。</summary>
    /// <summary>
    /// packet198：在「相位计数器 / 朝向 / 动作状态」上按拓包记录的轨道推进。
    /// <paramref name="trackElapsedMilliseconds"/> 为 null 时只替换血量（倒计时阶段的「定住」模板）。
    /// </summary>
    internal static byte[] BossStatePacket(int stageIndex, float health, double? trackElapsedMilliseconds)
    {
        var payload = BossStatePacket(stageIndex, health);
        if (payload.Length < BossActionFieldOffset + BossActionFieldLength ||
            trackElapsedMilliseconds is not { } elapsed)
        {
            return payload;
        }

        var track = StateTracks.Count > stageIndex && stageIndex >= 0 ? StateTracks[stageIndex] : null;
        if (track is null || track.Segments.Count == 0)
        {
            return payload;
        }

        var cycle = Math.Max(1, track.CycleMilliseconds);
        var entry = Math.Clamp(track.EntryMilliseconds, 0, Math.Max(0, cycle - 1));
        // 轨道 = 入场段（只播一次）+ 循环段：入场段走完后按循环长度取模。
        var time = elapsed <= entry ? elapsed : entry + (elapsed - entry) % cycle;
        if (time < 0d)
        {
            time += cycle;
        }

        var offset = 0d;
        for (var index = 0; index < track.Segments.Count; index++)
        {
            var segment = track.Segments[index];
            var duration = Math.Max(1, segment.DurationMilliseconds);
            if (time >= offset + duration && index < track.Segments.Count - 1)
            {
                offset += duration;
                continue;
            }

            var ratio = Math.Clamp((time - offset) / duration, 0d, 1d);
            var phase = segment.PhaseStart + (segment.PhaseEnd - segment.PhaseStart) * ratio;
            var timer = segment.TimerStart + (segment.TimerEnd - segment.TimerStart) * ratio;
            var yaw = segment.YawStart + (segment.YawEnd - segment.YawStart) * ratio;
            BitConverter.TryWriteBytes(payload.AsSpan(BossPhaseFieldOffset), (float)phase);
            BitConverter.TryWriteBytes(payload.AsSpan(BossTimerFieldOffset), (float)timer);
            BitConverter.TryWriteBytes(payload.AsSpan(BossYawFieldOffset), (float)yaw);
            segment.Action.CopyTo(payload, BossActionFieldOffset);
            break;
        }

        return payload;
    }

    internal static byte[] BossStageTimerPacket(double secondsRemaining)
    {
        var stages = Lazy.Value.Stages;
        if (stages.Count == 0)
        {
            return Array.Empty<byte>();
        }

        var template = stages[0].TimerPacket;
        var payload = (byte[])template.Clone();
        if (payload.Length >= 6)
        {
            BitConverter.TryWriteBytes(payload.AsSpan(2), (float)Math.Round(Math.Max(0d, secondsRemaining), 2));
        }

        return payload;
    }

    private static Loaded Load()
    {
        var path = ResolveConfigPath();
        if (string.IsNullOrWhiteSpace(path))
        {
            return Loaded.Empty;
        }

        try
        {
            var root = JsonSerializer.Deserialize<BossCombatRoot>(File.ReadAllText(path, Encoding.UTF8), JsonOptions);
            if (root is null)
            {
                return Loaded.Empty;
            }

            var stages = new List<BossStage>();
            foreach (var entry in root.Stages ?? [])
            {
                if (entry is null)
                {
                    continue;
                }

                var state = Decode(entry.Packet198Hex, path, "packet198", entry.Stage);
                var timer = Decode(entry.Packet199Hex, path, "packet199", entry.Stage);
                if (state.Length == 0 || timer.Length == 0)
                {
                    continue;
                }

                stages.Add(new BossStage(entry.Stage, entry.Health, entry.TimeLimitSeconds, state, timer));
            }

            var stateTracks = BuildStateTracks(root.StateTracks, stages, path);

            var packet106 = Decode(root.GameInitPacket106Hex, path, "packet106", 0);
            var playerState = Decode(root.GameInitPlayerStatePacket112Hex, path, "packet112", 0);
            var prelude = Decode(root.GameInitPreludePacket212Hex, path, "packet212", 0);
            var hasData = stages.Count > 0 && packet106.Length > 0;

            var spawnTransform = root.SpawnTransform ?? new SpawnTransformEntry();
            var spawn = new SpawnTransform(
                spawnTransform.ActorFloat,
                spawnTransform.X,
                spawnTransform.Y,
                spawnTransform.Z,
                spawnTransform.Yaw);

            var interval = root.StateIntervalMilliseconds is > 0 and <= 1000 ? root.StateIntervalMilliseconds : 200;
            var repeat = root.PlayerStateRepeatCount is > 0 and <= 8 ? root.PlayerStateRepeatCount : 3;
            var countdown = root.LoadingCountdownSeconds > 0f ? root.LoadingCountdownSeconds : 10f;
            var spawnDelay = root.BossSpawnDelaySeconds > 0d ? root.BossSpawnDelaySeconds : countdown;

            Log.Information(
                "Boss combat catalog loaded: {Path} stages={Stages} health={Health} countdown={Countdown} spawnDelay={SpawnDelay} intervalMs={Interval} packet106Bytes={Packet106Bytes} packet112Bytes={Packet112Bytes}",
                path,
                stages.Count,
                string.Join(",", stages.Select(stage => stage.Health)),
                countdown,
                spawnDelay,
                interval,
                packet106.Length,
                playerState.Length);

            Log.Information(
                "Boss combat state tracks loaded: stages={Stages} segments={Segments} entryMs={Entries} cyclesMs={Cycles}",
                stateTracks.Count,
                stateTracks.Sum(track => track.Segments.Count),
                string.Join(",", stateTracks.Select(track => track.EntryMilliseconds)),
                string.Join(",", stateTracks.Select(track => track.CycleMilliseconds)));

            return new Loaded(
                hasData,
                countdown,
                spawnDelay,
                interval,
                repeat,
                spawn,
                prelude,
                packet106,
                playerState,
                stages,
                stateTracks);
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load boss combat catalog from {Path}", path);
            return Loaded.Empty;
        }
    }

    private static byte[] Decode(string? hex, string path, string label, int stage)
    {
        if (string.IsNullOrWhiteSpace(hex))
        {
            Log.Warning("Boss combat {Label} (stage {Stage}) is missing in {Path}", label, stage, path);
            return Array.Empty<byte>();
        }

        try
        {
            return Convert.FromHexString(hex.Replace(" ", string.Empty));
        }
        catch (FormatException ex)
        {
            Log.Warning(ex, "Boss combat {Label} (stage {Stage}) has invalid hex in {Path}", label, stage, path);
            return Array.Empty<byte>();
        }
    }

    /// <summary>把 JSON 里的动作轨道按阶段顺序展开（缺失的阶段给空轨道）。</summary>
    private static IReadOnlyList<BossStateTrack> BuildStateTracks(
        List<BossStateTrackEntry>? entries,
        IReadOnlyList<BossStage> stages,
        string path)
    {
        var byStage = new Dictionary<int, BossStateTrackEntry>();
        foreach (var entry in entries ?? [])
        {
            if (entry is not null)
            {
                byStage[entry.Stage] = entry;
            }
        }

        var tracks = new List<BossStateTrack>(stages.Count);
        foreach (var stage in stages)
        {
            tracks.Add(BuildStateTrack(byStage.GetValueOrDefault(stage.Stage), stage.Stage, path));
        }

        return tracks;
    }

    private static BossStateTrack BuildStateTrack(BossStateTrackEntry? entry, int stage, string path)
    {
        var segments = new List<BossStateSegment>();
        foreach (var segment in entry?.Segments ?? [])
        {
            if (segment is null)
            {
                continue;
            }

            var action = Decode(segment.ActionHex, path, "packet198 action", stage);
            if (action.Length != BossActionFieldLength)
            {
                Log.Warning(
                    "Boss combat packet198 action bytes (stage {Stage}) must be {Expected} bytes, got {Actual} in {Path}",
                    stage,
                    BossActionFieldLength,
                    action.Length,
                    path);
                continue;
            }

            var duration = Math.Max(1, segment.DurationMilliseconds);
            segments.Add(new BossStateSegment(
                action,
                duration,
                segment.PhaseStart,
                segment.PhaseEnd,
                segment.TimerStart,
                segment.TimerEnd,
                segment.YawStart,
                segment.YawEnd));
        }

        // 前面 entrySegmentCount 段是只播一次的入场段（例如一阶段开场的转身），剩下的循环。
        var entryCount = Math.Clamp(entry?.EntrySegmentCount ?? 1, 1, Math.Max(1, segments.Count));
        var entryMilliseconds = segments.Take(entryCount).Sum(segment => segment.DurationMilliseconds);
        var cycleMilliseconds = segments.Skip(entryCount).Sum(segment => segment.DurationMilliseconds);
        if (cycleMilliseconds <= 0)
        {
            // 只有一段（或没填 entrySegmentCount）时整条轨道循环播。
            entryMilliseconds = 0;
            cycleMilliseconds = segments.Sum(segment => segment.DurationMilliseconds);
        }

        return new BossStateTrack(
            Math.Max(0, entryMilliseconds),
            Math.Max(1, cycleMilliseconds),
            segments);
    }

    private static string? ResolveConfigPath()
    {
        var envPath = Environment.GetEnvironmentVariable("AS_BOSS_COMBAT_PATH");
        if (!string.IsNullOrWhiteSpace(envPath) && File.Exists(envPath))
        {
            return envPath;
        }

        string[] candidates =
        [
            Path.Combine(AppContext.BaseDirectory, "Resources", "boss_combat.json"),
            Path.Combine(AppContext.BaseDirectory, "boss_combat.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "Resources", "boss_combat.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Resources", "boss_combat.json"),
        ];

        return candidates.FirstOrDefault(File.Exists);
    }

    private sealed record Loaded(
        bool HasData,
        float LoadingCountdownSeconds,
        double BossSpawnDelaySeconds,
        int StateIntervalMilliseconds,
        int PlayerStateRepeatCount,
        SpawnTransform Spawn,
        byte[] PreludePacket,
        byte[] GameInitPacket106,
        byte[] GameInitPlayerState,
        IReadOnlyList<BossStage> Stages,
        IReadOnlyList<BossStateTrack> StateTracks)
    {
        internal static readonly Loaded Empty = new(
            false,
            10f,
            10d,
            200,
            3,
            new SpawnTransform(5f, -0.735231f, 1.039062f, 3.187552f, 0f),
            Array.Empty<byte>(),
            Array.Empty<byte>(),
            Array.Empty<byte>(),
            Array.Empty<BossStage>(),
            Array.Empty<BossStateTrack>());
    }

    private sealed class BossCombatRoot
    {
        public float LoadingCountdownSeconds { get; set; }
        public double BossSpawnDelaySeconds { get; set; }
        public int StateIntervalMilliseconds { get; set; }
        public int PlayerStateRepeatCount { get; set; }
        public string? GameInitPacket106Hex { get; set; }
        public string? GameInitPlayerStatePacket112Hex { get; set; }
        public string? GameInitPreludePacket212Hex { get; set; }
        public SpawnTransformEntry? SpawnTransform { get; set; }
        public List<BossStageEntry>? Stages { get; set; }
        public List<BossStateTrackEntry>? StateTracks { get; set; }
    }

    private sealed class SpawnTransformEntry
    {
        public float ActorFloat { get; set; } = 5f;
        public float X { get; set; }
        public float Y { get; set; }
        public float Z { get; set; }
        public float Yaw { get; set; }
    }

    private sealed class BossStageEntry
    {
        public int Stage { get; set; }
        public int Health { get; set; }
        public double TimeLimitSeconds { get; set; }
        public string? Packet198Hex { get; set; }
        public string? Packet199Hex { get; set; }
    }

    private sealed class BossStateTrackEntry
    {
        public int Stage { get; set; }

        /// <summary>前面几段是只播一次的入场段（默认 1），剩下的循环。</summary>
        public int EntrySegmentCount { get; set; } = 1;

        public List<BossStateSegmentEntry>? Segments { get; set; }
    }

    private sealed class BossStateSegmentEntry
    {
        public string? ActionHex { get; set; }
        public int DurationMilliseconds { get; set; }
        public float PhaseStart { get; set; }
        public float PhaseEnd { get; set; }
        public float TimerStart { get; set; }
        public float TimerEnd { get; set; }
        public float YawStart { get; set; }
        public float YawEnd { get; set; }
    }
}
