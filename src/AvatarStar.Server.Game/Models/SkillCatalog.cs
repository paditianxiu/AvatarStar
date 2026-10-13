namespace AvatarStar.Server.Game;

/// <summary>
/// Definition of a single profession skill as returned by the `skill_list` RPC.
/// Reconstructed from observed client-bound packets (RPC id=39).
/// </summary>
/// <param name="Id">Skill id (client `skills[].id`).</param>
/// <param name="DisplayBase">Base game-text id; leveled variants append `_NN`.</param>
/// <param name="Resource">Icon/resource key (client renders `&lt;resDir&gt;&lt;resource&gt;.tga`).</param>
/// <param name="IsActive">"Y" for active abilities, "N" for passive ones.</param>
/// <param name="Type">Skill category; observed as 1.</param>
/// <param name="SubType">1 = profession skill, 2 = boss skill; observed as 1.</param>
/// <param name="HasLeveledDisplay">Whether the display id carries a level suffix.</param>
/// <param name="MaxDisplayLevel">Highest valued display variant that exists for this skill.</param>
/// <param name="Cooldowns">Cooldown in seconds per invested level (index 0 = level 1); null when unknown.</param>
/// <param name="Distances">Effect radius in metres per invested level (index 0 = level 1); null when unknown.</param>
/// <param name="BuffId">
/// In-game ability ("buff") id the retail server opens with packet 155 once the skill takes effect,
/// or -1 when the skill does not open an ability. Recovered from the shipped
/// `AvatarStar_cache/buff/*.lua` ability definitions, where every ability binds the same icon and
/// cast sound as its skill (e.g. buff 15 = latent.tga/cloakon, buff 6 = spurt.tga).
/// </param>
internal sealed record SkillDefinition(
    int Id,
    string DisplayBase,
    string Resource,
    bool IsActive,
    int Type = 1,
    int SubType = 1,
    bool HasLeveledDisplay = true,
    int MaxDisplayLevel = 5,
    float[]? Cooldowns = null,
    float[]? Distances = null,
    int BuffId = -1)
{
    /// <summary>Resolves the game-text id shown by the client for the given invested level.</summary>
    public string ResolveDisplay(int level)
    {
        if (!HasLeveledDisplay)
        {
            return DisplayBase;
        }

        // Level 0 (unlearned) and level 1 both use the `_01` variant; some skills only ship `_01`.
        var displayLevel = Math.Clamp(Math.Max(level, 1), 1, MaxDisplayLevel);
        return DisplayBase + "_" + displayLevel.ToString("D2", System.Globalization.CultureInfo.InvariantCulture);
    }

    /// <summary>Cooldown reported to the client for the given invested level (0 when unknown).</summary>
    public float ResolveCooldown(int level)
    {
        return ResolveLevelValue(Cooldowns, level);
    }

    /// <summary>Effect radius reported to the client for the given invested level (0 when unknown).</summary>
    public float ResolveDistance(int level)
    {
        return ResolveLevelValue(Distances, level);
    }

    private static float ResolveLevelValue(float[]? values, int level)
    {
        if (values is null || values.Length == 0)
        {
            return 0f;
        }

        return values[Math.Clamp(level, 1, values.Length) - 1];
    }
}

/// <summary>A single entry of the `skill_list` `costMap` (currency id + price to reset).</summary>
internal sealed record SkillResetCost(int Currency, int Cost);

/// <summary>
/// Per-occupation skill tables for the `skill_list` RPC.
/// Occupations match the client profession ids: 0=Guardian, 1=Heavy, 2=Assault, 3=Biochemical.
/// </summary>
internal static class SkillCatalog
{
    /// <summary>Highest number of points a single skill can hold.</summary>
    public const int MaxSkillLevel = 5;

    /// <summary>Constant `resetMaxLevel` reported to the client.</summary>
    public const int ResetMaxLevel = 3;

    private static readonly SkillDefinition[] GuardianSkills =
    [
        new(0, "id_datalist_Battlefield_Heal", "cure", IsActive: true,
            Cooldowns: [22f, 21f, 20f, 18f, 16f], Distances: [8f, 8f, 8f, 8f, 8f], BuffId: 0),
        new(3, "id_datalist_Shockwave", "shock", IsActive: true,
            Cooldowns: [18f, 17f, 15f, 13f, 10f], Distances: [6f, 6f, 6f, 6f, 6f], BuffId: 4),
        new(6, "id_datalist_Achilles_Heel", "vitals", IsActive: false, BuffId: 5),
        new(9, "id_datalist_Arrow_Shower", "rain", IsActive: true,
            Cooldowns: [12f, 12f, 12f, 12f, 12f], BuffId: 3),
        new(14, "id_datalist_Healing_Beacon", "energy", IsActive: true,
            Cooldowns: [20f, 20f, 20f, 20f, 20f], Distances: [5f, 5f, 5f, 5f, 5f], BuffId: 1),
        new(76, "tips_buff_langwangshichou", "feud", IsActive: false, HasLeveledDisplay: false, BuffId: 128)
    ];

