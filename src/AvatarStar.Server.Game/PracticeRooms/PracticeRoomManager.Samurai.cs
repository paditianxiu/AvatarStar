using System.Numerics;
using Serilog;

namespace AvatarStar.Server.Game;

internal sealed partial class PracticeRoomManager
{
    internal sealed class SamuraiCombatBatch
    {
        internal long Generation { get; set; }
        internal GameMatchResult? MatchResult { get; set; }
        public List<GameDamageAction> Damage { get; } = [];
        public List<SamuraiBuffChange> Buffs { get; } = [];
        public List<SamuraiMove> Moves { get; } = [];
    }

    internal sealed record SamuraiBuffChange(byte Uid, byte Buff, long Deadline, SamuraiCombatState State);
    internal sealed record SamuraiMove(byte Uid, GamePosition Position);

    public void ConfigureSamurai(int roomId, byte uid, PlayerStore.PlayerState? state)
    {
        lock (_lock)
        {
            if (_gamePlayersByRoomId.TryGetValue(roomId, out var players) && players.TryGetValue(uid, out var player))
                player.Samurai.BushidoLevel = state?.Character.Occupation == 4 && state.Character.Id == player.CharacterId ? state.GetSkillLevel(SamuraiSkills.Bushido) : 0;
        }
    }

    public bool TryActivateSamurai(int roomId, PracticeRoomChannelProtocol source, byte uid,
        PlayerStore.PlayerState state, int skillId, int level, out SamuraiCombatBatch batch)
    {
        batch = new SamuraiCombatBatch();
        lock (_lock)
        {
            if (state.Character.Occupation != 4 || state.GetSkillLevel(skillId) != level ||
                !_roomsById.TryGetValue(roomId, out var room) || room.Scores.Result is not null ||
                !_gameChannelsByRoomId.TryGetValue(roomId, out var channels) ||
                !channels.TryGetValue(source, out var sourceUid) || sourceUid != uid ||
                !_gamePlayersByRoomId.TryGetValue(roomId, out var players) ||
                !players.TryGetValue(uid, out var player) || player.CharacterId != state.Character.Id || player.CurrentHealth <= 0 ||
                ResolveGamePlayerTeamId(room, player) == GameTeamSpectator ||
                !TryResolveProximityWorldPosition(player, false, out var origin))
                return false;

            var now = Environment.TickCount64;
            batch.Generation = room.Scores.Generation;
            var forward = ResolveSamuraiFacing(player);
            if (skillId != SamuraiSkills.BladeGuard && forward.LengthSquared() < 0.5f)
                return false;
            if (!player.Samurai.TryActivate(skillId, level, now)) return false;
            player.Samurai.BushidoLevel = state.GetSkillLevel(SamuraiSkills.Bushido);
            if (skillId == SamuraiSkills.BladeGuard)
            {
                batch.Buffs.Add(new(uid, SamuraiSkills.GuardBuff, player.Samurai.GuardUntil, player.Samurai));
                return true;
            }

            var start = new Vector3(origin.X, origin.Y, origin.Z);
            // Snapshot candidates before moving the caster. Every enemy is visited once per cast.
            foreach (var enemy in players.Values.ToArray())
            {
                if (player.CurrentHealth <= 0 || room.Scores.Result is not null) break;
                if (enemy.Uid == uid || enemy.CurrentHealth <= 0 ||
                    !IsEnemyTeam(ResolveGamePlayerTeamId(room, player), ResolveGamePlayerTeamId(room, enemy)) ||
                    !TryResolveProximityWorldPosition(enemy, false, out var target) ||
                    !SamuraiSkills.Hits(skillId, start, forward, new(target.X, target.Y, target.Z))) continue;
                var push = skillId is SamuraiSkills.IaiSlash or SamuraiSkills.WindCut
                    ? new GameKnockbackAction(GameKnockbackAction.BlowUpBuffType, forward.X * 3f, 0.5f, forward.Y * 3f)
                    : (GameKnockbackAction?)null;
                ApplyCombatDamageNoLock(room, player, enemy, SamuraiSkills.Damage(skillId, level), false, push, batch, now);
            }
            if (skillId == SamuraiSkills.WindStep && player.CurrentHealth > 0 && room.Scores.Result is null)
                MoveSamuraiNoLock(player, start + new Vector3(forward.X, 0, forward.Y) * SamuraiSkills.StepDistance, batch);
            return true;
        }
    }

