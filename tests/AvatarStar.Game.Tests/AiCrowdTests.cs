using System.Numerics;
using System.Reflection;
using System.Text.Json;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;

internal static class AiCrowdTests
{
    internal static void Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        check(!AiSteering.CanMove(Vector3.Zero, new(2, 0, 0), [new(1, 0, 0)]), "swept movement cannot pass through an actor");
        check(AiSteering.CanMove(Vector3.Zero, new(0, 0, -.4f), [new(0, 0, .2f)]), "overlapping actors can separate");
        check(!AiSteering.CanMove(Vector3.Zero, new(.4f, 0, 0), [new(.2f, 0, 0)]), "overlap cannot be worsened");
        check(!AiSteering.CanMove(Vector3.Zero, new(.8f, 0, 0), [new(.2f, 0, 0)]), "overlap recovery cannot cross through another actor");
        check(AiSteering.CanMove(Vector3.Zero, new(2, 0, 0), [new(1, 3, 0)]), "another storey does not block movement");
        var fork = new AiNavigation([[0, 0, 0, 1, 2], [1, 0, 1, 0, 3], [1, 0, -1, 0, 3], [2, 0, 0, 1, 2]], []);
        var routes = Enumerable.Range(1, 32).Select(seed => string.Join(',', fork.Path(0, 3, seed))).Distinct().ToArray();
        check(routes.Length == 2, "random routing uses both equal-length lanes");
        check(fork.Path(0, 3, 0, [new(1, 0, 1)]).SequenceEqual(new[] { 0, 2, 3 }), "congestion selects unoccupied lane");
        check(AiSteering.Crowding(new(3, 0, 0), [Vector3.Zero]) > 0, "bots avoid nearby crowds before body contact");
        var grid = new List<float[]>();
        for (var z = 0; z < 17; z++) for (var x = 0; x < 17; x++)
        {
            var edges = new List<float> { x - 8, 0, z - 8 };
            if (x > 0) edges.Add(z * 17 + x - 1);
            if (x < 16) edges.Add(z * 17 + x + 1);
            if (z > 0) edges.Add((z - 1) * 17 + x);
            if (z < 16) edges.Add((z + 1) * 17 + x);
            grid.Add(edges.ToArray());
        }
        var openGround = new AiNavigation(grid.ToArray(), []);
        var reserved = new List<Vector3>();
        var routesToTarget = new HashSet<string>();
        for (var bot = 0; bot < 8; bot++)
        {
            var goal = AiSteering.SelectGoal(openGround, 0, openGround.Points[0], Vector3.Zero,
                6, bot * MathF.Tau / 8, bot + 1, reserved);
            routesToTarget.Add(string.Join(',', openGround.Path(0, goal, bot + 1, reserved)));
            reserved.Add(openGround.Points[goal]);
        }
        check(reserved.SelectMany((p, i) => reserved.Skip(i + 1).Select(q => AiSteering.PlanarDistance(p, q))).Min() >= 2.4f,
            "eight attackers choose separated firing positions around one target");
        check(routesToTarget.Count == 8 && reserved.Any(p => p.Z < -3) && reserved.Any(p => p.Z > 3),
            "independent flank routes reach both sides of the target");
        var cardParts = ShopItemDatabase.GetAllShopItems().Values.Where(c => c.Category == ShopItemDatabase.AvatarCardCategory)
            .Select(c => JsonSerializer.SerializeToElement(c.Avatar)).ToArray();
        var outfits = new HashSet<string>();
        foreach (var occupation in Enumerable.Range(0, 5)) foreach (var seed in Enumerable.Range(0, 10))
        {
            var player = AiPlayerFactory.Create(1500100000 + seed, occupation, config, new Random(seed));
            var avatar = JsonSerializer.SerializeToElement(player.Character.EquipAvatar);
            check(cardParts.Any(card => card.EnumerateObject().Where(p => p.Name != "avatarId").All(p =>
                avatar.TryGetProperty(p.Name, out var actual) && actual.GetString() ==
                (string.IsNullOrWhiteSpace(p.Value.GetString()) ? "{}" : p.Value.GetString()))), "AI wears a complete shop card, not mixed starter parts");
            check(player.Character.Occupation == occupation && player.GetEquippedAvatarItem() is not null, "shop appearance keeps selected career and equipped card");
            outfits.Add(string.Join("|", avatar.EnumerateObject()
                .Where(p => p.Name != "avatarId").OrderBy(p => p.Name)
                .Select(p => p.Name + "=" + p.Value.GetString())));
        }
        check(outfits.Count >= 5, "shop outfits vary across AI players");
        var manager = new PracticeRoomManager();
        var room = manager.CreateOrReplaceRoom(new(1, "host", "crowd", "LEVEL53", false, "", 400022, 4, 16, 3,
            true, false, 0, false, 0, 30, 0, 0, 0, 0));
        manager.ManageBots(room.RoomId, 1, 0, 0, 7, false, config, out _);
        manager.ManageBots(room.RoomId, 1, 1, 0, 8, false, config, out _);
        manager.TryStartGame(room.RoomId, out _, out _);
        Vector3 World(PracticeRoomManager.GamePosition p) => new(p.XRaw / 256f, p.YRaw / 256f, p.ZRaw / 256f);
        Dictionary<byte, Vector3> Positions() => manager.ListGamePlayers(room.RoomId).Where(p => p.LastPosition.HasValue).ToDictionary(p => p.Uid, p => World(p.LastPosition!.Value));
        var initial = Positions(); var previous = initial; var travel = initial.Keys.ToDictionary(uid => uid, _ => 0f);
        var nav = AiNavigation.ForLevel(room.LevelId)!;
        check(initial.Count == 15, "full room has fifteen bot runtimes");
        foreach (var p in manager.ListGamePlayers(room.RoomId).Where(p => p.LastPosition.HasValue))
        {
            var team = (byte)((room.Members.Single(m => m.CharacterId == p.CharacterId).SlotIndex - 1) / 8);
            manager.UpdateGamePlayerState(room.RoomId, p.Uid, team, 100000);
            manager.TrySetGamePlayerHealth(room.RoomId, p.Uid, 100000, out _);
        }
        var step = typeof(PracticeRoomManager).GetMethod("StepBotsNoLock", BindingFlags.NonPublic | BindingFlags.Instance)!;
        var start = Environment.TickCount64;
        var separated = true; var speedLimited = true; var collisionFree = true;
        var clientTime = initial.Keys.ToDictionary(uid => uid, _ => 0d);
        var timelineMatches = true;
        var groundedMovement = true;
        var sawWalking = false;
        for (var tick = 0; tick < 120; tick++)
        {
            var frame = step.Invoke(manager, new object[] { room, start + tick * 100 })!;
            var moves = (List<PracticeRoomManager.GameMovementDelta>)frame.GetType()
                .GetProperty("Moves", BindingFlags.Instance | BindingFlags.NonPublic)!.GetValue(frame)!;
            foreach (var move in moves)
            {
                // Native packet110 adds this byte / 255; replay the client's timeline.
                clientTime[move.Uid] += move.Tick / 255d;
                timelineMatches &= Math.Abs(clientTime[move.Uid] - (tick + 1) * .1) < .004;
                groundedMovement &= (move.Flags & 1) != 0 && (move.OptionalPayload[0] & 0x0F) == 2;
                sawWalking |= (move.OptionalPayload[0] & 0xF0) != 0;
            }
            var current = Positions();
            foreach (var (uid, point) in current)
            {
                var distance = Vector3.Distance(previous[uid], point); travel[uid] += distance;
                speedLimited &= distance <= .46f;
                collisionFree &= nav.Visible(previous[uid] + Vector3.UnitY, point + Vector3.UnitY);
                foreach (var other in current.Where(p => p.Key > uid && Math.Abs(p.Value.Y - point.Y) <= 1.4f))
                    separated &= AiSteering.PlanarDistance(point, other.Value) >= AiSteering.Clearance - .02f;
            }
            previous = current;
        }
        check(separated, "fifteen bots remain separated throughout pursuit");
        check(speedLimited && collisionFree, "avoidance obeys speed and map collision constraints");
        check(travel.Values.All(d => d > 2), "every bot makes progress instead of remaining in a spawn pile");
        check(timelineMatches, "client interpolation stays within four milliseconds of server movement");
        check(clientTime.Values.All(t => Math.Abs(t - 12) < .004), "twelve seconds of AI movement does not queue minutes of client animation");
        check(groundedMovement && sawWalking, "full-room pursuit drives ground locomotion instead of airborne animation");
        manager.RemoveRoom(room.RoomId);
    }
}
