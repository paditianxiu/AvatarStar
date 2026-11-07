using System.Numerics;
using AvatarStar.Server.Game.Config;
using Serilog;

namespace AvatarStar.Server.Game;

internal sealed partial class PracticeRoomManager
{
    private const int BotStepMilliseconds = 100;
    private readonly Dictionary<int, List<RoomBot>> _botsByRoom = new();
    private readonly Dictionary<long, PlayerStore.PlayerState> _botPlayers = new();
    private readonly Dictionary<int, CancellationTokenSource> _botLoops = new();
    private readonly HashSet<PracticeRoomChannelProtocol> _botReadyChannels = [];
    private int _nextBotId = 1_500_000_000;

    // StateLobby.GetSelfRoomInfo().RoomUid contains the channel's RoomId; the lobby
    // browser uses the packed token/id value. Both are valid client identifiers.
    internal bool TryGetAiRoom(int clientRoomUid, out PracticeRoomSession room)
    {
        lock (_lock)
            return TryGetByRoomUid(clientRoomUid, out room!) || _roomsById.TryGetValue(clientRoomUid, out room!);
    }

    internal PlayerStore.PlayerState? GetBotPlayer(long characterId)
    {
        lock (_lock) return _botPlayers.GetValueOrDefault(characterId);
    }