    private static Vector2 ResolveSamuraiFacing(GamePlayerRuntime player)
    {
        if (player.LastPosition is { } pose && (player.LastShoot is null || pose.LastSeenAt >= player.LastShoot.Value.LastSeenAt))
        {
            var raw = pose.Facing0Raw ?? pose.YawRaw;
            if (raw.HasValue)
            {
                var yaw = unchecked((ushort)raw.Value) / FacingRawAngleScale;
                return new(MathF.Sin(yaw), -MathF.Cos(yaw));
            }
        }
        if (player.LastShoot is { } shoot)
        {
            var direction = ResolveShootDirection(shoot);
            var flat = new Vector2(direction.X, direction.Z);
            if (flat.LengthSquared() > 0.0001f) return Vector2.Normalize(flat);
        }
        return Vector2.Zero;
    }

    private static void MoveSamuraiNoLock(GamePlayerRuntime player, Vector3 target, SamuraiCombatBatch batch)
    {
        if (!float.IsFinite(target.X + target.Y + target.Z) ||
            MathF.Abs(target.X * MovementRawCoordinateScale) > short.MaxValue ||
            MathF.Abs(target.Y * MovementRawCoordinateScale) > short.MaxValue ||
            MathF.Abs(target.Z * MovementRawCoordinateScale) > short.MaxValue) return;
        var old = player.LastPosition;
        var position = new GamePosition((short)(target.X * MovementRawCoordinateScale),
            (short)(target.Y * MovementRawCoordinateScale), (short)(target.Z * MovementRawCoordinateScale),
            old?.YawRaw, old?.Facing0Raw, old?.Facing1Raw, DateTimeOffset.UtcNow);
        player.LastPosition = position;
        // A pre-dash shot must not remain the source of subsequent melee/range checks.
        player.LastShoot = null;
        batch.Moves.Add(new(player.Uid, position));
    }

    private static GameDamageAction ApplyCombatDamageNoLock(PracticeRoomSession room, GamePlayerRuntime attacker, GamePlayerRuntime victim,
        int damage, bool weapon, GameKnockbackAction? push, SamuraiCombatBatch batch, long now,
        GameWeaponHit? weaponHit = null)
    {
        batch.Generation = room.Scores.Generation;
        if (weapon) damage = attacker.Samurai.WeaponDamage(damage, now);
        var guard = 0;
        Vector3 counterTarget = default;
        if (TryResolveProximityWorldPosition(attacker, false, out var a) &&
            TryResolveProximityWorldPosition(victim, false, out var v))
        {
            guard = victim.Samurai.ConsumeGuard(DistanceSquared(a.X, a.Y, a.Z, v.X, v.Y, v.Z), now);
            if (guard > 0)
            {
                damage = Math.Max(1, (int)((long)damage * (100 - SamuraiSkills.GuardReduction(guard)) / 100));
                batch.Buffs.Add(new(victim.Uid, SamuraiSkills.GuardBuff, 0, victim.Samurai));
                var delta = new Vector3(v.X - a.X, 0, v.Z - a.Z);
                counterTarget = new Vector3(a.X, a.Y, a.Z) +
                    (delta.LengthSquared() > 0.01f ? Vector3.Normalize(delta) * MathF.Min(1f, delta.Length()) : Vector3.Zero);
            }
        }
        var health = victim.CurrentHealth;
        damage = Math.Clamp(damage, 1, Math.Max(1, victim.MaxHealth));
        victim.CurrentHealth = Math.Max(0, health - damage);
        var killed = health > 0 && victim.CurrentHealth == 0;
        var killScore = killed ? RecordGameDeathNoLock(room, attacker, victim) : (GameKillScore?)null;
        batch.MatchResult = room.Scores.Result;
        var action = new GameDamageAction(attacker.Uid, victim.Uid, damage, victim.CurrentHealth,
            victim.MaxHealth, killed, push, weapon ? weaponHit : null, killScore);
        batch.Damage.Add(action);
        if (killed)
        {
            ClearSamuraiEffects(victim, batch);
            if (attacker.Samurai.OnKill(now))
                batch.Buffs.Add(new(attacker.Uid, SamuraiSkills.BushidoBuff, attacker.Samurai.BushidoUntil, attacker.Samurai));
        }
        if (guard > 0 && victim.CurrentHealth > 0 && attacker.CurrentHealth > 0 && room.Scores.Result is null)
        {
            MoveSamuraiNoLock(victim, counterTarget, batch);
            // Each guard is consumed before the follow-up; two guarded players cannot loop forever.
            ApplyCombatDamageNoLock(room, victim, attacker, SamuraiSkills.Damage(SamuraiSkills.BladeGuard, guard),
                false, null, batch, now);
        }
        return action;
    }

