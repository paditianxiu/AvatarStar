using System.Collections;
using System.Globalization;
using System.Net;
using System.Text;
using System.Text.Json;
using AvatarStar.Server.Game.Resources;
using AvatarStar.Server.Utilities;
using Serilog;

namespace AvatarStar.Server.Game;

internal sealed class PracticeRoomChannelProtocol
{
    private const byte DefaultServerSeed = 0x5A;
    private const uint XorInInitial = 0x54425749;
    private const uint XorOutInitial = 0x57495442;
    private const byte LocalGameUid = 1;
    private const int DefaultSpawnHealth = 1000;
    private const int FallbackBattleMapId = 17;
    private const int EquipmentBlockMaxEntries = 36;
    private const int GameLoadoutGroupCount = 3;
    private const int GameLoadoutGroupSize = 12;
    private static readonly bool UseLegacyMinimalPacket106PlayerList = false;
    private static readonly bool MirrorLoadoutAcrossGameGroups = false;
    private static readonly bool UseLegacyHotbarBootstrapSequence = false;
    private static readonly bool UseLegacyMinimalPacket103CharacterCreate = false;
    private static readonly bool UseLegacyMinimalPacket111Spawn = false;
    private const byte GameTeamRed = 0;
    private const byte GameTeamBlue = 1;
    private const byte GameTeamSpectator = 2;
    private const byte InitialGamePlayerActive = 1;
    private const byte InitialGamePlayerNotEntering = 0;
    private const byte InitialGamePlayerTransformReady = 1;
    private const short InitialGamePlayerActionStateFlags = 0x0002;
    private const byte GamePlayerListTerminator = 0;
    private const int PlayerEnteringClearRetryCount = 3;
    private const int GameActionAlternateWeaponCode = 0x0F;
    private const int GameActionPreviousWeaponCode = 0x10;
    private const int GameActionNextWeaponCode = 0x11;
    private const int GameActionFirstDirectWeaponSlotCode = 0x23;
    private const int GameActionLastDirectWeaponSlotCode = 0x2E;
    private const byte GameActionStateInactive = 0;
    private const short GameRemoteWeaponSlotPacketId = 128;
    private const byte ClientWeaponSlotCount = 12;
    private const byte ClientWeaponSlotNotifyMax = 18;
    private const byte ClientScrollableWeaponSlotCount = 7;
    private const int SilentLoadoutHudRefreshRetryCount = 0;
    private const int DeferredGameEnterStartDelayMilliseconds = 4000;
    private const int DeferredGameEnterPacket100DelayMilliseconds = 0;
    private const int DeferredGameEnterRpcQuietMilliseconds = 1500;
    private const int DeferredGameEnterMaxDelayMilliseconds = 10000;
    private const int GameInitSpawnFallbackDelayMilliseconds = 500;
    private const byte GameLoadoutHudReadyState = 1;
    private const string GameLoadoutHudRefreshPropertyName = "ammo_in_clip";
    private const string GameLoadoutAmmoOneClipPropertyName = "ammo_one_clip";
    private const double SpecialWeaponRearmMinSeconds = 0.25;
    private const double SpecialWeaponRearmMaxSeconds = 2.5;
    private static readonly bool EnableKnifeAutoRearmLoop = false;
    private const double KnifeAutoRearmInitialDelaySeconds = 0.15;
    private const int DefaultAccuracyDivisor = 1;
    private const byte GameCharacterTrailingReservedFlag = 0;
    private const byte GameCharacterModelReadyFlag = 1;
    private const string DefaultModelReadyResource = "bird";
    private const int DefaultModelReadyLevel = 2;
    private const bool EnableMovementCoordinateChangeLog = false;
    private const int MovementDebugSampleLogLimit = 96;
    private const string TeleportCommandName = "/tp";
    private const string SetCommandName = "/set";
    private const float MovementRawCoordinateScale = ActionPoseRawCoordinateScale;
    private const float ActionPoseRawCoordinateScale = 256f;
    private const short GameRemoteShootPacketId = 113;
    private const short GameRemoteHurtPacketId = 162;
    private const short GameRemoteDamageHitPacketId = 184;
    private const int GameObjectDeltaActorUidFlag = 0x00000001;
    private const int GameObjectDeltaTargetUidFlag = 0x00000002;
    private const int GameObjectDeltaWeaponSlotFlag = 0x00000004;
    private const int GameObjectDeltaActionFlag = 0x00000008;
    private const int GameObjectDeltaSkipTargetFlag = 0x00000020;
    private const int GameObjectDeltaIntValueFlag = 0x00004000;
    private const int GameObjectDeltaFloatValueFlag = 0x00008000;
    private const int GameObjectDeltaSubtypeFlag = 0x01000000;
    private const int GameObjectDeltaOriginFlag = 0x00200000;
    private const int GameObjectDeltaVectorFlag = 0x00400000;
    private const int GameObjectDeltaFacingFlag = 0x00800000;
    private const int GameRemoteShootObjectDeltaFlags =
        GameObjectDeltaActorUidFlag |
        GameObjectDeltaWeaponSlotFlag |
        GameObjectDeltaActionFlag |
        GameObjectDeltaSkipTargetFlag |
        GameObjectDeltaOriginFlag |
        GameObjectDeltaVectorFlag |
        GameObjectDeltaFacingFlag;
    private const int GameRemoteHurtObjectDeltaFlags =
        GameObjectDeltaActorUidFlag |
        GameObjectDeltaTargetUidFlag |
        GameObjectDeltaIntValueFlag |
        GameObjectDeltaFloatValueFlag |
        GameObjectDeltaSubtypeFlag;
    private const int GameRemoteDamageHitObjectDeltaFlags =
        GameObjectDeltaActorUidFlag |
        GameObjectDeltaTargetUidFlag |
        GameObjectDeltaIntValueFlag;
    private const byte GameRemoteShootActionByte = 1;
    private const byte GameRemoteShootSkipTargetMarker = 0xFE;
    private const short GameRemoteHurtSubtype = 73;
    private const int DefaultGameHurtDamage = 100;
    private const int MaxGameHurtDamage = 100000;
    private const float DefaultShootHitRadius = 1.6f;
    private const float ShotgunShootHitRadius = 3.0f;
    private const float MeleeShootHitRadius = 2.2f;
    private const float ShieldShootHitRadius = 2.6f;
    private const float DefaultShootMaxRange = 60f;
    private const float ShotgunShootMaxRange = 15f;
    private const float MeleeShootMaxRange = 2.8f;
    private const float ShieldShootMaxRange = 3.2f;
    private const float ShootFallbackVectorLength = 12f;
    private const float ShootVectorEpsilon = 0.001f;
    private const float FacingRawAngleScale = 8192f;

    // Gameplay tuning knobs. Change these values and restart the server.
    // Weapon fire_time is resolved per weapon resource first, then scaled here.
    // Lower scale/minimum values make weapons fire faster while preserving per-weapon differences.
    private const float WeaponFireTimeScale = 0.1f;
    private const float WeaponFireTimeMinimum = 0.08f;

    // Character movement tuning sent by packet103.
    // The first four fields are read right after maxHealth and copied into actor movement scalars.
    private const short GameCharacterInfoPacketId = 103;
    private const float CharacterWalkSpeed = 5f;
    private const float CharacterRollSlideScale = 8f;
    private const float CharacterJumpAirSpeed = 8f;
    private const float CharacterGravityScale = 2.5f;

    // MoveInfo order starts with unpacked_scripts/AvatarStar/scripts/move_info_d.lua.
    // Native wing/fly code also reads hidden entries after fly_total_time.
    // Index 15 is a fly animation variant selector: 0 plays fly.anim, >0 plays fly%02d.
    // Index 16 enables the hardcoded "takeoff" body animation; 0 falls back to stdjumpup.
    private const float CharacterJump2InitialVelocityX = 2f;
    private const float CharacterJump2InitialVelocityY = 10f;
    private const float CharacterJump2AccelerationX = 0f;
    private const float CharacterJump2AccelerationY = -16.9f;
    private const float CharacterJump2ExtraAccelerationX = 0f;
    private const float CharacterJump2ExtraAccelerationY = 0f;
    private const float CharacterJump2TotalTime = 0.8f;
    private const float CharacterMoveInfoNativeExtra = 1f;
    private const string CharacterWingFlightProfileConfigFileName = "wing_flight_profiles.json";

