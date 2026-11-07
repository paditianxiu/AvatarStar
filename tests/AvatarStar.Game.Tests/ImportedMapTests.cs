using System.Numerics;
using System.Text.Json;
using System.Reflection;
using AvatarStar.Server.Game;

internal static class ImportedMapTests
{
    internal static void Run(string root, Action<bool, string> check)
    {
        using var document = JsonDocument.Parse(File.ReadAllText(Path.Combine(root,
            "src/AvatarStar.Server.Game/Config/finalcombat_maps.json")));
        var maps = document.RootElement.GetProperty("maps").EnumerateArray().ToArray();
        check(maps.Length == 50, "all 50 source scenes registered");
        check(LobbyLevelCatalog.Levels.Select(m => m.Id).Distinct().Count() == LobbyLevelCatalog.Levels.Count,
            "lobby map IDs remain unique");
        check(!LobbyLevelCatalog.Levels.Any(m => m.Imported && m.Name == "LEVEL99"), "reserved map code preserved");
        var lobbyList = ((System.Collections.IEnumerable)typeof(GameClient)
            .GetMethod("GetConfiguredLobbyLevelsOrDefault", BindingFlags.Static | BindingFlags.NonPublic)!
            .Invoke(null, null)!).Cast<object>().ToArray();
        check(lobbyList.Length == LobbyLevelCatalog.Levels.Count, "packet 30 uses the complete expanded lobby list");
        var manager = new PracticeRoomManager();
        foreach (var map in maps)
        {
            var id = map.GetProperty("id").GetInt64();
            var code = map.GetProperty("code").GetString()!;
            check(LobbyLevelCatalog.ResolveLevelCode(id) == code && LobbyLevelCatalog.IsImported(id),
                $"{code}: lobby and battle map codes agree");
            check(LobbyLevelCatalog.ResolveMapShowName(id) == "id_fc_" + code.ToLowerInvariant(),
                $"{code}: room name uses registered Chinese text");
            check(lobbyList.Any(entry => (long)entry.GetType().GetProperty("Id")!.GetValue(entry)! == id &&
                (string)entry.GetType().GetProperty("Name")!.GetValue(entry)! == code), $"{code}: included in packet 30 list");
            var navigation = AiNavigation.ForLevel(id)!;
            check(navigation is not null && navigation.Points.Length >= 30, $"{code}: collision navigation loads");
            var red = navigation!.Spawn(0, 0);
            var blue = navigation.Spawn(1, 0);
            check(navigation.Path(red, blue).Count > 1, $"{code}: opposing spawns are reachable");
            var region = map.GetProperty("playableBounds").EnumerateArray().Select(v => v.GetSingle()).ToArray();
            var deadVolumes = map.GetProperty("deadVolumes").EnumerateArray()
                .Select(v => v.EnumerateArray().Select(n => n.GetSingle()).ToArray()).ToArray();
            foreach (byte team in new byte[] { 0, 1 })
            {
                var points = Enumerable.Range(0, 8).Select(i => navigation.Points[navigation.Spawn(team, i)]).ToArray();
                check(points.Distinct().Count() == 8, $"{code}: team {team} has eight separate spawn positions");
                foreach (var point in points)
                {
                    check(point.X >= region[0] && point.Z >= region[1] && point.X <= region[2] && point.Z <= region[3],
                        $"{code}: spawn stays inside playable map");
                    check(!deadVolumes.Any(v => point.X >= v[0] && point.X <= v[3] && point.Y + .16f >= v[1] &&
                        point.Y + .16f <= v[4] && point.Z >= v[2] && point.Z <= v[5]), $"{code}: spawn avoids death volumes");
                }
            }
            var room = manager.CreateOrReplaceRoom(new(987654, "import-test", "import-test", code, false, "", id, 4, 16, 3,
                true, false, 0, false, 0, 30, 0, 0, 0, 0));
            var spawn = manager.GetAiRoomSpawn(room.RoomId, 987654);
            check(spawn is not null, $"{code}: human player gets map spawn without any bots");
            var position = new Vector3(spawn!.Value.XRaw / 256f, spawn.Value.YRaw / 256f, spawn.Value.ZRaw / 256f);
            check(Vector3.Distance(position, navigation.Points[red]) < .01f, $"{code}: human spawn uses collision floor");
        }
    }
}
