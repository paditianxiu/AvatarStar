namespace AvatarStar.Server.Game.Config;

public class SysAvatarPayloadConfig
{
    public Dictionary<int, string> SysAvatarListPayloads { get; set; } = new();
    public OfficialAvatarCatalog? OfficialCatalog { get; set; }
}

public class OfficialAvatarCatalog
{
    public string? Version { get; set; }
    public string? Description { get; set; }
    public string? Source { get; set; }
    public List<OfficialProfession> Professions { get; set; } = new();
}

public class OfficialProfession
{
    public int Occupation { get; set; }
    public string? DisplayName { get; set; }
    public string? Description { get; set; }
    public OfficialBaseStats? BaseStats { get; set; }
    public List<OfficialWeapon> Weapons { get; set; } = new();
    public OfficialPresets? Presets { get; set; }
}

public class OfficialBaseStats
{
    public int Life { get; set; }
    public float Armor { get; set; }
    public float Recovery { get; set; }
}

public class OfficialWeapon
{
    public required string Resource { get; set; }
    public required string SubType { get; set; }
    public string? DisplayName { get; set; }
    public string? Description { get; set; }
}

public class OfficialPresets
{
    public OfficialPreset? Male { get; set; }
    public OfficialPreset? Female { get; set; }
}

public class OfficialPreset
{
    public string? AvatarId { get; set; }
}