    private static void ClearSamuraiEffects(GamePlayerRuntime player, SamuraiCombatBatch batch)
    {
        if (player.Samurai.GuardUntil != 0) batch.Buffs.Add(new(player.Uid, SamuraiSkills.GuardBuff, 0, player.Samurai));
        if (player.Samurai.BushidoUntil != 0) batch.Buffs.Add(new(player.Uid, SamuraiSkills.BushidoBuff, 0, player.Samurai));
        player.Samurai.Clear();
    }

    public async Task<int> BroadcastSamuraiCombatAsync(int roomId, SamuraiCombatBatch batch)
    {
        PracticeRoomSession room;
        lock (_lock)
            if (!_roomsById.TryGetValue(roomId, out room!)) return 0;
        // A queued pre-win batch must never overwrite the final score after packet131.
        await room.Scores.BroadcastGate.WaitAsync();
        try
        {
            lock (_lock)
                if (!_roomsById.TryGetValue(roomId, out var current) || !ReferenceEquals(current, room) ||
                    batch.Generation != room.Scores.Generation || room.Scores.EndAnnounced) return 0;
            var sent = await BroadcastSamuraiCombatCoreAsync(roomId, batch);
            await SendFiveKillFeedbackAsync(roomId, batch);
            if (batch.MatchResult is { } result) await AnnounceMatchEndAsync(room, result);
            return sent;
        }
        finally { room.Scores.BroadcastGate.Release(); }
    }

    private async Task<int> BroadcastSamuraiCombatCoreAsync(int roomId, SamuraiCombatBatch batch)
    {
        KeyValuePair<PracticeRoomChannelProtocol, byte>[] targets;
        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels)) return 0;
            targets = channels.ToArray();
        }
        var sent = 0;
        foreach (var (target, uid) in targets)
        {
            try
            {
                foreach (var action in batch.Damage)
                {
                    await target.SendGameDamageHitAsync(action);
                    if (action.Knockback is { } push) await target.SendPacket162RemoteKnockbackAsync(action, push);
                }
                foreach (var buff in batch.Buffs)
                {
                    if (buff.Deadline > 0)
                        await target.SendPacket162RemoteAbilityOpenAsync(buff.Uid, buff.Uid, 0, buff.Buff, "samurai-open");
                    else
                        await target.SendPacket155SkillCastStateAsync(buff.Uid, buff.Buff, "samurai-close");
                }
                foreach (var counter in batch.Buffs.Where(b => b.Buff == SamuraiSkills.GuardBuff && b.Deadline == 0 &&
                             b.Uid == uid && batch.Moves.Any(m => m.Uid == b.Uid)))
                    await target.SendPacket160GameSkillActivateAsync(counter.Uid, SamuraiSkills.CounterSlot, "samurai-counter");
                foreach (var move in batch.Moves.Where(m => m.Uid == uid))
                    await target.SendSamuraiMoveAsync(roomId, move.Position);
                sent++;
            }
            catch (Exception ex)
            {
                Log.Debug(ex, "Samurai broadcast failed in room {RoomId}", roomId);
                UnregisterGameChannel(roomId, target, out _);
            }
        }
        if (!IsGameFinished(roomId))
        {
            foreach (var action in batch.Damage.Where(a => a.Killed))
                _ = RespawnGamePlayerAfterDelayAsync(roomId, action.VictimUid, GameAutoRespawnDelayMilliseconds, "samurai-combat");
            foreach (var buff in batch.Buffs.Where(b => b.Deadline > 0))
                _ = CloseSamuraiBuffAfterDelayAsync(roomId, buff);
        }
        return sent;
    }

    private async Task CloseSamuraiBuffAfterDelayAsync(int roomId, SamuraiBuffChange buff)
    {
        try
        {
            await Task.Delay((int)Math.Clamp(buff.Deadline - Environment.TickCount64, 0, 6000));
            PracticeRoomChannelProtocol[] targets;
            lock (_lock)
            {
                if (IsGameFinished(roomId) || !_gamePlayersByRoomId.TryGetValue(roomId, out var players) ||
                    !players.TryGetValue(buff.Uid, out var player) || !ReferenceEquals(player.Samurai, buff.State) ||
                    player.Samurai.Deadline(buff.Buff) != buff.Deadline ||
                    !_gameChannelsByRoomId.TryGetValue(roomId, out var channels)) return;
                targets = channels.Keys.ToArray();
            }
            foreach (var target in targets)
            {
                try { await target.SendPacket155SkillCastStateAsync(buff.Uid, buff.Buff, "samurai-expired"); }
                catch { UnregisterGameChannel(roomId, target, out _); }
            }
        }
        catch (Exception ex) { Log.Debug(ex, "Samurai buff expiry failed in room {RoomId}", roomId); }
    }
}
