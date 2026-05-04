using AvatarStar.Server.Persistence;

namespace AvatarStar.Server.Game.Config;

internal static class SysAvatarPayloadLoader
{
    public static int Load(SysAvatarPayloadConfig config, string configDirectory)
    {
        var dbLoaded = LoadFromDatabase(config);
        if (dbLoaded > 0)
        {
            return dbLoaded;
        }

        if (string.IsNullOrWhiteSpace(configDirectory))
        {
            return 0;
        }

        var payloadDirectory = Path.Combine(configDirectory, "SysAvatarPayloads");
        if (!Directory.Exists(payloadDirectory))
        {
            return 0;
        }

        var loaded = 0;
        foreach (var file in Directory.EnumerateFiles(payloadDirectory, "*.lua").OrderBy(x => x))
        {
            if (!TryReadJobId(file, out var jobId))
            {
                continue;
            }

            var payload = File.ReadAllText(file).Trim();
            if (string.IsNullOrWhiteSpace(payload) ||
                !payload.Contains("sysAvatar", StringComparison.Ordinal) ||
                !payload.Contains("weapons", StringComparison.Ordinal))
            {
                continue;
            }

            config.SysAvatarListPayloads[jobId] = payload;
            loaded++;
        }

        if (loaded > 0)
        {
            config.OfficialCatalog = BuildOfficialCatalog(config.SysAvatarListPayloads);
        }

        return loaded;
    }

    private static int LoadFromDatabase(SysAvatarPayloadConfig config)
    {
        try
        {
            using var db = new AvatarStarDbContext();
            var payloads = db.ConfigDocuments
                .Where(x => x.Category == "sysavatar_payload" || x.Key.Contains("SysAvatarPayloads"))
                .OrderBy(x => x.Key)
                .ToArray();
            var loaded = 0;
            foreach (var payloadDoc in payloads)
            {
                if (!TryReadJobId(payloadDoc.Key, out var jobId))
                {
                    continue;
                }

                var payload = payloadDoc.JsonContent.Trim();
                if (string.IsNullOrWhiteSpace(payload) ||
                    !payload.Contains("sysAvatar", StringComparison.Ordinal) ||
                    !payload.Contains("weapons", StringComparison.Ordinal))
                {
                    continue;
                }

                config.SysAvatarListPayloads[jobId] = payload;
                loaded++;
            }

            if (loaded > 0)
            {
                config.OfficialCatalog = BuildOfficialCatalog(config.SysAvatarListPayloads);
            }

            return loaded;
        }
        catch
        {
            return 0;
        }
    }

    private static bool TryReadJobId(string file, out int jobId)
    {
        jobId = 0;
        var stem = Path.GetFileNameWithoutExtension(file);
        var length = 0;
        while (length < stem.Length && char.IsDigit(stem[length]))
        {
            length++;
        }

        return length > 0 && int.TryParse(stem[..length], out jobId);
    }

    private static OfficialAvatarCatalog BuildOfficialCatalog(IReadOnlyDictionary<int, string> payloads)
    {
        var catalog = new OfficialAvatarCatalog
        {
            Version = "payload-overrides",
            Description = "Server catalog derived from Config/SysAvatarPayloads.",
            Source = "sysavatar_list payload files"
        };

        foreach (var (jobId, payload) in payloads.OrderBy(x => x.Key))
        {
            if (!TryReadProfession(payload, out var profession))
            {
                profession = new OfficialProfession
                {
                    Occupation = Math.Clamp(jobId - 1, 0, 3),
                    DisplayName = jobId switch
                    {
                        1 => "UI_profession_Guardian",
                        2 => "UI_profession_Gunner",
                        3 => "UI_profession_Assassin",
                        4 => "UI_profession_Biochemical",
                        _ => "UI_profession_Guardian"
                    },
                    Description = jobId switch
                    {
                        1 => "UI_profession_Guardian_desc",
                        2 => "UI_profession_Gunner_desc",
                        3 => "UI_profession_Assassin_desc",
                        4 => "UI_profession_Biochemical_desc",
                        _ => "UI_profession_Guardian_desc"
                    }
                };
            }

            catalog.Professions.Add(profession);
        }

        return catalog;
    }

    private static bool TryReadProfession(string payload, out OfficialProfession profession)
    {
        var occupation = MatchInt(payload, @"(?m)^\s*occupation\s*=\s*(\d+)");
        if (occupation is null)
        {
            profession = new OfficialProfession { Occupation = 0 };
            return false;
        }

        var avatars = System.Text.RegularExpressions.Regex.Matches(payload, @"avatarId\s*=\s*""([^""]+)""")
            .Select(x => x.Groups[1].Value)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Distinct()
            .Take(2)
            .ToArray();

        profession = new OfficialProfession
        {
            Occupation = occupation.Value,
            DisplayName = MatchText(payload, @"(?m)^\s*displayName\s*=\s*""([^""]*)"""),
            Description = MatchText(payload, @"(?m)^\s*description\s*=\s*""([^""]*)"""),
            BaseStats = new OfficialBaseStats
            {
                Life = MatchInt(payload, @"(?m)^\s*life\s*=\s*(\d+)") ?? 0,
                Recovery = MatchFloat(payload, @"(?m)^\s*recovery\s*=\s*([0-9.]+)") ?? 0,
                Armor = MatchFloat(payload, @"(?m)^\s*armor\s*=\s*([0-9.]+)") ?? 0
            },
            Presets = new OfficialPresets
            {
                Male = avatars.Length > 0 ? new OfficialPreset { AvatarId = avatars[0] } : null,
                Female = avatars.Length > 1 ? new OfficialPreset { AvatarId = avatars[1] } : null
            }
        };

        foreach (System.Text.RegularExpressions.Match match in System.Text.RegularExpressions.Regex.Matches(
            payload,
            @"\{\s*resource\s*=\s*""(?<resource>[^""]*)""\s*,\s*subType\s*=\s*""(?<subType>[^""]*)""\s*,\s*displayName\s*=\s*""(?<displayName>[^""]*)""\s*,\s*description\s*=\s*""(?<description>[^""]*)""\s*,\s*\}",
            System.Text.RegularExpressions.RegexOptions.Singleline))
        {
            profession.Weapons.Add(new OfficialWeapon
            {
                Resource = match.Groups["resource"].Value,
                SubType = match.Groups["subType"].Value,
                DisplayName = match.Groups["displayName"].Value,
                Description = match.Groups["description"].Value
            });
        }

        return true;
    }

    private static string? MatchText(string text, string pattern)
    {
        var match = System.Text.RegularExpressions.Regex.Match(text, pattern);
        return match.Success ? match.Groups[1].Value : null;
    }

    private static int? MatchInt(string text, string pattern)
    {
        var value = MatchText(text, pattern);
        return int.TryParse(value, out var parsed) ? parsed : null;
    }

    private static float? MatchFloat(string text, string pattern)
    {
        var value = MatchText(text, pattern);
        return float.TryParse(value, System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : null;
    }
}
