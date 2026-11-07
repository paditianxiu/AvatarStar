using System.Collections.Concurrent;
using System.IO.Compression;
using System.Numerics;
using System.Text.Json;

namespace AvatarStar.Server.Game;

/// <summary>Walkable edges and visibility come from the client's cooked collision meshes.</summary>
internal sealed class AiNavigation
{
    private static readonly ConcurrentDictionary<string, Lazy<AiNavigation?>> Cache = new();
    internal Vector3[] Points { get; }
    internal int[][] Edges { get; }
    private readonly Dictionary<(int, int), List<float[]>> _triangles = new();
    private readonly int[] _components;
    private readonly int _mainComponent;
    private readonly Dictionary<(int, int), List<int>> _pointCells = new();
    private readonly Dictionary<byte, int[]> _spawns = new();

    internal AiNavigation(float[][] nodes, float[][] triangles)
    {
        Points = nodes.Select(n => new Vector3(n[0], n[1], n[2])).ToArray();
        Edges = nodes.Select(n => n.Skip(3).Select(v => checked((int)v)).ToArray()).ToArray();
        if (Points.Length == 0 || Edges.Any(e => e.Any(i => i < 0 || i >= Points.Length)))
            throw new InvalidDataException("Invalid navigation graph");
        _components = Enumerable.Repeat(-1, Points.Length).ToArray();
        for (var i = 0; i < Points.Length; i++)
        {
            if (_components[i] >= 0) continue;
            var queue = new Queue<int>(); queue.Enqueue(i); _components[i] = i;
            while (queue.TryDequeue(out var n)) foreach (var next in Edges[n])
                if (_components[next] < 0) { _components[next] = i; queue.Enqueue(next); }
        }
        _mainComponent = _components.GroupBy(c => c).MaxBy(g => g.Count())!.Key;
        for (var i = 0; i < Points.Length; i++)
        {
            var key = ((int)MathF.Floor(Points[i].X / 4), (int)MathF.Floor(Points[i].Z / 4));
            if (!_pointCells.TryGetValue(key, out var cell)) _pointCells[key] = cell = [];
            cell.Add(i);
        }
        foreach (var t in triangles)
        {
            if (t.Length != 9 || t.Any(v => !float.IsFinite(v))) throw new InvalidDataException("Invalid collision mesh");
            var minX = Math.Max(-128, (int)MathF.Floor(Math.Min(t[0], Math.Min(t[3], t[6])) / 2));
            var maxX = Math.Min(128, (int)MathF.Floor(Math.Max(t[0], Math.Max(t[3], t[6])) / 2));
            var minZ = Math.Max(-128, (int)MathF.Floor(Math.Min(t[2], Math.Min(t[5], t[8])) / 2));
            var maxZ = Math.Min(128, (int)MathF.Floor(Math.Max(t[2], Math.Max(t[5], t[8])) / 2));
            for (var x = minX; x <= maxX; x++) for (var z = minZ; z <= maxZ; z++)
            {
                if (!_triangles.TryGetValue((x, z), out var bucket)) _triangles[(x, z)] = bucket = [];
                bucket.Add(t);
            }
        }
    }