    private static readonly SkillDefinition[] HeavySkills =
    [
        new(1, "id_datalist_Shield", "shield", IsActive: true,
            Cooldowns: [23f, 22f, 21f, 20f, 18f], Distances: [8f, 8f, 8f, 8f, 8f], BuffId: 8),
        new(4, "id_datalist_Haste", "gallop", IsActive: true,
            Cooldowns: [15f, 15f, 15f, 15f, 15f], Distances: [8f, 8f, 8f, 8f, 8f], BuffId: 9),
        new(7, "id_datalist_Perseverance", "tenacity", IsActive: false, BuffId: 12),
        new(10, "id_datalist_Blitzkrieg", "heavy", IsActive: false, BuffId: 11),
        new(12, "id_datalist_Damage_Converter", "transfer", IsActive: false,
            Distances: [8f, 8f, 8f, 8f, 8f], BuffId: 10)
    ];

    private static readonly SkillDefinition[] AssaultSkills =
    [
        new(2, "id_datalist_Stealth", "latent", IsActive: true,
            Cooldowns: [23f, 21f, 18f, 15f, 13f], Distances: [11f, 10f, 9f, 8f, 6f], BuffId: 15),
        new(5, "id_datalist_Fatal_Shot", "piercing", IsActive: false, BuffId: 16),
        new(8, "id_datalist_Poison_Pierce", "poison", IsActive: false, BuffId: 17),
        new(11, "id_datalist_Deadly_Sprint", "spurt", IsActive: true,
            Cooldowns: [22f, 21f, 20f, 19f, 17f], BuffId: 6),
        new(13, "id_datalist_Trap", "snare", IsActive: true,
            // The retail in-game equipment block reports Trap with a 0 range, so no distance is sent.
            Cooldowns: [25f, 23f, 21f, 18f, 15f], Distances: [0f, 0f, 0f, 0f, 0f], BuffId: 19)
    ];

    private static readonly SkillDefinition[] BiochemicalSkills =
    [
        new(38, "id_datalist_shengmingchuandao", "conduction", IsActive: true, MaxDisplayLevel: 1, BuffId: 61),
        new(39, "id_datalist_shengmingchouqu", "suckblood", IsActive: false, MaxDisplayLevel: 1, BuffId: 72),
        new(40, "id_datalist_wenyichuanbo", "plague", IsActive: false, MaxDisplayLevel: 1, BuffId: 71),
        new(41, "id_datalist_duqidan", "gasbomb", IsActive: false, MaxDisplayLevel: 1, BuffId: 70),
        new(42, "id_datalist_guojifanying", "overreaction", IsActive: true, MaxDisplayLevel: 1, BuffId: 68)
    ];

    // Ordered as observed: diamond (2), ticket (4), gold (1).
    private static readonly SkillResetCost[] GuardianResetCosts = [new(2, 0), new(4, 0), new(1, 0)];
    private static readonly SkillResetCost[] HeavyResetCosts = [new(2, 1), new(4, 0), new(1, 500)];
    private static readonly SkillResetCost[] AssaultResetCosts = [new(2, 2), new(4, 0), new(1, 1000)];
    private static readonly SkillResetCost[] BiochemicalResetCosts = [new(2, 1), new(4, 0), new(1, 500)];

    // Skill ids are unique across occupations, so a flat table can serve lookups that
    // only know a skill id (e.g. the in-game equipment block).
    private static readonly SkillDefinition[] AllSkills =
    [
        .. GuardianSkills, .. HeavySkills, .. AssaultSkills, .. BiochemicalSkills
    ];

    public static IReadOnlyList<SkillDefinition> GetSkills(int occupation)
    {
        return occupation switch
        {
            1 => HeavySkills,
            2 => AssaultSkills,
            3 => BiochemicalSkills,
            _ => GuardianSkills
        };
    }

    public static IReadOnlyList<SkillResetCost> GetResetCosts(int occupation)
    {
        return occupation switch
        {
            1 => HeavyResetCosts,
            2 => AssaultResetCosts,
            3 => BiochemicalResetCosts,
            _ => GuardianResetCosts
        };
    }

    /// <summary>Finds a profession skill definition by its (globally unique) skill id, or null when unknown.</summary>
    public static SkillDefinition? FindSkill(int skillId)
    {
        foreach (var definition in AllSkills)
        {
            if (definition.Id == skillId)
            {
                return definition;
            }
        }

        return null;
    }

    /// <summary>
    /// Resolves the in-game ability ("buff") id the retail server opens with packet 155 when the
    /// skill takes effect, or -1 when the skill does not open an ability.
    /// </summary>
    public static int ResolveBuffId(int skillId)
    {
        return FindSkill(skillId)?.BuffId ?? -1;
    }
}