    internal GamePosition? GetAiRoomSpawn(int roomId, long characterId)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out var room)) return null;
            if ((!_botsByRoom.TryGetValue(roomId, out var bots) || bots.Count == 0) &&
                !LobbyLevelCatalog.IsImported(room.LevelId)) return null;
            var member = room.Members.FirstOrDefault(m => m.CharacterId == characterId);
            var nav = AiNavigation.ForLevel(room.LevelId);
            if (member is null || nav is null) return null;
            var team = (byte)((member.SlotIndex - 1) / 8);
            return BotPosition(nav.Points[nav.Spawn(team, (member.SlotIndex - 1) % 8)], team == 0 ? 0 : MathF.PI);
        }
    }

    internal bool ManageBots(int roomUid, long actorId, int team, int occupation, int count, bool remove,
        SysAvatarPayloadConfig config, out string message)
    {
        lock (_lock)
        {
            message = "参数无效";
            if (team is < 0 or > 1 || occupation is < 0 or > 4 || count is < 1 or > 8) return false;
            if (!TryGetAiRoom(roomUid, out var room)) { message = "房间已关闭"; return false; }
            if (actorId != room.HostCharacterId) { message = "只有房主可以管理 AI 玩家"; return false; }
            if (room.RoomState != 1) { message = "请在开始比赛前管理 AI 玩家"; return false; }
            if (room.GameType == LobbyLevelCatalog.BossGameType) { message = "远征模式暂不支持房间 AI"; return false; }
            _botsByRoom.TryGetValue(room.RoomId, out var bots);
            if (remove)
            {
                var removed = 0;
                foreach (var bot in (bots ?? []).ToArray())
                {
                    var member = room.Members.FirstOrDefault(m => m.CharacterId == bot.Player.Character.Id);
                    if (member is null || (member.SlotIndex - 1) / 8 != team) continue;
                    room.RemoveMember(member.CharacterId); bots!.Remove(bot); _botPlayers.Remove(member.CharacterId);
                    if (_gamePlayersByRoomId.TryGetValue(room.RoomId, out var players)) players.Remove(bot.Uid);
                    if (_gameMovementByRoomId.TryGetValue(room.RoomId, out var movement)) movement.Remove(bot.Uid);
                    removed++;
                }
                room.RefreshCurrentClientNum(); message = $"已移除 {removed} 名 AI 玩家"; return true;
            }
            if (AiNavigation.ForLevel(room.LevelId) is null)
            { message = "此地图缺少可用导航，请选择地图 50、51、52 或 53"; return false; }
            var slots = Enumerable.Range(team * 8 + 1, 8).Select(i => (byte)i)
                .Where(i => room.Members.All(m => m.SlotIndex != i)).Take(count).ToArray();
            if (slots.Length != count || room.Members.Count + count > (room.MaxClientNum == 0 ? 16 : room.MaxClientNum))
            { message = "队伍位置或房间人数不足，请减少数量"; return false; }
            if (!AddBotsNoLock(room, slots.Select(slot => (slot, occupation)).ToArray(), config, out message)) return false;
            message = $"已向{(team == 0 ? "红" : "蓝")}队添加 {count} 名 AI 玩家"; return true;
        }
    }

    internal bool FillRoomWithBots(int roomUid, long actorId, SysAvatarPayloadConfig config, out string message)
    {
        lock (_lock)
        {
            if (!TryGetAiRoom(roomUid, out var room)) { message = "房间已关闭"; return false; }
            if (actorId != room.HostCharacterId) { message = "只有房主可以管理 AI 玩家"; return false; }
            if (room.RoomState != 1) { message = "请在开始比赛前管理 AI 玩家"; return false; }
            if (room.GameType == LobbyLevelCatalog.BossGameType) { message = "远征模式暂不支持房间 AI"; return false; }
            if (AiNavigation.ForLevel(room.LevelId) is null)
            { message = "此地图缺少可用导航，请选择地图 50、51、52 或 53"; return false; }
            var occupied = room.Members.Select(m => m.SlotIndex).ToHashSet();
            var free = new[] { new Queue<byte>(), new Queue<byte>() };
            for (byte slot = 1; slot <= 16; slot++)
                if (!occupied.Contains(slot)) free[(slot - 1) / 8].Enqueue(slot);
            var remaining = Math.Max(0, (room.MaxClientNum == 0 ? 16 : room.MaxClientNum) - room.Members.Count);
            var placements = new List<(byte Slot, int Occupation)>();
            while (remaining-- > 0 && (free[0].Count > 0 || free[1].Count > 0))
            {
                // Fill the smaller team first; ties vary while every existing member stays put.
                var team = free[0].Count == free[1].Count ? Random.Shared.Next(2) : free[0].Count > free[1].Count ? 0 : 1;
                placements.Add((free[team].Dequeue(), Random.Shared.Next(5)));
            }
            if (placements.Count == 0) { message = "房间已满，无需添加 AI"; return true; }
            if (!AddBotsNoLock(room, placements, config, out message)) return false;
            var red = placements.Count(p => p.Slot <= 8);
            message = $"已随机填满：红队新增 {red} 名，蓝队新增 {placements.Count - red} 名 AI";
            return true;
        }
    }

    private bool AddBotsNoLock(PracticeRoomSession room, IReadOnlyList<(byte Slot, int Occupation)> placements,
        SysAvatarPayloadConfig config, out string message)
    {
        // Prepare every model/loadout before adding any member, so failed fills remain atomic.
        var additions = new List<(byte Slot, RoomBot Bot)>();
        try
        {
            foreach (var placement in placements)
                additions.Add((placement.Slot, new RoomBot(AiPlayerFactory.Create(_nextBotId++, placement.Occupation, config, Random.Shared))));
        }
        catch (InvalidOperationException ex) { message = ex.Message; return false; }
        if (!_botsByRoom.TryGetValue(room.RoomId, out var bots)) _botsByRoom[room.RoomId] = bots = [];
        foreach (var (slot, bot) in additions)
        {
            var character = bot.Player.Character;
            if (!room.TryUpsertMember(new(character.Id, character.Name, character.Level, character.Occupation, 0, 0, 0), out var member))
                throw new InvalidOperationException("Prevalidated bot capacity changed");
            member.SlotIndex = slot; member.Ready = true;
            bots.Add(bot); _botPlayers.Add(character.Id, bot.Player);
        }
        room.RefreshCurrentClientNum(); message = string.Empty; return true;
    }

    private bool PrepareBotsNoLock(PracticeRoomSession room)
    {
        if (!_botsByRoom.TryGetValue(room.RoomId, out var bots) || bots.Count == 0) return true;
        var nav = AiNavigation.ForLevel(room.LevelId);
        if (nav is null || room.GameType == LobbyLevelCatalog.BossGameType) return false;
        StopBotsNoLock(room.RoomId);
        if (_gameChannelsByRoomId.TryGetValue(room.RoomId, out var currentChannels))
            foreach (var channel in currentChannels.Keys) _botReadyChannels.Remove(channel);
        if (!_gamePlayersByRoomId.TryGetValue(room.RoomId, out var players)) _gamePlayersByRoomId[room.RoomId] = players = [];
        foreach (var bot in bots) if (bot.Uid != 0) players.Remove(bot.Uid);
        var reservedSpawns = room.Members.Where(m => !_botPlayers.ContainsKey(m.CharacterId) && m.SlotIndex <= 16)
            .Select(m => nav.Points[nav.Spawn((byte)((m.SlotIndex - 1) / 8), (m.SlotIndex - 1) % 8)]).ToList();
        byte uid = 128;
        foreach (var bot in bots)
        {
            while (players.ContainsKey(uid)) uid++;
            bot.Uid = uid++;
            var member = room.Members.Single(m => m.CharacterId == bot.Player.Character.Id);
            var team = (byte)((member.SlotIndex - 1) / 8);
            var runtime = new GamePlayerRuntime(bot.Uid, member.CharacterId, member.CharacterName)
            { TeamId = team, MaxHealth = bot.Player.Character.MaxHealth, CurrentHealth = bot.Player.Character.MaxHealth };
            players.Add(bot.Uid, runtime);
            bot.SpawnOrdinal = (member.SlotIndex - 1) % 8;
            ResetBotNoLock(bot, runtime, nav, bot.SpawnOrdinal, reservedSpawns);
            reservedSpawns.Add(BotWorld(runtime.LastPosition!.Value));
        }
        return true;
    }

    private static GamePosition BotPosition(Vector3 position, float yaw) => new(
        (short)Math.Clamp(position.X * 256, short.MinValue, short.MaxValue),
        (short)Math.Clamp(position.Y * 256, short.MinValue, short.MaxValue),
        (short)Math.Clamp(position.Z * 256, short.MinValue, short.MaxValue),
        unchecked((short)(yaw * 8192)), unchecked((short)(yaw * 8192)), 0, DateTimeOffset.UtcNow);

    private static Vector3 BotWorld(GamePosition p) => new(p.XRaw / 256f, p.YRaw / 256f, p.ZRaw / 256f);

    private static void ResetBotNoLock(RoomBot bot, GamePlayerRuntime runtime, AiNavigation nav, int ordinal,
        IReadOnlyList<Vector3>? occupied = null)
    {
        bot.Node = nav.Spawn(runtime.TeamId, ordinal);
        if (occupied is { Count: > 0 })
        {
            var home = nav.Points[bot.Node];
            bot.Node = nav.Nearby(home, 12, bot.Node).OrderBy(n =>
                Vector3.DistanceSquared(nav.Points[n], home) + AiSteering.Crowding(nav.Points[n], occupied) * 100).FirstOrDefault(bot.Node);
        }
        bot.Route.Clear(); bot.Target = 0; bot.Goal = -1; bot.BlockedTicks = 0; bot.MovementTimeRemainder = 0;
        bot.Slot = 0; bot.Ammo.Clear(); bot.NextShot = Environment.TickCount64 + 1200;
        bot.NextPlan = 0; bot.ReloadUntil = 0; bot.NextTarget = 0; bot.NextFlank = 0;
        runtime.LastPosition = BotPosition(nav.Points[bot.Node], runtime.TeamId == 0 ? 0 : MathF.PI);
        runtime.LastShoot = null;
    }

    internal async Task ActivateBotsAsync(int roomId, PracticeRoomChannelProtocol channel)
    {
        (long Id, byte Uid)[] bots;
        PracticeRoomSession room;
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room!) || room.RoomState != 2 || room.Scores.Result is not null ||
                !_botsByRoom.TryGetValue(roomId, out var list) || !_botReadyChannels.Add(channel)) return;
            bots = list.Select(b => ((long)b.Player.Character.Id, b.Uid)).ToArray();
        }
        foreach (var bot in bots)
        {
            await channel.SendRemoteGamePlayerRespawnAsync(room, bot.Id, bot.Uid, "ai-initial-spawn");
            var member = room.Members.Single(m => m.CharacterId == bot.Id);
            await channel.SendPacket107GamePlayerEnterAsync(bot.Uid, (byte)((member.SlotIndex - 1) / 8), "ai-ready");
        }
        lock (_lock)
        {
            if (!_roomsById.ContainsKey(roomId) || room.Scores.Result is not null || _botLoops.ContainsKey(roomId)) return;
            var cancellation = new CancellationTokenSource(); _botLoops.Add(roomId, cancellation);
            _ = RunBotsAsync(roomId, cancellation);
        }
    }

    private async Task RunBotsAsync(int roomId, CancellationTokenSource cancellation)
    {
        try
        {
            using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(BotStepMilliseconds));
            while (await timer.WaitForNextTickAsync(cancellation.Token))
            {
                BotFrame frame;
                PracticeRoomChannelProtocol[] targets;
                lock (_lock)
                {
                    if (!_roomsById.TryGetValue(roomId, out var room) || room.RoomState != 2 || room.Scores.Result is not null ||
                        !_gameChannelsByRoomId.TryGetValue(roomId, out var channels)) break;
                    targets = channels.Keys.Where(_botReadyChannels.Contains).ToArray();
                    if (targets.Length == 0) continue;
                    frame = StepBotsNoLock(room, Environment.TickCount64);
                }
                await BroadcastBotFrameAsync(roomId, frame, targets);
            }
        }
        catch (OperationCanceledException) { }
        catch (Exception ex) { Log.Error(ex, "AI loop failed in room {RoomId}", roomId); }
        finally
        {
            lock (_lock) if (_botLoops.GetValueOrDefault(roomId) == cancellation) _botLoops.Remove(roomId);
            cancellation.Dispose();
        }
    }

    private async Task BroadcastBotFrameAsync(int roomId, BotFrame frame, PracticeRoomChannelProtocol[] targets)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out var room) || room.Scores.EndAnnounced ||
                frame.Combat.Generation != room.Scores.Generation ||
                room.Scores.Result is not null && !ReferenceEquals(frame.Combat.MatchResult, room.Scores.Result)) return;
        }
        foreach (var target in targets)
        {
            try
            {
                foreach (var move in frame.Moves) await target.SendPacket110GameMovementAsync(move);
                foreach (var (uid, slotZeroBased) in frame.Switches)
                    await target.SendPacket128RemoteWeaponSlotAsync(uid, slotZeroBased, "ai-switch");
                foreach (var uid in frame.Reloads) await target.SendPacket117RemoteReloadActionAsync(uid);
                foreach (var shot in frame.Shots.Where(s => !frame.Combat.Damage.Any(d => d.WeaponHit?.Shot == s)))
                    await target.SendPacket113RemoteShootAsync(shot);
            }
            catch { UnregisterGameChannel(roomId, target, out _); }
        }
        if (frame.Combat.Damage.Count > 0) await BroadcastSamuraiCombatAsync(roomId, frame.Combat);
    }

    private BotFrame StepBotsNoLock(PracticeRoomSession room, long now)
    {
        var frame = new BotFrame();
        frame.Combat.Generation = room.Scores.Generation;
        if (room.Scores.Result is not null) return frame;
        if (!_botsByRoom.TryGetValue(room.RoomId, out var bots) || !_gamePlayersByRoomId.TryGetValue(room.RoomId, out var players)) return frame;
        var nav = AiNavigation.ForLevel(room.LevelId)!;
        var readyHumans = _gameChannelsByRoomId.GetValueOrDefault(room.RoomId)?
            .Where(p => _botReadyChannels.Contains(p.Key)).Select(p => p.Value).ToHashSet() ?? [];
        // Rotate movement priority so the same actor does not always claim a narrow doorway first.
        var rotation = bots.Count == 0 ? 0 : (int)(now / 100 % bots.Count);
        foreach (var bot in bots.Skip(rotation).Concat(bots.Take(rotation)))
        {
            if (room.Scores.Result is not null) break;
            if (!players.TryGetValue(bot.Uid, out var actor) || actor.CurrentHealth <= 0 || actor.LastPosition is not { } pose) continue;
            var position = BotWorld(pose);
            var enemies = players.Values.Where(p => p.CurrentHealth > 0 && p.TeamId < 2 && p.TeamId != actor.TeamId &&
                p.LastPosition.HasValue && (readyHumans.Contains(p.Uid) || _botPlayers.ContainsKey(p.CharacterId)))
                .ToArray();
            var target = enemies.FirstOrDefault(p => p.Uid == bot.Target);
            if (target is null || now >= bot.NextTarget)
            {
                target = enemies.MinBy(p => Vector3.Distance(position, BotWorld(p.LastPosition!.Value)) +
                    bots.Count(b => b != bot && b.Target == p.Uid) * 8 + AiSteering.Noise(bot.Seed, p.Uid, 0) * 5 -
                    (p.Uid == bot.Target ? 4 : 0));
                bot.NextTarget = now + bot.Random.Next(1200, 2400);
            }
            var occupied = players.Values.Where(p => p.Uid != bot.Uid && p.CurrentHealth > 0 && p.LastPosition.HasValue)
                .Select(p => BotWorld(p.LastPosition!.Value)).ToArray();
            var targetPosition = target?.LastPosition is { } tp ? BotWorld(tp) : position;
            var distance = target is null ? float.PositiveInfinity : Vector3.Distance(position, targetPosition);
            var visible = target is not null && nav.Visible(position + Vector3.UnitY * 1.3f, targetPosition + Vector3.UnitY * 1.2f);
            if (bot.Target != (target?.Uid ?? 0)) { bot.Target = target?.Uid ?? 0; bot.NextShot = Math.Max(bot.NextShot, now + 500); }
            var weapon = bot.Weapons.MinBy(w => WeaponSuitability(w, distance))!;
            var stats = PracticeRoomChannelProtocol.ResolveGameWeaponRuntimeStats(weapon);
            var hit = PracticeRoomChannelProtocol.ResolveGameWeaponHitRule(weapon);
            var range = Math.Min(hit.MaxRange, weapon.Subtype is 6 or 13 ? 2.5f : 40f);
            if (bot.Slot != weapon.Slot && now >= bot.ReloadUntil)
            {
                bot.Slot = weapon.Slot;
                // Packet 128 takes a zero-based index; 113 and loadout slots are one-based.
                // Sending 3 here selects equipment slot 4 and can activate a local skill.
                frame.Switches.Add((bot.Uid, (byte)(bot.Slot - 1)));
                bot.NextShot = Math.Max(bot.NextShot, now + 300);
            }
            if (now >= bot.NextPlan && bot.Route.Count == 0)
            {
                bot.Node = nav.Nearest(position);
                if (now >= bot.NextFlank)
                {
                    bot.FlankAngle += (bot.Random.NextSingle() * 2 - 1) * 2.2f;
                    bot.NextFlank = now + bot.Random.Next(4000, 7500);
                }
                var desired = actor.CurrentHealth < actor.MaxHealth * .3f ? Math.Min(range * .85f, 22) : Math.Min(range * bot.RangeBias, 15);
                // Reserve upcoming route positions as well as destinations, spreading traffic
                // before several bots enter the same corridor.
                var reservations = occupied.Concat(bots.Where(b => b != bot && b.Goal >= 0 &&
                    players.TryGetValue(b.Uid, out var other) && other.CurrentHealth > 0).SelectMany(b =>
                        b.Route.Take(6).Where((_, i) => i % 2 == 1).Append(b.Goal).Distinct().Select(n => nav.Points[n]))).ToArray();
                var routeSeed = bot.Random.Next(1, int.MaxValue);
                bot.Goal = AiSteering.SelectGoal(nav, bot.Node, position, target is null ? null : targetPosition,
                    desired, bot.FlankAngle, routeSeed, reservations);
                var path = nav.Path(bot.Node, bot.Goal, routeSeed, reservations);
                // Follow only baked edges, with no straight-line shortcut through obstacles.
                bot.Route = new Queue<int>(path.Where((n, i) => i != 0 || Vector3.Distance(position, nav.Points[n]) > .05f));
                bot.NextPlan = now + bot.Random.Next(1800, 3200);
            }
            var before = position;
            var budget = bot.Speed * (BotStepMilliseconds / 1000f);
            while (budget > 0 && bot.Route.TryPeek(out var next))
            {
                var delta = nav.Points[next] - position; var length = delta.Length();
                var step = length <= budget ? nav.Points[next] : position + delta / length * budget;
                if (!AiSteering.CanMove(position, step, occupied))
                {
                    bot.BlockedTicks++;
                    if (bot.BlockedTicks >= 3)
                    {
                        // At a node sidestep along another baked edge; mid-edge yield back to its start.
                        var alternatives = Vector3.Distance(position, nav.Points[bot.Node]) < .08f
                            ? nav.Edges[bot.Node] : new[] { bot.Node };
                        var detour = alternatives.Where(n => AiSteering.CanMove(position, nav.Points[n], occupied))
                            .OrderBy(n => AiSteering.Crowding(nav.Points[n], occupied) * 4 +
                                bot.Random.NextSingle()).Select(n => (int?)n).FirstOrDefault();
                        bot.Route.Clear(); bot.Goal = -1;
                        if (detour.HasValue) bot.Route.Enqueue(detour.Value);
                        bot.NextPlan = now + bot.Random.Next(250, 650);
                        bot.BlockedTicks = 0;
                    }
                    break;
                }
                bot.BlockedTicks = 0; position = step;
                if (length <= budget) { bot.Node = next; bot.Route.Dequeue(); budget -= length; }
                else budget = 0;
                // Re-evaluate pursuit at every reached node instead of following a stale enemy position.
                if (now >= bot.NextPlan && bot.Route.Count > 0 && budget > 0) { bot.Route.Clear(); break; }
            }
            var moved = position - before;
            var look = target is not null && visible ? targetPosition - position : moved;
            var yaw = look.LengthSquared() > .001f ? MathF.Atan2(look.X, -look.Z) : (pose.YawRaw ?? 0) / 8192f;
            var newPose = BotPosition(position, yaw); actor.LastPosition = newPose;
            // Packet110's optional 16-bit field is ping; facing already carries the yaw.
            var (flags, payload) = PracticeRoomChannelProtocol.BuildTeleportMovementPayload(newPose with { YawRaw = null });
            // Native PS_OnGround. Without it, directional movement plays an airborne pose.
            var input = (byte)0x02;
            if (moved.LengthSquared() > .0001f)
            {
                var forward = new Vector3(MathF.Sin(yaw), 0, -MathF.Cos(yaw));
                var side = new Vector3(MathF.Cos(yaw), 0, MathF.Sin(yaw));
                var f = Vector3.Dot(moved, forward); var s = Vector3.Dot(moved, side);
                input |= Math.Abs(f) >= Math.Abs(s) ? (byte)(f >= 0 ? 0x10 : 0x20) : (byte)(s >= 0 ? 0x80 : 0x40);
            }
            // The client adds this byte / 255 to its movement timeline; it is NOT a sequence.
            // Carry the fraction so 100 ms steps alternate 25/26 without accumulating drift.
            bot.MovementTimeRemainder += BotStepMilliseconds * 255;
            var elapsed = (byte)(bot.MovementTimeRemainder / 1000);
            bot.MovementTimeRemainder %= 1000;
            frame.Moves.Add(new(bot.Uid, elapsed, (byte)(flags | 1), new[] { input }.Concat(payload).ToArray(), DateTimeOffset.UtcNow));
            if (target is null || !visible || distance > range || now < bot.NextShot || now < bot.ReloadUntil) continue;
            // Recheck visibility from the new muzzle position after movement.
            var origin = position + Vector3.UnitY * 1.3f;
            var aim = targetPosition + Vector3.UnitY * 1.2f;
            if (!nav.Visible(origin, aim)) continue;
            var capacity = Math.Max(1, stats.AmmoOneClip);
            var ammo = bot.Ammo.GetValueOrDefault(weapon.Slot, capacity);
            if (ammo == 0)
            {
                bot.ReloadUntil = now + (long)(Math.Clamp(stats.CoolDown, 1.2f, 4f) * 1000);
                bot.Ammo[weapon.Slot] = capacity; frame.Reloads.Add(bot.Uid); continue;
            }
            if (weapon.Subtype is not (6 or 13)) bot.Ammo[weapon.Slot] = ammo - 1;
            bot.NextShot = now + (long)(Math.Max(.14f, stats.FireTime) * 1000);
            var error = Math.Max(.12f, distance * .025f);
            var offset = new Vector3((Random.Shared.NextSingle() * 2 - 1) * error, (Random.Shared.NextSingle() * 2 - 1) * error, 0);
            var direction = Vector3.Normalize(aim + offset - origin);
            var shoot = new GameShootAction(bot.Uid, 0, weapon.Slot, newPose.XRaw,
                (short)(origin.Y * 256), newPose.ZRaw, newPose.Facing0Raw ?? 0,
                unchecked((short)(-MathF.Asin(direction.Y) * 8192)), direction.X, direction.Y, direction.Z, DateTimeOffset.UtcNow);
            actor.LastShoot = shoot; frame.Shots.Add(shoot);
            if (offset.Length() <= (weapon.Subtype == 4 ? 1.1f : .65f))
                ApplyCombatDamageNoLock(room, actor, target, PracticeRoomChannelProtocol.ResolveGameWeaponDamage(weapon), true,
                    null, frame.Combat, now, new GameWeaponHit(shoot, PlayShot: true));
        }
        return frame;
    }

    private static float WeaponSuitability(PlayerStore.PlayerState.GameLoadoutItem w, float distance) => w.Subtype switch
    {
        6 or 13 => distance < 2.4f ? 0 : 100,
        4 or 15 => Math.Abs(distance - 7),
        2 or 12 or 16 => Math.Abs(distance - 25),
        11 or 14 => distance < 7 ? 80 : Math.Abs(distance - 20),
        _ => Math.Abs(distance - 14) + 1
    };

    private void StopBotsNoLock(int roomId)
    {
        if (_botLoops.Remove(roomId, out var loop)) loop.Cancel();
    }

    private void RemoveBotsNoLock(int roomId)
    {
        StopBotsNoLock(roomId);
        if (_gameChannelsByRoomId.TryGetValue(roomId, out var channels)) foreach (var channel in channels.Keys) _botReadyChannels.Remove(channel);
        if (_botsByRoom.Remove(roomId, out var bots)) foreach (var bot in bots) _botPlayers.Remove(bot.Player.Character.Id);
    }

    private sealed class RoomBot(PlayerStore.PlayerState player)
    {
        internal PlayerStore.PlayerState Player { get; } = player;
        internal PlayerStore.PlayerState.GameLoadoutItem[] Weapons { get; } = player.GetGameLoadoutItems().Where(w => w.ItemType == 2 && w.Slot <= 3).ToArray();
        internal byte Uid, Slot, Target;
        internal readonly int Seed = Random.Shared.Next(1, int.MaxValue);
        internal readonly Random Random = new(Random.Shared.Next());
        internal readonly float Speed = 3.7f + Random.Shared.NextSingle() * .8f;
        internal readonly float RangeBias = .48f + Random.Shared.NextSingle() * .24f;
        internal float FlankAngle = Random.Shared.NextSingle() * MathF.Tau;
        internal int Node, SpawnOrdinal, BlockedTicks, MovementTimeRemainder, Goal = -1;
        internal long NextPlan, NextShot, ReloadUntil, NextTarget, NextFlank;
        internal Queue<int> Route = new();
        internal Dictionary<byte, int> Ammo = [];
    }

    private sealed class BotFrame
    {
        internal List<GameMovementDelta> Moves { get; } = [];
        internal List<GameShootAction> Shots { get; } = [];
        internal List<(byte Uid, byte SlotZeroBased)> Switches { get; } = [];
        internal List<byte> Reloads { get; } = [];
        internal SamuraiCombatBatch Combat { get; } = new();
    }
}
