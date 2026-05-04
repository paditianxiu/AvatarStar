using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using AvatarStar.Server.Persistence;

namespace AvatarStar.Server.Game.Resources;

/// <summary>
/// Loads a game_text (i18n) mapping: id_* -> localized UTF-8 string.
/// Intended for server-side tooling (GM HTTP / admin UI), not required by the game client.
/// </summary>
public static class GameTextDatabase
{
    private static readonly object Gate = new();
    private static Dictionary<string, string> _map = new(StringComparer.Ordinal);
    private static string? _activePath;
    private static bool _loaded;

    public static string? GetActivePath() => _activePath;

    public static bool Reload()
    {
        lock (Gate)
        {
            _loaded = true;
            _activePath = null;
            _map = new(StringComparer.Ordinal);
            return TryLoadLocked();
        }
    }

    public static string Translate(string? key)
    {
        if (string.IsNullOrWhiteSpace(key)) return string.Empty;
        EnsureLoaded();
        lock (Gate)
        {
            return _map.TryGetValue(key, out var v) ? v : key;
        }
    }

    public static bool TryTranslate(string? key, out string value)
    {
        value = string.Empty;
        if (string.IsNullOrWhiteSpace(key)) return false;
        EnsureLoaded();
        lock (Gate)
        {
            if (_map.TryGetValue(key, out var v))
            {
                value = v;
                return true;
            }
        }
        return false;
    }

    public static string TranslateKnownOrEmpty(string? key)
    {
        return TryTranslate(key, out var value) ? value : string.Empty;
    }

    public static string TranslateFirstKnown(params string?[] candidates)
    {
        foreach (var candidate in candidates)
        {
            if (TryTranslate(candidate, out var value))
            {
                return value;
            }
        }

        return string.Empty;
    }

    private static void EnsureLoaded()
    {
        lock (Gate)
        {
            if (_loaded) return;
            _loaded = true;
            _ = TryLoadLocked();
        }
    }

    private static bool TryLoadLocked()
    {
        try
        {
            if (TryLoadFromDatabaseLocked())
            {
                return true;
            }

            var overridePath =
                Environment.GetEnvironmentVariable("AVATARSTAR_GAME_TEXT_JSON")
                ?? Environment.GetEnvironmentVariable("AS_GAME_TEXT_JSON")
                ?? Environment.GetEnvironmentVariable("AVATARSTAR_GAME_TEXT_LUA")
                ?? Environment.GetEnvironmentVariable("AS_GAME_TEXT_LUA")
                ?? string.Empty;

            var candidates = new List<string>();
            if (!string.IsNullOrWhiteSpace(overridePath))
            {
                candidates.Add(overridePath);
            }

            candidates.Add(Path.Combine(AppContext.BaseDirectory, "Resources", "game_text_id_to_text.json"));
            candidates.Add(Path.Combine(AppContext.BaseDirectory, "game_text_id_to_text.json"));
            candidates.Add(Path.Combine(AppContext.BaseDirectory, "Resources", "game_text_extracted.lua"));
            candidates.Add(Path.Combine(AppContext.BaseDirectory, "game_text_extracted.lua"));
            candidates.Add(Path.Combine(Directory.GetCurrentDirectory(), "Config", "game_text_id_to_text.json"));
            candidates.Add(Path.Combine(Directory.GetCurrentDirectory(), "Config", "game_text_extracted.lua"));
            candidates.Add(Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Resources", "game_text_id_to_text.json"));
            candidates.Add(Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Resources", "game_text_extracted.lua"));

            // Common local unpack path (optional; only loaded if present).
            candidates.Add(Path.Combine("D:\\Avatarstar\\UnPde\\AvatarStar_zh_cn\\scripts\\game_text_extracted.lua"));

            var path = candidates.FirstOrDefault(File.Exists);
            if (path is null) return false;

            Dictionary<string, string>? map = null;
            if (Path.GetExtension(path).Equals(".lua", StringComparison.OrdinalIgnoreCase))
            {
                map = TryParseLuaGameTextTable(File.ReadAllText(path, Encoding.UTF8));
            }
            else
            {
                var json = File.ReadAllText(path, Encoding.UTF8);
                map = JsonSerializer.Deserialize<Dictionary<string, string>>(json, new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = false
                });
            }

            if (map is null || map.Count == 0) return false;

            _map = new Dictionary<string, string>(map, StringComparer.Ordinal);
            _activePath = path;
            return true;
        }
        catch
        {
            _map = new(StringComparer.Ordinal);
            _activePath = null;
            return false;
        }
    }

    private static bool TryLoadFromDatabaseLocked()
    {
        try
        {
            using var db = new AvatarStarDbContext();
            var rows = db.GameTexts.ToArray();
            if (rows.Length == 0)
            {
                return false;
            }

            _map = rows.ToDictionary(x => x.TextId, x => x.Text, StringComparer.Ordinal);
            _activePath = "database:game_texts";
            return true;
        }
        catch
        {
            return false;
        }
    }

    private static Dictionary<string, string> TryParseLuaGameTextTable(string lua)
    {
        // Expected format (from tools/extract_game_text.py):
        //   return { ["id_xxx"] = "text ...", ... }
        var map = new Dictionary<string, string>(StringComparer.Ordinal);
        if (string.IsNullOrWhiteSpace(lua)) return map;

        var len = lua.Length;
        var i = 0;
        while (i < len)
        {
            var keyStart = lua.IndexOf("[\"", i, StringComparison.Ordinal);
            if (keyStart < 0) break;

            var keyEnd = lua.IndexOf("\"]", keyStart + 2, StringComparison.Ordinal);
            if (keyEnd < 0) break;

            var key = lua.Substring(keyStart + 2, keyEnd - (keyStart + 2));
            i = keyEnd + 2;

            // seek '='
            while (i < len && char.IsWhiteSpace(lua[i])) i++;
            if (i >= len || lua[i] != '=') continue;
            i++;
            while (i < len && char.IsWhiteSpace(lua[i])) i++;
            if (i >= len || lua[i] != '"') continue;
            i++; // skip opening quote

            var sb = new StringBuilder();
            while (i < len)
            {
                var ch = lua[i++];
                if (ch == '"')
                {
                    break; // end string
                }
                if (ch == '\\' && i < len)
                {
                    var n = lua[i++];
                    sb.Append(n switch
                    {
                        'n' => '\n',
                        'r' => '\r',
                        't' => '\t',
                        '"' => '"',
                        '\\' => '\\',
                        _ => n
                    });
                    continue;
                }
                sb.Append(ch);
            }

            if (!map.ContainsKey(key))
            {
                map[key] = sb.ToString();
            }
        }

        return map;
    }
}