    internal static AiNavigation? ForLevel(long levelId)
    {
        var code = LobbyLevelCatalog.ResolveLevelCode(levelId) ?? $"LEVEL{levelId}";
        if (!System.Text.RegularExpressions.Regex.IsMatch(code, @"^LEVEL\d+$")) return null;
        return Cache.GetOrAdd(code, name => new Lazy<AiNavigation?>(() =>
        {
            var relative = System.IO.Path.Combine("Config", "AiNavigation", name + ".json.gz");
            var file = new[] { System.IO.Path.Combine(AppContext.BaseDirectory, relative), System.IO.Path.Combine("src", "AvatarStar.Server.Game", relative) }.FirstOrDefault(File.Exists);
            if (file is null) return null;
            using var input = File.OpenRead(file);
            using var zip = new GZipStream(input, CompressionMode.Decompress);
            var data = JsonSerializer.Deserialize<NavigationFile>(zip, new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            if (data?.Version != 1) throw new InvalidDataException("Unsupported navigation version");
            return new AiNavigation(data.Nodes, data.Triangles);
        })).Value;
    }

    internal int Nearest(Vector3 point, int connectedTo = -1)
    {
        var best = -1; var distance = float.PositiveInfinity;
        for (var i = 0; i < Points.Length; i++)
        {
            if (connectedTo >= 0 && _components[i] != _components[connectedTo]) continue;
            var d = Vector3.DistanceSquared(point, Points[i]);
            if (d < distance) { best = i; distance = d; }
        }
        return best;
    }

    internal int Spawn(byte team, int ordinal)
    {
        lock (_spawns)
        {
            if (!_spawns.TryGetValue(team, out var spawn))
            {
                var anchor = Nearest(new Vector3(-22, 2, 15), _mainComponent);
                var candidates = Enumerable.Range(0, Points.Length).Where(i => _components[i] == _mainComponent).ToArray();
                if (team != 0) anchor = candidates.MaxBy(i => Vector3.DistanceSquared(Points[i], Points[anchor]));
                var selected = new List<int>();
                foreach (var n in candidates.OrderBy(i => Vector3.DistanceSquared(Points[i], Points[anchor])))
                {
                    if (selected.All(i => AiSteering.PlanarDistance(Points[n], Points[i]) >= 2.4f)) selected.Add(n);
                    if (selected.Count == 8) break;
                }
                _spawns[team] = spawn = selected.ToArray();
            }
            return spawn[Math.Abs(ordinal) % spawn.Length];
        }
    }

    internal IEnumerable<int> Nearby(Vector3 center, float radius, int connectedTo)
    {
        for (var x = (int)MathF.Floor((center.X - radius) / 4); x <= (int)MathF.Floor((center.X + radius) / 4); x++)
        for (var z = (int)MathF.Floor((center.Z - radius) / 4); z <= (int)MathF.Floor((center.Z + radius) / 4); z++)
        {
            if (!_pointCells.TryGetValue((x, z), out var cell)) continue;
            foreach (var n in cell)
                if (_components[n] == _components[connectedTo] && Vector3.DistanceSquared(center, Points[n]) <= radius * radius) yield return n;
        }
    }

    internal List<int> Path(int start, int goal, int routeSeed = 0, IReadOnlyList<Vector3>? occupied = null)
    {
        if (start < 0 || goal < 0 || _components[start] != _components[goal]) return [];
        var open = new PriorityQueue<int, float>();
        var costs = new Dictionary<int, float> { [start] = 0 };
        var parents = new Dictionary<int, int>(); var closed = new HashSet<int>();
        var penalties = new Dictionary<int, float>();
        open.Enqueue(start, 0);
        while (open.TryDequeue(out var n, out _))
        {
            if (!closed.Add(n)) continue;
            if (n == goal)
            {
                var result = new List<int> { n };
                while (parents.TryGetValue(n, out n)) result.Add(n);
                result.Reverse(); return result;
            }
            foreach (var next in Edges[n])
            {
                if (!penalties.TryGetValue(next, out var penalty))
                {
                    // Stable per route and area, so agents choose different lanes without jittering.
                    penalty = routeSeed == 0 ? 0 : AiSteering.Noise(routeSeed,
                        (int)MathF.Floor(Points[next].X / 4), (int)MathF.Floor(Points[next].Z / 4)) * 1.35f;
                    penalty += AiSteering.Crowding(Points[next], occupied);
                    penalties[next] = penalty;
                }
                var cost = costs[n] + Vector3.Distance(Points[n], Points[next]) * (1 + penalty);
                if (costs.TryGetValue(next, out var old) && old <= cost) continue;
                costs[next] = cost; parents[next] = n;
                open.Enqueue(next, cost + Vector3.Distance(Points[next], Points[goal]));
            }
        }
        return [];
    }

    internal bool Visible(Vector3 from, Vector3 to)
    {
        var delta = to - from; var seen = new HashSet<float[]>();
        for (var x = (int)MathF.Floor(Math.Min(from.X, to.X) / 2); x <= (int)MathF.Floor(Math.Max(from.X, to.X) / 2); x++)
        for (var z = (int)MathF.Floor(Math.Min(from.Z, to.Z) / 2); z <= (int)MathF.Floor(Math.Max(from.Z, to.Z) / 2); z++)
        {
            if (!_triangles.TryGetValue((x, z), out var bucket)) continue;
            foreach (var t in bucket)
            {
                if (!seen.Add(t)) continue;
                var a = new Vector3(t[0], t[1], t[2]);
                var e1 = new Vector3(t[3], t[4], t[5]) - a; var e2 = new Vector3(t[6], t[7], t[8]) - a;
                var p = Vector3.Cross(delta, e2); var det = Vector3.Dot(e1, p);
                if (Math.Abs(det) < 0.000001f) continue;
                var s = from - a; var u = Vector3.Dot(s, p) / det;
                if (u < 0 || u > 1) continue;
                var q = Vector3.Cross(s, e1); var v = Vector3.Dot(delta, q) / det;
                if (v < 0 || u + v > 1) continue;
                var distance = Vector3.Dot(e2, q) / det;
                if (distance > .001f && distance < .999f) return false;
            }
        }
        return true;
    }

    private sealed record NavigationFile(int Version, float[][] Nodes, float[][] Triangles);
}
