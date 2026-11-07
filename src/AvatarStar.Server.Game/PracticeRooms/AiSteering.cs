using System.Numerics;

namespace AvatarStar.Server.Game;

internal static class AiSteering
{
    internal const float Clearance = 1.05f;

    internal static float PlanarDistance(Vector3 a, Vector3 b) => Vector2.Distance(new(a.X, a.Z), new(b.X, b.Z));

    internal static float Noise(int seed, int x, int z)
    {
        var hash = unchecked((uint)seed ^ (uint)x * 0x9e3779b9u ^ (uint)z * 0x85ebca6bu);
        hash ^= hash >> 16; hash *= 0x7feb352du; hash ^= hash >> 15;
        return (hash & 0xffff) / 65535f;
    }

    internal static float Crowding(Vector3 point, IReadOnlyList<Vector3>? occupied)
    {
        if (occupied is null) return 0;
        var penalty = 0f;
        foreach (var other in occupied)
        {
            if (Math.Abs(point.Y - other.Y) > 1.4f) continue;
            var distance = PlanarDistance(point, other);
            if (distance < 3) penalty += (3 - distance) * (3 - distance);
        }
        return penalty;
    }

    // Sweep the complete step, preventing overlap and passing through another actor.
    // Already-overlapping actors may move apart, including a human entering the bot's space.
    internal static bool CanMove(Vector3 from, Vector3 to, IReadOnlyList<Vector3> occupied)
    {
        var a = new Vector2(from.X, from.Z); var b = new Vector2(to.X, to.Z); var delta = b - a;
        foreach (var other in occupied)
        {
            if (Math.Abs(other.Y - (from.Y + to.Y) / 2) > 1.4f) continue;
            var point = new Vector2(other.X, other.Z);
            var start = Vector2.Distance(a, point); var end = Vector2.Distance(b, point);
            if (start < Clearance && end > start + .001f) continue;
            var t = delta.LengthSquared() < .000001f ? 0 : Math.Clamp(Vector2.Dot(point - a, delta) / delta.LengthSquared(), 0, 1);
            if (Vector2.DistanceSquared(a + delta * t, point) < Clearance * Clearance) return false;
        }
        return true;
    }

    internal static int SelectGoal(AiNavigation nav, int node, Vector3 position, Vector3? target,
        float desiredRange, float flankAngle, int seed, IReadOnlyList<Vector3> occupied)
    {
        var center = target ?? position;
        var candidates = nav.Nearby(center, target.HasValue ? desiredRange + 7 : 16, node).ToArray();
        if (candidates.Length == 0) return nav.Nearest(center, node);
        var preferred = target.HasValue
            ? center + new Vector3(MathF.Cos(flankAngle), 0, MathF.Sin(flankAngle)) * desiredRange
            : position + new Vector3(MathF.Cos(flankAngle), 0, MathF.Sin(flankAngle)) * 10;
        var ranked = candidates.Select(n =>
        {
            var p = nav.Points[n];
            var rangeCost = target.HasValue ? Math.Abs(PlanarDistance(p, center) - desiredRange) * 2 : 0;
            var score = rangeCost + PlanarDistance(p, preferred) * .5f + PlanarDistance(p, position) * .08f +
                Crowding(p, occupied) * 5 + Noise(seed, n, 0) * 1.5f;
            return (Node: n, Score: score);
        }).OrderBy(p => p.Score).Take(16).ToArray();
        if (target.HasValue)
            foreach (var candidate in ranked)
                if (nav.Visible(nav.Points[candidate.Node] + Vector3.UnitY * 1.3f, center + Vector3.UnitY * 1.2f)) return candidate.Node;
        return ranked[0].Node;
    }
}