    private static readonly JsonSerializerOptions CharacterWingFlightProfileJsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        ReadCommentHandling = JsonCommentHandling.Skip,
        AllowTrailingCommas = true
    };

    private sealed record GameLoadoutProperty(string Name, int Value, int MaxValue);

    private sealed record GamePacketPlayer(
        byte Uid,
        long CharacterId,
        string CharacterName,
        byte TeamId,
        byte Career,
        int Level,
        byte RankType,
        int RankLevel,
        int MaxHealth,
        PlayerStore.PlayerState? PlayerState,
        CharacterInfo? Character,
        IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem> LoadoutItems,
        IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem> EquipmentItems,
        IReadOnlyList<PlayerStore.PlayerState.GameIndependentTrinketItem> IndependentTrinketItems,
        PracticeRoomManager.GamePosition? LastPosition);

    private sealed record CharacterFlyMotionProfile(
        string Name,
        float RiseInitialVelocityX,
        float RiseInitialVelocityY,
        float RiseAccelerationX,
        float RiseAccelerationY,
        float RiseExtraAccelerationX,
        float RiseExtraAccelerationY,
        float RiseTotalTime,
        float InitialVelocityX,
        float InitialVelocityY,
        float AccelerationX,
        float AccelerationY,
        float ExtraAccelerationX,
        float ExtraAccelerationY,
        float TotalTime,
        float AnimationVariant,
        float TakeoffAnimationEnabled,
        float Cooldown,
        string? TimeAttribute = null,
        float TimeAttributeScale = 1f,
        float? MinimumTime = null,
        float? MaximumTime = null,
        string? CooldownAttribute = null,
        float CooldownAttributeScale = 1f,
        float? MinimumCooldown = null,
        float? MaximumCooldown = null);

    private sealed record CharacterWingFlightProfileRules(
        string Source,
        string DefaultMode,
        IReadOnlyDictionary<string, CharacterFlyMotionProfile> Profiles,
        IReadOnlyDictionary<string, string> WingModes)
    {
        public CharacterFlyMotionProfile Resolve(IReadOnlyList<string> tokens)
        {
            foreach (var token in tokens)
            {
                if (WingModes.TryGetValue(token, out var mode) &&
                    Profiles.TryGetValue(mode, out var profile))
                {
                    return profile;
                }
            }

            return Profiles.TryGetValue(DefaultMode, out var defaultProfile)
                ? defaultProfile
                : CharacterGlideFlyProfile;
        }
    }

    private sealed class CharacterWingFlightProfileConfig
    {
        public string? DefaultMode { get; set; }

        public Dictionary<string, CharacterWingFlightProfileEntry>? Profiles { get; set; }

        public Dictionary<string, string>? Wings { get; set; }
    }

    private sealed class CharacterWingFlightProfileEntry
    {
        public CharacterWingFlightVectorEntry? Rise { get; set; }

        public CharacterWingFlightVectorEntry? Fly { get; set; }

        public CharacterGlideToFlightEntry? GlideToFlight { get; set; }

        public string? FlyAnimation { get; set; }

        public float? FlyAnim { get; set; }

        public string? TakeoffAnimation { get; set; }

        public float? Takeoff { get; set; }

        public float? Cooldown { get; set; }

        public string? CooldownAttribute { get; set; }

        public float? CooldownScale { get; set; }

        public float? MinCooldown { get; set; }

        public float? MaxCooldown { get; set; }
    }

    private sealed class CharacterWingFlightVectorEntry
    {
        public float? Height { get; set; }

        public float? ForwardSpeed { get; set; }

        public float? Gravity { get; set; }

        public float[]? V0 { get; set; }

        public float[]? A0 { get; set; }

        public float[]? Aa { get; set; }

        public float? Time { get; set; }

        public string? TimeAttribute { get; set; }

        public float? TimeScale { get; set; }

        public float? MinTime { get; set; }

        public float? MaxTime { get; set; }
    }

    private sealed class CharacterGlideToFlightEntry
    {
        public float? GlideSpeed { get; set; }

        public float? FallSpeed { get; set; }

        public float? Duration { get; set; }

        public string? DurationAttribute { get; set; }

        public float? DurationScale { get; set; }

        public float? MinDuration { get; set; }

        public float? MaxDuration { get; set; }

        public float? FlightSpeed { get; set; }

        public float? FinalVerticalSpeed { get; set; }
    }

    private static readonly CharacterFlyMotionProfile CharacterTakeoffOnlyFlyProfile = new(
        "takeoff-only",
        RiseInitialVelocityX: CharacterJump2InitialVelocityX,
        RiseInitialVelocityY: CharacterJump2InitialVelocityY,
        RiseAccelerationX: CharacterJump2AccelerationX,
        RiseAccelerationY: CharacterJump2AccelerationY,
        RiseExtraAccelerationX: CharacterJump2ExtraAccelerationX,
        RiseExtraAccelerationY: CharacterJump2ExtraAccelerationY,
        RiseTotalTime: CharacterJump2TotalTime,
        InitialVelocityX: 0f,
        InitialVelocityY: 0f,
        AccelerationX: 0f,
        AccelerationY: 0f,
        ExtraAccelerationX: 0f,
        ExtraAccelerationY: 0f,
        TotalTime: 2f,
        AnimationVariant: 0f,
        TakeoffAnimationEnabled: 1f,
        Cooldown: 0f);

    private static readonly CharacterFlyMotionProfile CharacterGlideFlyProfile = new(
        "glide",
        RiseInitialVelocityX: CharacterJump2InitialVelocityX,
        RiseInitialVelocityY: CharacterJump2InitialVelocityY,
        RiseAccelerationX: CharacterJump2AccelerationX,
        RiseAccelerationY: CharacterJump2AccelerationY,
        RiseExtraAccelerationX: CharacterJump2ExtraAccelerationX,
        RiseExtraAccelerationY: CharacterJump2ExtraAccelerationY,
        RiseTotalTime: CharacterJump2TotalTime,
        InitialVelocityX: 1f,
        InitialVelocityY: -3f,
        AccelerationX: 0f,
        AccelerationY: 0f,
        ExtraAccelerationX: 1.2f,
        ExtraAccelerationY: 0.1f,
        TotalTime: 8f,
        AnimationVariant: 0f,
        TakeoffAnimationEnabled: 0f,
        Cooldown: 0f);

    private static readonly CharacterFlyMotionProfile CharacterHorizontalFlyProfile = new(
        "horizontal",
        RiseInitialVelocityX: CharacterJump2InitialVelocityX,
        RiseInitialVelocityY: CharacterJump2InitialVelocityY,
        RiseAccelerationX: CharacterJump2AccelerationX,
        RiseAccelerationY: CharacterJump2AccelerationY,
        RiseExtraAccelerationX: CharacterJump2ExtraAccelerationX,
        RiseExtraAccelerationY: CharacterJump2ExtraAccelerationY,
        RiseTotalTime: CharacterJump2TotalTime,
        InitialVelocityX: 8f,
        InitialVelocityY: 0f,
        AccelerationX: 0f,
        AccelerationY: 0f,
        ExtraAccelerationX: 2.4f,
        ExtraAccelerationY: 0f,
        TotalTime: 8f,
        AnimationVariant: 1f,
        TakeoffAnimationEnabled: 0f,
        Cooldown: 0f);

    private static readonly IReadOnlyDictionary<string, CharacterFlyMotionProfile> CharacterDefaultFlyProfiles =
        new Dictionary<string, CharacterFlyMotionProfile>(StringComparer.OrdinalIgnoreCase)
        {
            [CharacterTakeoffOnlyFlyProfile.Name] = CharacterTakeoffOnlyFlyProfile,
            [CharacterGlideFlyProfile.Name] = CharacterGlideFlyProfile,
            [CharacterHorizontalFlyProfile.Name] = CharacterHorizontalFlyProfile
        };

    private static readonly IReadOnlyDictionary<string, string> CharacterDefaultWingFlightModes =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
        {
            ["wing10"] = CharacterTakeoffOnlyFlyProfile.Name,
            ["wing31"] = CharacterTakeoffOnlyFlyProfile.Name,
            ["wing18"] = CharacterHorizontalFlyProfile.Name,
            ["wing32"] = CharacterHorizontalFlyProfile.Name,
            ["wing34"] = CharacterHorizontalFlyProfile.Name,
            ["wing35"] = CharacterHorizontalFlyProfile.Name,
            ["wing36"] = CharacterHorizontalFlyProfile.Name,
            ["wing37"] = CharacterHorizontalFlyProfile.Name,
            ["wing38"] = CharacterHorizontalFlyProfile.Name,
            ["wing40"] = CharacterHorizontalFlyProfile.Name,
            ["wing41"] = CharacterHorizontalFlyProfile.Name,
            ["wing42"] = CharacterHorizontalFlyProfile.Name,
            ["wing43"] = CharacterHorizontalFlyProfile.Name,
            ["wing45"] = CharacterHorizontalFlyProfile.Name
        };

    private static readonly CharacterWingFlightProfileRules CharacterFallbackWingFlightRules = new(
        Source: "built-in",
        DefaultMode: CharacterGlideFlyProfile.Name,
        Profiles: CharacterDefaultFlyProfiles,
        WingModes: CharacterDefaultWingFlightModes);

    private static readonly Lazy<CharacterWingFlightProfileRules> CharacterWingFlightRules = new(
        LoadCharacterWingFlightProfileRules);

    private static CharacterWingFlightProfileRules LoadCharacterWingFlightProfileRules()
    {
        foreach (var configPath in GetCharacterWingFlightProfileConfigCandidates().Distinct(StringComparer.OrdinalIgnoreCase))
        {
            if (!File.Exists(configPath))
            {
                continue;
            }

            try
            {
                var json = File.ReadAllText(configPath, Encoding.UTF8);
                var config = JsonSerializer.Deserialize<CharacterWingFlightProfileConfig>(
                    json,
                    CharacterWingFlightProfileJsonOptions);
                var rules = BuildCharacterWingFlightProfileRules(config, configPath);
                Log.Information(
                    "Wing flight profile config loaded: path={Path} defaultMode={DefaultMode} profiles={ProfileCount} wings={WingCount}",
                    rules.Source,
                    rules.DefaultMode,
                    rules.Profiles.Count,
                    rules.WingModes.Count);
                return rules;
            }
            catch (Exception ex)
            {
                Log.Warning(ex, "Failed to load wing flight profile config from {Path}; using built-in defaults", configPath);
                return CharacterFallbackWingFlightRules;
            }
        }

        Log.Information("Wing flight profile config not found; using built-in defaults");
        return CharacterFallbackWingFlightRules;
    }

    private static CharacterWingFlightProfileRules BuildCharacterWingFlightProfileRules(
        CharacterWingFlightProfileConfig? config,
        string source)
    {
        if (config is null)
        {
            return CharacterFallbackWingFlightRules;
        }

        var profiles = new Dictionary<string, CharacterFlyMotionProfile>(
            CharacterDefaultFlyProfiles,
            StringComparer.OrdinalIgnoreCase);

        if (config.Profiles is not null)
        {
            foreach (var (mode, entry) in config.Profiles)
            {
                var normalizedMode = NormalizeWingFlightMode(mode);
                if (normalizedMode.Length == 0)
                {
                    continue;
                }

                profiles.TryGetValue(normalizedMode, out var baseProfile);
                profiles[normalizedMode] = CreateCharacterFlyMotionProfile(normalizedMode, entry, baseProfile);
            }
        }

        var defaultMode = NormalizeWingFlightMode(config.DefaultMode);
        if (defaultMode.Length == 0 || !profiles.ContainsKey(defaultMode))
        {
            defaultMode = CharacterGlideFlyProfile.Name;
        }

        var wingModes = config.Wings is null
            ? new Dictionary<string, string>(CharacterDefaultWingFlightModes, StringComparer.OrdinalIgnoreCase)
            : new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        if (config.Wings is not null)
        {
            foreach (var (resource, mode) in config.Wings)
            {
                var normalizedMode = NormalizeWingFlightMode(mode);
                if (normalizedMode.Length == 0 || !profiles.ContainsKey(normalizedMode))
                {
                    Log.Warning(
                        "Wing flight profile config ignores resource={Resource} because mode={Mode} is not defined",
                        resource,
                        mode);
                    continue;
                }

                foreach (var token in EnumerateClientResourceTokens(resource))
                {
                    wingModes[token] = normalizedMode;
                }
            }
        }

        return new CharacterWingFlightProfileRules(source, defaultMode, profiles, wingModes);
    }

    private static CharacterFlyMotionProfile CreateCharacterFlyMotionProfile(
        string mode,
        CharacterWingFlightProfileEntry? entry,
        CharacterFlyMotionProfile? baseProfile)
    {
        var rise = ResolveCharacterRiseMotion(entry?.Rise, baseProfile);
        var fly = ResolveCharacterFlyMotion(entry, baseProfile);
        var timeRule = ResolveCharacterFlyTimeRule(entry, baseProfile);
        var cooldownRule = ResolveCharacterFlyCooldownRule(entry, baseProfile);

        return new CharacterFlyMotionProfile(
            mode,
            RiseInitialVelocityX: rise.V0.X,
            RiseInitialVelocityY: rise.V0.Y,
            RiseAccelerationX: rise.A0.X,
            RiseAccelerationY: rise.A0.Y,
            RiseExtraAccelerationX: rise.Aa.X,
            RiseExtraAccelerationY: rise.Aa.Y,
            RiseTotalTime: rise.Time,
            InitialVelocityX: fly.V0.X,
            InitialVelocityY: fly.V0.Y,
            AccelerationX: fly.A0.X,
            AccelerationY: fly.A0.Y,
            ExtraAccelerationX: fly.Aa.X,
            ExtraAccelerationY: fly.Aa.Y,
            TotalTime: fly.Time,
            AnimationVariant: ResolveCharacterFlyAnimationVariant(entry, baseProfile),
            TakeoffAnimationEnabled: ResolveCharacterTakeoffAnimationEnabled(entry, baseProfile),
            Cooldown: entry?.Cooldown ?? baseProfile?.Cooldown ?? 0f,
            TimeAttribute: timeRule.Attribute,
            TimeAttributeScale: timeRule.Scale,
            MinimumTime: timeRule.Minimum,
            MaximumTime: timeRule.Maximum,
            CooldownAttribute: cooldownRule.Attribute,
            CooldownAttributeScale: cooldownRule.Scale,
            MinimumCooldown: cooldownRule.Minimum,
            MaximumCooldown: cooldownRule.Maximum);
    }

    private static (float X, float Y) GetDefaultRiseV0(CharacterFlyMotionProfile? baseProfile)
    {
        return (baseProfile?.RiseInitialVelocityX ?? CharacterJump2InitialVelocityX,
            baseProfile?.RiseInitialVelocityY ?? CharacterJump2InitialVelocityY);
    }

    private static (float X, float Y) GetDefaultRiseA0(CharacterFlyMotionProfile? baseProfile)
    {
        return (baseProfile?.RiseAccelerationX ?? CharacterJump2AccelerationX,
            baseProfile?.RiseAccelerationY ?? CharacterJump2AccelerationY);
    }

    private static (float X, float Y) GetDefaultRiseAa(CharacterFlyMotionProfile? baseProfile)
    {
        return (baseProfile?.RiseExtraAccelerationX ?? CharacterJump2ExtraAccelerationX,
            baseProfile?.RiseExtraAccelerationY ?? CharacterJump2ExtraAccelerationY);
    }

    private static (float X, float Y) GetDefaultFlyV0(CharacterFlyMotionProfile? baseProfile)
    {
        return (baseProfile?.InitialVelocityX ?? 0f, baseProfile?.InitialVelocityY ?? 0f);
    }

    private static (float X, float Y) GetDefaultFlyA0(CharacterFlyMotionProfile? baseProfile)
    {
        return (baseProfile?.AccelerationX ?? 0f, baseProfile?.AccelerationY ?? 0f);
    }

    private static (float X, float Y) GetDefaultFlyAa(CharacterFlyMotionProfile? baseProfile)
    {
        return (baseProfile?.ExtraAccelerationX ?? 0f, baseProfile?.ExtraAccelerationY ?? 0f);
    }

    private static ((float X, float Y) V0, (float X, float Y) A0, (float X, float Y) Aa, float Time) ResolveCharacterRiseMotion(
        CharacterWingFlightVectorEntry? rise,
        CharacterFlyMotionProfile? baseProfile)
    {
        var defaultV0 = GetDefaultRiseV0(baseProfile);
        var defaultA0 = GetDefaultRiseA0(baseProfile);
        var defaultAa = GetDefaultRiseAa(baseProfile);
        var v0 = ReadVector2(rise?.V0, defaultV0.X, defaultV0.Y);
        var a0 = ReadVector2(rise?.A0, defaultA0.X, defaultA0.Y);
        var aa = ReadVector2(rise?.Aa, defaultAa.X, defaultAa.Y);
        var time = rise?.Time ?? baseProfile?.RiseTotalTime ?? CharacterJump2TotalTime;

        if (rise?.ForwardSpeed is not null)
        {
            v0.X = rise.ForwardSpeed.Value;
        }

        if (rise?.Gravity is not null)
        {
            a0.Y = rise.Gravity.Value;
        }

        if (rise?.Height is not null && time > 0f)
        {
            v0.Y = (rise.Height.Value - (0.5f * a0.Y * time * time)) / time;
        }

        return (v0, a0, aa, time);
    }

    private static (string? Attribute, float Scale, float? Minimum, float? Maximum) ResolveCharacterFlyTimeRule(
        CharacterWingFlightProfileEntry? entry,
        CharacterFlyMotionProfile? baseProfile)
    {
        if (!string.IsNullOrWhiteSpace(entry?.GlideToFlight?.DurationAttribute))
        {
            return (
                entry.GlideToFlight.DurationAttribute,
                entry.GlideToFlight.DurationScale ?? baseProfile?.TimeAttributeScale ?? 1f,
                entry.GlideToFlight.MinDuration ?? baseProfile?.MinimumTime,
                entry.GlideToFlight.MaxDuration ?? baseProfile?.MaximumTime);
        }

        if (!string.IsNullOrWhiteSpace(entry?.Fly?.TimeAttribute))
        {
            return (
                entry.Fly.TimeAttribute,
                entry.Fly.TimeScale ?? baseProfile?.TimeAttributeScale ?? 1f,
                entry.Fly.MinTime ?? baseProfile?.MinimumTime,
                entry.Fly.MaxTime ?? baseProfile?.MaximumTime);
        }

        return (
            baseProfile?.TimeAttribute,
            baseProfile?.TimeAttributeScale ?? 1f,
            baseProfile?.MinimumTime,
            baseProfile?.MaximumTime);
    }

    private static (string? Attribute, float Scale, float? Minimum, float? Maximum) ResolveCharacterFlyCooldownRule(
        CharacterWingFlightProfileEntry? entry,
        CharacterFlyMotionProfile? baseProfile)
    {
        if (!string.IsNullOrWhiteSpace(entry?.CooldownAttribute))
        {
            return (
                entry.CooldownAttribute,
                entry.CooldownScale ?? baseProfile?.CooldownAttributeScale ?? 1f,
                entry.MinCooldown ?? baseProfile?.MinimumCooldown,
                entry.MaxCooldown ?? baseProfile?.MaximumCooldown);
        }

        return (
            baseProfile?.CooldownAttribute,
            baseProfile?.CooldownAttributeScale ?? 1f,
            baseProfile?.MinimumCooldown,
            baseProfile?.MaximumCooldown);
    }


    private static ((float X, float Y) V0, (float X, float Y) A0, (float X, float Y) Aa, float Time) ResolveCharacterFlyMotion(
        CharacterWingFlightProfileEntry? entry,
        CharacterFlyMotionProfile? baseProfile)
    {
        var defaultV0 = GetDefaultFlyV0(baseProfile);
        var defaultA0 = GetDefaultFlyA0(baseProfile);
        var defaultAa = GetDefaultFlyAa(baseProfile);
        var v0 = ReadVector2(entry?.Fly?.V0, defaultV0.X, defaultV0.Y);
        var a0 = ReadVector2(entry?.Fly?.A0, defaultA0.X, defaultA0.Y);
        var aa = ReadVector2(entry?.Fly?.Aa, defaultAa.X, defaultAa.Y);
        var time = entry?.Fly?.Time ?? baseProfile?.TotalTime ?? 0f;

        if (entry?.GlideToFlight is null)
        {
            return (v0, a0, aa, time);
        }

        var transition = entry.GlideToFlight;
        var duration = transition.Duration ?? time;
        if (duration <= 0f)
        {
            duration = 0.1f;
        }

        var glideSpeed = transition.GlideSpeed ?? v0.X;
        var fallSpeed = Math.Abs(transition.FallSpeed ?? Math.Max(0f, -v0.Y));
        var initialVerticalSpeed = -fallSpeed;
        var flightSpeed = transition.FlightSpeed ?? (glideSpeed + (aa.X * duration));
        var finalVerticalSpeed = transition.FinalVerticalSpeed ?? 0f;

        v0 = (glideSpeed, initialVerticalSpeed);
        a0 = (0f, 0f);
        aa = ((flightSpeed - glideSpeed) / duration, (finalVerticalSpeed - initialVerticalSpeed) / duration);
        time = duration;

        return (v0, a0, aa, time);
    }

    private static float ResolveCharacterFlyAnimationVariant(
        CharacterWingFlightProfileEntry? entry,
        CharacterFlyMotionProfile? baseProfile)
    {
        if (!string.IsNullOrWhiteSpace(entry?.FlyAnimation))
        {
            return ParseCharacterFlyAnimationVariant(entry.FlyAnimation, baseProfile?.AnimationVariant ?? 0f);
        }

        return entry?.FlyAnim ?? baseProfile?.AnimationVariant ?? 0f;
    }

    private static float ResolveCharacterTakeoffAnimationEnabled(
        CharacterWingFlightProfileEntry? entry,
        CharacterFlyMotionProfile? baseProfile)
    {
        if (!string.IsNullOrWhiteSpace(entry?.TakeoffAnimation))
        {
            return ParseCharacterTakeoffAnimationEnabled(entry.TakeoffAnimation, baseProfile?.TakeoffAnimationEnabled ?? 0f);
        }

        return entry?.Takeoff ?? baseProfile?.TakeoffAnimationEnabled ?? 0f;
    }

    private static float ParseCharacterFlyAnimationVariant(string animation, float fallback)
    {
        var normalized = animation.Trim();
        if (normalized.Equals("fly", StringComparison.OrdinalIgnoreCase))
        {
            return 0f;
        }

        if (normalized.StartsWith("fly", StringComparison.OrdinalIgnoreCase) &&
            int.TryParse(normalized[3..], NumberStyles.Integer, CultureInfo.InvariantCulture, out var flyIndex))
        {
            return Math.Max(0, flyIndex);
        }

        return float.TryParse(normalized, NumberStyles.Float, CultureInfo.InvariantCulture, out var parsed)
            ? Math.Max(0f, parsed)
            : fallback;
    }

    private static float ParseCharacterTakeoffAnimationEnabled(string animation, float fallback)
    {
        var normalized = animation.Trim();
        if (normalized.Equals("takeoff", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("true", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("on", StringComparison.OrdinalIgnoreCase))
        {
            return 1f;
        }

        if (normalized.Equals("stdjumpup", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("stdjump", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("jumpup", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("fallback", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("false", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("off", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("none", StringComparison.OrdinalIgnoreCase))
        {
            return 0f;
        }

        return float.TryParse(normalized, NumberStyles.Float, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : fallback;
    }

    private static (float X, float Y) ReadVector2(float[]? values, float defaultX, float defaultY)
    {
        return values is { Length: >= 2 }
            ? (values[0], values[1])
            : (defaultX, defaultY);
    }

    private static string NormalizeWingFlightMode(string? mode)
    {
        return (mode ?? string.Empty).Trim();
    }

    private static IEnumerable<string> GetCharacterWingFlightProfileConfigCandidates()
    {
        yield return Path.Combine(AppContext.BaseDirectory, "Config", CharacterWingFlightProfileConfigFileName);
        yield return Path.Combine(Directory.GetCurrentDirectory(), "Config", CharacterWingFlightProfileConfigFileName);
        yield return Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Config", CharacterWingFlightProfileConfigFileName);
    }

    private sealed record GameWeaponRuntimeStats(
        float CoolDown,
        float FireTime,
        float Range,
        int AmmoOneClip,
        float ShotSpread,
        int ShootBulletCount,
        bool HasExplosionRadius,
        float ExplodeTime,
        float ReadyTime,
        float ThrowOutTime,
        float Gravity,
        float OwnerType,
        float TrajectoryValue,
        float ExplodeParticleHasBuff,
        float ExtraProjectileValue0,
        float ExtraProjectileValue1,
        float ExtraProjectileValue2);

    private static readonly string[] AvatarBlobKeys =
    {
        "skin",
        "eye",
        "mouth",
        "nose",
        "ear",
        "beard",
        "hair",
        "helmet",
        "underwear",
        "outerwear",
        "trousers",
        "glove",
        "shoes",
        "decal",
        "movable",
        "immobile",
        "immobileUp",
        "immobileDown"
    };

    private readonly PracticeRoomManager _practiceRoomManager;
    private readonly PlayerStore _playerStore;
    private readonly Func<byte[], Task> _sendPayloadAsync;
    private readonly string _remoteLabel;
    private readonly IPAddress _remoteAddress;
    private readonly SemaphoreSlim _sendLock = new(1, 1);

    private ChannelState _state = ChannelState.AwaitClientSeed;
    private int _currentRoomId;
    private uint _xorInState;
    private uint _xorOutState;
    private int _playerEnteringClearRetriesRemaining;
    private int _silentLoadoutHudRefreshRetriesRemaining;
    private bool _localPlayerEnterPacketSent;
    private bool _localPlayerEnterBroadcastSent;
    private int _gameInitSpawnHandshakeStarted;
    private int _gameInitSpawnHandshakeGeneration;
    private int _activeClientGameInitRefreshSent;
    private long _candidateCharacterId;
    private long _currentCharacterId;
    private byte _localGameUid = LocalGameUid;
    private byte _currentWeaponSlot;
    private byte _previousWeaponSlot;
    private PracticeRoomManager.PracticeRoomSession? _currentGameRoom;
    private readonly HashSet<byte> _knownGamePlayerUids = new();
    private readonly Dictionary<byte, DateTimeOffset> _lastSpecialWeaponRearmBySlot = new();
    private CancellationTokenSource? _knifeAutoRearmCts;
    private int _movementDebugSamplesRemaining = MovementDebugSampleLogLimit;
    private byte _lastGameMovementInputByte;
    private byte _lastGameMovementTick;
    private bool _hasLastGameMovementInputByte;
    private int? _setHealthOverride;
    private float? _setWalkSpeedOverride;
    private float? _setJumpHeightOverride;
    private readonly Dictionary<long, int> _setBulletAmmoOneClipOverridesByItemId = new();

    public PracticeRoomChannelProtocol(
        PracticeRoomManager practiceRoomManager,
        PlayerStore playerStore,
        Func<byte[], Task> sendPayloadAsync,
        IPAddress remoteAddress,
        string remoteLabel)
    {
        _practiceRoomManager = practiceRoomManager;
        _playerStore = playerStore;
        _sendPayloadAsync = sendPayloadAsync;
        _remoteAddress = remoteAddress;
        _remoteLabel = remoteLabel;
    }

    public async Task HandleAsync(PacketReader reader)
    {
        if (_state == ChannelState.AwaitClientSeed)
        {
            await HandleClientSeedAsync(reader);
            return;
        }

        XorNetworkCodec.DecodeInPlace(reader.Data, ref _xorInState);
        await HandleDecodedAsync(reader);
    }

    public void OnClientDisconnected()
    {
        _ = CleanupAfterDisconnectAsync();
    }

    private async Task CleanupAfterDisconnectAsync()
    {
        try
        {
            await CleanupRoomStateAsync(sendLeaveAck: false, trigger: "disconnect");
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Channel disconnect cleanup failed from {Remote}", _remoteLabel);
        }
    }

    private async Task HandleClientSeedAsync(PacketReader reader)
    {
        // The channel seed packet itself is still XORed with the fixed initial states.
        // Only after exchanging the one-byte seeds do both sides reset to CRC32_TABLE[seed].
        var initialInState = XorInInitial;
        XorNetworkCodec.DecodeInPlace(reader.Data, ref initialInState);

        if (!reader.TryReadByte(out var clientSeed))
        {
            Log.Warning("Channel handshake failed from {Remote}: missing client seed payload", _remoteLabel);
            return;
        }

        _xorInState = XorNetworkCodec.SeedState(clientSeed);

        var serverSeedPayload = new[] { DefaultServerSeed };
        var initialOutState = XorOutInitial;
        XorNetworkCodec.EncodeInPlace(serverSeedPayload.AsSpan(), ref initialOutState);
        await _sendPayloadAsync(serverSeedPayload);

        _xorOutState = XorNetworkCodec.SeedState(DefaultServerSeed);
        _state = ChannelState.AwaitClientHello;

        Log.Information(
            "Channel handshake accepted from {Remote}: clientSeed=0x{ClientSeed:X2} serverSeed=0x{ServerSeed:X2}",
            _remoteLabel,
            clientSeed,
            DefaultServerSeed);
    }

    private async Task HandleDecodedAsync(PacketReader reader)
    {
        if (!reader.TryReadShort(out var packetId))
        {
            Log.Warning("Channel packet parse failed from {Remote}: missing opcode", _remoteLabel);
            return;
        }

        switch (_state)
        {
            case ChannelState.AwaitClientHello when packetId == 0:
                await HandleClientHelloAsync(reader);
                break;
            case ChannelState.AwaitRoomEnter when packetId == 2:
                await HandlePacket2RoomEnterAsync(reader);
                break;
            case ChannelState.InRoom when packetId == 3:
                await HandlePacket3LeaveRoomAsync(reader);
                break;
            case ChannelState.InRoom when packetId == 6:
                await HandlePacket6RoomChangeOptionAsync(reader);
                break;
            case ChannelState.InRoom when packetId == 8:
                await HandlePacket8RoomReadyAsync(reader);
                break;
            case ChannelState.InRoom when packetId == 10:
                await HandlePacket10StartGameAsync(reader);
                break;
            case ChannelState.InRoom when packetId == 12:
                await HandlePacket12ChangeSlotAsync(reader);
                break;
            case ChannelState.InRoom when packetId == 100:
                await HandlePacket100EnterGameAsync(reader);
                break;
            case ChannelState.InGame when packetId == 3:
                await HandlePacket3LeaveRoomAsync(reader);
                break;
            case ChannelState.InGame when packetId == 100:
                await HandlePacket100DuplicateEnterGameAsync(reader);
                break;
            case ChannelState.InGame when packetId == 102:
                await HandlePacket102InGameChatAsync(reader);
                break;
            case ChannelState.InGame when packetId == 103:
                await HandlePacket103GameCharacterRequestAsync(reader);
                break;
            case ChannelState.InGame when packetId == 104:
                await HandlePacket104GamePingAsync(reader);
                break;
            case ChannelState.InGame when packetId == 105:
                await HandlePacket105GameSyncAsync(reader);
                break;
            case ChannelState.InGame when packetId == 106:
                await HandlePacket106GameActionPoseAsync(reader);
                break;
            case ChannelState.InGame when packetId == 112:
                await HandlePacket112GameActionVectorAsync(reader);
                break;
            case ChannelState.InGame when packetId == 113:
                await HandlePacket113GameActionScalarAsync(reader);
                break;
            case ChannelState.InGame when packetId == 117:
                await HandlePacket117GameReloadAsync(reader);
                break;
            case ChannelState.InGame when packetId == 118:
                await HandlePacket118GameDropWeaponAsync(reader);
                break;
            case ChannelState.InGame when packetId == 120:
                await HandlePacket120GameClientNotifyAsync(reader);
                break;
            case ChannelState.InGame when packetId == 125:
                HandlePacket125GamePickUpDropItem(reader);
                break;
            case ChannelState.InGame when packetId == 121:
                await HandlePacket121LeaveGameAsync(reader);
                break;
            case ChannelState.InGame when packetId == 137:
                await HandlePacket137GameClientReadyAsync(reader);
                break;
            case ChannelState.InGame when packetId == 141:
                await HandlePacket141GameSpawnReadyAsync(reader);
                break;
            case ChannelState.InGame when packetId == 142:
                await HandlePacket142GameReloadReadyAsync(reader);
                break;
            case ChannelState.InGame when packetId == 143:
                await HandlePacket143GameActionStateAsync(reader);
                break;
            case ChannelState.InGame when packetId == 156:
                await HandlePacket156GameInfoOverlayRequestAsync(reader);
                break;
            case ChannelState.InGame when packetId == 162:
                await HandlePacket162ConfirmRefreshBornPointAsync(reader);
                break;
            case ChannelState.InGame when packetId == 157:
                HandlePacket157GameClientNoPayload(reader);
                break;
            default:
                if (_state == ChannelState.InGame)
                {
                    var payload = reader.RemainingSpan.ToArray();
                    if (TryExtractSlashCommand(payload, out var command) &&
                        await TryHandleInGameCommandAsync(packetId, command))
                    {
                        break;
                    }
                }

                Log.Warning(
                    "Unhandled channel packet state={State} packetId={PacketId} remaining={Remaining} remote={Remote}",
                    _state,
                    packetId,
                    reader.Remaining,
                    _remoteLabel);
                break;
        }
    }

    private async Task HandlePacket102InGameChatAsync(PacketReader reader)
    {
        var payload = reader.RemainingSpan.ToArray();
        if (payload.Length > 0)
        {
            _ = reader.TryReadFixedBytes(payload.Length, out _);
        }

        if (TryExtractSlashCommand(payload, out var command) &&
            await TryHandleInGameCommandAsync(102, command))
        {
            return;
        }

        var preview = TryExtractUtf8Text(payload, out var text)
            ? text
            : HexDump.Dump(payload, 32).TrimEnd();
        Log.Debug(
            "Channel packet102 <- {Remote}: in-game chat consumed len={Length} preview={Preview}",
            _remoteLabel,
            payload.Length,
            preview);
    }

    private async Task<bool> TryHandleInGameCommandAsync(short packetId, string command)
    {
        if (IsSetCommand(command))
        {
            return await TryHandleSetCommandAsync(packetId, command);
        }

        if (!IsTeleportCommand(command))
        {
            return false;
        }

        var args = command.Length <= TeleportCommandName.Length
            ? string.Empty
            : command[TeleportCommandName.Length..].Trim();
        if (args.Length == 0)
        {
            Log.Warning(
                "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=missing-target",
                _remoteLabel,
                packetId,
                command);
            return true;
        }

        if (_currentGameRoom is null)
        {
            Log.Warning(
                "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=no-active-room",
                _remoteLabel,
                packetId,
                command);
            return true;
        }

        var currentPosition = TryGetLocalGamePosition(out var localPosition)
            ? localPosition
            : (PracticeRoomManager.GamePosition?)null;
        if (TryParseTeleportCoordinates(args, currentPosition, out var coordinates, out var usesRelativeCoordinates))
        {
            await TeleportLocalPlayerToAsync(coordinates, packetId);
            return true;
        }

        if (usesRelativeCoordinates)
        {
            Log.Warning(
                "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=invalid-relative-coordinates currentPositionKnown={CurrentPositionKnown}",
                _remoteLabel,
                packetId,
                command,
                currentPosition.HasValue);
            return true;
        }

        if (!_practiceRoomManager.TryFindGamePlayerPositionByName(
                _currentGameRoom.RoomId,
                args,
                out var target))
        {
            Log.Warning(
                "In-game command ignored from {Remote}: packetId={PacketId} command={Command} target={Target} reason=target-not-found-or-no-position",
                _remoteLabel,
                packetId,
                command,
                args);
            return true;
        }

        await TeleportLocalPlayerToAsync(target, packetId);
        return true;
    }

    private bool TryGetLocalGamePosition(out PracticeRoomManager.GamePosition position)
    {
        position = default;

        if (_currentGameRoom is null ||
            !_practiceRoomManager.TryFindGamePlayerPositionByName(
                _currentGameRoom.RoomId,
                _localGameUid.ToString(CultureInfo.InvariantCulture),
                out var playerPosition))
        {
            return false;
        }

        position = playerPosition.Position;
        return true;
    }

    private async Task TeleportLocalPlayerToAsync(
        PracticeRoomManager.GamePlayerPosition target,
        short packetId)
    {
        if (_currentGameRoom is null)
        {
            return;
        }

        var now = DateTimeOffset.UtcNow;
        var position = target.Position with { LastSeenAt = now };
        await SendPacket111GameTeleportAsync(
            RawToWorldCoordinate(position.XRaw),
            RawToWorldCoordinate(position.YRaw),
            RawToWorldCoordinate(position.ZRaw),
            0f,
            "nickname");
        var broadcastCount = await ApplyLocalTeleportAsync(position, now);

        Log.Information(
            "In-game command {Command} handled from {Remote}: packetId={PacketId} localUid={LocalUid} target={TargetName} targetUid={TargetUid} positionRaw=({X},{Y},{Z}) positionWorld=({WorldX},{WorldY},{WorldZ}) yawRaw={Yaw} facingRaw=({Facing0},{Facing1}) broadcastCount={BroadcastCount}",
            TeleportCommandName,
            _remoteLabel,
            packetId,
            _localGameUid,
            target.CharacterName,
            target.Uid,
            position.XRaw,
            position.YRaw,
            position.ZRaw,
            FormatProtocolFloat(RawToWorldCoordinate(position.XRaw)),
            FormatProtocolFloat(RawToWorldCoordinate(position.YRaw)),
            FormatProtocolFloat(RawToWorldCoordinate(position.ZRaw)),
            position.YawRaw?.ToString(CultureInfo.InvariantCulture) ?? "-",
            position.Facing0Raw?.ToString(CultureInfo.InvariantCulture) ?? "-",
            position.Facing1Raw?.ToString(CultureInfo.InvariantCulture) ?? "-",
            broadcastCount);
    }

    private async Task TeleportLocalPlayerToAsync(
        TeleportCoordinates target,
        short packetId)
    {
        if (_currentGameRoom is null)
        {
            return;
        }

        var now = DateTimeOffset.UtcNow;
        var position = target.Position with { LastSeenAt = now };
        var coordinateSource = target.Relative ? "relative-coordinates" : "coordinates";
        await SendPacket111GameTeleportAsync(target.X, target.Y, target.Z, 0f, coordinateSource);
        var broadcastCount = await ApplyLocalTeleportAsync(position, now);

        Log.Information(
            "In-game command {Command} handled from {Remote}: packetId={PacketId} localUid={LocalUid} source={Source} positionWorld=({WorldX},{WorldY},{WorldZ}) positionRaw=({X},{Y},{Z}) yawRaw={Yaw} facingRaw=({Facing0},{Facing1}) broadcastCount={BroadcastCount}",
            TeleportCommandName,
            _remoteLabel,
            packetId,
            _localGameUid,
            coordinateSource,
            FormatProtocolFloat(target.X),
            FormatProtocolFloat(target.Y),
            FormatProtocolFloat(target.Z),
            position.XRaw,
            position.YRaw,
            position.ZRaw,
            position.YawRaw?.ToString(CultureInfo.InvariantCulture) ?? "-",
            position.Facing0Raw?.ToString(CultureInfo.InvariantCulture) ?? "-",
            position.Facing1Raw?.ToString(CultureInfo.InvariantCulture) ?? "-",
            broadcastCount);
    }

    private async Task<int> ApplyLocalTeleportAsync(
        PracticeRoomManager.GamePosition position,
        DateTimeOffset now)
    {
        if (_currentGameRoom is null)
        {
            return 0;
        }

        var (flags, optionalPayload) = BuildTeleportMovementPayload(position);
        var movement = new PracticeRoomManager.GameMovementDelta(
            _localGameUid,
            NextGameMovementTick(),
            flags,
            optionalPayload,
            now);

        await SendPacket110GameMovementAsync(movement);
        _practiceRoomManager.UpdateGameMovement(_currentGameRoom.RoomId, movement);
        _practiceRoomManager.UpdateGamePosition(_currentGameRoom.RoomId, _localGameUid, position);

        return await _practiceRoomManager.BroadcastGameMovementAsync(
            _currentGameRoom.RoomId,
            this,
            movement);
    }

    private byte NextGameMovementTick()
    {
        unchecked
        {
            _lastGameMovementTick = (byte)(_lastGameMovementTick + 1);
        }

        return _lastGameMovementTick;
    }

    private static bool IsTeleportCommand(string command)
    {
        if (!command.StartsWith(TeleportCommandName, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return command.Length == TeleportCommandName.Length ||
            char.IsWhiteSpace(command[TeleportCommandName.Length]);
    }

    private static bool IsSetCommand(string command)
    {
        if (!command.StartsWith(SetCommandName, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return command.Length == SetCommandName.Length ||
            char.IsWhiteSpace(command[SetCommandName.Length]);
    }

    private static bool TryParseTeleportCoordinates(
        string args,
        PracticeRoomManager.GamePosition? currentPosition,
        out TeleportCoordinates coordinates,
        out bool usesRelativeCoordinates)
    {
        coordinates = default;
        usesRelativeCoordinates = false;

        var parts = args.Split(
            [' ', ',', '\t'],
            StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (parts.Length != 3)
        {
            return false;
        }

        usesRelativeCoordinates = IsRelativeCoordinate(parts[0]) ||
            IsRelativeCoordinate(parts[1]) ||
            IsRelativeCoordinate(parts[2]);
        if (usesRelativeCoordinates && currentPosition is null)
        {
            return false;
        }

        var currentX = currentPosition.HasValue ? RawToWorldCoordinate(currentPosition.Value.XRaw) : 0f;
        var currentY = currentPosition.HasValue ? RawToWorldCoordinate(currentPosition.Value.YRaw) : 0f;
        var currentZ = currentPosition.HasValue ? RawToWorldCoordinate(currentPosition.Value.ZRaw) : 0f;
        if (!TryParseWorldCoordinateComponent(parts[0], currentX, out var x) ||
            !TryParseWorldCoordinateComponent(parts[1], currentY, out var y) ||
            !TryParseWorldCoordinateComponent(parts[2], currentZ, out var z))
        {
            return false;
        }

        var xRaw = WorldToRawCoordinate(x);
        var yRaw = WorldToRawCoordinate(y);
        var zRaw = WorldToRawCoordinate(z);
        var position = new PracticeRoomManager.GamePosition(
            xRaw,
            yRaw,
            zRaw,
            null,
            null,
            null,
            DateTimeOffset.UtcNow);
        coordinates = new TeleportCoordinates(
            RawToWorldCoordinate(xRaw),
            RawToWorldCoordinate(yRaw),
            RawToWorldCoordinate(zRaw),
            usesRelativeCoordinates,
            position);
        return true;
    }

    private static bool TryParseWorldCoordinateComponent(
        string value,
        float currentCoordinate,
        out float coordinate)
    {
        coordinate = 0f;

        if (IsRelativeCoordinate(value))
        {
            var offsetText = value[1..];
            if (offsetText.Length == 0)
            {
                coordinate = currentCoordinate;
                return true;
            }

            if (!TryParseWorldCoordinate(offsetText, out var offset))
            {
                return false;
            }

            coordinate = currentCoordinate + offset;
            return true;
        }

        return TryParseWorldCoordinate(value, out coordinate);
    }

    private static bool TryParseWorldCoordinate(string value, out float coordinate)
    {
        coordinate = 0f;

        if (!float.TryParse(
                value,
                NumberStyles.Float,
                CultureInfo.InvariantCulture,
                out var parsed) ||
            float.IsNaN(parsed) ||
            float.IsInfinity(parsed))
        {
            return false;
        }

        coordinate = parsed;
        return true;
    }

    private static bool IsRelativeCoordinate(string value)
    {
        return value.StartsWith("~", StringComparison.Ordinal);
    }

    private static short WorldToRawCoordinate(float coordinate)
    {
        var rounded = MathF.Round(coordinate * MovementRawCoordinateScale, MidpointRounding.AwayFromZero);
        var clamped = Math.Clamp(rounded, short.MinValue, short.MaxValue);
        return (short)clamped;
    }

    private static float RawToWorldCoordinate(short raw)
    {
        return raw / MovementRawCoordinateScale;
    }

    private static bool TryExtractSlashCommand(byte[] payload, out string command)
    {
        const int MaxCommandBytes = 256;
        command = string.Empty;

        for (var offset = 0; offset <= payload.Length - sizeof(int); offset++)
        {
            var length =
                payload[offset] |
                (payload[offset + 1] << 8) |
                (payload[offset + 2] << 16) |
                (payload[offset + 3] << 24);
            if (length <= 0 || length > MaxCommandBytes || offset + sizeof(int) + length > payload.Length)
            {
                continue;
            }

            var candidate = Encoding.UTF8.GetString(payload, offset + sizeof(int), length).Trim();
            if (candidate.StartsWith("/", StringComparison.Ordinal))
            {
                command = candidate;
                return true;
            }
        }

        for (var offset = 0; offset <= payload.Length - sizeof(short); offset++)
        {
            var length = payload[offset] | (payload[offset + 1] << 8);
            if (length <= 0 || length > MaxCommandBytes || offset + sizeof(short) + length > payload.Length)
            {
                continue;
            }

            var candidate = Encoding.UTF8.GetString(payload, offset + sizeof(short), length).Trim();
            if (candidate.StartsWith("/", StringComparison.Ordinal))
            {
                command = candidate;
                return true;
            }
        }

        for (var offset = 0; offset < payload.Length; offset++)
        {
            var length = (int)payload[offset];
            if (length <= 0 || length > MaxCommandBytes || offset + 1 + length > payload.Length)
            {
                continue;
            }

            var candidate = Encoding.UTF8.GetString(payload, offset + 1, length).Trim();
            if (candidate.StartsWith("/", StringComparison.Ordinal))
            {
                command = candidate;
                return true;
            }
        }

        for (var start = 0; start < payload.Length; start++)
        {
            if (payload[start] != (byte)'/')
            {
                continue;
            }

            var end = start + 1;
            while (end < payload.Length &&
                   end - start < MaxCommandBytes &&
                   payload[end] != 0 &&
                   (payload[end] >= 0x20 || payload[end] >= 0x80))
            {
                end++;
            }

            var candidate = Encoding.UTF8.GetString(payload, start, end - start).Trim();
            if (candidate.StartsWith("/", StringComparison.Ordinal))
            {
                command = candidate;
                return true;
            }
        }

        return false;
    }

    private static bool TryExtractUtf8Text(byte[] payload, out string text)
    {
        text = string.Empty;
        const int MaxTextBytes = 256;

        for (var offset = 0; offset <= payload.Length - sizeof(int); offset++)
        {
            var length =
                payload[offset] |
                (payload[offset + 1] << 8) |
                (payload[offset + 2] << 16) |
                (payload[offset + 3] << 24);
            if (length <= 0 || length > MaxTextBytes || offset + sizeof(int) + length > payload.Length)
            {
                continue;
            }

            text = Encoding.UTF8.GetString(payload, offset + sizeof(int), length).Trim();
            return text.Length > 0;
        }

        for (var offset = 0; offset <= payload.Length - sizeof(short); offset++)
        {
            var length = payload[offset] | (payload[offset + 1] << 8);
            if (length <= 0 || length > MaxTextBytes || offset + sizeof(short) + length > payload.Length)
            {
                continue;
            }

            text = Encoding.UTF8.GetString(payload, offset + sizeof(short), length).Trim();
            return text.Length > 0;
        }

        for (var offset = 0; offset < payload.Length; offset++)
        {
            var length = (int)payload[offset];
            if (length <= 0 || length > MaxTextBytes || offset + 1 + length > payload.Length)
            {
                continue;
            }

            text = Encoding.UTF8.GetString(payload, offset + 1, length).Trim();
            return text.Length > 0;
        }

        var start = Array.FindIndex(payload, b => b >= 0x20);
        if (start < 0)
        {
            return false;
        }

        var end = start;
        while (end < payload.Length &&
               end - start < MaxTextBytes &&
               payload[end] != 0 &&
               (payload[end] >= 0x20 || payload[end] >= 0x80))
        {
            end++;
        }

        text = Encoding.UTF8.GetString(payload, start, end - start).Trim();
        return text.Length > 0;
    }

    private static (byte Flags, byte[] OptionalPayload) BuildTeleportMovementPayload(
        PracticeRoomManager.GamePosition position)
    {
        var flags = (byte)0x04;
        var payload = new List<byte>(12);

        if (position.YawRaw.HasValue)
        {
            flags |= 0x08;
            WriteInt16LittleEndian(payload, position.YawRaw.Value);
        }

        WriteInt16LittleEndian(payload, position.XRaw);
        WriteInt16LittleEndian(payload, position.YRaw);
        WriteInt16LittleEndian(payload, position.ZRaw);

        if (position.Facing0Raw.HasValue && position.Facing1Raw.HasValue)
        {
            flags |= 0x02;
            WriteInt16LittleEndian(payload, position.Facing0Raw.Value);
            WriteInt16LittleEndian(payload, position.Facing1Raw.Value);
        }

        return (flags, payload.ToArray());
    }

    private static void WriteInt16LittleEndian(List<byte> payload, short value)
    {
        var raw = unchecked((ushort)value);
        payload.Add((byte)raw);
        payload.Add((byte)(raw >> 8));
    }

    private async Task HandleClientHelloAsync(PacketReader reader)
    {
        var helloInt = reader.TryReadInt(out var tempInt) ? tempInt : 0;
        var helloLong = reader.TryReadLong(out var tempLong) ? tempLong : 0;
        _candidateCharacterId = ResolveCandidateCharacterId(helloLong, helloInt);

        Log.Information(
            "Channel hello from {Remote}: value0={HelloInt} value1={HelloLong} candidateCharacterId={CandidateCharacterId}",
            _remoteLabel,
            helloInt,
            helloLong,
            _candidateCharacterId);

        await SendPacket15Async();
        _state = ChannelState.AwaitRoomEnter;
    }

    private async Task HandlePacket2RoomEnterAsync(PacketReader reader)
    {
        if (!AvatarStarClientProtocol.TryReadChannelRoomEnter(reader, out var enterRoom))
        {
            Log.Warning("Channel packet2 parse failed from {Remote}", _remoteLabel);
            await SendPacket16RoomEnterResultAsync(null, resultCode: 1);
            return;
        }

        Log.Information(
            "Channel enter room request from {Remote}: roomId={RoomId} token={Token} capability={Capability} hasCapability={HasCapability}",
            _remoteLabel,
            enterRoom.RoomId,
            enterRoom.Token,
            enterRoom.Capability,
            enterRoom.HasCapability);

        if (!_practiceRoomManager.TryGetByRoomId(enterRoom.RoomId, out var pendingRoom))
        {
            await SendPacket16RoomEnterResultAsync(null, resultCode: 1);
            return;
        }

        var enterRequest = ResolveEnteringPlayer(enterRoom, pendingRoom);

        if (!_practiceRoomManager.TryEnterRoom(
                enterRoom.RoomId,
                enterRoom.Password,
                enterRequest,
                out var room,
                out var resultCode))
        {
            await SendPacket16RoomEnterResultAsync(null, resultCode);
            return;
        }

        _currentRoomId = room.RoomId;
        _currentCharacterId = enterRequest.CharacterId;
        _practiceRoomManager.RegisterRoomChannel(room.RoomId, this, _currentCharacterId);

        await SendPacket16RoomEnterResultAsync(room, resultCode: 0);
        await _practiceRoomManager.BroadcastRoomSnapshotAsync(room.RoomId);
        _state = ChannelState.InRoom;
    }

    private async Task HandlePacket3LeaveRoomAsync(PacketReader reader)
    {
        Log.Information(
            "Channel leave room request from {Remote}: roomId={RoomId} remaining={Remaining}",
            _remoteLabel,
            _currentRoomId,
            reader.Remaining);

        await CleanupRoomStateAsync(sendLeaveAck: true, trigger: "packet3-leave-room");
    }

    private async Task CleanupRoomStateAsync(bool sendLeaveAck, string trigger)
    {
        if (_currentRoomId != 0)
        {
            await CleanupGameStateAsync(resetMemberState: false, trigger);

            var roomId = _currentRoomId;
            var characterId = _currentCharacterId;
            _practiceRoomManager.UnregisterRoomChannel(roomId, this);
            if (_practiceRoomManager.TryLeaveRoom(
                    roomId,
                    characterId,
                    out var room,
                    out var roomRemoved) &&
                !roomRemoved &&
                room is not null)
            {
                await _practiceRoomManager.BroadcastRoomSnapshotAsync(room.RoomId);
            }

            _currentRoomId = 0;
            _currentCharacterId = 0;
        }

        ResetLocalGameState();
        _state = ChannelState.AwaitRoomEnter;

        if (sendLeaveAck)
        {
            await SendPacket17LeaveRoomAsync();
        }

        Log.Information(
            "Channel room cleanup from {Remote}: trigger={Trigger}",
            _remoteLabel,
            trigger);
    }

    private async Task CleanupGameStateAsync(bool resetMemberState, string trigger)
    {
        var roomId = _currentGameRoom?.RoomId ?? _currentRoomId;
        if (roomId != 0)
        {
            var removedUid = (byte)0;
            var leftGameChannel = false;
            if (resetMemberState &&
                _practiceRoomManager.TryLeaveGame(roomId, _currentCharacterId, this, out var room, out removedUid))
            {
                leftGameChannel = true;
                await _practiceRoomManager.BroadcastRoomSnapshotAsync(room.RoomId);
            }
            else if (!_practiceRoomManager.UnregisterGameChannel(roomId, this, out removedUid))
            {
                removedUid = 0;
            }
            else
            {
                leftGameChannel = true;
                removedUid = removedUid == 0 ? _localGameUid : removedUid;
            }

            if (leftGameChannel && removedUid != 0)
            {
                var broadcastCount = await _practiceRoomManager.BroadcastGamePlayerLeftAsync(
                    roomId,
                    this,
                    removedUid);
                Log.Information(
                    "Channel packet108 broadcast from {Remote}: trigger={Trigger} leftUid={LeftUid} broadcastCount={BroadcastCount}",
                    _remoteLabel,
                    trigger,
                    removedUid,
                    broadcastCount);
            }
        }

        ResetLocalGameState();

        Log.Information(
            "Channel game cleanup from {Remote}: trigger={Trigger} roomId={RoomId} resetMemberState={ResetMemberState}",
            _remoteLabel,
            trigger,
            roomId,
            resetMemberState);
    }

    private void ResetLocalGameState()
    {
        _currentGameRoom = null;
        _localGameUid = LocalGameUid;
        _localPlayerEnterPacketSent = false;
        _localPlayerEnterBroadcastSent = false;
        Volatile.Write(ref _gameInitSpawnHandshakeStarted, 0);
        Volatile.Write(ref _activeClientGameInitRefreshSent, 0);
        unchecked
        {
            _gameInitSpawnHandshakeGeneration++;
        }
        _playerEnteringClearRetriesRemaining = 0;
        _silentLoadoutHudRefreshRetriesRemaining = 0;
        _currentWeaponSlot = 0;
        _previousWeaponSlot = 0;
        _knownGamePlayerUids.Clear();
        _lastSpecialWeaponRearmBySlot.Clear();
        _movementDebugSamplesRemaining = MovementDebugSampleLogLimit;
        _lastGameMovementInputByte = 0;
        _lastGameMovementTick = 0;
        _hasLastGameMovementInputByte = false;
        _setHealthOverride = null;
        _setWalkSpeedOverride = null;
        _setJumpHeightOverride = null;
        _setBulletAmmoOneClipOverridesByItemId.Clear();
        StopKnifeAutoRearmLoop();
    }

    private async Task HandlePacket6RoomChangeOptionAsync(PacketReader reader)
    {
        if (!AvatarStarClientProtocol.TryReadChannelRoomOptionChange(reader, out var optionChange))
        {
            Log.Warning("Channel packet6 parse failed from {Remote}", _remoteLabel);
            return;
        }

        Log.Information(
            "Channel room option change from {Remote}: roomId={RoomId} roomName={RoomName} levelId={LevelId} gameType={GameType} maxClientNum={MaxClientNum} spawnTime={SpawnTime} joinHalfWay={JoinHalfWay} checkBalance={CheckBalance} canBeWatched={CanBeWatched} matching={Matching} enterLimit={EnterLimit}",
            _remoteLabel,
            _currentRoomId,
            optionChange.RoomName,
            optionChange.LevelId,
            optionChange.GameType,
            optionChange.MaxClientNum,
            optionChange.SpawnTime,
            optionChange.JoinHalfWay,
            optionChange.CheckBalance,
            optionChange.CanBeWatched,
            optionChange.Matching,
            optionChange.EnterLimit);

        PracticeRoomManager.PracticeRoomSession? room = null;
        var resultCode = 1;
        if (_currentRoomId == 0 ||
            !_practiceRoomManager.TryUpdateRoomOptions(
                _currentRoomId,
                new PracticeRoomManager.PracticeRoomUpdateRequest(
                    RoomName: optionChange.RoomName,
                    UsePassword: optionChange.UsePassword,
                    Password: optionChange.Password,
                    LevelId: optionChange.LevelId,
                    GameType: optionChange.GameType,
                    MaxClientNum: optionChange.MaxClientNum,
                    SpawnTime: optionChange.SpawnTime,
                    JoinHalfWay: optionChange.JoinHalfWay,
                    CheckBalance: optionChange.CheckBalance,
                    Matching: optionChange.Matching,
                    CanBeWatched: optionChange.CanBeWatched,
                    MapName: optionChange.MapName,
                    EnterLimit: optionChange.EnterLimit),
                out room,
                out resultCode))
        {
            Log.Warning(
                "Channel packet6 update failed from {Remote}: roomId={RoomId} resultCode={ResultCode}",
                _remoteLabel,
                _currentRoomId,
                resultCode);
            await SendPacket20RoomOptionChangeResultAsync(resultCode);
            return;
        }

        if (room is null)
        {
            Log.Warning("Channel packet6 update produced null room from {Remote}", _remoteLabel);
            await SendPacket20RoomOptionChangeResultAsync(resultCode);
            return;
        }

        await SendPacket2RoomInfoChangedAsync(room);
        await SendPacket4RoomOptionChangedAsync(room);
        await SendPacket18RoomClientListSyncAsync(room);
        await SendPacket20RoomOptionChangeResultAsync(resultCode: 0);
    }

    private async Task HandlePacket12ChangeSlotAsync(PacketReader reader)
    {
        if (!reader.TryReadByte(out var slotIndex))
        {
            Log.Warning("Channel packet12 parse failed from {Remote}", _remoteLabel);
            return;
        }

        Log.Information(
            "Channel change slot request from {Remote}: roomId={RoomId} slotIndex={SlotIndex}",
            _remoteLabel,
            _currentRoomId,
            slotIndex);

        PracticeRoomManager.PracticeRoomSession? room = null;
        var resultCode = 1;
        if (_currentRoomId == 0 ||
            !_practiceRoomManager.TryMoveMemberSlot(_currentRoomId, _currentCharacterId, slotIndex, out room, out resultCode))
        {
            Log.Warning(
                "Channel packet12 move failed from {Remote}: roomId={RoomId} slotIndex={SlotIndex} resultCode={ResultCode}",
                _remoteLabel,
                _currentRoomId,
                slotIndex,
                resultCode);
            return;
        }

        if (room is null)
        {
            Log.Warning("Channel packet12 move produced null room from {Remote}", _remoteLabel);
            return;
        }

        await SendPacket26SlotChangedAsync(room, _currentCharacterId, slotIndex);
        await _practiceRoomManager.BroadcastRoomSnapshotAsync(room.RoomId);
    }

    private async Task HandlePacket8RoomReadyAsync(PacketReader reader)
    {
        if (!reader.TryReadByte(out var readyByte))
        {
            Log.Warning("Channel packet8 ready parse failed from {Remote}", _remoteLabel);
            await SendPacket21GameReadyResultAsync(resultCode: 1);
            return;
        }

        var ready = readyByte != 0;
        PracticeRoomManager.PracticeRoomSession? room = null;
        var resultCode = 1;
        if (_currentRoomId == 0 ||
            !_practiceRoomManager.TrySetMemberReady(_currentRoomId, _currentCharacterId, ready, out room, out resultCode))
        {
            Log.Warning(
                "Channel packet8 ready failed from {Remote}: roomId={RoomId} ready={Ready} resultCode={ResultCode}",
                _remoteLabel,
                _currentRoomId,
                ready,
                resultCode);
            await SendPacket21GameReadyResultAsync(resultCode);
            return;
        }

        Log.Information(
            "Channel packet8 ready from {Remote}: roomId={RoomId} ready={Ready}",
            _remoteLabel,
            _currentRoomId,
            ready);

        await SendPacket21GameReadyResultAsync(resultCode: 0);
        await SendPacket6RoomReadyNotifyAsync(_currentCharacterId, ready);
        await _practiceRoomManager.BroadcastRoomSnapshotAsync(room.RoomId);
    }

    private async Task HandlePacket10StartGameAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Warning(
                "Channel packet10 start game from {Remote}: unexpected remaining={Remaining}",
                _remoteLabel,
                reader.Remaining);
        }

        PracticeRoomManager.PracticeRoomSession? room = null;
        var resultCode = 1;
        if (_currentRoomId == 0 ||
            !_practiceRoomManager.TryStartGame(_currentRoomId, out room, out resultCode))
        {
            Log.Warning(
                "Channel packet10 start failed from {Remote}: roomId={RoomId} resultCode={ResultCode}",
                _remoteLabel,
                _currentRoomId,
                resultCode);
            await SendPacket22GameStartResultAsync(resultCode);
            return;
        }

        if (room is null)
        {
            Log.Warning("Channel packet10 start produced null room from {Remote}", _remoteLabel);
            await SendPacket22GameStartResultAsync(resultCode);
            return;
        }

        await SendPacket22GameStartResultAsync(resultCode: 0);
        await SendPacket2RoomInfoChangedAsync(room);
        await SendPacket18RoomClientListSyncAsync(room);
        await SendPacket8GameStartNotifyAsync();
        await _practiceRoomManager.BroadcastGameStartAsync(room.RoomId, this);
        ScheduleDeferredGameEnterSequence(
            room,
            "packet10-start",
            DeferredGameEnterStartDelayMilliseconds);

        Log.Information(
            "Channel packet10 start accepted from {Remote}: roomId={RoomId}; deferredEnterDelayMs={DelayMs}",
            _remoteLabel,
            room.RoomId,
            DeferredGameEnterStartDelayMilliseconds);
    }

    private async Task HandlePacket100EnterGameAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Warning(
                "Channel packet100 enter game from {Remote}: unexpected remaining={Remaining}",
                _remoteLabel,
                reader.Remaining);
        }

        var resultCode = 1;
        if (_currentRoomId == 0 ||
            !_practiceRoomManager.TryEnterGame(_currentRoomId, _currentCharacterId, out var room, out resultCode))
        {
            Log.Warning(
                "Channel packet100 enter failed from {Remote}: roomId={RoomId} resultCode={ResultCode}",
                _remoteLabel,
                _currentRoomId,
                resultCode);
            await SendPacket100GameEnterResultAsync(resultCode);
            return;
        }

        Log.Information(
            "Channel packet100 enter accepted from {Remote}: roomId={RoomId} contextId={ContextId}; waiting for RPC quiet window",
            _remoteLabel,
            room.RoomId,
            room.ContextId);

        await _practiceRoomManager.BroadcastRoomSnapshotAsync(room.RoomId);
        ScheduleDeferredGameEnterSequence(
            room,
            "packet100-enter",
            DeferredGameEnterPacket100DelayMilliseconds);
    }

    private async Task HandlePacket100DuplicateEnterGameAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet100 duplicate enter from {Remote}: trailing={Remaining}",
                _remoteLabel,
                reader.Remaining);
        }

        if (_currentGameRoom is null)
        {
            Log.Warning("Channel packet100 duplicate enter from {Remote} ignored: no active game room", _remoteLabel);
            await SendPacket100GameEnterResultAsync(resultCode: 1);
            return;
        }

        Log.Information(
            "Channel packet100 duplicate enter from {Remote}: roomId={RoomId}; resending enter result only",
            _remoteLabel,
            _currentGameRoom.RoomId);
        await SendPacket100GameEnterResultAsync(resultCode: 0);
    }

    private async Task BeginGameEnterSequenceAsync(
        PracticeRoomManager.PracticeRoomSession room,
        string source)
    {
        if (_state == ChannelState.InGame && _currentGameRoom is not null)
        {
            Log.Information(
                "Channel game enter duplicate ignored from {Remote}: source={Source} roomId={RoomId}",
                _remoteLabel,
                source,
                _currentGameRoom.RoomId);
            await SendPacket100GameEnterResultAsync(resultCode: 0);
            return;
        }

        _state = ChannelState.InGame;
        _currentGameRoom = room;
        var localMember = GetLocalGameMember(room);
        var localCharacterId = localMember?.CharacterId ?? room.HostCharacterId;
        var localCharacterName = localMember?.CharacterName ?? room.HostName;
        _localGameUid = _practiceRoomManager.RegisterGameChannel(
            room.RoomId,
            this,
            localCharacterId,
            localCharacterName);
        var localPlayerState = ResolvePlayerState(localCharacterId);
        _practiceRoomManager.UpdateGamePlayerState(
            room.RoomId,
            _localGameUid,
            ResolveGameTeamId(localMember),
            ResolveLocalGamePlayerHealth(localPlayerState?.Character));
        UpdateLocalGameSpawnPosition(room, overwriteExisting: true, source);
        _localPlayerEnterPacketSent = false;
        _localPlayerEnterBroadcastSent = false;
        Volatile.Write(ref _gameInitSpawnHandshakeStarted, 0);
        Volatile.Write(ref _activeClientGameInitRefreshSent, 0);
        unchecked
        {
            _gameInitSpawnHandshakeGeneration++;
        }
        _playerEnteringClearRetriesRemaining = 0;
        _silentLoadoutHudRefreshRetriesRemaining = 0;
        _currentWeaponSlot = 0;
        _previousWeaponSlot = 0;
        _knownGamePlayerUids.Clear();
        _lastSpecialWeaponRearmBySlot.Clear();
        _movementDebugSamplesRemaining = MovementDebugSampleLogLimit;
        _lastGameMovementInputByte = 0;
        _lastGameMovementTick = 0;
        _hasLastGameMovementInputByte = false;
        StopKnifeAutoRearmLoop();

        if (!UseLegacyHotbarBootstrapSequence)
        {
            await SendPacket9GameClientEnterNotifyAsync(room);
        }

        await SendPacket100GameEnterResultAsync(resultCode: 0);
        await SendPacket102GameAuthenticationAsync(room);
        await SendPacket103GameCharacterCreateListAsync(room);
        await SendPacket105GameLoadingReadyAsync();
        if (UseLegacyHotbarBootstrapSequence)
        {
            if (TryBeginGameInitSpawnHandshake())
            {
                await SendGameInitSpawnPacketsAsync(room, "legacy-hotbar-bootstrap", preferKnownPosition: false);
            }
        }
        else
        {
            ScheduleGameInitSpawnHandshakeFallback(room, source);
        }

        Log.Information(
            "Channel game enter bootstrap sent to {Remote}: source={Source} roomId={RoomId} localUid={LocalUid} legacyHotbarBootstrap={LegacyHotbarBootstrap}",
            _remoteLabel,
            source,
            room.RoomId,
            _localGameUid,
            UseLegacyHotbarBootstrapSequence);
    }

    private void ScheduleDeferredGameEnterSequence(
        PracticeRoomManager.PracticeRoomSession room,
        string source,
        int initialDelayMilliseconds)
    {
        var roomId = room.RoomId;
        var generation = _gameInitSpawnHandshakeGeneration;
        _ = BeginDeferredGameEnterSequenceAsync(room, roomId, generation, source, initialDelayMilliseconds);
    }

    private async Task BeginDeferredGameEnterSequenceAsync(
        PracticeRoomManager.PracticeRoomSession room,
        int roomId,
        int generation,
        string source,
        int initialDelayMilliseconds)
    {
        try
        {
            if (initialDelayMilliseconds > 0)
            {
                await Task.Delay(initialDelayMilliseconds);
            }

            if (_state != ChannelState.InRoom ||
                _currentRoomId != roomId ||
                generation != _gameInitSpawnHandshakeGeneration)
            {
                return;
            }

            var quietWaitMs = await WaitForGameClientRpcQuietAsync(roomId, generation);
            if (_state != ChannelState.InRoom ||
                _currentRoomId != roomId ||
                generation != _gameInitSpawnHandshakeGeneration)
            {
                return;
            }

            Log.Information(
                "Channel deferred game enter bootstrap -> {Remote}: source={Source} roomId={RoomId} delayMs={DelayMs} rpcQuietWaitMs={QuietWaitMs}",
                _remoteLabel,
                source,
                roomId,
                initialDelayMilliseconds,
                quietWaitMs);

            await BeginGameEnterSequenceAsync(room, source);
        }
        catch (Exception ex)
        {
            Log.Warning(
                ex,
                "Channel deferred game enter bootstrap failed -> {Remote}: source={Source} roomId={RoomId}",
                _remoteLabel,
                source,
                roomId);
        }
    }

    private async Task<int> WaitForGameClientRpcQuietAsync(int roomId, int generation)
    {
        var started = DateTimeOffset.UtcNow;
        var waitedMs = 0;
        while ((_state == ChannelState.InRoom || _state == ChannelState.InGame) &&
               _currentRoomId == roomId &&
               generation == _gameInitSpawnHandshakeGeneration &&
               _practiceRoomManager.TryGetGameClientRpcActivity(_currentCharacterId, out var activity))
        {
            var now = DateTimeOffset.UtcNow;
            var idleMs = (int)Math.Max(0, (now - activity.LastSeenAt).TotalMilliseconds);
            if (idleMs >= DeferredGameEnterRpcQuietMilliseconds ||
                (now - started).TotalMilliseconds >= DeferredGameEnterMaxDelayMilliseconds)
            {
                break;
            }

            var delayMs = Math.Clamp(DeferredGameEnterRpcQuietMilliseconds - idleMs, 100, 250);
            await Task.Delay(delayMs);
            waitedMs = (int)Math.Max(waitedMs, (DateTimeOffset.UtcNow - started).TotalMilliseconds);
        }

        return waitedMs;
    }

    public async Task SendRoomSnapshotAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        if (_currentRoomId != room.RoomId)
        {
            return;
        }

        await SendPacket19RoomInfoSyncAsync(room);
        await SendPacket18RoomClientListSyncAsync(room);
    }

    public async Task SendRemoteGameStartAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        if (_currentRoomId != room.RoomId || _state != ChannelState.InRoom)
        {
            return;
        }

        await SendPacket2RoomInfoChangedAsync(room);
        await SendPacket18RoomClientListSyncAsync(room);
        await SendPacket8GameStartNotifyAsync();
        ScheduleDeferredGameEnterSequence(
            room,
            "remote-start",
            DeferredGameEnterStartDelayMilliseconds);

        Log.Information(
            "Channel remote game start -> {Remote}: roomId={RoomId}; deferredEnterDelayMs={DelayMs}",
            _remoteLabel,
            room.RoomId,
            DeferredGameEnterStartDelayMilliseconds);
    }

    private async Task HandlePacket103GameCharacterRequestAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet103 <- {Remote}: character request trailing={Remaining}",
                _remoteLabel,
                reader.Remaining);
        }

        if (_currentGameRoom is null)
        {
            Log.Warning("Channel packet103 character request from {Remote} ignored: no active game room", _remoteLabel);
            return;
        }

        if (!TryBeginGameInitSpawnHandshake())
        {
            Log.Verbose("Channel packet103 character request from {Remote} ignored: game init/spawn handshake already sent", _remoteLabel);
            return;
        }

        Log.Information("Channel packet103 <- {Remote}: client requested game init/spawn handshake", _remoteLabel);

        await SendGameInitSpawnPacketsAsync(_currentGameRoom, "packet103", preferKnownPosition: false);
        await SendLocalPlayerEnteredOnceAsync();
        _playerEnteringClearRetriesRemaining = PlayerEnteringClearRetryCount;
        await SendPendingPlayerEnteringClearAsync("packet111");
    }

    private bool TryBeginGameInitSpawnHandshake()
    {
        if (Interlocked.Exchange(ref _gameInitSpawnHandshakeStarted, 1) != 0)
        {
            return false;
        }
        return true;
    }

    private async Task<bool> TryHandleSetCommandAsync(short packetId, string command)
    {
        if (_currentGameRoom is null)
        {
            Log.Warning(
                "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=no-active-room",
                _remoteLabel,
                packetId,
                command);
            return true;
        }

        var args = command.Length <= SetCommandName.Length
            ? string.Empty
            : command[SetCommandName.Length..].Trim();
        var parts = args.Split(' ', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (parts.Length != 2)
        {
            Log.Warning(
                "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=invalid-set-syntax",
                _remoteLabel,
                packetId,
                command);
            return true;
        }

        var key = parts[0].Trim();
        var valueText = parts[1].Trim();
        if (key.Equals("health", StringComparison.OrdinalIgnoreCase))
        {
            if (!int.TryParse(valueText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var health))
            {
                Log.Warning(
                    "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=invalid-health",
                    _remoteLabel,
                    packetId,
                    command);
                return true;
            }

            await SetLocalHealthAsync(Math.Clamp(health, 1, 100000), packetId);
            return true;
        }

        if (key.Equals("bullet", StringComparison.OrdinalIgnoreCase))
        {
            if (!int.TryParse(valueText, NumberStyles.Integer, CultureInfo.InvariantCulture, out var bulletCount))
            {
                Log.Warning(
                    "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=invalid-bullet",
                    _remoteLabel,
                    packetId,
                    command);
                return true;
            }

            await SetLocalWeaponBulletCountAsync(Math.Clamp(bulletCount, 0, 100000), packetId);
            return true;
        }

        if (!float.TryParse(valueText, NumberStyles.Float, CultureInfo.InvariantCulture, out var value))
        {
            Log.Warning(
                "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=invalid-float",
                _remoteLabel,
                packetId,
                command);
            return true;
        }

        value = Math.Clamp(value, 0.1f, 1000f);
        if (key.Equals("speed", StringComparison.OrdinalIgnoreCase))
        {
            _setWalkSpeedOverride = value;
            await RefreshLocalCharacterCreateAsync("set-speed");
            Log.Information(
                "In-game command {Command} handled from {Remote}: packetId={PacketId} localUid={LocalUid} speed={Speed}",
                SetCommandName,
                _remoteLabel,
                packetId,
                _localGameUid,
                FormatProtocolFloat(value));
            return true;
        }

        if (key.Equals("jump", StringComparison.OrdinalIgnoreCase))
        {
            _setJumpHeightOverride = value;
            await RefreshLocalCharacterCreateAsync("set-jump");
            Log.Information(
                "In-game command {Command} handled from {Remote}: packetId={PacketId} localUid={LocalUid} jump={Jump}",
                SetCommandName,
                _remoteLabel,
                packetId,
                _localGameUid,
                FormatProtocolFloat(value));
            return true;
        }

        Log.Warning(
            "In-game command ignored from {Remote}: packetId={PacketId} command={Command} reason=unknown-set-key key={Key}",
            _remoteLabel,
            packetId,
            command,
            key);
        return true;
    }

    private async Task SetLocalWeaponBulletCountAsync(int bulletCount, short packetId)
    {
        var slotOneBased = ResolveCurrentReloadReadySlot();
        var item = ResolveLocalLoadoutItem(slotOneBased);
        if (item is null)
        {
            Log.Warning(
                "In-game command {Command} failed from {Remote}: packetId={PacketId} localUid={LocalUid} slot={Slot} bullet={BulletCount} reason=current-weapon-not-found",
                SetCommandName,
                _remoteLabel,
                packetId,
                _localGameUid,
                slotOneBased,
                bulletCount);
            return;
        }

        var ammoOneClip = bulletCount;
        _setBulletAmmoOneClipOverridesByItemId[item.ItemId] = ammoOneClip;

        if (_currentGameRoom is not null)
        {
            await RefreshLocalCharacterCreateAsync("set-bullet");
        }

        await SendPacket143GameLoadoutItemPropertyRefreshAsync(
            item,
            GameLoadoutAmmoOneClipPropertyName,
            ammoOneClip,
            "set-bullet");
        await SendPacket143GameLoadoutItemPropertyRefreshAsync(
            item,
            GameLoadoutHudRefreshPropertyName,
            bulletCount,
            "set-bullet");
        await SendPacket175GameReloadReadyAsync(slotOneBased, "set-bullet");
        await SendPacket143GameLoadoutItemPropertyRefreshAsync(
            item,
            GameLoadoutHudRefreshPropertyName,
            bulletCount,
            "set-bullet-after-ack");

        Log.Information(
            "In-game command {Command} handled from {Remote}: packetId={PacketId} localUid={LocalUid} slot={Slot} itemId={ItemId} resource={Resource} bullet={BulletCount} ammoOneClip={AmmoOneClip}; packet103 character refresh sent, packet143 ammo refresh sent, packet175 local ack sent",
            SetCommandName,
            _remoteLabel,
            packetId,
            _localGameUid,
            slotOneBased,
            item.ItemId,
            item.Resource,
            bulletCount,
            ammoOneClip);
    }

    private async Task SetLocalHealthAsync(int health, short packetId)
    {
        if (_currentGameRoom is null)
        {
            return;
        }

        _setHealthOverride = health;
        if (!_practiceRoomManager.TrySetGamePlayerHealth(
                _currentGameRoom.RoomId,
                _localGameUid,
                health,
                out var action))
        {
            Log.Warning(
                "In-game command {Command} failed from {Remote}: packetId={PacketId} localUid={LocalUid} health={Health} reason=player-not-found",
                SetCommandName,
                _remoteLabel,
                packetId,
                _localGameUid,
                health);
            return;
        }

        var broadcastCount = await _practiceRoomManager.BroadcastGameDamageHitAsync(_currentGameRoom.RoomId, action);
        await SendLocalStateUiRefreshAsync("set-health", health);
        Log.Information(
            "In-game command {Command} handled from {Remote}: packetId={PacketId} localUid={LocalUid} health={Health} broadcastCount={BroadcastCount}",
            SetCommandName,
            _remoteLabel,
            packetId,
            _localGameUid,
            health,
            broadcastCount);
    }

    private async Task SendLocalStateUiRefreshAsync(string trigger, int? healthOverride = null)
    {
        if (_currentGameRoom is null)
        {
            return;
        }

        var hasKnownPosition = TryGetLocalGamePosition(out var position);
        if (!hasKnownPosition)
        {
            var (spawnX, spawnY, spawnZ, _) = ResolveSpawnPoint(_currentGameRoom);
            position = new PracticeRoomManager.GamePosition(
                WorldToRawCoordinate(spawnX),
                WorldToRawCoordinate(spawnY),
                WorldToRawCoordinate(spawnZ),
                null,
                null,
                null,
                DateTimeOffset.UtcNow);
            _practiceRoomManager.UpdateGamePositionIfMissing(_currentGameRoom.RoomId, _localGameUid, position);
        }

        var refreshTrigger = hasKnownPosition ? trigger : $"{trigger}-spawn-fallback";
        var health = healthOverride ?? ResolveLocalRuntimeHealth(_currentGameRoom);
        await SendPacket111GameTeleportAsync(
            RawToWorldCoordinate(position.XRaw),
            RawToWorldCoordinate(position.YRaw),
            RawToWorldCoordinate(position.ZRaw),
            position.YawRaw.HasValue ? RawToWorldCoordinate(position.YawRaw.Value) : 0f,
            refreshTrigger,
            health);
        Log.Information(
            "Channel packet111 state refresh -> {Remote}: trigger={Trigger} uid={Uid} health={Health} positionRaw=({X},{Y},{Z})",
            _remoteLabel,
            refreshTrigger,
            _localGameUid,
            health,
            position.XRaw,
            position.YRaw,
            position.ZRaw);
    }

    private async Task RefreshLocalCharacterCreateAsync(string trigger)
    {
        if (_currentGameRoom is null)
        {
            return;
        }

        var player = ResolveGamePlayersForPacket(_currentGameRoom)
            .FirstOrDefault(player => player.Uid == _localGameUid);
        if (player is null)
        {
            return;
        }

        await SendPacket103GameCharacterCreateAsync(player);
        Log.Information(
            "Channel packet{PacketId} refresh -> {Remote}: trigger={Trigger} uid={Uid}",
            GameCharacterInfoPacketId,
            _remoteLabel,
            trigger,
            _localGameUid);
    }

    private void ScheduleGameInitSpawnHandshakeFallback(
        PracticeRoomManager.PracticeRoomSession room,
        string source)
    {
        var roomId = room.RoomId;
        var generation = _gameInitSpawnHandshakeGeneration;
        _ = SendGameInitSpawnHandshakeFallbackAsync(roomId, generation, source);
    }

    private async Task SendGameInitSpawnHandshakeFallbackAsync(
        int roomId,
        int generation,
        string source)
    {
        try
        {
            await Task.Delay(GameInitSpawnFallbackDelayMilliseconds);
            if (_state != ChannelState.InGame ||
                _currentGameRoom is not { } room ||
                room.RoomId != roomId ||
                generation != _gameInitSpawnHandshakeGeneration ||
                !TryBeginGameInitSpawnHandshake())
            {
                return;
            }

            Log.Information(
                "Channel game init/spawn fallback waiting for RPC quiet -> {Remote}: source={Source} roomId={RoomId} delayMs={DelayMs}",
                _remoteLabel,
                source,
                roomId,
                GameInitSpawnFallbackDelayMilliseconds);

            var quietWaitMs = await WaitForGameClientRpcQuietAsync(roomId, generation);
            if (_state != ChannelState.InGame ||
                _currentGameRoom is not { } activeRoom ||
                activeRoom.RoomId != roomId ||
                generation != _gameInitSpawnHandshakeGeneration)
            {
                return;
            }

            Log.Information(
                "Channel game init/spawn fallback -> {Remote}: source={Source} roomId={RoomId} delayMs={DelayMs} rpcQuietWaitMs={QuietWaitMs}",
                _remoteLabel,
                source,
                roomId,
                GameInitSpawnFallbackDelayMilliseconds,
                quietWaitMs);

            await SendGameInitSpawnPacketsAsync(room, "game-enter-fallback", preferKnownPosition: false);
            _playerEnteringClearRetriesRemaining = PlayerEnteringClearRetryCount;
            await SendPendingPlayerEnteringClearAsync("game-enter-fallback");
        }
        catch (Exception ex)
        {
            Log.Warning(
                ex,
                "Channel game init/spawn fallback failed -> {Remote}: source={Source} roomId={RoomId}",
                _remoteLabel,
                source,
                roomId);
        }
    }

    private async Task SendGameInitSpawnPacketsAsync(
        PracticeRoomManager.PracticeRoomSession room,
        string trigger,
        bool preferKnownPosition)
    {
        if (preferKnownPosition && TryGetLocalGamePosition(out var position))
        {
            await SendPacket111GameTeleportAsync(
                RawToWorldCoordinate(position.XRaw),
                RawToWorldCoordinate(position.YRaw),
                RawToWorldCoordinate(position.ZRaw),
                0f,
                trigger);
        }
        else
        {
            await SendPacket111GameSpawnAsync(room, trigger);
        }

        await SendPacket106GameInitAsync(room);
    }

    private async Task SendActiveClientGameInitRefreshOnceAsync(string trigger)
    {
        if (_currentGameRoom is null ||
            Interlocked.Exchange(ref _activeClientGameInitRefreshSent, 1) != 0)
        {
            return;
        }

        Log.Information(
            "Channel active-client init refresh -> {Remote}: trigger={Trigger} roomId={RoomId}",
            _remoteLabel,
            trigger,
            _currentGameRoom.RoomId);

        await SendGameInitSpawnPacketsAsync(_currentGameRoom, trigger, preferKnownPosition: true);
        await SendLocalPlayerEnteredOnceAsync();
        _playerEnteringClearRetriesRemaining = PlayerEnteringClearRetryCount;
        await SendPendingPlayerEnteringClearAsync(trigger);
        await SendPendingSilentLoadoutHudRefreshAsync(trigger);
    }

    private async Task HandlePacket104GamePingAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet104 <- {Remote}: ping trailing={Remaining}",
                _remoteLabel,
                reader.Remaining);
        }

        await SendPacket109GamePingBackAsync();
    }

    private async Task HandlePacket120GameClientNotifyAsync(PacketReader reader)
    {
        if (!reader.TryReadByte(out var notifyValue))
        {
            Log.Warning("Channel packet120 <- {Remote}: ignored, missing notify value", _remoteLabel);
            return;
        }

        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet120 <- {Remote}: value={Value} trailing={Remaining}",
                _remoteLabel,
                notifyValue,
                reader.Remaining);
            return;
        }

        if (_currentGameRoom is not null && notifyValue < ClientWeaponSlotNotifyMax)
        {
            TryApplyLocalWeaponSlot(notifyValue, ClientWeaponSlotNotifyMax);
            var broadcastCount = await _practiceRoomManager.BroadcastGameWeaponSlotAsync(
                _currentGameRoom.RoomId,
                this,
                _localGameUid,
                notifyValue,
                "packet120-weapon-slot");

            Log.Information(
                "Channel packet120 <- {Remote}: weapon-slot uid={Uid} slot={Slot} broadcastCount={BroadcastCount}",
                _remoteLabel,
                _localGameUid,
                notifyValue,
                broadcastCount);
            await SendPendingPlayerEnteringClearAsync("packet120");
            await SendPendingSilentLoadoutHudRefreshAsync("packet120");
            return;
        }

        Log.Verbose("Channel packet120 <- {Remote}: value={Value}", _remoteLabel, notifyValue);
        await SendPendingPlayerEnteringClearAsync("packet120");
        await SendPendingSilentLoadoutHudRefreshAsync("packet120");
    }

    private async Task HandlePacket137GameClientReadyAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet137 <- {Remote}: trailing={Remaining}",
                _remoteLabel,
                reader.Remaining);
            return;
        }

        Log.Verbose("Channel packet137 <- {Remote}: client-side ready notify", _remoteLabel);
        await SendPendingPlayerEnteringClearAsync("packet137");
        await SendPendingSilentLoadoutHudRefreshAsync("packet137");
    }

    private async Task HandlePacket141GameSpawnReadyAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet141 <- {Remote}: trailing={Remaining}",
                _remoteLabel,
                reader.Remaining);
        }

        Log.Information("Channel packet141 <- {Remote}: local spawn ready; marking local player entered", _remoteLabel);
        if (_currentGameRoom is not null)
        {
            var localMember = GetLocalGameMember(_currentGameRoom);
            var localCharacterId = localMember?.CharacterId ?? _currentGameRoom.HostCharacterId;
            var localPlayerState = ResolvePlayerState(localCharacterId);
            _practiceRoomManager.UpdateGamePlayerState(
                _currentGameRoom.RoomId,
                _localGameUid,
                ResolveGameTeamId(localMember),
                ResolveLocalGamePlayerHealth(localPlayerState?.Character));
            UpdateLocalGameSpawnPosition(_currentGameRoom, overwriteExisting: true, "packet141");
        }

        if (UseLegacyHotbarBootstrapSequence)
        {
            Log.Information(
                "Channel packet141 <- {Remote}: legacy hotbar bootstrap active; skipping packet107/151 follow-up",
                _remoteLabel);
            return;
        }

        await SendLocalPlayerEnteredOnceAsync();
        _playerEnteringClearRetriesRemaining = PlayerEnteringClearRetryCount;
        _silentLoadoutHudRefreshRetriesRemaining = SilentLoadoutHudRefreshRetryCount;
        await SendPendingPlayerEnteringClearAsync("packet141");
        await SendPendingSilentLoadoutHudRefreshAsync("packet141");
        StartKnifeAutoRearmLoopIfNeeded("packet141");
    }

    private async Task HandlePacket113GameActionScalarAsync(PacketReader reader)
    {
        if (!reader.TryReadInt(out var rawValue))
        {
            Log.Warning(
                "Channel packet113 <- {Remote}: malformed action scalar remaining={Remaining}",
                _remoteLabel,
                reader.Remaining);
            return;
        }

        var scalar = BitConverter.Int32BitsToSingle(rawValue);
        await SendPacket114GameActionScalarAckAsync(rawValue, "packet113-local-ack");
        var knifeRearmCount = await SendKnifeWeaponRearmAsync("packet113");
        var damage = ResolveGameHurtDamage(rawValue, scalar);
        var damageResult = _currentGameRoom is null
            ? PracticeRoomManager.GameDamageBroadcastResult.NotApplied
            : await _practiceRoomManager.BroadcastGameDamageAsync(
                _currentGameRoom.RoomId,
                this,
                _localGameUid,
                damage);

        Log.Information(
            "Channel packet113 <- {Remote}: hurtRaw=0x{RawValue:X8} hurtScalar={Scalar} damage={Damage} trailing={Trailing}; packet114 local ack sent, knifeRearmCount={KnifeRearmCount}, damageApplied={DamageApplied}, victimUid={VictimUid}, victimHealth={VictimHealth}/{VictimMaxHealth}, killed={Killed}, broadcastCount={BroadcastCount}, deathBroadcastCount={DeathBroadcastCount}, damageReason={DamageReason}, candidates={DamageCandidateCount}, positioned={DamagePositionedCandidateCount}, attackerTeam={DamageAttackerTeamId}, bestHitScore={DamageBestHitScore}",
            _remoteLabel,
            rawValue,
            scalar,
            damage,
            reader.Remaining,
            knifeRearmCount,
            damageResult.Applied,
            damageResult.VictimUid,
            damageResult.VictimHealth,
            damageResult.VictimMaxHealth,
            damageResult.Killed,
            damageResult.BroadcastCount,
            damageResult.DeathBroadcastCount,
            damageResult.Reason,
            damageResult.CandidateCount,
            damageResult.PositionedCandidateCount,
            damageResult.AttackerTeamId,
            FormatGameHitScore(damageResult.BestHitScore));
    }

    private async Task HandlePacket156GameInfoOverlayRequestAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet156 <- {Remote}: expected empty payload trailing={Trailing}",
                _remoteLabel,
                reader.Remaining);
            return;
        }

        Log.Information("Channel packet156 <- {Remote}: game-info overlay show request; packet194 ack sent", _remoteLabel);
        await SendPacket194GameInfoOverlayShowAckAsync();
    }

    private async Task HandlePacket162ConfirmRefreshBornPointAsync(PacketReader reader)
    {
        var payload = reader.RemainingSpan.ToArray();
        if (payload.Length > 0)
        {
            _ = reader.TryReadFixedBytes(payload.Length, out _);
        }

        if (_currentGameRoom is null)
        {
            Log.Warning(
                "Channel packet162 <- {Remote}: confirm-refresh-born-point ignored, no active game room trailingBytes={TrailingBytes} hex={PayloadHex}",
                _remoteLabel,
                payload.Length,
                Convert.ToHexString(payload));
            return;
        }

        var localMember = GetLocalGameMember(_currentGameRoom);
        var localCharacterId = localMember?.CharacterId ?? _currentGameRoom.HostCharacterId;
        var localPlayerState = ResolvePlayerState(localCharacterId);
        var maxHealth = ResolveLocalGamePlayerHealth(localPlayerState?.Character);
        _practiceRoomManager.UpdateGamePlayerState(
            _currentGameRoom.RoomId,
            _localGameUid,
            ResolveGameTeamId(localMember),
            maxHealth);
        UpdateLocalGameSpawnPosition(_currentGameRoom, overwriteExisting: true, "packet162");

        await SendPacket111GameSpawnAsync(_currentGameRoom);
        var broadcastCount = await _practiceRoomManager.BroadcastGamePlayerRespawnAsync(
            _currentGameRoom.RoomId,
            this,
            _localGameUid);

        Log.Information(
            "Channel packet162 <- {Remote}: confirm-refresh-born-point uid={Uid} health={Health} trailingBytes={TrailingBytes} hex={PayloadHex}; packet111 local respawn sent, broadcastCount={BroadcastCount}",
            _remoteLabel,
            _localGameUid,
            maxHealth,
            payload.Length,
            Convert.ToHexString(payload),
            broadcastCount);
    }

    private void HandlePacket157GameClientNoPayload(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet157 <- {Remote}: expected empty payload trailing={Trailing}",
                _remoteLabel,
                reader.Remaining);
            return;
        }

        Log.Verbose("Channel packet157 <- {Remote}: game-info overlay close/no-payload notify", _remoteLabel);
    }

    private async Task HandlePacket121LeaveGameAsync(PacketReader reader)
    {
        if (reader.Remaining > 0)
        {
            Log.Verbose(
                "Channel packet121 <- {Remote}: leave-game trailing={Remaining}",
                _remoteLabel,
                reader.Remaining);
        }

        await CleanupGameStateAsync(resetMemberState: true, trigger: "packet121-leave-game");
        _state = _currentRoomId == 0 ? ChannelState.AwaitRoomEnter : ChannelState.InRoom;

        await SendPacket12GameLeaveNotifyAsync();
    }

    private async Task HandlePacket105GameSyncAsync(PacketReader reader)
    {
        if (_currentGameRoom is null)
        {
            Log.Warning("Channel packet105 <- {Remote}: ignored, no active game room", _remoteLabel);
            return;
        }

        if (!reader.TryReadByte(out var tick) || !reader.TryReadByte(out var flags))
        {
            Log.Warning(
                "Channel packet105 <- {Remote}: malformed sync payload remaining={Remaining}",
                _remoteLabel,
                reader.Remaining);
            return;
        }

        _lastGameMovementTick = tick;

        var expectedOptionalBytes = GetGameMovementOptionalByteCount(flags);
        if (reader.Remaining < expectedOptionalBytes)
        {
            Log.Warning(
                "Channel packet105 <- {Remote}: truncated sync payload tick={Tick} flags=0x{Flags:X2} remaining={Remaining} expectedOptionalBytes={ExpectedOptionalBytes}",
                _remoteLabel,
                tick,
                flags,
                reader.Remaining,
                expectedOptionalBytes);
            return;
        }

        if (!reader.TryReadFixedBytes(expectedOptionalBytes, out var optionalPayload))
        {
            Log.Warning(
                "Channel packet105 <- {Remote}: failed to consume optional payload tick={Tick} flags=0x{Flags:X2} remaining={Remaining} expectedOptionalBytes={ExpectedOptionalBytes}",
                _remoteLabel,
                tick,
                flags,
                reader.Remaining,
                expectedOptionalBytes);
            return;
        }

        var trailingBytes = reader.Remaining;
        var trailingPayloadHex = trailingBytes > 0
            ? Convert.ToHexString(reader.RemainingSpan.ToArray())
            : string.Empty;
        var movement = new PracticeRoomManager.GameMovementDelta(
            _localGameUid,
            tick,
            flags,
            optionalPayload,
            DateTimeOffset.UtcNow);
        var movementSample = DecodeGameMovementSample(flags, optionalPayload);
        if (movementSample.InputByte.HasValue)
        {
            _lastGameMovementInputByte = movementSample.InputByte.Value;
            _hasLastGameMovementInputByte = true;
        }

        if (movementSample.HasPosition)
        {
            _practiceRoomManager.UpdateGamePosition(
                _currentGameRoom.RoomId,
                _localGameUid,
                new PracticeRoomManager.GamePosition(
                    movementSample.PositionXRaw,
                    movementSample.PositionYRaw,
                    movementSample.PositionZRaw,
                    movementSample.YawRaw,
                    movementSample.HasFacing ? movementSample.Facing0Raw : null,
                    movementSample.HasFacing ? movementSample.Facing1Raw : null,
                    DateTimeOffset.UtcNow));
        }

        _practiceRoomManager.UpdateGameMovement(_currentGameRoom.RoomId, movement);
        var broadcastCount = await _practiceRoomManager.BroadcastGameMovementAsync(
            _currentGameRoom.RoomId,
            this,
            movement);

        var hasRollOrDirectionInput =
            movementSample.InputByte.HasValue &&
            (movementSample.InputByte.Value & 0xF6) != 0;
        if (EnableMovementCoordinateChangeLog &&
            (hasRollOrDirectionInput || movementSample.HasPosition || _movementDebugSamplesRemaining > 0))
        {
            if (_movementDebugSamplesRemaining > 0)
            {
                _movementDebugSamplesRemaining--;
            }

            Log.Information(
                "Channel packet105 movement sample <- {Remote}: tick={Tick} flags=0x{Flags:X2} input={InputByte} inputKnown={InputKnown} direction={Direction} actionBits={ActionBits} hasYaw={HasYaw} yawRaw={YawRaw} hasPos={HasPosition} posRaw={PositionRaw} hasFacing={HasFacing} facingRaw={FacingRaw} optionalBytes={OptionalBytes} trailingBytes={TrailingBytes} uid={Uid} broadcastCount={BroadcastCount}",
                _remoteLabel,
                tick,
                flags,
                FormatOptionalByte(movementSample.InputByte),
                movementSample.InputByte.HasValue || _hasLastGameMovementInputByte,
                FormatMovementDirection(movementSample.InputByte ?? (_hasLastGameMovementInputByte ? _lastGameMovementInputByte : null)),
                FormatMovementActionBits(movementSample.InputByte ?? (_hasLastGameMovementInputByte ? _lastGameMovementInputByte : null)),
                movementSample.YawRaw.HasValue,
                movementSample.YawRaw?.ToString(CultureInfo.InvariantCulture) ?? "-",
                movementSample.HasPosition,
                movementSample.HasPosition
                    ? $"({movementSample.PositionXRaw},{movementSample.PositionYRaw},{movementSample.PositionZRaw})"
                    : "-",
                movementSample.HasFacing,
                movementSample.HasFacing
                    ? $"({movementSample.Facing0Raw},{movementSample.Facing1Raw})"
                    : "-",
                optionalPayload.Length,
                trailingBytes,
                movement.Uid,
                broadcastCount);
        }

        Log.Verbose(
            "Channel packet105 <- {Remote}: tick={Tick} flags=0x{Flags:X2} optionalBytes={OptionalBytes} trailingBytes={TrailingBytes} uid={Uid} broadcastCount={BroadcastCount} trailingPayload={TrailingPayloadHex}",
            _remoteLabel,
            tick,
            flags,
            optionalPayload.Length,
            trailingBytes,
            movement.Uid,
            broadcastCount,
            trailingPayloadHex);

        await SendActiveClientGameInitRefreshOnceAsync("packet105-active-client");
        await SendPendingPlayerEnteringClearAsync("packet105");
        await SendPendingSilentLoadoutHudRefreshAsync("packet105");
    }

    private async Task HandlePacket106GameActionPoseAsync(PacketReader reader)
    {
        var payload = reader.RemainingSpan.ToArray();
        if (!reader.TryReadByte(out var action) ||
            !reader.TryReadShort(out var originXRaw) ||
            !reader.TryReadShort(out var originYRaw) ||
            !reader.TryReadShort(out var originZRaw) ||
            !reader.TryReadShort(out var facing0Raw) ||
            !reader.TryReadShort(out var facing1Raw) ||
            !reader.TryReadByte(out var poseState) ||
            !TryReadProtocolFloat(reader, out var vectorX) ||
            !TryReadProtocolFloat(reader, out var vectorY) ||
            !TryReadProtocolFloat(reader, out var vectorZ))
        {
            Log.Warning(
                "Channel packet106 <- {Remote}: malformed action-pose payloadBytes={PayloadBytes} remaining={Remaining} hex={PayloadHex}",
                _remoteLabel,
                payload.Length,
                reader.Remaining,
                Convert.ToHexString(payload));
            return;
        }

        byte? optionalTag = null;
        short? optionalValue = null;
        byte? optionalByte = null;
        if (reader.TryReadByte(out var optionalTagValue))
        {
            optionalTag = optionalTagValue;
            if (optionalTagValue != 0 &&
                reader.TryReadShort(out var optionalShortValue) &&
                reader.TryReadByte(out var optionalByteValue))
            {
                optionalValue = optionalShortValue;
                optionalByte = optionalByteValue;
            }
        }

        var trailingBytes = reader.Remaining;
        var trailingPayloadHex = string.Empty;
        if (trailingBytes > 0)
        {
            reader.TryReadFixedBytes(trailingBytes, out var trailingPayload);
            trailingPayloadHex = Convert.ToHexString(trailingPayload ?? Array.Empty<byte>());
        }

        var originX = ActionPoseRawToWorldCoordinate(originXRaw);
        var originY = ActionPoseRawToWorldCoordinate(originYRaw);
        var originZ = ActionPoseRawToWorldCoordinate(originZRaw);
        if (_currentGameRoom is null)
        {
            Log.Warning(
                "Channel packet106 <- {Remote}: action-pose ignored, no active game room action={Action} poseState={PoseState} origin={Origin} vector={Vector}",
                _remoteLabel,
                action,
                poseState,
                FormatGameVector3(originX, originY, originZ),
                FormatGameVector3(vectorX, vectorY, vectorZ));
            return;
        }

        if (!IsFiniteGameVector3(originX, originY, originZ) ||
            !IsFiniteGameVector3(vectorX, vectorY, vectorZ))
        {
            Log.Warning(
                "Channel packet106 <- {Remote}: action-pose skipped action={Action} poseState={PoseState} origin={Origin} vector={Vector} payloadBytes={PayloadBytes} hex={PayloadHex}",
                _remoteLabel,
                action,
                poseState,
                FormatGameVector3(originX, originY, originZ),
                FormatGameVector3(vectorX, vectorY, vectorZ),
                payload.Length,
                Convert.ToHexString(payload));
            return;
        }

        var slotOneBased = ResolveShootSlotOneBased(poseState);
        UpdateLocalGamePositionFromActionPose(originX, originY, originZ, facing0Raw, facing1Raw);
        var shoot = new PracticeRoomManager.GameShootAction(
            _localGameUid,
            action,
            slotOneBased,
            originXRaw,
            originYRaw,
            originZRaw,
            facing0Raw,
            facing1Raw,
            vectorX,
            vectorY,
            vectorZ,
            DateTimeOffset.UtcNow);
        var broadcastCount = await _practiceRoomManager.BroadcastGameShootAsync(
            _currentGameRoom.RoomId,
            this,
            shoot);
        var weaponItem = ResolveLocalLoadoutItem(slotOneBased);
        var weaponDamage = ResolveGameWeaponDamage(weaponItem);
        var hitRule = ResolveGameWeaponHitRule(weaponItem);
        var clientTargetUid = ResolveClientShootTargetUid(optionalTag, optionalValue);
        var damageResult = await _practiceRoomManager.BroadcastGameDamageAsync(
            _currentGameRoom.RoomId,
            this,
            _localGameUid,
            weaponDamage,
            hitRule,
            clientTargetUid);

        Log.Information(
            "Channel packet106 <- {Remote}: shoot action={Action} uid={Uid} slot={Slot} poseState={PoseState} weapon={WeaponResource} weaponDamage={WeaponDamage} hitRadius={HitRadius} maxRange={MaxRange} origin={Origin} vector={Vector} facing0={Facing0} facing1={Facing1} optionalTag={OptionalTag} optionalValue={OptionalValue} optionalByte={OptionalByte} clientTargetUid={ClientTargetUid} trailingBytes={TrailingBytes} trailingPayload={TrailingPayloadHex}; packet113 broadcastCount={BroadcastCount}, damageApplied={DamageApplied}, victimUid={VictimUid}, victimHealth={VictimHealth}/{VictimMaxHealth}, killed={Killed}, damageBroadcastCount={DamageBroadcastCount}, deathBroadcastCount={DeathBroadcastCount}, damageReason={DamageReason}, candidates={DamageCandidateCount}, positioned={DamagePositionedCandidateCount}, attackerTeam={DamageAttackerTeamId}, bestHitScore={DamageBestHitScore}",
            _remoteLabel,
            action,
            _localGameUid,
            slotOneBased,
            poseState,
            weaponItem?.Resource ?? "-",
            weaponDamage,
            hitRule.HitRadius,
            hitRule.MaxRange,
            FormatGameVector3(originX, originY, originZ),
            FormatGameVector3(vectorX, vectorY, vectorZ),
            unchecked((ushort)facing0Raw),
            unchecked((ushort)facing1Raw),
            optionalTag,
            optionalValue,
            optionalByte,
            clientTargetUid,
            trailingBytes,
            trailingPayloadHex,
            broadcastCount,
            damageResult.Applied,
            damageResult.VictimUid,
            damageResult.VictimHealth,
            damageResult.VictimMaxHealth,
            damageResult.Killed,
            damageResult.BroadcastCount,
            damageResult.DeathBroadcastCount,
            damageResult.Reason,
            damageResult.CandidateCount,
            damageResult.PositionedCandidateCount,
            damageResult.AttackerTeamId,
            FormatGameHitScore(damageResult.BestHitScore));
    }

    private async Task HandlePacket112GameActionVectorAsync(PacketReader reader)
    {
        if (!reader.TryReadByte(out var action) ||
            !TryReadProtocolFloat(reader, out var originX) ||
            !TryReadProtocolFloat(reader, out var originY) ||
            !TryReadProtocolFloat(reader, out var originZ) ||
            !TryReadProtocolFloat(reader, out var vectorX) ||
            !TryReadProtocolFloat(reader, out var vectorY) ||
            !TryReadProtocolFloat(reader, out var vectorZ) ||
            !reader.TryReadShort(out var facing0Raw) ||
            !reader.TryReadShort(out var facing1Raw))
        {
            Log.Warning(
                "Channel packet112 <- {Remote}: malformed action-vector payload remaining={Remaining}",
                _remoteLabel,
                reader.Remaining);
            return;
        }

        var trailingBytes = reader.Remaining;
        var trailingPayloadHex = string.Empty;
        if (trailingBytes > 0)
        {
            reader.TryReadFixedBytes(trailingBytes, out var trailingPayload);
            trailingPayloadHex = Convert.ToHexString(trailingPayload ?? Array.Empty<byte>());
        }

        if (_currentGameRoom is null)
        {
            Log.Warning(
                "Channel packet112 <- {Remote}: action-vector ignored, no active game room action={Action} origin={Origin} vector={Vector}",
                _remoteLabel,
                action,
                FormatGameVector3(originX, originY, originZ),
                FormatGameVector3(vectorX, vectorY, vectorZ));
            return;
        }

        var specialRearmCount = await SendSpecialWeaponRearmIfDueAsync("packet112");

        Log.Information(
            "Channel packet112 <- {Remote}: grenade-throw action={Action} uid={Uid} origin={Origin} vector={Vector} facing0={Facing0} facing1={Facing1} trailingBytes={TrailingBytes} trailingPayload={TrailingPayloadHex}; remote equipment-action broadcast skipped, specialRearmCount={SpecialRearmCount}",
            _remoteLabel,
            action,
            _localGameUid,
            FormatGameVector3(originX, originY, originZ),
            FormatGameVector3(vectorX, vectorY, vectorZ),
            unchecked((ushort)facing0Raw),
            unchecked((ushort)facing1Raw),
            trailingBytes,
            trailingPayloadHex,
            specialRearmCount);
    }

    private async Task HandlePacket117GameReloadAsync(PacketReader reader)
    {
        if (_currentGameRoom is null)
        {
            Log.Warning("Channel packet117 <- {Remote}: reload ignored, no active game room", _remoteLabel);
            return;
        }

        if (reader.Remaining > 0)
        {
            var trailingBytes = reader.Remaining;
            reader.TryReadFixedBytes(trailingBytes, out var trailingPayload);
            Log.Verbose(
                "Channel packet117 <- {Remote}: unexpected reload trailingBytes={TrailingBytes} hex={PayloadHex}",
                _remoteLabel,
                trailingBytes,
                Convert.ToHexString(trailingPayload ?? Array.Empty<byte>()));
        }

        var slotOneBased = ResolveCurrentReloadReadySlot();
        var ammoRefreshSent = await SendLocalReloadReadyAsync(slotOneBased, "packet117-reload");
        var broadcastCount = await _practiceRoomManager.BroadcastGameReloadActionAsync(
            _currentGameRoom.RoomId,
            this,
            _localGameUid,
            (byte)(slotOneBased - 1));

        Log.Information(
            "Channel packet117 <- {Remote}: reload uid={Uid}; packet143 local ammo refresh sent={AmmoRefreshSent}; packet175 local ack sent slot={Slot}; broadcastCount={BroadcastCount}",
            _remoteLabel,
            _localGameUid,
            ammoRefreshSent,
            slotOneBased,
            broadcastCount);
    }

    private async Task HandlePacket118GameDropWeaponAsync(PacketReader reader)
    {
        if (_currentGameRoom is null)
        {
            Log.Warning("Channel packet118 <- {Remote}: drop-weapon ignored, no active game room", _remoteLabel);
            return;
        }

        if (reader.Remaining > 0)
        {
            var trailingBytes = reader.Remaining;
            reader.TryReadFixedBytes(trailingBytes, out var trailingPayload);
            Log.Verbose(
                "Channel packet118 <- {Remote}: unexpected drop-weapon trailingBytes={TrailingBytes} hex={PayloadHex}",
                _remoteLabel,
                trailingBytes,
                Convert.ToHexString(trailingPayload ?? Array.Empty<byte>()));
        }

        var broadcastCount = await _practiceRoomManager.BroadcastGameDropWeaponAsync(
            _currentGameRoom.RoomId,
            this,
            _localGameUid);

        Log.Verbose(
            "Channel packet118 <- {Remote}: drop-weapon uid={Uid} broadcastCount={BroadcastCount}",
            _remoteLabel,
            _localGameUid,
            broadcastCount);
    }

    private void HandlePacket125GamePickUpDropItem(PacketReader reader)
    {
        if (_currentGameRoom is null)
        {
            Log.Warning("Channel packet125 <- {Remote}: pickup-drop-item ignored, no active game room", _remoteLabel);
            return;
        }

        var payload = reader.RemainingSpan.ToArray();
        if (reader.Remaining > 0)
        {
            reader.TryReadFixedBytes(reader.Remaining, out _);
        }

        Log.Information(
            "Channel packet125 <- {Remote}: pickup-drop-item uid={Uid} payloadBytes={PayloadBytes} hex={PayloadHex}; broadcast skipped",
            _remoteLabel,
            _localGameUid,
            payload.Length,
            Convert.ToHexString(payload));
    }

    private async Task HandlePacket142GameReloadReadyAsync(PacketReader reader)
    {
        if (_currentGameRoom is null)
        {
            Log.Warning("Channel packet142 <- {Remote}: reload-ready ignored, no active game room", _remoteLabel);
            return;
        }

        var slotOneBased = reader.TryReadByte(out var clientSlot) && clientSlot > 0
            ? clientSlot
            : ResolveCurrentReloadReadySlot();

        if (reader.Remaining > 0)
        {
            var trailingBytes = reader.Remaining;
            reader.TryReadFixedBytes(trailingBytes, out var trailingPayload);
            Log.Verbose(
                "Channel packet142 <- {Remote}: reload-ready slot={Slot} trailingBytes={TrailingBytes} hex={PayloadHex}",
                _remoteLabel,
                slotOneBased,
                trailingBytes,
                Convert.ToHexString(trailingPayload ?? Array.Empty<byte>()));
        }

        slotOneBased = (byte)Math.Clamp((int)slotOneBased, 1, ClientWeaponSlotCount);
        var ammoRefreshSent = await SendLocalReloadReadyAsync(slotOneBased, "packet142-reload-ready");

        Log.Information(
            "Channel packet142 <- {Remote}: reload-ready uid={Uid}; packet143 local ammo refresh sent={AmmoRefreshSent}; packet175 local ack sent slot={Slot}",
            _remoteLabel,
            _localGameUid,
            ammoRefreshSent,
            slotOneBased);
    }

    private async Task HandlePacket143GameActionStateAsync(PacketReader reader)
    {
        if (!reader.TryReadInt(out var actionCode) || !reader.TryReadByte(out var actionState))
        {
            Log.Warning(
                "Channel packet143 <- {Remote}: malformed action-state payload remaining={Remaining}",
                _remoteLabel,
                reader.Remaining);
            return;
        }

        if (reader.Remaining > 0)
        {
            var trailingBytes = reader.Remaining;
            reader.TryReadFixedBytes(trailingBytes, out var trailingPayload);
            Log.Verbose(
                "Channel packet143 <- {Remote}: actionCode={ActionCode} state={ActionState} trailingBytes={TrailingBytes} hex={PayloadHex}",
                _remoteLabel,
                actionCode,
                actionState,
                trailingBytes,
                Convert.ToHexString(trailingPayload ?? Array.Empty<byte>()));
        }

        if (_currentGameRoom is null)
        {
            Log.Warning(
                "Channel packet143 <- {Remote}: action-state ignored, no active game room actionCode={ActionCode} state={ActionState}",
                _remoteLabel,
                actionCode,
                actionState);
            return;
        }

        if (TryResolveWeaponSlotChange(actionCode, actionState, out var weaponSlot, out var weaponSlotReason))
        {
            var weaponSlotBroadcastCount = await _practiceRoomManager.BroadcastGameWeaponSlotAsync(
                _currentGameRoom.RoomId,
                this,
                _localGameUid,
                weaponSlot,
                weaponSlotReason);

            Log.Information(
                "Channel packet143 <- {Remote}: weapon-slot broadcast actionCode={ActionCode} state={ActionState} uid={Uid} slot={Slot} reason={Reason} broadcastCount={BroadcastCount}",
                _remoteLabel,
                actionCode,
                actionState,
                _localGameUid,
                weaponSlot,
                weaponSlotReason,
                weaponSlotBroadcastCount);
            return;
        }

        Log.Verbose(
            "Channel packet143 <- {Remote}: actionCode={ActionCode} state={ActionState} consumed",
            _remoteLabel,
            actionCode,
            actionState);
    }

    private bool TryResolveWeaponSlotChange(
        int actionCode,
        byte actionState,
        out byte weaponSlot,
        out string reason)
    {
        weaponSlot = 0;
        reason = string.Empty;

        if (actionState == GameActionStateInactive)
        {
            return false;
        }

        var availableSlots = GetAvailableClientWeaponSlots(ClientWeaponSlotCount);
        if (availableSlots.Length == 0)
        {
            return false;
        }

        if (actionCode is >= GameActionFirstDirectWeaponSlotCode and <= GameActionLastDirectWeaponSlotCode)
        {
            var requestedSlot = (byte)(actionCode - GameActionFirstDirectWeaponSlotCode);
            if (!availableSlots.Contains(requestedSlot) || !TryApplyLocalWeaponSlot(requestedSlot))
            {
                return false;
            }

            weaponSlot = requestedSlot;
            reason = "packet143-direct-weapon-slot";
            return true;
        }

        if (actionCode == GameActionNextWeaponCode)
        {
            foreach (var candidateSlot in availableSlots.Where(slot => slot < ClientScrollableWeaponSlotCount))
            {
                if (candidateSlot <= _currentWeaponSlot)
                {
                    continue;
                }

                if (!TryApplyLocalWeaponSlot(candidateSlot))
                {
                    return false;
                }

                weaponSlot = candidateSlot;
                reason = "packet143-next-weapon";
                return true;
            }

            return false;
        }

        if (actionCode == GameActionPreviousWeaponCode)
        {
            foreach (var candidateSlot in availableSlots
                         .Where(slot => slot < ClientScrollableWeaponSlotCount)
                         .OrderByDescending(slot => slot))
            {
                if (candidateSlot >= _currentWeaponSlot)
                {
                    continue;
                }

                if (!TryApplyLocalWeaponSlot(candidateSlot))
                {
                    return false;
                }

                weaponSlot = candidateSlot;
                reason = "packet143-previous-weapon";
                return true;
            }

            return false;
        }

        if (actionCode != GameActionAlternateWeaponCode)
        {
            return false;
        }

        if (_previousWeaponSlot != _currentWeaponSlot &&
            availableSlots.Contains(_previousWeaponSlot) &&
            TryApplyLocalWeaponSlot(_previousWeaponSlot))
        {
            weaponSlot = _currentWeaponSlot;
            reason = "packet143-alternate-previous-weapon";
            return true;
        }

        foreach (var candidateSlot in availableSlots)
        {
            if (candidateSlot == _currentWeaponSlot)
            {
                continue;
            }

            if (!TryApplyLocalWeaponSlot(candidateSlot))
            {
                return false;
            }

            weaponSlot = candidateSlot;
            reason = "packet143-alternate-first-weapon";
            return true;
        }

        return false;
    }

    private bool TryApplyLocalWeaponSlot(byte weaponSlot, byte maxSlotExclusive = ClientWeaponSlotCount)
    {
        if (weaponSlot >= maxSlotExclusive || weaponSlot == _currentWeaponSlot)
        {
            return false;
        }

        _previousWeaponSlot = _currentWeaponSlot;
        _currentWeaponSlot = weaponSlot;
        return true;
    }

    private byte[] GetAvailableClientWeaponSlots(byte slotCount)
    {
        if (_currentGameRoom is null)
        {
            return [];
        }

        var playerState = GetLocalPlayerState(_currentGameRoom);
        var loadoutItems = playerState?.GetGameLoadoutItems() ?? Array.Empty<PlayerStore.PlayerState.GameLoadoutItem>();
        return GetSupportedGameEquipmentItems(loadoutItems)
            .Select(item => (int)item.Slot - 1)
            .Where(slot => slot >= 0 && slot < slotCount)
            .Distinct()
            .OrderBy(slot => slot)
            .Select(slot => (byte)slot)
            .ToArray();
    }

    private byte ResolveCurrentReloadReadySlot()
    {
        return (byte)(Math.Min((int)_currentWeaponSlot, ClientWeaponSlotCount - 1) + 1);
    }

    private byte ResolveShootSlotOneBased(byte poseState)
    {
        if (poseState is > 0 and <= ClientWeaponSlotCount)
        {
            return poseState;
        }

        return ResolveCurrentReloadReadySlot();
    }

    private async Task<bool> SendLocalReloadReadyAsync(byte slotOneBased, string trigger)
    {
        slotOneBased = (byte)Math.Clamp((int)slotOneBased, 1, ClientWeaponSlotCount);
        var item = ResolveLocalLoadoutItem(slotOneBased);
        var ammoRefreshSent = false;
        if (item is not null)
        {
            await SendPacket143GameLoadoutItemRefreshAsync(item, trigger);
            ammoRefreshSent = true;
        }

        await SendPacket175GameReloadReadyAsync(slotOneBased, trigger);
        return ammoRefreshSent;
    }

    private PlayerStore.PlayerState.GameLoadoutItem? ResolveLocalLoadoutItem(byte slotOneBased)
    {
        if (_currentGameRoom is null)
        {
            return null;
        }

        var playerState = GetLocalPlayerState(_currentGameRoom);
        var loadoutItems = playerState?.GetGameLoadoutItems() ?? Array.Empty<PlayerStore.PlayerState.GameLoadoutItem>();
        return loadoutItems.FirstOrDefault(item => item.Slot == slotOneBased && IsSupportedGameEquipmentItem(item));
    }

    private static int ResolveGameWeaponDamage(PlayerStore.PlayerState.GameLoadoutItem? item)
    {
        if (item is not null &&
            TryGetWeaponTipNumber(item.Resource, "output", out var output) &&
            output > 0f)
        {
            return Math.Clamp((int)MathF.Round(output), 1, MaxGameHurtDamage);
        }

        return DefaultGameHurtDamage;
    }

    private byte ResolveClientShootTargetUid(byte? optionalTag, short? optionalValue)
    {
        if (optionalTag is not > 0 ||
            optionalTag.Value == _localGameUid)
        {
            return 0;
        }

        return optionalTag.Value;
    }

    private static PracticeRoomManager.GameDamageHitRule ResolveGameWeaponHitRule(
        PlayerStore.PlayerState.GameLoadoutItem? item)
    {
        var hitRadius = item?.Subtype switch
        {
            4 => ShotgunShootHitRadius,
            6 => MeleeShootHitRadius,
            13 => ShieldShootHitRadius,
            _ => DefaultShootHitRadius
        };
        var maxRange = item?.Subtype switch
        {
            4 => ShotgunShootMaxRange,
            6 => MeleeShootMaxRange,
            13 => ShieldShootMaxRange,
            _ => DefaultShootMaxRange
        };

        if (item is not null &&
            TryGetWeaponTipNumber(item.Resource, "distance", out var distance) &&
            distance > 0f)
        {
            maxRange = Math.Clamp(NormalizeWeaponDistance(distance), 0.5f, DefaultShootMaxRange);
        }

        return new PracticeRoomManager.GameDamageHitRule(
            RequireShootHit: true,
            UseProximityHit: item?.Subtype is 6 or 13,
            HitRadius: hitRadius,
            MaxRange: maxRange);
    }

    private static float NormalizeWeaponDistance(float distance)
    {
        return distance > 100f ? distance / 40f : distance;
    }

    private static bool TryGetWeaponTipNumber(string resource, string propertyName, out float value)
    {
        value = 0f;
        if (!ShopItemDatabase.TryGetShopItemByResource(resource, out var item) ||
            item.Tip is not IReadOnlyDictionary<string, object?> tip ||
            !tip.TryGetValue(propertyName, out var propertyValue))
        {
            return false;
        }

        return TryReadTipNumber(propertyValue, out value);
    }

    private static bool TryReadTipNumber(object? value, out float number)
    {
        number = 0f;
        switch (value)
        {
            case float f when float.IsFinite(f):
                number = f;
                return true;
            case double d when double.IsFinite(d):
                number = (float)d;
                return true;
            case int i:
                number = i;
                return true;
            case long l:
                number = l;
                return true;
            case IReadOnlyList<object?> list:
                foreach (var item in list)
                {
                    if (TryReadTipNumber(item, out number))
                    {
                        return true;
                    }
                }

                return false;
            case JsonElement element:
                return TryReadJsonElementNumber(element, out number);
            default:
                return false;
        }
    }

    private static bool TryReadJsonElementNumber(JsonElement element, out float number)
    {
        number = 0f;
        switch (element.ValueKind)
        {
            case JsonValueKind.Number when element.TryGetSingle(out var single) && float.IsFinite(single):
                number = single;
                return true;
            case JsonValueKind.Array:
                foreach (var item in element.EnumerateArray())
                {
                    if (TryReadJsonElementNumber(item, out number))
                    {
                        return true;
                    }
                }

                return false;
            default:
                return false;
        }
    }

    private static int GetGameMovementOptionalByteCount(byte flags)
    {
        var length = 0;
        if ((flags & 0x01) != 0)
        {
            length += 1;
        }

        if ((flags & 0x08) != 0)
        {
            length += 2;
        }

        if ((flags & 0x04) != 0)
        {
            length += 6;
        }

        if ((flags & 0x02) != 0)
        {
            length += 4;
        }

        return length;
    }

    private static bool TryReadProtocolFloat(PacketReader reader, out float value)
    {
        value = 0f;
        if (!reader.TryReadInt(out var rawValue))
        {
            return false;
        }

        value = BitConverter.Int32BitsToSingle(rawValue);
        return true;
    }

    private static int ResolveGameHurtDamage(int rawValue, float scalar)
    {
        if (float.IsFinite(scalar) && scalar > 0f && scalar <= MaxGameHurtDamage)
        {
            return Math.Clamp((int)MathF.Round(scalar), 1, MaxGameHurtDamage);
        }

        if (rawValue is > 0 and <= MaxGameHurtDamage)
        {
            return rawValue;
        }

        return DefaultGameHurtDamage;
    }

    private static void WriteGameObjectDeltaFlags(PacketWriter writer, int flags)
    {
        writer.WriteByte((byte)(flags >> 24));
        writer.WriteByte((byte)(flags >> 16));
        writer.WriteByte((byte)(flags >> 8));
        writer.WriteByte((byte)flags);
    }

    private static void WriteCompressedVector3Raw(PacketWriter writer, short x, short y, short z)
    {
        writer.WriteShort(x);
        writer.WriteShort(y);
        writer.WriteShort(z);
    }

    private static void WriteCompressedVector3(PacketWriter writer, float x, float y, float z)
    {
        writer.WriteShort(ToCompressedVectorRaw(x));
        writer.WriteShort(ToCompressedVectorRaw(y));
        writer.WriteShort(ToCompressedVectorRaw(z));
    }

    private static short ToCompressedVectorRaw(float value)
    {
        if (!float.IsFinite(value))
        {
            return 0;
        }

        return (short)Math.Clamp(
            (int)MathF.Round(value * ActionPoseRawCoordinateScale),
            short.MinValue + 1,
            short.MaxValue);
    }

    private static (float X, float Y, float Z) ResolveRemoteShootVector(PracticeRoomManager.GameShootAction shoot)
    {
        if (IsUsableShootVector(shoot.VectorX, shoot.VectorY, shoot.VectorZ))
        {
            return (shoot.VectorX, shoot.VectorY, shoot.VectorZ);
        }

        var yaw = shoot.Facing0Raw / FacingRawAngleScale;
        var pitch = shoot.Facing1Raw / FacingRawAngleScale;
        var cosPitch = MathF.Cos(pitch);
        var x = MathF.Sin(yaw) * cosPitch * ShootFallbackVectorLength;
        var y = MathF.Sin(pitch) * ShootFallbackVectorLength;
        var z = -MathF.Cos(yaw) * cosPitch * ShootFallbackVectorLength;
        return IsFiniteGameVector3(x, y, z) ? (x, y, z) : (0f, 0f, -ShootFallbackVectorLength);
    }

    private static bool IsUsableShootVector(float x, float y, float z)
    {
        return IsFiniteGameVector3(x, y, z) &&
               (MathF.Abs(x) > ShootVectorEpsilon ||
                MathF.Abs(y) > ShootVectorEpsilon ||
                MathF.Abs(z) > ShootVectorEpsilon);
    }

    private static float ActionPoseRawToWorldCoordinate(short raw)
    {
        return raw / ActionPoseRawCoordinateScale;
    }

    private static bool IsFiniteGameVector3(float x, float y, float z)
    {
        return float.IsFinite(x) && float.IsFinite(y) && float.IsFinite(z);
    }

    private static MovementSyncSample DecodeGameMovementSample(byte flags, byte[] payload)
    {
        var offset = 0;
        byte? inputByte = null;
        short? yawRaw = null;
        var hasPosition = false;
        short positionXRaw = 0;
        short positionYRaw = 0;
        short positionZRaw = 0;
        var hasFacing = false;
        short facing0Raw = 0;
        short facing1Raw = 0;

        if ((flags & 0x01) != 0 && TryReadInt8(payload, ref offset, out var input))
        {
            inputByte = input;
        }

        if ((flags & 0x08) != 0 && TryReadInt16LittleEndian(payload, ref offset, out var yaw))
        {
            yawRaw = yaw;
        }

        if ((flags & 0x04) != 0 &&
            TryReadInt16LittleEndian(payload, ref offset, out var posX) &&
            TryReadInt16LittleEndian(payload, ref offset, out var posY) &&
            TryReadInt16LittleEndian(payload, ref offset, out var posZ))
        {
            hasPosition = true;
            positionXRaw = posX;
            positionYRaw = posY;
            positionZRaw = posZ;
        }

        if ((flags & 0x02) != 0 &&
            TryReadInt16LittleEndian(payload, ref offset, out var facing0) &&
            TryReadInt16LittleEndian(payload, ref offset, out var facing1))
        {
            hasFacing = true;
            facing0Raw = facing0;
            facing1Raw = facing1;
        }

        return new MovementSyncSample(
            inputByte,
            yawRaw,
            hasPosition,
            positionXRaw,
            positionYRaw,
            positionZRaw,
            hasFacing,
            facing0Raw,
            facing1Raw);
    }

    private static bool TryReadInt8(byte[] payload, ref int offset, out byte value)
    {
        value = 0;
        if (offset >= payload.Length)
        {
            return false;
        }

        value = payload[offset];
        offset++;
        return true;
    }

    private static bool TryReadInt16LittleEndian(byte[] payload, ref int offset, out short value)
    {
        value = 0;
        if (payload.Length - offset < 2)
        {
            return false;
        }

        value = (short)(payload[offset] | (payload[offset + 1] << 8));
        offset += 2;
        return true;
    }

    private static string FormatOptionalByte(byte? value)
    {
        return value.HasValue
            ? $"0x{value.Value:X2}"
            : "-";
    }

    private static string FormatMovementDirection(byte? input)
    {
        if (!input.HasValue)
        {
            return "-";
        }

        var parts = new List<string>(4);
        var value = input.Value;
        if ((value & 0x10) != 0)
        {
            parts.Add("forward");
        }

        if ((value & 0x20) != 0)
        {
            parts.Add("back");
        }

        if ((value & 0x40) != 0)
        {
            parts.Add("left");
        }

        if ((value & 0x80) != 0)
        {
            parts.Add("right");
        }

        return parts.Count == 0
            ? "none"
            : string.Join("+", parts);
    }

    private static string FormatMovementActionBits(byte? input)
    {
        if (!input.HasValue)
        {
            return "-";
        }

        var parts = new List<string>(3);
        var value = input.Value;
        if ((value & 0x01) != 0)
        {
            parts.Add("bit01");
        }

        if ((value & 0x02) != 0)
        {
            parts.Add("bit02");
        }

        if ((value & 0x04) != 0)
        {
            parts.Add("bit04");
        }

        return parts.Count == 0
            ? "none"
            : string.Join("+", parts);
    }

    private readonly record struct MovementSyncSample(
        byte? InputByte,
        short? YawRaw,
        bool HasPosition,
        short PositionXRaw,
        short PositionYRaw,
        short PositionZRaw,
        bool HasFacing,
        short Facing0Raw,
        short Facing1Raw);

    private readonly record struct TeleportCoordinates(
        float X,
        float Y,
        float Z,
        bool Relative,
        PracticeRoomManager.GamePosition Position);

    private async Task SendPendingPlayerEnteringClearAsync(string trigger)
    {
        if (_playerEnteringClearRetriesRemaining <= 0)
        {
            return;
        }

        _playerEnteringClearRetriesRemaining--;
        await SendPacket151PlayerEnteringCompleteAsync(trigger, _playerEnteringClearRetriesRemaining);
    }

    private async Task SendPendingSilentLoadoutHudRefreshAsync(string trigger)
    {
        if (_silentLoadoutHudRefreshRetriesRemaining <= 0 || _currentGameRoom is null)
        {
            return;
        }

        var playerState = GetLocalPlayerState(_currentGameRoom);
        var loadoutItems = playerState?.GetGameLoadoutItems() ?? Array.Empty<PlayerStore.PlayerState.GameLoadoutItem>();
        if (loadoutItems.Count == 0)
        {
            _silentLoadoutHudRefreshRetriesRemaining = 0;
            Log.Verbose(
                "Channel packet143 silent in-game hotbar refresh skipped for {Remote}: trigger={Trigger} loadout=empty",
                _remoteLabel,
                trigger);
            return;
        }

        _silentLoadoutHudRefreshRetriesRemaining--;
        await SendPacket143SilentGameLoadoutHudRefreshAsync(
            loadoutItems,
            trigger,
            _silentLoadoutHudRefreshRetriesRemaining);
    }

    private async Task<int> SendSpecialWeaponRearmIfDueAsync(string trigger)
    {
        if (_currentGameRoom is null)
        {
            return 0;
        }

        var playerState = GetLocalPlayerState(_currentGameRoom);
        var loadoutItems = playerState?.GetGameLoadoutItems() ?? Array.Empty<PlayerStore.PlayerState.GameLoadoutItem>();
        var rearmItems = loadoutItems
            .Where(IsSpecialRearmGameEquipmentItem)
            .OrderBy(item => item.Slot)
            .ToArray();
        if (rearmItems.Length == 0)
        {
            return 0;
        }

        var now = DateTimeOffset.UtcNow;
        var sentCount = 0;
        foreach (var item in rearmItems)
        {
            if (item.Slot == 0)
            {
                continue;
            }

            var rearmInterval = ResolveSpecialWeaponRearmInterval(item);
            if (_lastSpecialWeaponRearmBySlot.TryGetValue(item.Slot, out var lastRearm) &&
                now - lastRearm < rearmInterval)
            {
                continue;
            }

            _lastSpecialWeaponRearmBySlot[item.Slot] = now;
            await SendPacket143GameLoadoutItemRefreshAsync(item, $"special-rearm-{trigger}");
            await SendPacket175GameReloadReadyAsync(item.Slot, $"special-rearm-{trigger}");
            sentCount++;
        }

        if (sentCount > 0)
        {
            Log.Information(
                "Channel special weapon rearm -> {Remote}: trigger={Trigger} itemCount={ItemCount}",
                _remoteLabel,
                trigger,
                sentCount);
        }

        return sentCount;
    }

    private void StartKnifeAutoRearmLoopIfNeeded(string trigger)
    {
        if (!EnableKnifeAutoRearmLoop || _knifeAutoRearmCts is not null || _currentGameRoom is null)
        {
            return;
        }

        var interval = ResolveKnifeAutoRearmInterval(_currentGameRoom);
        if (interval is null)
        {
            return;
        }

        var cts = new CancellationTokenSource();
        _knifeAutoRearmCts = cts;
        _ = RunKnifeAutoRearmLoopAsync(trigger, interval.Value, cts.Token);

        Log.Information(
            "Channel knife auto rearm loop started -> {Remote}: trigger={Trigger} intervalMs={IntervalMs}",
            _remoteLabel,
            trigger,
            (int)interval.Value.TotalMilliseconds);
    }

    private void StopKnifeAutoRearmLoop()
    {
        var cts = _knifeAutoRearmCts;
        if (cts is null)
        {
            return;
        }

        _knifeAutoRearmCts = null;
        cts.Cancel();
    }

    private async Task RunKnifeAutoRearmLoopAsync(
        string trigger,
        TimeSpan interval,
        CancellationToken cancellationToken)
    {
        try
        {
            await Task.Delay(TimeSpan.FromSeconds(KnifeAutoRearmInitialDelaySeconds), cancellationToken);
            while (!cancellationToken.IsCancellationRequested &&
                   _state == ChannelState.InGame &&
                   _currentGameRoom is not null)
            {
                var sentCount = await SendKnifeWeaponRearmAsync($"auto-{trigger}");
                if (sentCount == 0)
                {
                    break;
                }

                await Task.Delay(interval, cancellationToken);
            }
        }
        catch (OperationCanceledException)
        {
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Channel knife auto rearm loop stopped after send failure -> {Remote}", _remoteLabel);
            if (_currentGameRoom is not null)
            {
                _practiceRoomManager.UnregisterGameChannel(_currentGameRoom.RoomId, this, out _);
            }
        }
        finally
        {
            if (_knifeAutoRearmCts?.Token == cancellationToken)
            {
                _knifeAutoRearmCts = null;
            }
        }
    }

    private TimeSpan? ResolveKnifeAutoRearmInterval(PracticeRoomManager.PracticeRoomSession room)
    {
        var playerState = GetLocalPlayerState(room);
        var knifeItems = (playerState?.GetGameLoadoutItems() ?? Array.Empty<PlayerStore.PlayerState.GameLoadoutItem>())
            .Where(IsKnifeRearmGameEquipmentItem)
            .ToArray();
        if (knifeItems.Length == 0)
        {
            return null;
        }

        return knifeItems
            .Select(ResolveSpecialWeaponRearmInterval)
            .DefaultIfEmpty(TimeSpan.FromSeconds(SpecialWeaponRearmMinSeconds))
            .Min();
    }

    internal async Task<int> SendKnifeWeaponRearmAsync(string trigger)
    {
        if (_currentGameRoom is null)
        {
            return 0;
        }

        var playerState = GetLocalPlayerState(_currentGameRoom);
        var knifeItems = (playerState?.GetGameLoadoutItems() ?? Array.Empty<PlayerStore.PlayerState.GameLoadoutItem>())
            .Where(IsKnifeRearmGameEquipmentItem)
            .OrderBy(item => item.Slot)
            .ToArray();
        var sentCount = 0;
        foreach (var item in knifeItems)
        {
            if (item.Slot == 0)
            {
                continue;
            }

            await SendPacket143GameLoadoutItemRefreshAsync(item, $"knife-rearm-{trigger}");
            await SendPacket175GameReloadReadyAsync(item.Slot, $"knife-rearm-{trigger}");
            sentCount++;
        }

        if (sentCount > 0)
        {
            Log.Information(
                "Channel knife weapon rearm -> {Remote}: trigger={Trigger} itemCount={ItemCount}",
                _remoteLabel,
                trigger,
                sentCount);
        }

        return sentCount;
    }

    private Task SendPacket15Async()
    {
        using var writer = new PacketWriter();
        writer.WriteShort(15);
        return SendPacketAsync(writer);
    }

    private Task SendPacket6RoomReadyNotifyAsync(long characterId, bool ready)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(6);
        writer.WriteLong(characterId);
        writer.WriteByte(ready ? (byte)1 : (byte)0);

        Log.Information(
            "Channel packet6 -> {Remote}: characterId={CharacterId} ready={Ready}",
            _remoteLabel,
            characterId,
            ready);

        return SendPacketAsync(writer);
    }

    private Task SendPacket8GameStartNotifyAsync()
    {
        using var writer = new PacketWriter();
        writer.WriteShort(8);

        Log.Information("Channel packet8 -> {Remote}: game-start notify", _remoteLabel);
        return SendPacketAsync(writer);
    }

    private Task SendPacket9GameClientEnterNotifyAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        using var writer = new PacketWriter();
        var member = GetLocalGameMember(room);
        var characterId = member?.CharacterId ?? room.HostCharacterId;

        writer.WriteShort(9);
        writer.WriteLong(characterId);

        Log.Information(
            "Channel packet9 -> {Remote}: characterId={CharacterId} game-client-enter notify",
            _remoteLabel,
            characterId);

        return SendPacketAsync(writer);
    }

    private Task SendPacket12GameLeaveNotifyAsync()
    {
        using var writer = new PacketWriter();
        writer.WriteShort(12);

        Log.Information("Channel packet12 -> {Remote}: game-leave notify", _remoteLabel);
        return SendPacketAsync(writer);
    }

    private Task SendPacket22GameStartResultAsync(int resultCode, byte subCode = 0)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(22);
        writer.WriteInt(resultCode);
        writer.WriteByte(subCode);

        Log.Information(
            "Channel packet22 -> {Remote}: resultCode={ResultCode} subCode={SubCode}",
            _remoteLabel,
            resultCode,
            subCode);

        return SendPacketAsync(writer);
    }

    private Task SendPacket21GameReadyResultAsync(int resultCode)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(21);
        writer.WriteInt(resultCode);

        Log.Information(
            "Channel packet21 -> {Remote}: resultCode={ResultCode}",
            _remoteLabel,
            resultCode);

        return SendPacketAsync(writer);
    }

    private Task SendPacket100GameEnterResultAsync(int resultCode, byte subCode = 0)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(100);
        writer.WriteInt(resultCode);
        writer.WriteByte(subCode);

        Log.Information(
            "Channel packet100 -> {Remote}: resultCode={ResultCode} subCode={SubCode}",
            _remoteLabel,
            resultCode,
            subCode);

        return SendPacketAsync(writer);
    }

    private Task SendPacket102GameAuthenticationAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        using var writer = new PacketWriter();
        var levelCode = ResolveBattleLevelCode(room);
        var mapId = ResolveBattleMapId(levelCode);

        writer.WriteShort(102);
        writer.WriteString(levelCode);
        writer.WriteByte(room.GameType);
        writer.WriteByte(_localGameUid);
        writer.WriteInt(mapId);

        Log.Information(
            "Channel packet102 -> {Remote}: levelCode={LevelCode} gameType={GameType} localUid={LocalUid} roomLevelId={RoomLevelId} mapId={MapId}",
            _remoteLabel,
            levelCode,
            room.GameType,
            _localGameUid,
            room.LevelId,
            mapId);

        return SendPacketAsync(writer);
    }

    private Task SendPacket105GameLoadingReadyAsync()
    {
        using var writer = new PacketWriter();
        writer.WriteShort(105);

        Log.Information("Channel packet105 -> {Remote}: game-loading substate advance", _remoteLabel);
        return SendPacketAsync(writer);
    }

    private Task SendPacket109GamePingBackAsync()
    {
        using var writer = new PacketWriter();
        writer.WriteShort(109);

        Log.Verbose("Channel packet109 -> {Remote}: ping back", _remoteLabel);
        return SendPacketAsync(writer);
    }

    internal Task SendPacket110GameMovementAsync(PracticeRoomManager.GameMovementDelta movement)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(110);
        writer.WriteByte(movement.Uid);
        writer.WriteByte(movement.Tick);
        writer.WriteByte(movement.Flags);
        writer.WriteRaw(movement.OptionalPayload);

        Log.Verbose(
            "Channel packet110 -> {Remote}: uid={Uid} tick={Tick} flags=0x{Flags:X2} optionalBytes={OptionalBytes}",
            _remoteLabel,
            movement.Uid,
            movement.Tick,
            movement.Flags,
            movement.OptionalPayload.Length);
        return SendPacketAsync(writer);
    }

    internal Task SendPacket113RemoteShootAsync(PracticeRoomManager.GameShootAction shoot)
    {
        using var writer = new PacketWriter();
        var vector = ResolveRemoteShootVector(shoot);

        writer.WriteShort(GameRemoteShootPacketId);
        WriteGameObjectDeltaFlags(writer, GameRemoteShootObjectDeltaFlags);
        writer.WriteByte(shoot.Uid);
        writer.WriteByte(shoot.SlotOneBased);
        writer.WriteByte(GameRemoteShootActionByte);
        writer.WriteByte(GameRemoteShootSkipTargetMarker);
        WriteCompressedVector3Raw(writer, shoot.OriginXRaw, shoot.OriginYRaw, shoot.OriginZRaw);
        WriteCompressedVector3(writer, vector.X, vector.Y, vector.Z);
        writer.WriteShort(shoot.Facing0Raw);
        writer.WriteShort(shoot.Facing1Raw);

        Log.Verbose(
            "Channel packet113 -> {Remote}: remote shoot uid={Uid} action={Action} slot={Slot} originRaw=({OriginX},{OriginY},{OriginZ}) vector={Vector} facing0={Facing0} facing1={Facing1}",
            _remoteLabel,
            shoot.Uid,
            shoot.Action,
            shoot.SlotOneBased,
            shoot.OriginXRaw,
            shoot.OriginYRaw,
            shoot.OriginZRaw,
            FormatGameVector3(vector.X, vector.Y, vector.Z),
            unchecked((ushort)shoot.Facing0Raw),
            unchecked((ushort)shoot.Facing1Raw));
        return SendPacketAsync(writer);
    }

    internal Task SendPacket117RemoteReloadActionAsync(byte actorUid)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(117);
        writer.WriteByte(actorUid);

        Log.Information(
            "Channel packet117 -> {Remote}: remote reload uid={Uid}",
            _remoteLabel,
            actorUid);
        return SendPacketAsync(writer);
    }

    internal Task SendPacket118RemoteDropWeaponAsync(byte actorUid)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(118);
        writer.WriteByte(actorUid);

        Log.Verbose(
            "Channel packet118 -> {Remote}: remote drop-weapon uid={Uid}",
            _remoteLabel,
            actorUid);
        return SendPacketAsync(writer);
    }

    internal Task SendPacket128RemoteWeaponSlotAsync(
        byte actorUid,
        byte weaponSlot,
        string trigger)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(GameRemoteWeaponSlotPacketId);
        writer.WriteByte(actorUid);
        writer.WriteByte(weaponSlot);

        Log.Verbose(
            "Channel packet128 -> {Remote}: remote weapon-slot uid={Uid} slot={Slot} trigger={Trigger}",
            _remoteLabel,
            actorUid,
            weaponSlot,
            trigger);
        return SendPacketAsync(writer);
    }

    internal Task SendPacket162RemoteHurtAsync(PracticeRoomManager.GameDamageAction damage)
    {
        using var writer = new PacketWriter();

        writer.WriteShort(GameRemoteHurtPacketId);
        WriteGameObjectDeltaFlags(writer, GameRemoteHurtObjectDeltaFlags);
        writer.WriteByte(damage.VictimUid);
        writer.WriteByte(damage.AttackerUid);
        writer.WriteShort(GameRemoteHurtSubtype);
        writer.WriteInt(damage.VictimHealth);
        writer.WriteFloat(damage.Damage);

        Log.Verbose(
            "Channel packet162 -> {Remote}: hurt attackerUid={AttackerUid} victimUid={VictimUid} damage={Damage} health={Health}/{MaxHealth} subtype={Subtype}",
            _remoteLabel,
            damage.AttackerUid,
            damage.VictimUid,
            damage.Damage,
            damage.VictimHealth,
            damage.VictimMaxHealth,
            GameRemoteHurtSubtype);
        return SendPacketAsync(writer);
    }

    internal Task SendPacket184RemoteDamageHitAsync(PracticeRoomManager.GameDamageAction damage)
    {
        using var writer = new PacketWriter();

        writer.WriteShort(GameRemoteDamageHitPacketId);
        WriteGameObjectDeltaFlags(writer, GameRemoteDamageHitObjectDeltaFlags);
        writer.WriteByte(damage.AttackerUid);
        writer.WriteByte(damage.VictimUid);
        writer.WriteInt(damage.VictimHealth);

        if (damage.Killed)
        {
            Log.Information(
                "Channel packet184 -> {Remote}: fatal-hit attackerUid={AttackerUid} victimUid={VictimUid} damage={Damage} health={Health}/{MaxHealth}",
                _remoteLabel,
                damage.AttackerUid,
                damage.VictimUid,
                damage.Damage,
                damage.VictimHealth,
                damage.VictimMaxHealth);
        }
        else
        {
            Log.Information(
                "Channel packet184 -> {Remote}: damage-hit attackerUid={AttackerUid} victimUid={VictimUid} damage={Damage} health={Health}/{MaxHealth}",
                _remoteLabel,
                damage.AttackerUid,
                damage.VictimUid,
                damage.Damage,
                damage.VictimHealth,
                damage.VictimMaxHealth);
        }

        return SendPacketAsync(writer);
    }

    private Task SendPacket114GameActionScalarAckAsync(int rawValue, string trigger)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(114);
        writer.WriteInt(rawValue);

        Log.Verbose(
            "Channel packet114 -> {Remote}: action scalar ack raw=0x{RawValue:X8} scalar={Scalar} trigger={Trigger}",
            _remoteLabel,
            rawValue,
            BitConverter.Int32BitsToSingle(rawValue),
            trigger);
        return SendPacketAsync(writer);
    }

    internal Task SendPacket175GameReloadReadyAsync(byte slotOneBased, string trigger)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(175);
        writer.WriteByte(slotOneBased);

        Log.Verbose(
            "Channel packet175 -> {Remote}: reload-ready slot={Slot} trigger={Trigger}",
            _remoteLabel,
            slotOneBased,
            trigger);
        return SendPacketAsync(writer);
    }

    private Task SendPacket194GameInfoOverlayShowAckAsync()
    {
        using var writer = new PacketWriter();
        writer.WriteShort(194);

        Log.Verbose(
            "Channel packet194 -> {Remote}: game-info overlay show ack",
            _remoteLabel);
        return SendPacketAsync(writer);
    }

    private Task SendPacket106GameInitAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        using var writer = new PacketWriter();
        var member = GetLocalGameMember(room);
        var playerState = GetLocalPlayerState(room);
        var character = playerState?.Character;
        var career = (byte)(character?.Occupation ?? member?.Career ?? 0);
        var loadoutSource = playerState?.GetGameLoadoutSource() ?? "empty";
        var loadoutItems = playerState?.GetGameLoadoutItems() ?? Array.Empty<PlayerStore.PlayerState.GameLoadoutItem>();
        var loadoutGroups = BuildGameLoadoutGroups(loadoutItems);
        var playerHealth = ResolveLocalGamePlayerHealth(character);
        var teamId = ResolveGameTeamId(member);
        var packet106HeaderByte = UseLegacyHotbarBootstrapSequence ? career : teamId;
        var gamePlayers = ResolveGamePlayersForPacket(room);

        writer.WriteShort(106);
        writer.WriteByte(_localGameUid);
        writer.WriteByte(packet106HeaderByte);
        writer.WriteByte(0);
        writer.WriteByte(room.GameType);
        var playerEntryCount = UseLegacyMinimalPacket106PlayerList ? 0 : gamePlayers.Count;
        var packet106PlayerHealth = UseLegacyMinimalPacket106PlayerList ? 0 : playerHealth;
        var packet106EquipmentBlockCount = UseLegacyMinimalPacket106PlayerList ? 0 : CountGamePlayerEquipmentEntries(gamePlayers);
        if (UseLegacyMinimalPacket106PlayerList)
        {
            writer.WriteByte(GamePlayerListTerminator);
        }
        else
        {
            WriteGamePlayerList(writer, room, gamePlayers);
        }

        _knownGamePlayerUids.Clear();
        foreach (var player in gamePlayers)
        {
            _knownGamePlayerUids.Add(player.Uid);
        }

        _knownGamePlayerUids.Add(_localGameUid);

        writer.WriteByte(0);
        writer.WriteInt(0);
        writer.WriteByte(1);
        writer.WriteShort(0);
        writer.WriteShort(0);
        writer.WriteShort(0);
        WriteGameLoadoutGroups(writer, loadoutGroups);

        Log.Information(
            "Channel packet106 -> {Remote}: localUid={LocalUid} teamId={TeamId} career={Career} headerByte={HeaderByte} gameType={GameType} playerEntries={PlayerEntries} playerHealthField={PlayerHealthField} playerTail={PlayerTail} equipmentBlockCount={EquipmentBlockCount} loadoutCount={LoadoutCount} loadoutGroups={LoadoutGroups} loadoutSource={LoadoutSource} backpackStats=True loadout={Loadout}",
            _remoteLabel,
            _localGameUid,
            teamId,
            career,
            packet106HeaderByte,
            room.GameType,
            playerEntryCount,
            packet106PlayerHealth,
            UseLegacyMinimalPacket106PlayerList ? "legacy-empty" : FormatGamePlayerTailSummary(),
            packet106EquipmentBlockCount,
            loadoutItems.Count,
            FormatGameLoadoutGroupCounts(loadoutGroups),
            loadoutSource,
            FormatGameLoadoutSummary(loadoutItems));

        return SendPacketAsync(writer);
    }

    private async Task SendLocalPlayerEnteredOnceAsync()
    {
        if (_localPlayerEnterPacketSent || _currentGameRoom is null)
        {
            return;
        }

        _localPlayerEnterPacketSent = true;
        var member = GetLocalGameMember(_currentGameRoom);
        var teamId = ResolveGameTeamId(member);
        await SendPacket107GamePlayerEnterAsync(_localGameUid, teamId, "local-player-enter");
        await BroadcastLocalPlayerEnteredOnceAsync("local-player-enter");
    }

    private async Task BroadcastLocalPlayerEnteredOnceAsync(string trigger)
    {
        if (_localPlayerEnterBroadcastSent || _currentGameRoom is null)
        {
            return;
        }

        _localPlayerEnterBroadcastSent = true;
        var member = GetLocalGameMember(_currentGameRoom);
        var teamId = ResolveGameTeamId(member);
        var broadcastCount = await _practiceRoomManager.BroadcastGamePlayerEnteredAsync(
            _currentGameRoom.RoomId,
            this,
            _localGameUid,
            teamId);
        Log.Information(
            "Channel packet107 broadcast from {Remote}: trigger={Trigger} localUid={LocalUid} teamId={TeamId} broadcastCount={BroadcastCount}",
            _remoteLabel,
            trigger,
            _localGameUid,
            teamId,
            broadcastCount);
    }

    internal Task SendPacket107GamePlayerEnterAsync(byte actorUid, byte teamId, string trigger)
    {
        using var writer = new PacketWriter();

        writer.WriteShort(107);
        writer.WriteByte(actorUid);
        writer.WriteByte(teamId);

        Log.Information(
            "Channel packet107 -> {Remote}: uid={Uid} teamId={TeamId} trigger={Trigger}",
            _remoteLabel,
            actorUid,
            teamId,
            trigger);
        _knownGamePlayerUids.Add(actorUid);
        return SendPacketAsync(writer);
    }

    internal Task SendPacket108GamePlayerLeaveAsync(byte actorUid, string trigger)
    {
        using var writer = new PacketWriter();

        writer.WriteShort(108);
        writer.WriteByte(actorUid);

        Log.Information(
            "Channel packet108 -> {Remote}: uid={Uid} trigger={Trigger}",
            _remoteLabel,
            actorUid,
            trigger);
        _knownGamePlayerUids.Remove(actorUid);
        return SendPacketAsync(writer);
    }

    internal async Task SendRemoteGamePlayerEnteredAsync(
        PracticeRoomManager.PracticeRoomSession room,
        long characterId,
        byte actorUid,
        byte teamId,
        string trigger)
    {
        if (_knownGamePlayerUids.Count == 0)
        {
            Log.Information(
                "Channel remote player-enter skipped for {Remote}: uid={Uid} teamId={TeamId} trigger={Trigger} reason=target-game-init-not-sent",
                _remoteLabel,
                actorUid,
                teamId,
                trigger);
            return;
        }

        if (_knownGamePlayerUids.Contains(actorUid))
        {
            Log.Information(
                "Channel remote player-enter skipped for {Remote}: uid={Uid} teamId={TeamId} trigger={Trigger} reason=already-known",
                _remoteLabel,
                actorUid,
                teamId,
                trigger);
            return;
        }

        var member = room.Members.FirstOrDefault(candidate => candidate.CharacterId == characterId);
        var player = CreateGamePacketPlayer(
            room,
            new PracticeRoomManager.GamePlayerSnapshot(
                actorUid,
                characterId,
                member?.CharacterName ?? string.Empty,
                null));

        await SendPacket103GameCharacterCreateAsync(player);
        await SendPacket111GameSpawnAsync(room, player, trigger);
        await SendPacket107GamePlayerEnterAsync(actorUid, teamId, trigger);
    }

    internal Task SendRemoteGamePlayerRespawnAsync(
        PracticeRoomManager.PracticeRoomSession room,
        long characterId,
        byte actorUid,
        string trigger)
    {
        var member = room.Members.FirstOrDefault(candidate => candidate.CharacterId == characterId);
        var player = CreateGamePacketPlayer(
            room,
            new PracticeRoomManager.GamePlayerSnapshot(
                actorUid,
                characterId,
                member?.CharacterName ?? string.Empty,
                null));

        _knownGamePlayerUids.Add(actorUid);
        return SendPacket111GameSpawnAsync(room, player, trigger);
    }

    internal Task SendLocalGamePlayerRespawnAsync(
        PracticeRoomManager.PracticeRoomSession room,
        string trigger)
    {
        _knownGamePlayerUids.Add(_localGameUid);
        UpdateLocalGameSpawnPosition(room, overwriteExisting: true, trigger);
        return SendPacket111GameSpawnAsync(room, trigger);
    }

    private Task SendPacket151PlayerEnteringCompleteAsync(string trigger, int retriesRemaining)
    {
        using var writer = new PacketWriter();
        // Client dispatch uses packetId - 2; opcode 151 is the one-float player-entering overlay clear.
        writer.WriteShort(151);
        writer.WriteFloat(0f);

        Log.Information(
            "Channel packet151 -> {Remote}: player-entering overlay clear trigger={Trigger} retriesRemaining={RetriesRemaining}",
            _remoteLabel,
            trigger,
            retriesRemaining);
        return SendPacketAsync(writer);
    }

    private async Task SendPacket143SilentGameLoadoutHudRefreshAsync(
        IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem> loadoutItems,
        string trigger,
        int retriesRemaining)
    {
        var sentCount = 0;
        foreach (var item in loadoutItems.Where(IsSupportedGameEquipmentItem).OrderBy(item => item.Slot))
        {
            await SendPacket143GameLoadoutItemRefreshAsync(item, trigger);
            sentCount++;
        }

        Log.Information(
            "Channel packet143 -> {Remote}: silent in-game hotbar refresh trigger={Trigger} state={State} property={Property} itemCount={ItemCount} retriesRemaining={RetriesRemaining}",
            _remoteLabel,
            trigger,
            GameLoadoutHudReadyState,
            GameLoadoutHudRefreshPropertyName,
            sentCount,
            retriesRemaining);
    }

    private Task SendPacket143GameLoadoutItemRefreshAsync(
        PlayerStore.PlayerState.GameLoadoutItem item,
        string trigger)
    {
        return SendPacket143GameLoadoutItemPropertyRefreshAsync(
            item,
            GameLoadoutHudRefreshPropertyName,
            ResolveAmmoOneClipForClient(item),
            trigger);
    }

    private Task SendPacket143GameLoadoutItemPropertyRefreshAsync(
        PlayerStore.PlayerState.GameLoadoutItem item,
        string propertyName,
        int value,
        string trigger)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(143);
        writer.WriteLong(item.ItemId);
        writer.WriteString(propertyName);
        writer.WriteInt(value);
        writer.WriteByte(GameLoadoutHudReadyState);

        Log.Verbose(
            "Channel packet143 -> {Remote}: loadout item refresh trigger={Trigger} slot={Slot} itemId={ItemId} resource={Resource} state={State} property={Property} value={Value}",
            _remoteLabel,
            trigger,
            item.Slot,
            item.ItemId,
            item.Resource,
            GameLoadoutHudReadyState,
            propertyName,
            value);
        return SendPacketAsync(writer);
    }

    private void WriteGamePlayerList(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room,
        IReadOnlyList<GamePacketPlayer> gamePlayers)
    {
        foreach (var player in gamePlayers)
        {
            writer.WriteByte(player.Uid);
            writer.WriteString(TrimProtocolString(player.CharacterName, 63));
            writer.WriteByte(0);
            writer.WriteByte(player.TeamId);
            writer.WriteByte(1);
            writer.WriteShort(0);
            writer.WriteInt(player.MaxHealth);
            writer.WriteShort(InitialGamePlayerActionStateFlags);
            writer.WriteShort(0);
            writer.WriteShort(0);
            WriteGamePlayerTransform(writer, room, player.LastPosition);
            WriteGameEquipmentBlock(writer, player.EquipmentItems);
            writer.WriteByte(InitialGamePlayerActive);
            writer.WriteByte(InitialGamePlayerNotEntering);
            writer.WriteByte(InitialGamePlayerTransformReady);
        }

        writer.WriteByte(GamePlayerListTerminator);
    }

    private static int CountGamePlayerEquipmentEntries(IReadOnlyList<GamePacketPlayer> gamePlayers)
    {
        return gamePlayers.Sum(player => player.EquipmentItems.Count);
    }

    private static string FormatGamePlayerTailSummary()
    {
        return $"{InitialGamePlayerActive}/{InitialGamePlayerNotEntering}/{InitialGamePlayerTransformReady}";
    }

    private static int ResolveGamePlayerHealth(CharacterInfo? character)
    {
        return Math.Max(character?.MaxHealth ?? 0, DefaultSpawnHealth);
    }

    private int ResolveLocalGamePlayerHealth(CharacterInfo? character)
    {
        return _setHealthOverride ?? ResolveGamePlayerHealth(character);
    }

    private int ResolveLocalRuntimeHealth(PracticeRoomManager.PracticeRoomSession room)
    {
        if (_practiceRoomManager.TryGetGamePlayerHealth(
                room.RoomId,
                _localGameUid,
                out var currentHealth,
                out _))
        {
            return Math.Max(1, currentHealth);
        }

        return ResolveLocalGamePlayerHealth(GetLocalPlayerState(room)?.Character);
    }

    private static byte ResolveGameTeamId(PracticeRoomManager.PracticeRoomMember? member)
    {
        return member?.SlotIndex switch
        {
            >= 9 and <= 16 => GameTeamBlue,
            >= 17 and <= 24 => GameTeamSpectator,
            _ => GameTeamRed
        };
    }

    private static void WriteGamePlayerTransform(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room,
        PracticeRoomManager.GamePosition? position)
    {
        if (position.HasValue)
        {
            writer.WriteFloat(RawToWorldCoordinate(position.Value.XRaw));
            writer.WriteFloat(RawToWorldCoordinate(position.Value.YRaw));
            writer.WriteFloat(RawToWorldCoordinate(position.Value.ZRaw));
        }
        else
        {
            var (spawnX, spawnY, spawnZ, _) = ResolveSpawnPoint(room);
            writer.WriteFloat(spawnX);
            writer.WriteFloat(spawnY);
            writer.WriteFloat(spawnZ);
        }

        writer.WriteFloat(0f);
        writer.WriteFloat(0f);
        writer.WriteFloat(0f);
        writer.WriteFloat(1f);
    }

    private static string ResolveBattleLevelCode(PracticeRoomManager.PracticeRoomSession room)
    {
        if (room.LevelId > 0)
        {
            return $"LEVEL{room.LevelId}";
        }

        return room.GameType switch
        {
            4 => $"LEVEL{FallbackBattleMapId}",
            _ => $"LEVEL{FallbackBattleMapId}"
        };
    }

    private static int ResolveBattleMapId(string levelCode)
    {
        var digits = new string(levelCode.Where(char.IsDigit).ToArray());
        return int.TryParse(digits, out var mapId) && mapId > 0
            ? mapId
            : FallbackBattleMapId;
    }

    private static long ResolveCandidateCharacterId(long helloLong, int helloInt)
    {
        if (helloLong is > 0 and <= int.MaxValue)
        {
            return helloLong;
        }

        return helloInt > 0 ? helloInt : 0;
    }

    private PracticeRoomManager.PracticeRoomEnterRequest ResolveEnteringPlayer(
        AvatarStarClientProtocol.ChannelRoomEnterPayload enterRoom,
        PracticeRoomManager.PracticeRoomSession room)
    {
        if (_practiceRoomManager.TryConsumePendingChannelJoin(
                room.ChannelToken,
                _remoteAddress,
                room.RoomId,
                out var pendingRequest))
        {
            Log.Information(
                "Channel enter identity resolved from lobby request: remote={Remote} roomId={RoomId} characterId={CharacterId}",
                _remoteLabel,
                room.RoomId,
                pendingRequest.CharacterId);
            return pendingRequest;
        }

        var hasRoomChannel = _practiceRoomManager.HasRoomChannel(room.RoomId);
        var characterId = enterRoom.Token > 0 ? enterRoom.Token : 0;

        if (characterId == 0 &&
            _candidateCharacterId > 0 &&
            (!hasRoomChannel || _candidateCharacterId != room.HostCharacterId))
        {
            characterId = (int)Math.Min(_candidateCharacterId, int.MaxValue);
        }

        if (characterId == 0 && !hasRoomChannel && room.HostCharacterId is > 0 and <= int.MaxValue)
        {
            characterId = (int)room.HostCharacterId;
        }

        if (characterId == 0)
        {
            characterId = _practiceRoomManager.AllocateTransientCharacterId();
        }

        var player = _playerStore.GetOrCreate(characterId);
        return CreateEnterRequest(player);
    }

    private static PracticeRoomManager.PracticeRoomEnterRequest CreateEnterRequest(PlayerStore.PlayerState player)
    {
        var character = player.Character;
        return new PracticeRoomManager.PracticeRoomEnterRequest(
            CharacterId: character.Id,
            CharacterName: character.Name,
            Level: character.Level,
            Occupation: character.Occupation,
            RankType: 0,
            RankLevel: 0,
            VipLevel: 0);
    }

    private PlayerStore.PlayerState? GetLocalPlayerState(PracticeRoomManager.PracticeRoomSession room)
    {
        var characterId = GetLocalGameMember(room)?.CharacterId ?? room.HostCharacterId;
        if (characterId <= 0 || characterId > int.MaxValue)
        {
            return null;
        }

        return _playerStore.GetOrCreate((int)characterId);
    }

    private IReadOnlyList<GamePacketPlayer> ResolveGamePlayersForPacket(PracticeRoomManager.PracticeRoomSession room)
    {
        var snapshots = _practiceRoomManager.ListGamePlayers(room.RoomId);
        if (snapshots.Count == 0)
        {
            var localMember = GetLocalGameMember(room);
            snapshots =
            [
                new PracticeRoomManager.GamePlayerSnapshot(
                    _localGameUid,
                    localMember?.CharacterId ?? room.HostCharacterId,
                    localMember?.CharacterName ?? room.HostName,
                    null)
            ];
        }

        return snapshots
            .OrderBy(snapshot => snapshot.Uid)
            .Select(snapshot => CreateGamePacketPlayer(room, snapshot))
            .ToArray();
    }

    private GamePacketPlayer CreateGamePacketPlayer(
        PracticeRoomManager.PracticeRoomSession room,
        PracticeRoomManager.GamePlayerSnapshot snapshot)
    {
        var member = room.Members.FirstOrDefault(candidate => candidate.CharacterId == snapshot.CharacterId);
        var playerState = ResolvePlayerState(snapshot.CharacterId);
        var character = playerState?.Character;
        var characterName = FirstNonEmpty(member?.CharacterName, snapshot.CharacterName, character?.Name, room.HostName);
        var characterId = character?.Id ?? member?.CharacterId ?? snapshot.CharacterId;
        var career = (byte)(character?.Occupation ?? member?.Career ?? 0);
        var level = Math.Max(1, character?.Level ?? member?.Level ?? 1);
        var rankType = member?.RankType is > 0 ? member.RankType : (byte)1;
        var rankLevel = member?.RankLevel is > 0 ? member.RankLevel : 1;
        var loadoutItems = playerState?.GetGameLoadoutItems() ?? Array.Empty<PlayerStore.PlayerState.GameLoadoutItem>();
        var equipmentItems = GetSupportedGameEquipmentItems(loadoutItems);
        var independentTrinketItems = playerState?.GetGameIndependentTrinketItems() ??
            Array.Empty<PlayerStore.PlayerState.GameIndependentTrinketItem>();

        return new GamePacketPlayer(
            snapshot.Uid,
            characterId,
            characterName,
            ResolveGameTeamId(member),
            career,
            level,
            rankType,
            rankLevel,
            snapshot.Uid == _localGameUid ? ResolveLocalGamePlayerHealth(character) : ResolveGamePlayerHealth(character),
            playerState,
            character,
            loadoutItems,
            equipmentItems,
            independentTrinketItems,
            snapshot.LastPosition);
    }

    private PlayerStore.PlayerState? ResolvePlayerState(long characterId)
    {
        if (characterId <= 0 || characterId > int.MaxValue)
        {
            return null;
        }

        return _playerStore.GetOrCreate((int)characterId);
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value;
            }
        }

        return string.Empty;
    }

    private void WriteGameLoadoutGroups(
        PacketWriter writer,
        IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem[]> loadoutGroups)
    {
        foreach (var groupItems in loadoutGroups)
        {
            if (groupItems.Length == 0)
            {
                writer.WriteInt(0);
                continue;
            }

            writer.WriteInt(groupItems.Length);
            foreach (var item in groupItems)
            {
                WriteGameLoadoutItem(writer, item);
            }
        }
    }

    private static PlayerStore.PlayerState.GameLoadoutItem[][] BuildGameLoadoutGroups(
        IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem> loadoutItems)
    {
        if (MirrorLoadoutAcrossGameGroups)
        {
            var mirroredItems = loadoutItems
                .OrderBy(item => item.Slot)
                .Take(GameLoadoutGroupSize)
                .ToArray();

            return Enumerable
                .Range(0, GameLoadoutGroupCount)
                .Select(_ => mirroredItems)
                .ToArray();
        }

        return Enumerable
            .Range(0, GameLoadoutGroupCount)
            .Select(groupIndex =>
            {
                var groupStart = groupIndex * GameLoadoutGroupSize + 1;
                var groupEnd = groupStart + GameLoadoutGroupSize - 1;
                return loadoutItems
                    .Where(item => item.Slot >= groupStart && item.Slot <= groupEnd)
                    .OrderBy(item => item.Slot)
                    .ToArray();
            })
            .ToArray();
    }

    private static void WriteEmptyGameEquipmentBlock(PacketWriter writer)
    {
        writer.WriteInt(0);
    }

    private static IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem> GetSupportedGameEquipmentItems(
        IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem> loadoutItems)
    {
        return loadoutItems
            .Where(IsSupportedGameEquipmentItem)
            .OrderBy(item => item.Slot)
            .Take(EquipmentBlockMaxEntries)
            .ToArray();
    }

    private string FormatGameLoadoutSummary(IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem> loadoutItems)
    {
        if (loadoutItems.Count == 0)
        {
            return "(empty)";
        }

        return string.Join(
            "; ",
            loadoutItems.Select(item =>
            {
                var stats = ResolveGameWeaponRuntimeStatsForClient(item);
                var properties = ResolveGameLoadoutPropertiesForClient(item);
                var propertyText = properties.Count == 0
                    ? "props=0"
                    : string.Join(",", properties.Select(property => $"{property.Name}:{property.Value}/{property.MaxValue}"));
                var explosionText = stats.HasExplosionRadius
                    ? $",explosion_radius:{FormatProtocolFloat(stats.Range)},explode_time:{FormatProtocolFloat(stats.ExplodeTime)}"
                    : string.Empty;
                return $"slot={item.Slot},type={item.ItemType},pid={item.ItemId},res={item.Resource},sub={NormalizeGameEquipmentSubtype(item.Subtype)},packet106Byte=subtype,packet106Props=0,packet143State={GameLoadoutHudReadyState},cool_down:{FormatProtocolFloat(stats.CoolDown)},fire_time:{FormatProtocolFloat(stats.FireTime)},range:{FormatProtocolFloat(stats.Range)}{explosionText},runtime_{propertyText}";
            }));
    }

    private static string FormatGameLoadoutGroupCounts(
        IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem[]> loadoutGroups)
    {
        return string.Join("/", loadoutGroups.Select(group => group.Length));
    }

    private static bool IsSupportedGameEquipmentItem(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (item.ItemType != 2 || string.IsNullOrWhiteSpace(item.Resource))
        {
            return false;
        }

        if (item.Resource.Contains("wing", StringComparison.OrdinalIgnoreCase) ||
            item.Resource.StartsWith("badge", StringComparison.OrdinalIgnoreCase) ||
            item.Resource.StartsWith("ring", StringComparison.OrdinalIgnoreCase) ||
            item.Resource.StartsWith("deco_", StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        return IsSupportedGameEquipmentSubtype(NormalizeGameEquipmentSubtype(item.Subtype));
    }

    private static bool IsSpecialRearmGameEquipmentItem(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (!IsSupportedGameEquipmentItem(item))
        {
            return false;
        }

        if (IsKnifeRearmGameEquipmentItem(item))
        {
            return true;
        }

        var subtype = NormalizeGameEquipmentSubtype(item.Subtype);
        if (subtype is 10)
        {
            return true;
        }

        return item.Resource.StartsWith("grenade_", StringComparison.OrdinalIgnoreCase);
    }

    private static bool IsKnifeRearmGameEquipmentItem(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (!IsSupportedGameEquipmentItem(item))
        {
            return false;
        }

        var subtype = NormalizeGameEquipmentSubtype(item.Subtype);
        return subtype is 6 or 13 ||
               item.Resource.StartsWith("knives_", StringComparison.OrdinalIgnoreCase) ||
               item.Resource.Contains("knife", StringComparison.OrdinalIgnoreCase);
    }

    private static TimeSpan ResolveSpecialWeaponRearmInterval(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStats(item);
        var seconds = Math.Max(stats.CoolDown, Math.Max(stats.FireTime, Math.Max(stats.ReadyTime, stats.ThrowOutTime)));
        seconds = Math.Clamp(seconds, (float)SpecialWeaponRearmMinSeconds, (float)SpecialWeaponRearmMaxSeconds);
        return TimeSpan.FromSeconds(seconds);
    }

    private void WriteGameEquipmentBlock(
        PacketWriter writer,
        IReadOnlyList<PlayerStore.PlayerState.GameLoadoutItem> equipmentItems)
    {
        writer.WriteInt(equipmentItems.Count);
        foreach (var item in equipmentItems)
        {
            WriteGameEquipmentEntry(writer, item);
        }
    }

    private static bool IsSupportedGameEquipmentSubtype(byte subtype)
    {
        return subtype is 1 or 2 or 3 or 4 or 5 or 6 or 10 or 11 or 12 or 13 or 14 or 15 or 16;
    }

    private static byte NormalizeGameEquipmentSubtype(byte subtype)
    {
        return subtype == 0 ? (byte)1 : subtype;
    }

    private void WriteGameEquipmentEntry(
        PacketWriter writer,
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var slot = (byte)Math.Clamp((int)item.Slot, 1, EquipmentBlockMaxEntries);
        var subtype = NormalizeGameEquipmentSubtype(item.Subtype);

        writer.WriteByte(slot);
        writer.WriteByte(2);
        writer.WriteByte(subtype);

        switch (subtype)
        {
            case 2:
                WriteBasicWeaponEquipmentPayload(writer, item);
                WriteZeroInts(writer, 2);
                break;
            case 4:
                WriteBasicWeaponEquipmentPayload(writer, item);
                writer.WriteInt(ResolveShootBulletCount(item));
                break;
            case 6:
            case 13:
                WriteCompactGameEquipmentPayload(writer, item);
                break;
            case 10:
                WriteThrowableExplosiveEquipmentPayload(writer, item);
                break;
            case 11:
            case 12:
                WriteExplosiveProjectileEquipmentPayload(writer, item);
                break;
            case 14:
                WriteGrenadeLauncherEquipmentPayload(writer, item);
                break;
            case 16:
                WriteCrossbowExplosiveEquipmentPayload(writer, item);
                break;
            default:
                WriteBasicWeaponEquipmentPayload(writer, item);
                break;
        }
    }

    private void WriteGameEquipmentCommonPayload(
        PacketWriter writer,
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStatsForClient(item);

        writer.WriteString(TrimProtocolString(item.Resource, 63));
        writer.WriteString(TrimProtocolString(ResolveGameEquipmentDisplayName(item), 255));
        writer.WriteFloat(stats.CoolDown);
        writer.WriteFloat(stats.Range);
    }

    private void WriteBasicWeaponEquipmentPayload(
        PacketWriter writer,
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStatsForClient(item);

        WriteGameEquipmentCommonPayload(writer, item);

        writer.WriteFloat(stats.FireTime);
        writer.WriteInt(stats.AmmoOneClip);
        writer.WriteFloat(stats.ShotSpread);
        writer.WriteByte(0);
        writer.WriteInt(0);
        writer.WriteInt(0);
        writer.WriteFloat(0f);
        writer.WriteByte(0);
        writer.WriteByte(0);
    }

    private void WriteExplosiveProjectileEquipmentPayload(
        PacketWriter writer,
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStatsForClient(item);

        WriteBasicWeaponEquipmentPayload(writer, item);
        writer.WriteFloat(stats.ExplodeTime);
        writer.WriteFloat(stats.OwnerType);
        writer.WriteFloat(stats.TrajectoryValue);
        writer.WriteFloat(stats.ExplodeParticleHasBuff);
    }

    private void WriteThrowableExplosiveEquipmentPayload(
        PacketWriter writer,
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStatsForClient(item);

        WriteBasicWeaponEquipmentPayload(writer, item);
        writer.WriteFloat(stats.ExplodeTime);
        writer.WriteFloat(stats.Gravity);
        writer.WriteFloat(stats.ReadyTime);
        writer.WriteFloat(stats.ExtraProjectileValue0);
        writer.WriteFloat(stats.ExtraProjectileValue1);
        writer.WriteFloat(stats.TrajectoryValue);
    }

    private void WriteGrenadeLauncherEquipmentPayload(
        PacketWriter writer,
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStatsForClient(item);

        WriteExplosiveProjectileEquipmentPayload(writer, item);
        writer.WriteFloat(stats.ExtraProjectileValue0);
        writer.WriteFloat(stats.ExtraProjectileValue1);
        writer.WriteFloat(stats.ExtraProjectileValue2);
    }

    private void WriteCrossbowExplosiveEquipmentPayload(
        PacketWriter writer,
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStatsForClient(item);

        WriteExplosiveProjectileEquipmentPayload(writer, item);
        writer.WriteFloat(stats.ExtraProjectileValue0);
        writer.WriteFloat(stats.ExtraProjectileValue1);
    }

    private void WriteCompactGameEquipmentPayload(
        PacketWriter writer,
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStatsForClient(item);

        WriteGameEquipmentCommonPayload(writer, item);
        writer.WriteFloat(stats.FireTime);
        writer.WriteInt(DefaultAccuracyDivisor);
        writer.WriteByte(0);
        writer.WriteByte(0);
    }

    private static void WriteZeroInts(PacketWriter writer, int count)
    {
        for (var index = 0; index < count; index++)
        {
            writer.WriteInt(0);
        }
    }

    private static string ResolveGameEquipmentDisplayName(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (ShopItemDatabase.TryGetShopItemByResource(item.Resource, out var shopItem) &&
            !string.IsNullOrWhiteSpace(shopItem.Display))
        {
            return shopItem.Display;
        }

        return string.IsNullOrWhiteSpace(item.DisplayName)
            ? item.Resource
            : item.DisplayName;
    }

    private static GameWeaponRuntimeStats ResolveGameWeaponRuntimeStats(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var ammoOneClip = ResolveAmmoOneClip(item);
        var shootBulletCount = ResolveShootBulletCount(item);
        var fireTime = ResolveDefaultFireTime(item);
        var coolDown = ResolveDefaultCoolDown(item);
        var range = ResolveDefaultRange(item);
        var shotSpread = ResolveDefaultShotSpread(item);
        var explodeTime = ResolveDefaultExplodeTime(item);
        var readyTime = 0f;
        var throwOutTime = 0f;
        var gravity = ResolveDefaultGravity(item);
        var ownerType = -5f;
        var trajectoryValue = 28f;
        var explodeParticleHasBuff = 12.6f;
        var extraProjectileValue0 = 0f;
        var extraProjectileValue1 = 0f;
        var extraProjectileValue2 = 0f;

        if (ShopItemDatabase.TryGetShopItemByResource(item.Resource, out var shopItem))
        {
            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredFireTime,
                    "fireSpeed",
                    "fireTime",
                    "fire_time"))
            {
                fireTime = ClampPositiveFloat(configuredFireTime, fireTime);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredCoolDown,
                    "coolDown",
                    "cool_down"))
            {
                coolDown = ClampPositiveFloat(configuredCoolDown, fireTime);
            }
            else
            {
                coolDown = ResolveDefaultCoolDown(item);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredRange,
                    "range",
                    "distance"))
            {
                range = ClampPositiveFloat(configuredRange, range);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredShotSpread,
                    "shootSpread",
                    "shotSpread",
                    "shot_spread"))
            {
                shotSpread = ClampPositiveFloat(configuredShotSpread, shotSpread);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredExplodeTime,
                    "explodeTime",
                    "explode_time",
                    "fuseTime",
                    "fuse_time"))
            {
                explodeTime = ClampPositiveFloat(configuredExplodeTime, explodeTime);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredReadyTime,
                    "readyTime",
                    "ready_time"))
            {
                readyTime = ClampNonNegativeFloat(configuredReadyTime, readyTime);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredThrowOutTime,
                    "throwOutTime",
                    "throw_out_time"))
            {
                throwOutTime = ClampNonNegativeFloat(configuredThrowOutTime, throwOutTime);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredGravity,
                    "gravity"))
            {
                gravity = ClampFiniteFloat(configuredGravity, gravity);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredOwnerType,
                    "ownerType",
                    "owner_type"))
            {
                ownerType = ClampFiniteFloat(configuredOwnerType, ownerType);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredTrajectoryValue,
                    "trajectoryValue",
                    "trajectory_value",
                    "trajectory"))
            {
                trajectoryValue = ClampFiniteFloat(configuredTrajectoryValue, trajectoryValue);
            }

            if (TryGetTipFirstNumberAny(
                    shopItem.Tip,
                    out var configuredParticleBuff,
                    "explodeParticleHasBuff",
                    "explode_particle_has_buff"))
            {
                explodeParticleHasBuff = ClampFiniteFloat(configuredParticleBuff, explodeParticleHasBuff);
            }
        }

        fireTime = ResolveTunedWeaponFireTime(fireTime);

        var hasExplosionRadius = IsExplosiveProjectileSubtype(NormalizeGameEquipmentSubtype(item.Subtype)) && range > 0f;

        return new GameWeaponRuntimeStats(
            CoolDown: coolDown,
            FireTime: fireTime,
            Range: range,
            AmmoOneClip: ammoOneClip,
            ShotSpread: shotSpread,
            ShootBulletCount: shootBulletCount,
            HasExplosionRadius: hasExplosionRadius,
            ExplodeTime: explodeTime,
            ReadyTime: readyTime,
            ThrowOutTime: throwOutTime,
            Gravity: gravity,
            OwnerType: ownerType,
            TrajectoryValue: trajectoryValue,
            ExplodeParticleHasBuff: explodeParticleHasBuff,
            ExtraProjectileValue0: extraProjectileValue0,
            ExtraProjectileValue1: extraProjectileValue1,
            ExtraProjectileValue2: extraProjectileValue2);
    }

    private void WriteGameLoadoutItem(PacketWriter writer, PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var subtype = NormalizeGameEquipmentSubtype(item.Subtype);

        writer.WriteByte(item.Slot);
        writer.WriteByte(item.ItemType);
        writer.WriteLong(item.ItemId);
        writer.WriteString(TrimProtocolString(item.Resource, 63));
        writer.WriteByte(item.Grade);
        writer.WriteString(TrimProtocolString(item.DisplayName, 255));
        writer.WriteByte(subtype);
        WriteGameLoadoutProperties(writer, item);
    }

    private void WriteGameLoadoutProperties(PacketWriter writer, PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var properties = ResolveGameLoadoutPropertiesForPacket106(item);
        writer.WriteInt(properties.Count);
        foreach (var property in properties)
        {
            writer.WriteString(TrimProtocolString(property.Name, 31));
            writer.WriteInt(property.Value);
            writer.WriteInt(property.MaxValue);
        }
    }

    private IReadOnlyList<GameLoadoutProperty> ResolveGameLoadoutPropertiesForPacket106(
        PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (!_setBulletAmmoOneClipOverridesByItemId.TryGetValue(item.ItemId, out var ammoOneClip))
        {
            return Array.Empty<GameLoadoutProperty>();
        }

        return
        [
            new GameLoadoutProperty(GameLoadoutAmmoOneClipPropertyName, ammoOneClip, ammoOneClip),
            new GameLoadoutProperty(GameLoadoutHudRefreshPropertyName, ammoOneClip, ammoOneClip),
        ];
    }

    private static IReadOnlyList<GameLoadoutProperty> ResolveGameLoadoutProperties(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (item.ItemType != 2 || string.IsNullOrWhiteSpace(item.Resource))
        {
            return Array.Empty<GameLoadoutProperty>();
        }

        var properties = new List<GameLoadoutProperty>(3);
        var ammoOneClip = ResolveAmmoOneClip(item);
        if (ammoOneClip > 0)
        {
            properties.Add(new GameLoadoutProperty(GameLoadoutAmmoOneClipPropertyName, ammoOneClip, ammoOneClip));
            properties.Add(new GameLoadoutProperty(GameLoadoutHudRefreshPropertyName, ammoOneClip, ammoOneClip));
        }

        var shootBulletCount = ResolveShootBulletCount(item);
        if (shootBulletCount > 0)
        {
            properties.Add(new GameLoadoutProperty("shoot_bullet_count", shootBulletCount, shootBulletCount));
        }

        return properties;
    }

    private IReadOnlyList<GameLoadoutProperty> ResolveGameLoadoutPropertiesForClient(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (item.ItemType != 2 || string.IsNullOrWhiteSpace(item.Resource))
        {
            return Array.Empty<GameLoadoutProperty>();
        }

        var properties = new List<GameLoadoutProperty>(3);
        var ammoOneClip = ResolveAmmoOneClipForClient(item);
        if (ammoOneClip > 0)
        {
            properties.Add(new GameLoadoutProperty(GameLoadoutAmmoOneClipPropertyName, ammoOneClip, ammoOneClip));
            properties.Add(new GameLoadoutProperty(GameLoadoutHudRefreshPropertyName, ammoOneClip, ammoOneClip));
        }

        var shootBulletCount = ResolveShootBulletCount(item);
        if (shootBulletCount > 0)
        {
            properties.Add(new GameLoadoutProperty("shoot_bullet_count", shootBulletCount, shootBulletCount));
        }

        return properties;
    }

    private GameWeaponRuntimeStats ResolveGameWeaponRuntimeStatsForClient(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var stats = ResolveGameWeaponRuntimeStats(item);
        var ammoOneClip = ResolveAmmoOneClipForClient(item);
        return ammoOneClip == stats.AmmoOneClip
            ? stats
            : stats with { AmmoOneClip = ammoOneClip };
    }

    private int ResolveAmmoOneClipForClient(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        var ammoOneClip = ResolveAmmoOneClip(item);
        return _setBulletAmmoOneClipOverridesByItemId.TryGetValue(item.ItemId, out var overrideValue)
            ? overrideValue
            : ammoOneClip;
    }

    private static int ResolveAmmoOneClip(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (ShopItemDatabase.TryGetShopItemByResource(item.Resource, out var shopItem) &&
            TryGetTipFirstNumber(shopItem.Tip, "ammoOneClip", out var configuredClip))
        {
            return ClampPositivePropertyValue(configuredClip);
        }

        return item.Subtype switch
        {
            6 or 13 => 0,
            10 or 11 or 12 or 16 => 1,
            14 => 6,
            _ => 30
        };
    }

    private static int ResolveShootBulletCount(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        if (ShopItemDatabase.TryGetShopItemByResource(item.Resource, out var shopItem))
        {
            if (TryGetTipFirstNumber(shopItem.Tip, "shootBulletCount", out var camelValue))
            {
                return ClampPositivePropertyValue(camelValue);
            }

            if (TryGetTipFirstNumber(shopItem.Tip, "shoot_bullet_count", out var snakeValue))
            {
                return ClampPositivePropertyValue(snakeValue);
            }
        }

        return item.Subtype == 4 ||
            item.Resource.Contains("shotgun", StringComparison.OrdinalIgnoreCase)
            ? 8
            : 1;
    }

    private static float ResolveDefaultFireTime(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        return item.Subtype switch
        {
            2 => 1.85f,
            4 => 1.4f,
            11 or 12 => 1.6f,
            14 or 16 => 1.55f,
            _ => 1.15f
        };
    }

    private static float ResolveDefaultCoolDown(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        return item.Subtype switch
        {
            2 => 1.1f,
            3 => 0.85f,
            4 => 0.75f,
            10 => 1.0f,
            11 or 12 => 1.6f,
            14 or 16 => 1.2f,
            _ => 0.65f
        };
    }

    private static float ResolveDefaultRange(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        return item.Subtype switch
        {
            6 or 13 => 2.2f,
            11 or 12 => 5f,
            10 => 3.5f,
            14 => 3.8f,
            16 => 5f,
            4 => 20f,
            _ => 30f
        };
    }

    private static float ResolveDefaultShotSpread(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        return item.Subtype switch
        {
            2 => 2.2f,
            4 => 4.2f,
            6 or 13 => 0f,
            10 or 11 or 12 or 14 or 16 => 1f,
            _ => 3.2f
        };
    }

    private static bool IsExplosiveProjectileSubtype(byte subtype)
    {
        return subtype is 10 or 11 or 12 or 14 or 16;
    }

    private static float ResolveDefaultExplodeTime(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        return NormalizeGameEquipmentSubtype(item.Subtype) switch
        {
            10 => 2.5f,
            11 or 12 or 14 or 16 => 10f,
            _ => 0f
        };
    }

    private static float ResolveDefaultGravity(PlayerStore.PlayerState.GameLoadoutItem item)
    {
        return NormalizeGameEquipmentSubtype(item.Subtype) switch
        {
            10 => -9.8f,
            _ => 0f
        };
    }

    private static string FormatProtocolFloat(float value)
    {
        return value.ToString("0.###", CultureInfo.InvariantCulture);
    }

    private static float ResolveTunedWeaponFireTime(float fireTime)
    {
        if (float.IsNaN(fireTime) || float.IsInfinity(fireTime) || fireTime <= 0f)
        {
            return WeaponFireTimeMinimum;
        }

        return MathF.Max(WeaponFireTimeMinimum, fireTime * WeaponFireTimeScale);
    }

    private static string FormatGameVector3(float x, float y, float z)
    {
        return string.Create(
            CultureInfo.InvariantCulture,
            $"({FormatProtocolFloat(x)},{FormatProtocolFloat(y)},{FormatProtocolFloat(z)})");
    }

    private static string FormatGameHitScore(float value)
    {
        return float.IsFinite(value) && value < float.MaxValue
            ? FormatProtocolFloat(value)
            : "-";
    }

    private static bool TryGetTipFirstNumberAny(object? tip, out double value, params string[] keys)
    {
        foreach (var key in keys)
        {
            if (TryGetTipFirstNumber(tip, key, out value))
            {
                return true;
            }
        }

        value = 0;
        return false;
    }

    private static bool TryGetTipFirstNumber(object? tip, string key, out double value)
    {
        value = 0;
        if (!TryGetTipValue(tip, key, out var rawValue))
        {
            return false;
        }

        return TryReadFirstNumber(rawValue, out value);
    }

    private static bool TryGetTipValue(object? tip, string key, out object? value)
    {
        value = null;
        if (tip is IReadOnlyDictionary<string, object?> tipMap)
        {
            if (tipMap.TryGetValue(key, out value))
            {
                return true;
            }

            foreach (var pair in tipMap)
            {
                if (string.Equals(pair.Key, key, StringComparison.OrdinalIgnoreCase))
                {
                    value = pair.Value;
                    return true;
                }
            }

            return false;
        }

        if (tip is JsonElement element && element.ValueKind == JsonValueKind.Object)
        {
            foreach (var property in element.EnumerateObject())
            {
                if (string.Equals(property.Name, key, StringComparison.OrdinalIgnoreCase))
                {
                    value = property.Value;
                    return true;
                }
            }
        }

        return false;
    }

    private static bool TryReadFirstNumber(object? rawValue, out double value)
    {
        switch (rawValue)
        {
            case null:
                value = 0;
                return false;
            case byte byteValue:
                value = byteValue;
                return true;
            case sbyte sbyteValue:
                value = sbyteValue;
                return true;
            case short shortValue:
                value = shortValue;
                return true;
            case ushort ushortValue:
                value = ushortValue;
                return true;
            case int intValue:
                value = intValue;
                return true;
            case uint uintValue:
                value = uintValue;
                return true;
            case long longValue:
                value = longValue;
                return true;
            case ulong ulongValue:
                value = ulongValue;
                return true;
            case float floatValue:
                value = floatValue;
                return true;
            case double doubleValue:
                value = doubleValue;
                return true;
            case decimal decimalValue:
                value = (double)decimalValue;
                return true;
            case string stringValue:
                return double.TryParse(stringValue, NumberStyles.Float, CultureInfo.InvariantCulture, out value);
            case JsonElement element:
                return TryReadJsonNumber(element, out value);
            case IEnumerable sequence:
                foreach (var item in sequence)
                {
                    if (TryReadFirstNumber(item, out value))
                    {
                        return true;
                    }
                }

                value = 0;
                return false;
            default:
                value = 0;
                return false;
        }
    }

    private static bool TryReadJsonNumber(JsonElement element, out double value)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.Number:
                return element.TryGetDouble(out value);
            case JsonValueKind.String:
                return double.TryParse(element.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out value);
            case JsonValueKind.Array:
                foreach (var child in element.EnumerateArray())
                {
                    if (TryReadJsonNumber(child, out value))
                    {
                        return true;
                    }
                }

                break;
        }

        value = 0;
        return false;
    }

    private static int ClampPositivePropertyValue(double value)
    {
        if (double.IsNaN(value) || double.IsInfinity(value) || value <= 0)
        {
            return 0;
        }

        return value >= int.MaxValue
            ? int.MaxValue
            : (int)Math.Round(value, MidpointRounding.AwayFromZero);
    }

    private static float ClampPositiveFloat(double value, float fallback)
    {
        if (double.IsNaN(value) || double.IsInfinity(value) || value <= 0)
        {
            return fallback;
        }

        return value >= float.MaxValue
            ? float.MaxValue
            : (float)value;
    }

    private static float ClampNonNegativeFloat(double value, float fallback)
    {
        if (double.IsNaN(value) || double.IsInfinity(value) || value < 0)
        {
            return fallback;
        }

        return value >= float.MaxValue
            ? float.MaxValue
            : (float)value;
    }

    private static float ClampFiniteFloat(double value, float fallback)
    {
        if (double.IsNaN(value) || double.IsInfinity(value))
        {
            return fallback;
        }

        if (value >= float.MaxValue)
        {
            return float.MaxValue;
        }

        return value <= -float.MaxValue
            ? -float.MaxValue
            : (float)value;
    }

    private static string TrimProtocolString(string value, int maxBytes)
    {
        if (Encoding.UTF8.GetByteCount(value) <= maxBytes)
        {
            return value;
        }

        var builder = new StringBuilder(value.Length);
        var byteLength = 0;
        foreach (var ch in value)
        {
            var charLength = Encoding.UTF8.GetByteCount(ch.ToString());
            if (byteLength + charLength > maxBytes)
            {
                break;
            }

            builder.Append(ch);
            byteLength += charLength;
        }

        return builder.ToString();
    }

    private async Task SendPacket103GameCharacterCreateListAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        var gamePlayers = ResolveGamePlayersForPacket(room);
        foreach (var player in gamePlayers)
        {
            await SendPacket103GameCharacterCreateAsync(player);
        }
    }

    private Task SendPacket103GameCharacterCreateAsync(
        GamePacketPlayer player,
        short packetId = GameCharacterInfoPacketId)
    {
        using var writer = new PacketWriter();
        var playerState = player.PlayerState;
        var character = player.Character;
        var characterId = player.CharacterId;
        var characterName = player.CharacterName;
        var career = player.Career;
        var level = player.Level;
        var rankType = player.RankType;
        var rankLevel = player.RankLevel;
        var maxHealth = player.MaxHealth;
        var avatarParts = GetAvatarBlobParts(character?.EquipAvatar);
        var independentTrinketItems = player.IndependentTrinketItems;
        var independentTrinketResources = independentTrinketItems.Select(item => item.Resource).ToArray();
        var isLocalPlayer = player.Uid == _localGameUid;
        var walkSpeed = isLocalPlayer ? _setWalkSpeedOverride ?? CharacterWalkSpeed : CharacterWalkSpeed;
        var rollSlideScale = isLocalPlayer && _setWalkSpeedOverride.HasValue
            ? CharacterRollSlideScale * (walkSpeed / CharacterWalkSpeed)
            : CharacterRollSlideScale;
        var jumpAirSpeed = isLocalPlayer ? _setJumpHeightOverride ?? CharacterJumpAirSpeed : CharacterJumpAirSpeed;
        var flyMotionProfile = ResolveCharacterFlyMotionProfile(independentTrinketItems);
        if (isLocalPlayer && _setJumpHeightOverride.HasValue)
        {
            var jumpInitialVelocityY = ResolveJumpInitialVelocityY(
                _setJumpHeightOverride.Value,
                flyMotionProfile.RiseAccelerationY,
                flyMotionProfile.RiseTotalTime);
            flyMotionProfile = flyMotionProfile with
            {
                RiseInitialVelocityY = jumpInitialVelocityY
            };
        }

        var characterMoveInfo = CreateCharacterMoveInfo(flyMotionProfile);
        if (UseLegacyMinimalPacket103CharacterCreate)
        {
            writer.WriteShort(packetId);
            writer.WriteByte(player.Uid);
            writer.WriteByte(1);
            writer.WriteLong(characterId);
            writer.WriteString(characterName);
            writer.WriteInt(character?.MaxHealth ?? DefaultSpawnHealth);
            writer.WriteInt(0);
            writer.WriteByte(career);
            writer.WriteLong(characterId);
            writer.WriteString(string.Empty);
            writer.WriteByte(0);
            writer.WriteByte(0);
            writer.WriteInt(0);
            writer.WriteFloat(0f);
            writer.WriteFloat(0f);
            writer.WriteFloat(0f);
            writer.WriteFloat(0f);
            writer.WriteInt(0);

            foreach (var part in avatarParts)
            {
                writer.WriteBytes(Encoding.UTF8.GetBytes(part));
            }

            WriteGameIndependentTrinketResourceBlock(writer, independentTrinketResources);

            for (var index = 0; index < 6; index++)
            {
                writer.WriteString(string.Empty);
            }

            writer.WriteInt(0);
            writer.WriteInt(0);
            writer.WriteInt(0);
            writer.WriteInt(0);
            writer.WriteInt(0);
            writer.WriteByte(0);
            writer.WriteByte(0);

            Log.Information(
                "Channel packet{PacketId} -> {Remote}: uid={Uid} characterId={CharacterId} career={Career} maxHealth={MaxHealth} legacyMinimal=True avatarBlobCount={AvatarBlobCount} independentTrinketCount={IndependentTrinketCount} independentTrinkets={IndependentTrinkets}",
                packetId,
                _remoteLabel,
                player.Uid,
                characterId,
                career,
                character?.MaxHealth ?? DefaultSpawnHealth,
                avatarParts.Count(part => !string.IsNullOrWhiteSpace(part) && part != "{}"),
                CountIndependentTrinketResources(independentTrinketResources),
                FormatIndependentTrinketResourceSummary(independentTrinketResources));

            return SendPacketAsync(writer);
        }

        var loadoutSource = playerState?.GetGameLoadoutSource() ?? "empty";
        var loadoutItems = player.LoadoutItems;
        var equipmentItems = player.EquipmentItems;
        var teamId = player.TeamId;

        writer.WriteShort(packetId);
        writer.WriteByte(player.Uid);
        writer.WriteByte(teamId);
        writer.WriteLong(characterId);
        writer.WriteString(TrimProtocolString(characterName, 63));
        writer.WriteInt(level);
        writer.WriteInt(rankType);
        writer.WriteByte((byte)Math.Clamp(rankLevel, 0, byte.MaxValue));
        writer.WriteLong(0);
        writer.WriteString(string.Empty);
        writer.WriteByte(career);
        writer.WriteByte(0);
        writer.WriteInt(maxHealth);
        writer.WriteFloat(walkSpeed);
        writer.WriteFloat(rollSlideScale);
        writer.WriteFloat(jumpAirSpeed);
        writer.WriteFloat(CharacterGravityScale);
        WriteGameEquipmentBlock(writer, equipmentItems);

        foreach (var part in avatarParts)
        {
            writer.WriteBytes(Encoding.UTF8.GetBytes(part));
        }

        WriteGameIndependentTrinketResourceBlock(writer, independentTrinketResources);

        for (var index = 0; index < 6; index++)
        {
            writer.WriteString(string.Empty);
        }

        writer.WriteInt(0);
        writer.WriteInt(0);
        writer.WriteInt(0);
        writer.WriteInt(0);
        WriteCharacterMoveInfo(writer, characterMoveInfo);
        writer.WriteByte(GameCharacterTrailingReservedFlag);
        writer.WriteByte(GameCharacterModelReadyFlag);
        writer.WriteString(DefaultModelReadyResource);
        writer.WriteString(DefaultModelReadyResource);
        writer.WriteInt(DefaultModelReadyLevel);
        WriteGameEquipmentBlock(writer, equipmentItems);
        writer.WriteInt(0);

        Log.Information(
            "Channel packet{PacketId} -> {Remote}: uid={Uid} teamId={TeamId} characterId={CharacterId} level={Level} rankType={RankType} rankLevel={RankLevel} career={Career} maxHealth={MaxHealth} movementScalars=({WalkSpeed},{RollSlide},{JumpAir},{Gravity}) movementTuning={MovementTuning} equipmentBlockCount={EquipmentBlockCount} avatarBlobCount={AvatarBlobCount} independentTrinketCount={IndependentTrinketCount} moveInfoCount={MoveInfoCount} modelReady={ModelReady} modelReadyResource={ModelReadyResource} modelReadyLevel={ModelReadyLevel} loadoutSource={LoadoutSource} backpackStats=True independentTrinkets={IndependentTrinkets} loadout={Loadout}",
            packetId,
            _remoteLabel,
            player.Uid,
            teamId,
            characterId,
            level,
            rankType,
            rankLevel,
            career,
            maxHealth,
            FormatProtocolFloat(walkSpeed),
            FormatProtocolFloat(rollSlideScale),
            FormatProtocolFloat(jumpAirSpeed),
            FormatProtocolFloat(CharacterGravityScale),
            FormatCharacterMovementTuningSummary(flyMotionProfile),
            equipmentItems.Count,
            avatarParts.Count(part => !string.IsNullOrWhiteSpace(part) && part != "{}"),
            CountIndependentTrinketResources(independentTrinketResources),
            characterMoveInfo.Length,
            GameCharacterModelReadyFlag,
            DefaultModelReadyResource,
            DefaultModelReadyLevel,
            loadoutSource,
            FormatIndependentTrinketResourceSummary(independentTrinketResources),
            FormatGameLoadoutSummary(loadoutItems));

        return SendPacketAsync(writer);
    }

    private static void WriteGameIndependentTrinketResourceBlock(
        PacketWriter writer,
        IReadOnlyList<string> resources)
    {
        const int independentTrinketSlotCount = 5;
        for (var index = 0; index < independentTrinketSlotCount; index++)
        {
            var resource = index < resources.Count ? resources[index] : string.Empty;
            writer.WriteString(resource ?? string.Empty);
        }
    }

    private static int CountIndependentTrinketResources(IReadOnlyList<string> resources)
    {
        return resources.Count(resource => !string.IsNullOrWhiteSpace(resource));
    }

    private static string FormatIndependentTrinketResourceSummary(IReadOnlyList<string> resources)
    {
        var populated = resources
            .Select((resource, index) => new { Slot = index + 1, Resource = resource })
            .Where(item => !string.IsNullOrWhiteSpace(item.Resource))
            .Select(item => $"slot={item.Slot},res={item.Resource}")
            .ToArray();

        return populated.Length == 0 ? "none" : string.Join("; ", populated);
    }

    private static string FormatCharacterMovementTuningSummary(CharacterFlyMotionProfile flyProfile)
    {
        return string.Format(
            CultureInfo.InvariantCulture,
            "motion=({0},{1},{2},{3}) jump2=(height:{4};v0:{5},{6};a0:{7},{8};aa:{9},{10};time:{11}) flyMode={12} flyPlan=(glideSpeed:{13};fallSpeed:{14};duration:{15};flightSpeed:{16};finalY:{17};cooldown:{18}) fly=(v0:{19},{20};a0:{21},{22};aa:{23},{24};time:{25}) actions=(fly:{26};takeoff:{27}) native=(extra:{28};flyAnim:{29};takeoff:{30})",
            CharacterWalkSpeed,
            CharacterRollSlideScale,
            CharacterJumpAirSpeed,
            CharacterGravityScale,
            EstimateRiseHeight(flyProfile),
            flyProfile.RiseInitialVelocityX,
            flyProfile.RiseInitialVelocityY,
            flyProfile.RiseAccelerationX,
            flyProfile.RiseAccelerationY,
            flyProfile.RiseExtraAccelerationX,
            flyProfile.RiseExtraAccelerationY,
            flyProfile.RiseTotalTime,
            flyProfile.Name,
            flyProfile.InitialVelocityX,
            Math.Max(0f, -flyProfile.InitialVelocityY),
            flyProfile.TotalTime,
            EstimateFinalHorizontalSpeed(flyProfile),
            EstimateFinalVerticalSpeed(flyProfile),
            flyProfile.Cooldown,
            flyProfile.InitialVelocityX,
            flyProfile.InitialVelocityY,
            flyProfile.AccelerationX,
            flyProfile.AccelerationY,
            flyProfile.ExtraAccelerationX,
            flyProfile.ExtraAccelerationY,
            flyProfile.TotalTime,
            FormatCharacterFlyAnimationName(flyProfile.AnimationVariant),
            FormatCharacterTakeoffAnimationName(flyProfile.TakeoffAnimationEnabled),
            CharacterMoveInfoNativeExtra,
            flyProfile.AnimationVariant,
            flyProfile.TakeoffAnimationEnabled);
    }

    private static float EstimateRiseHeight(CharacterFlyMotionProfile flyProfile)
    {
        return (flyProfile.RiseInitialVelocityY * flyProfile.RiseTotalTime) +
            (0.5f * flyProfile.RiseAccelerationY * flyProfile.RiseTotalTime * flyProfile.RiseTotalTime);
    }

    private static float ResolveJumpInitialVelocityY(float targetHeight, float accelerationY, float totalTime)
    {
        var time = totalTime <= 0.01f ? CharacterJump2TotalTime : totalTime;
        return (targetHeight - (0.5f * accelerationY * time * time)) / time;
    }

    private static float EstimateFinalHorizontalSpeed(CharacterFlyMotionProfile flyProfile)
    {
        return flyProfile.InitialVelocityX + (flyProfile.ExtraAccelerationX * flyProfile.TotalTime);
    }

    private static float EstimateFinalVerticalSpeed(CharacterFlyMotionProfile flyProfile)
    {
        return flyProfile.InitialVelocityY + (flyProfile.ExtraAccelerationY * flyProfile.TotalTime);
    }

    private static string FormatCharacterFlyAnimationName(float animationVariant)
    {
        var index = (int)Math.Round(animationVariant);
        return index <= 0 ? "fly" : string.Format(CultureInfo.InvariantCulture, "fly{0:00}", index);
    }

    private static string FormatCharacterTakeoffAnimationName(float takeoffAnimationEnabled)
    {
        return takeoffAnimationEnabled == 0f ? "stdjumpup" : "takeoff";
    }

    private static float[] CreateCharacterMoveInfo(CharacterFlyMotionProfile flyProfile)
    {
        return
        [
            flyProfile.RiseInitialVelocityX,
            flyProfile.RiseInitialVelocityY,
            flyProfile.RiseAccelerationX,
            flyProfile.RiseAccelerationY,
            flyProfile.RiseExtraAccelerationX,
            flyProfile.RiseExtraAccelerationY,
            flyProfile.RiseTotalTime,
            flyProfile.InitialVelocityX,
            flyProfile.InitialVelocityY,
            flyProfile.AccelerationX,
            flyProfile.AccelerationY,
            flyProfile.ExtraAccelerationX,
            flyProfile.ExtraAccelerationY,
            flyProfile.TotalTime,
            CharacterMoveInfoNativeExtra,
            flyProfile.AnimationVariant,
            flyProfile.TakeoffAnimationEnabled
        ];
    }

    private static void WriteCharacterMoveInfo(PacketWriter writer, IReadOnlyList<float> moveInfo)
    {
        writer.WriteInt(moveInfo.Count);
        foreach (var value in moveInfo)
        {
            writer.WriteFloat(value);
        }
    }

    private static CharacterFlyMotionProfile ResolveCharacterFlyMotionProfile(IReadOnlyList<PlayerStore.PlayerState.GameIndependentTrinketItem> independentTrinkets)
    {
        var wing = independentTrinkets.Count > 0 ? independentTrinkets[0] : null;
        var wingResource = wing?.Resource ?? string.Empty;
        var tokens = EnumerateClientResourceTokens(wingResource).ToArray();
        var profile = CharacterWingFlightRules.Value.Resolve(tokens);
        return ApplyCharacterFlyTimeAttribute(profile, wing?.BackpackItem);
    }

    private static CharacterFlyMotionProfile ApplyCharacterFlyTimeAttribute(
        CharacterFlyMotionProfile profile,
        InventoryItem? backpackItem)
    {
        if (backpackItem?.Attributes is null)
        {
            return profile;
        }

        var resolvedProfile = profile;
        if (!string.IsNullOrWhiteSpace(profile.TimeAttribute))
        {
            var keys = profile.TimeAttribute.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            if (keys.Length > 0 &&
                TryGetInventoryAttributeFirstNumberAny(backpackItem.Attributes, out var configuredTime, keys))
            {
                var resolvedTime = ClampPositiveFloat(configuredTime * profile.TimeAttributeScale, profile.TotalTime);
                if (profile.MinimumTime is { } minimumTime)
                {
                    resolvedTime = MathF.Max(minimumTime, resolvedTime);
                }

                if (profile.MaximumTime is { } maximumTime)
                {
                    resolvedTime = MathF.Min(maximumTime, resolvedTime);
                }

                resolvedProfile = resolvedProfile with { TotalTime = resolvedTime };
            }
        }

        if (!string.IsNullOrWhiteSpace(profile.CooldownAttribute))
        {
            var keys = profile.CooldownAttribute.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
            if (keys.Length > 0 &&
                TryGetInventoryAttributeFirstNumberAny(backpackItem.Attributes, out var configuredCooldown, keys))
            {
                var resolvedCooldown = ClampNonNegativeFloat(configuredCooldown * profile.CooldownAttributeScale, profile.Cooldown);
                if (profile.MinimumCooldown is { } minimumCooldown)
                {
                    resolvedCooldown = MathF.Max(minimumCooldown, resolvedCooldown);
                }

                if (profile.MaximumCooldown is { } maximumCooldown)
                {
                    resolvedCooldown = MathF.Min(maximumCooldown, resolvedCooldown);
                }

                resolvedProfile = resolvedProfile with { Cooldown = resolvedCooldown };
            }
        }

        return resolvedProfile;
    }

    private static bool TryGetInventoryAttributeFirstNumberAny(
        IReadOnlyDictionary<string, double> attributes,
        out double value,
        params string[] keys)
    {
        foreach (var key in keys)
        {
            if (attributes.TryGetValue(key, out value))
            {
                return true;
            }

            foreach (var pair in attributes)
            {
                if (string.Equals(pair.Key, key, StringComparison.OrdinalIgnoreCase))
                {
                    value = pair.Value;
                    return true;
                }
            }
        }

        value = 0;
        return false;
    }

    private static IEnumerable<string> EnumerateClientResourceTokens(string clientResource)
    {
        if (string.IsNullOrWhiteSpace(clientResource))
        {
            yield break;
        }

        foreach (var rawPart in clientResource.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries))
        {
            var token = rawPart.Trim().Trim('\'', '"');
            if (token.Length == 0)
            {
                continue;
            }

            yield return token;

            const string indieSuffix = "_indie";
            if (token.EndsWith(indieSuffix, StringComparison.OrdinalIgnoreCase))
            {
                yield return token[..^indieSuffix.Length];
            }
        }
    }

    private static IReadOnlyList<string> GetAvatarBlobParts(object? equipAvatar)
    {
        return AvatarBlobKeys
            .Select(key => GetAvatarPart(equipAvatar, key))
            .ToArray();
    }

    private static string GetAvatarPart(object? equipAvatar, string key)
    {
        if (equipAvatar is null)
        {
            return "{}";
        }

        if (equipAvatar is JsonElement jsonElement)
        {
            if (jsonElement.ValueKind == JsonValueKind.Object &&
                jsonElement.TryGetProperty(key, out var property))
            {
                return property.ValueKind == JsonValueKind.String
                    ? NormalizeAvatarPart(property.GetString())
                    : NormalizeAvatarPart(property.ToString());
            }

            return "{}";
        }

        if (equipAvatar is IReadOnlyDictionary<string, string> stringMap &&
            stringMap.TryGetValue(key, out var stringValue))
        {
            return NormalizeAvatarPart(stringValue);
        }

        if (equipAvatar is IReadOnlyDictionary<string, object?> objectMap &&
            objectMap.TryGetValue(key, out var objectValue))
        {
            return NormalizeAvatarPart(objectValue?.ToString());
        }

        var propertyInfo = equipAvatar.GetType().GetProperty(key);
        return propertyInfo is null
            ? "{}"
            : NormalizeAvatarPart(propertyInfo.GetValue(equipAvatar)?.ToString());
    }

    private static string NormalizeAvatarPart(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? "{}" : value!;
    }

    private Task SendPacket111GameTeleportAsync(
        float x,
        float y,
        float z,
        float yaw,
        string source,
        int? healthOverride = null)
    {
        if (_currentGameRoom is null)
        {
            return Task.CompletedTask;
        }

        using var writer = new PacketWriter();
        var playerState = GetLocalPlayerState(_currentGameRoom);
        var health = healthOverride ?? ResolveLocalGamePlayerHealth(playerState?.Character);
        const short actorState = InitialGamePlayerActionStateFlags;
        const float actorFloat = 0f;

        writer.WriteShort(111);
        writer.WriteByte(_localGameUid);
        writer.WriteInt(health);
        writer.WriteShort(actorState);
        writer.WriteFloat(actorFloat);
        writer.WriteFloat(x);
        writer.WriteFloat(y);
        writer.WriteFloat(z);
        writer.WriteFloat(yaw);

        Log.Information(
            "Channel packet111 -> {Remote}: local teleport source={Source} localUid={LocalUid} health={Health} actorState={ActorState} actorFloat={ActorFloat} position=({X}, {Y}, {Z}) yaw={Yaw}",
            _remoteLabel,
            source,
            _localGameUid,
            health,
            actorState,
            actorFloat,
            FormatProtocolFloat(x),
            FormatProtocolFloat(y),
            FormatProtocolFloat(z),
            FormatProtocolFloat(yaw));

        return SendPacketAsync(writer);
    }

    private Task SendPacket111GameSpawnAsync(
        PracticeRoomManager.PracticeRoomSession room,
        string trigger = "local-spawn")
    {
        var member = GetLocalGameMember(room);
        var player = CreateGamePacketPlayer(
            room,
            new PracticeRoomManager.GamePlayerSnapshot(
                _localGameUid,
                member?.CharacterId ?? room.HostCharacterId,
                member?.CharacterName ?? room.HostName,
                null));

        return SendPacket111GameSpawnAsync(room, player, trigger);
    }

    private Task SendPacket111GameSpawnAsync(
        PracticeRoomManager.PracticeRoomSession room,
        GamePacketPlayer player,
        string trigger)
    {
        using var writer = new PacketWriter();
        if (UseLegacyMinimalPacket111Spawn)
        {
            var actorType = (short)player.Career;
            var legacyHealth = player.MaxHealth;

            writer.WriteShort(111);
            writer.WriteByte(player.Uid);
            writer.WriteInt(legacyHealth);
            writer.WriteShort(actorType);
            writer.WriteFloat(1f);
            writer.WriteFloat(0f);
            writer.WriteFloat(0f);
            writer.WriteFloat(0f);
            writer.WriteFloat(0f);

            Log.Information(
                "Channel packet111 -> {Remote}: trigger={Trigger} uid={Uid} health={Health} actorType={ActorType} legacyMinimal=True",
                _remoteLabel,
                trigger,
                player.Uid,
                legacyHealth,
                actorType);

            return SendPacketAsync(writer);
        }

        var health = player.MaxHealth;
        const short actorState = InitialGamePlayerActionStateFlags;
        const float spawnActorFloat = 0f;
        var (spawnPositionX, spawnPositionY, spawnPositionZ, spawnYaw) = ResolveGameSpawnTransform(room, player.LastPosition);

        writer.WriteShort(111);
        writer.WriteByte(player.Uid);
        writer.WriteInt(health);
        writer.WriteShort(actorState);
        writer.WriteFloat(spawnActorFloat);
        writer.WriteFloat(spawnPositionX);
        writer.WriteFloat(spawnPositionY);
        writer.WriteFloat(spawnPositionZ);
        writer.WriteFloat(spawnYaw);

        Log.Information(
            "Channel packet111 -> {Remote}: trigger={Trigger} uid={Uid} health={Health} actorState={ActorState} spawnActorFloat={SpawnActorFloat} spawnPosition=({SpawnPositionX}, {SpawnPositionY}, {SpawnPositionZ}) spawnYaw={SpawnYaw}",
            _remoteLabel,
            trigger,
            player.Uid,
            health,
            actorState,
            spawnActorFloat,
            spawnPositionX,
            spawnPositionY,
            spawnPositionZ,
            spawnYaw);

        return SendPacketAsync(writer);
    }

    private static (float X, float Y, float Z, float Yaw) ResolveGameSpawnTransform(
        PracticeRoomManager.PracticeRoomSession room,
        PracticeRoomManager.GamePosition? position)
    {
        if (position.HasValue)
        {
            return (
                RawToWorldCoordinate(position.Value.XRaw),
                RawToWorldCoordinate(position.Value.YRaw),
                RawToWorldCoordinate(position.Value.ZRaw),
                position.Value.YawRaw.HasValue
                    ? RawToWorldCoordinate(position.Value.YawRaw.Value)
                    : 0f);
        }

        return ResolveSpawnPoint(room);
    }

    private static (float X, float Y, float Z, float Yaw) ResolveSpawnPoint(
        PracticeRoomManager.PracticeRoomSession room)
    {
        // The reference server avoids the origin because some maps place dead-space
        // volumes there. Keep the spawn explicit until per-map spawn tables are decoded.
        return (-22f, 2f, 15f, 0f);
    }

    private void UpdateLocalGameSpawnPosition(
        PracticeRoomManager.PracticeRoomSession room,
        bool overwriteExisting,
        string trigger)
    {
        if (!overwriteExisting &&
            _practiceRoomManager.HasGamePosition(room.RoomId, _localGameUid))
        {
            return;
        }

        var (x, y, z, _) = ResolveSpawnPoint(room);
        var position = new PracticeRoomManager.GamePosition(
            WorldToRawCoordinate(x),
            WorldToRawCoordinate(y),
            WorldToRawCoordinate(z),
            null,
            null,
            null,
            DateTimeOffset.UtcNow);

        if (overwriteExisting)
        {
            _practiceRoomManager.UpdateGamePosition(room.RoomId, _localGameUid, position);
        }
        else
        {
            _practiceRoomManager.UpdateGamePositionIfMissing(room.RoomId, _localGameUid, position);
        }

        Log.Verbose(
            "Channel game position seed: trigger={Trigger} uid={Uid} position=({X},{Y},{Z}) overwrite={Overwrite}",
            trigger,
            _localGameUid,
            FormatProtocolFloat(x),
            FormatProtocolFloat(y),
            FormatProtocolFloat(z),
            overwriteExisting);
    }

    private void UpdateLocalGamePositionFromActionPose(
        float originX,
        float originY,
        float originZ,
        short facing0Raw,
        short facing1Raw)
    {
        if (_currentGameRoom is null)
        {
            return;
        }

        _practiceRoomManager.UpdateGamePosition(
            _currentGameRoom.RoomId,
            _localGameUid,
            new PracticeRoomManager.GamePosition(
                WorldToRawCoordinate(originX),
                WorldToRawCoordinate(originY),
                WorldToRawCoordinate(originZ),
                null,
                facing0Raw,
                facing1Raw,
                DateTimeOffset.UtcNow));
    }

    private PracticeRoomManager.PracticeRoomMember? GetLocalGameMember(PracticeRoomManager.PracticeRoomSession room)
    {
        if (_currentCharacterId > 0)
        {
            var localMember = room.Members.FirstOrDefault(member => member.CharacterId == _currentCharacterId);
            if (localMember is not null)
            {
                return localMember;
            }
        }

        return room.Members.FirstOrDefault(member => member.Host) ??
            room.Members.FirstOrDefault(member => member.CharacterId != 0);
    }

    private Task SendPacket16RoomEnterResultAsync(PracticeRoomManager.PracticeRoomSession? room, int resultCode)
    {
        using var writer = new PacketWriter();
        AvatarStarClientProtocol.WriteChannelRoomEnterResult(writer, room, resultCode);

        Log.Information(
            "Channel packet16 -> {Remote}: resultCode={ResultCode} contextId={ContextId} roomId={RoomId}",
            _remoteLabel,
            resultCode,
            room?.ContextId ?? 0,
            room?.RoomId ?? 0);

        return SendPacketAsync(writer);
    }

    private Task SendPacket19RoomInfoSyncAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        using var writer = new PacketWriter();
        AvatarStarClientProtocol.WriteChannelRoomInfoSync(writer, room);

        Log.Information(
            "Channel packet19 -> {Remote}: contextId={ContextId} roomId={RoomId} currentClientNum={CurrentClientNum}",
            _remoteLabel,
            room.ContextId,
            room.RoomId,
            room.CurrentClientNum);

        return SendPacketAsync(writer);
    }

    private Task SendPacket18RoomClientListSyncAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        using var writer = new PacketWriter();
        var populatedSlotCount = AvatarStarClientProtocol.WriteChannelRoomClientListSync(writer, room);

        Log.Information(
            "Channel packet18 -> {Remote}: contextId={ContextId} roomId={RoomId} populatedSlots={PopulatedSlots}",
            _remoteLabel,
            room.ContextId,
            room.RoomId,
            populatedSlotCount);

        return SendPacketAsync(writer);
    }

    private Task SendPacket17LeaveRoomAsync()
    {
        using var writer = new PacketWriter();
        writer.WriteShort(17);

        Log.Information("Channel packet17 -> {Remote}: leave-room ack", _remoteLabel);
        return SendPacketAsync(writer);
    }

    private Task SendPacket20RoomOptionChangeResultAsync(int resultCode)
    {
        using var writer = new PacketWriter();
        writer.WriteShort(20);
        writer.WriteInt(resultCode);

        Log.Information(
            "Channel packet20 -> {Remote}: resultCode={ResultCode}",
            _remoteLabel,
            resultCode);

        return SendPacketAsync(writer);
    }

    private Task SendPacket2RoomInfoChangedAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        using var writer = new PacketWriter();
        AvatarStarClientProtocol.WriteChannelRoomInfoChanged(writer, room);

        Log.Information(
            "Channel packet2 -> {Remote}: contextId={ContextId} roomId={RoomId} roomName={RoomName}",
            _remoteLabel,
            room.ContextId,
            room.RoomId,
            room.RoomName);

        return SendPacketAsync(writer);
    }

    private Task SendPacket4RoomOptionChangedAsync(PracticeRoomManager.PracticeRoomSession room)
    {
        using var writer = new PacketWriter();
        AvatarStarClientProtocol.WriteChannelRoomOptionChanged(writer, room);

        Log.Information(
            "Channel packet4 -> {Remote}: contextId={ContextId} roomId={RoomId} roomName={RoomName}",
            _remoteLabel,
            room.ContextId,
            room.RoomId,
            room.RoomName);

        return SendPacketAsync(writer);
    }

    private Task SendPacket26SlotChangedAsync(
        PracticeRoomManager.PracticeRoomSession room,
        long characterId,
        byte slotIndex)
    {
        using var writer = new PacketWriter();
        AvatarStarClientProtocol.WriteChannelSlotChanged(writer, characterId, slotIndex);

        Log.Information(
            "Channel packet26 -> {Remote}: roomId={RoomId} characterId={CharacterId} slotIndex={SlotIndex}",
            _remoteLabel,
            room.RoomId,
            characterId,
            slotIndex);

        return SendPacketAsync(writer);
    }

    private async Task SendPacketAsync(PacketWriter writer)
    {
        await SendPayloadAsync(writer.ToBuffer(), encrypt: true);
    }

    private async Task SendPayloadAsync(byte[] payload, bool encrypt)
    {
        await _sendLock.WaitAsync();
        try
        {
            if (encrypt)
            {
                XorNetworkCodec.EncodeInPlace(payload.AsSpan(), ref _xorOutState);
            }

            await _sendPayloadAsync(payload);
        }
        finally
        {
            _sendLock.Release();
        }
    }

    private enum ChannelState
    {
        AwaitClientSeed = 0,
        AwaitClientHello = 1,
        AwaitRoomEnter = 2,
        InRoom = 3,
        InGame = 4
    }
}
