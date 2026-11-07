using System.Text.Json;

namespace AvatarStar.Server.Game;

internal static class SamuraiAppearance
{
    public const string MaleAvatarId = "100201";
    public const string FemaleAvatarId = "100202";

    // These are existing mesh/texture keys in the unpacked client, not new binary models.
    public static Dictionary<string, string> Create(bool female)
    {
        var prefix = female ? "jadesamuraiw" : "jadesamurai";
        var avatar = new Dictionary<string, string>();
        foreach (var field in new[] { "skin", "eye", "mouth", "nose", "ear", "beard", "hair", "helmet",
                     "underwear", "outerwear", "trousers", "glove", "shoes", "decal", "movable", "immobile",
                     "immobileUp", "immobileDown" })
            avatar[field] = "{}";
        avatar["avatarId"] = female ? FemaleAvatarId : MaleAvatarId;
        avatar["skin"] = "{'onecolor_skin',1,-1,1,206,165,135,0,0,0,0,0,0}";
        avatar["eye"] = "{'seven_eye',2,0.149387,-0.154003,0,0.885843,0.885843,-0.149387,-0.154003,0,0.885843,0.885843,3,0,0,0,42,87,64,140,87,103}";
        avatar["mouth"] = "{'seven_mouth',3,0.00136006,-0.0307693,0,2.01155,1.00577,2,0,0,2,180,55,54,0,0,0}";
        avatar["hair"] = $"{{'{prefix}01_hair_lod0',7,-1,3,32,52,42,24,28,26,210,176,92}}";
        foreach (var (name, part, layer) in new[] { ("outerwear", 10, 1), ("trousers", 11, 0), ("glove", 12, 2), ("shoes", 13, 3) })
            avatar[name] = $"{{{{'{prefix}_{name}',{part},{layer},3,34,114,83,24,50,41,210,176,92}},}}";
        avatar["immobileUp"] = "{" + string.Join(",", Enumerable.Range(11, 4).Select((n, i) =>
            $"{{'{prefix}{n}_trinket_lod0',17,{i},3,34,114,83,24,50,41,210,176,92}}")) + ",}";
        avatar["immobileDown"] = "{" + string.Join(",", Enumerable.Range(15, 3).Select((n, i) =>
            $"{{'{prefix}{n}_trinket_lod0',18,{i},3,34,114,83,24,50,41,210,176,92}}")) + ",}";
        return avatar;
    }

    public static bool IsLegacyStarter(object avatar)
    {
        var json = JsonSerializer.SerializeToElement(avatar);
        if (!json.TryGetProperty("avatarId", out var id) || id.ValueKind != JsonValueKind.String || id.GetString() is not ("100003" or "100004"))
            return false;
        foreach (var field in new[] { "hair", "helmet", "immobile", "immobileUp", "immobileDown" })
        {
            if (json.TryGetProperty(field, out var value) && value.ValueKind == JsonValueKind.String &&
                value.GetString() is { Length: > 2 } text && !text.Contains("commandos", StringComparison.Ordinal))
                return false;
        }
        // Only exact bootstrap clothing qualifies; recoloured/custom costumes stay equipped.
        var female = id.GetString() == "100004";
        var expected = female
            ? new[] { "{{'femalecommandos_outerwear',10,1,2,132,122,185,51,46,52,0,0,0},}", "{{'femalecommandos_trousers',11,0,3,225,225,225,103,65,122,51,46,52},}", "{{'femalecommandos_glove',12,2,3,103,65,122,211,77,162,225,225,225},}", "{{'femalecommandos_shoes',13,3,2,55,59,96,221,221,221,0,0,0},}" }
            : new[] { "{{'malecommandos_outerwear',10,1,3,132,122,185,51,46,52,55,59,90},}", "{{'malecommandos_trousers',11,0,3,201,201,201,103,65,122,51,46,52},}", "{{'malecommandos_glove',12,2,3,103,65,122,211,77,162,51,46,52},}", "{{'malecommandos_shoes',13,3,2,55,59,96,245,244,249,0,0,0},}" };
        return new[] { "outerwear", "trousers", "glove", "shoes" }.Select((field, i) =>
            json.TryGetProperty(field, out var value) && value.GetString() == expected[i]).All(x => x);
    }
}
