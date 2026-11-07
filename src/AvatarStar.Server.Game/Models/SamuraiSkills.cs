using System.Numerics;

namespace AvatarStar.Server.Game;

/// <summary>Values from scripts/newsys/class/samurai.lua; resource scripts supply the cast effects.</summary>
internal static class SamuraiSkills
{
    // Server-assigned profession skill ids. Buff ids are a separate client namespace.
    public const int IaiSlash = 80;
    public const int WindStep = 81;
    public const int WindCut = 82;
    public const int BladeGuard = 83;
    public const int Bushido = 84;
    public const int Counter = 85;
    public const byte CounterSlot = 16;
    public static readonly SkillDefinition CounterDefinition = new(Counter,
        "id_datalist_Samurai_BladeGuard", "samurai_counter", false);
    public const byte GuardBuff = 69;
    public const byte BushidoBuff = 89;
    public const float StepDistance = 7f;
    public const float CounterRange = 8f;
    public const int BushidoSeconds = 6;

    public static readonly SkillDefinition[] Definitions =
    [
        new(IaiSlash, "id_datalist_Samurai_IaiSlash", "samurai_iaislash", true,
            Cooldowns: [14, 13, 12, 11, 10], Distances: [4.5f]),
        new(WindStep, "id_datalist_Samurai_WindStep", "samurai_windstep", true,
            Cooldowns: [16, 15, 14, 13, 12], Distances: [7]),
        new(WindCut, "id_datalist_Samurai_WindCut", "samurai_windcut", true,
            Cooldowns: [15, 14, 13, 12, 11], Distances: [12]),
        new(BladeGuard, "id_datalist_Samurai_BladeGuard", "samurai_bladeguard", true,
            Cooldowns: [20, 19, 17, 16, 14], Distances: [8], BuffId: GuardBuff),
        new(Bushido, "id_datalist_Samurai_Bushido", "samurai_bushido", false, BuffId: BushidoBuff)
    ];

    public static bool IsSamurai(int id) => id is >= IaiSlash and <= Bushido;
    private static int At(int level, int[] values) => values[Math.Clamp(level, 1, 5) - 1];
    public static int Damage(int id, int level) => id switch
    {
        IaiSlash => At(level, [300, 350, 400, 450, 500]),
        WindStep => At(level, [250, 300, 350, 400, 450]),
        WindCut => At(level, [280, 330, 380, 430, 480]),
        BladeGuard => At(level, [150, 200, 250, 300, 350]),
        _ => 0
    };
    public static int GuardMilliseconds(int level) => At(level, [4000, 4500, 5000, 5500, 6000]);
    public static int GuardReduction(int level) => At(level, [50, 55, 60, 65, 70]);
    public static int BushidoPercent(int level) => At(level, [10, 12, 14, 17, 20]);

    public static bool Hits(int id, Vector3 origin, Vector2 forward, Vector3 target)
    {
        if (!float.IsFinite(target.X + target.Y + target.Z + origin.X + origin.Y + origin.Z) ||
            !float.IsFinite(forward.LengthSquared()) || forward.LengthSquared() < 0.0001f ||
            MathF.Abs(target.Y - origin.Y) > 2f)
            return false;
        forward = Vector2.Normalize(forward);
        var delta = new Vector2(target.X - origin.X, target.Z - origin.Z);
        var along = Vector2.Dot(delta, forward);
        if (id == IaiSlash)
            return delta.LengthSquared() <= 4.5f * 4.5f && along >= delta.Length() * 0.5f - 0.0001f;
        var length = id == WindStep ? StepDistance : 12f;
        return id is WindStep or WindCut && along >= 0 && along <= length &&
            MathF.Abs(delta.X * forward.Y - delta.Y * forward.X) <= 1f;
    }
}

/// <summary>Room-local state, accessed under the room manager lock. Deadlines use monotonic time.</summary>
internal sealed class SamuraiCombatState
{
    private readonly Dictionary<int, long> _readyAt = new();
    public long GuardUntil { get; private set; }
    public int GuardLevel { get; private set; }
    public long BushidoUntil { get; private set; }
    public int BushidoLevel { get; set; }

    public bool TryActivate(int skillId, int level, long now)
    {
        var definition = SamuraiSkills.Definitions.FirstOrDefault(s => s.Id == skillId && s.IsActive);
        if (definition is null || level is < 1 or > 5 || _readyAt.GetValueOrDefault(skillId) > now)
            return false;
        _readyAt[skillId] = now + (long)(definition.ResolveCooldown(level) * 1000);
        if (skillId == SamuraiSkills.BladeGuard)
        {
            GuardLevel = level;
            GuardUntil = now + SamuraiSkills.GuardMilliseconds(level);
        }
        return true;
    }

    public int ConsumeGuard(float distanceSquared, long now)
    {
        if (GuardUntil <= now || !float.IsFinite(distanceSquared) || distanceSquared > 64f)
            return 0;
        var level = GuardLevel;
        GuardUntil = 0;
        return level;
    }

    public int WeaponDamage(int damage, long now) => BushidoLevel > 0 && BushidoUntil > now
        ? (int)Math.Min(int.MaxValue, (long)damage * (100 + SamuraiSkills.BushidoPercent(BushidoLevel)) / 100)
        : damage;

    public bool OnKill(long now)
    {
        if (BushidoLevel <= 0) return false;
        BushidoUntil = now + SamuraiSkills.BushidoSeconds * 1000;
        return true;
    }

    public long Deadline(byte buff) => buff == SamuraiSkills.GuardBuff ? GuardUntil : BushidoUntil;
    public void Clear()
    {
        GuardUntil = BushidoUntil = 0;
        _readyAt.Clear();
    }
}
