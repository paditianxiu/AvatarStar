using System.Net;
using System.Numerics;
using System.Reflection;
using System.Text.Json;
using AvatarStar.Server.Game;
using AvatarStar.Server;
using AvatarStar.Server.Utilities;
using AvatarStar.Server.Game.Config;

var checks = 0;
void Check(bool condition, string message)
{
    checks++;
    if (!condition) throw new Exception(message);
}

// Boundary geometry is independent of client hit claims.
var forward = new Vector2(0, -1);
Check(SamuraiSkills.Hits(80, Vector3.Zero, forward, new(0, 0, -4.5f)), "Iai range edge");
Check(!SamuraiSkills.Hits(80, Vector3.Zero, forward, new(0, 0, -4.51f)), "Iai out of range");
Check(SamuraiSkills.Hits(80, Vector3.Zero, forward, new(MathF.Sqrt(3), 0, -1)), "Iai 60 degree edge");
Check(!SamuraiSkills.Hits(80, Vector3.Zero, forward, new(2, 0, 0)), "Iai sideways excluded");
Check(!SamuraiSkills.Hits(80, Vector3.Zero, forward, new(0, 0, 1)), "Iai behind excluded");
foreach (var (id, length) in new[] { (81, 7f), (82, 12f) })
{
    Check(SamuraiSkills.Hits(id, Vector3.Zero, forward, new(1, 0, -length)), "path boundary");
    Check(!SamuraiSkills.Hits(id, Vector3.Zero, forward, new(1.01f, 0, -length)), "path width");
    Check(!SamuraiSkills.Hits(id, Vector3.Zero, forward, new(0, 0, -length - .01f)), "path length");
    Check(!SamuraiSkills.Hits(id, Vector3.Zero, forward, new(0, 3, -1)), "different floor");
    Check(!SamuraiSkills.Hits(id, Vector3.Zero, forward, new(float.NaN, 0, 0)), "nonfinite position");
}
var state = new SamuraiCombatState { BushidoLevel = 5 };
Check(!state.TryActivate(80, 0, 100), "unlearned skill");
Check(!state.TryActivate(84, 1, 100), "passive activation");
Check(state.TryActivate(80, 5, 100), "first cast");
Check(!state.TryActivate(80, 5, 10099), "cooldown not ready");
Check(state.TryActivate(80, 5, 10100), "cooldown exact edge");
Check(state.TryActivate(83, 5, 100), "guard starts");
Check(state.ConsumeGuard(64.01f, 101) == 0, "distant hit keeps guard");
Check(state.ConsumeGuard(64, 101) == 5, "eight metre guard");
Check(state.ConsumeGuard(1, 102) == 0, "guard only once");
state.Clear();
state.TryActivate(83, 1, 100);
Check(state.ConsumeGuard(1, 4100) == 0, "expired guard");
Check(state.WeaponDamage(100, 100) == 100, "passive needs kill");
state.OnKill(100);
Check(state.WeaponDamage(100, 6099) == 120, "passive increases weapon damage");
state.OnKill(6099);
Check(state.WeaponDamage(100, 6100) == 120, "kill refreshes passive");
Check(state.WeaponDamage(100, 12099) == 100, "passive expires at six seconds");
state.Clear();
Check(state.GuardUntil == 0 && state.BushidoUntil == 0, "death clears buffs");

// Persisted skills, hotbar and model stay profession 4 after a JSON round trip.
var config = new SysAvatarPayloadConfig();
var root = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../.."));
if (args.Length > 0) root = Path.GetFullPath(args[0]);
SysAvatarPayloadLoader.Load(config, Path.Combine(root, "src/AvatarStar.Server.Game/Config"));
var store = new PlayerStore();
var samurai = store.CreateCharacter(1, "Samurai-test", 4, config);
foreach (var skill in SamuraiSkills.Definitions) samurai.SetSkillLevel(skill.Id, 3);
Check(SkillCatalog.GetSkills(4).Select(s => s.Id).SequenceEqual(new[] { 80, 81, 82, 83, 84 }), "five profession skills");
Check(samurai.GetGameLoadoutItems().Where(x => x.ItemType == 1).Select(x => x.SkillId).Order().SequenceEqual(new[] { 80, 81, 82, 83, 85 }), "active hotbar plus counter");
var snapshot = JsonSerializer.Deserialize<PlayerStateSnapshot>(JsonSerializer.Serialize(samurai.ToSnapshot()))!;
var restored = PlayerStore.PlayerState.FromSnapshot(snapshot);
Check(restored.Character.Occupation == 4 && restored.GetSkillLevel(84) == 3, "stored profession and passive");
Check(JsonSerializer.Serialize(restored.Character.EquipAvatar).Contains("jadesamurai"), "stored model");
foreach (var female in new[] { false, true })
{
    var expected = SamuraiAppearance.Create(female);
    var payload = File.ReadAllText(Path.Combine(root, "src/AvatarStar.Server.Game/Config/SysAvatarPayloads/5_samurai.lua"));
    foreach (var (field, value) in expected)
        Check(payload.Contains($"{field} = \"{value}\""), $"creation and fallback model agree: {field}");
}
var legacy = new PlayerStore.PlayerState(CharacterInfo.Create(90, "Legacy", 4));
legacy.Character = legacy.Character with { EquipAvatar = new Dictionary<string, string>
{
    ["avatarId"] = "100003",
    ["outerwear"] = "{{'malecommandos_outerwear',10,1,3,132,122,185,51,46,52,55,59,90},}",
    ["trousers"] = "{{'malecommandos_trousers',11,0,3,201,201,201,103,65,122,51,46,52},}",
    ["glove"] = "{{'malecommandos_glove',12,2,3,103,65,122,211,77,162,51,46,52},}",
    ["shoes"] = "{{'malecommandos_shoes',13,3,2,55,59,96,245,244,249,0,0,0},}"
} };
legacy.SetSkillLevel(38, 3);
legacy.EnsureStarterInventory();
Check(JsonSerializer.Serialize(legacy.Character.EquipAvatar).Contains("jadesamurai"), "bootstrap costume upgrades");
Check(legacy.Storages[5].Count == 2 && legacy.GetSkillLevel(38) == 0, "old card retained and wrong points refunded");
legacy.EnsureStarterInventory();
Check(legacy.Storages[5].Count == 2, "migration is idempotent");
var custom = new PlayerStore.PlayerState(CharacterInfo.Create(91, "Custom", 4));
custom.Character = custom.Character with { EquipAvatar = new { avatarId = "100003", outerwear = "custom" } };
custom.EnsureStarterInventory();
Check(JsonSerializer.Serialize(custom.Character.EquipAvatar).Contains("custom"), "custom costume stays equipped");

// Exercise the actual manager and packet senders with in-memory channel transports.
var manager = new PracticeRoomManager();
var room = manager.CreateOrReplaceRoom(new(1, "Samurai-test", "test", "LEVEL01", false, "", 1, 1, 16, 3,
    true, false, 0, false, 0, 30, 4, 0, 0, 0));
var sent = new Dictionary<byte, List<byte[]>>();
PracticeRoomChannelProtocol Channel(long characterId, byte team, float x, float z, out byte uid)
{
    var packets = new List<byte[]>();
    uint decodeState = 0;
    var channel = new PracticeRoomChannelProtocol(manager, store, p => { var bytes = p.ToArray(); XorNetworkCodec.DecodeInPlace(bytes, ref decodeState); packets.Add(bytes); return Task.CompletedTask; }, IPAddress.Loopback, "test");
    uid = manager.RegisterGameChannel(room.RoomId, channel, characterId, "test");
    sent[uid] = packets;
    typeof(PracticeRoomChannelProtocol).GetField("_currentGameRoom", BindingFlags.Instance | BindingFlags.NonPublic)!.SetValue(channel, room);
    typeof(PracticeRoomChannelProtocol).GetField("_localGameUid", BindingFlags.Instance | BindingFlags.NonPublic)!.SetValue(channel, uid);
    manager.UpdateGamePlayerState(room.RoomId, uid, team, 2000);
    manager.TrySetGamePlayerHealth(room.RoomId, uid, 2000, out _);
    manager.UpdateGamePosition(room.RoomId, uid, new((short)(x * 256), 0, (short)(z * 256), 0, 0, 0, DateTimeOffset.UtcNow));
    return channel;
}
var source = Channel(1, 0, 0, 0, out var caster);
var enemyChannel = Channel(2, 1, 0, -3, out var enemy);
_ = Channel(3, 0, 0, -2, out var ally);
_ = Channel(4, 1, 0, 3, out var behind);
_ = Channel(5, 2, 0, -2, out var spectator);
_ = Channel(6, 1, .5f, -6, out var distant);
manager.ConfigureSamurai(room.RoomId, caster, samurai);
Check(manager.TryActivateSamurai(room.RoomId, source, caster, samurai, 80, 3, out var slash), "manager accepts learned cast");
Check(slash.Damage.Count == 1 && slash.Damage[0].VictimUid == enemy && slash.Damage[0].Damage == 400, "fan only hits live forward enemy");
Check(slash.Damage[0].Knockback is { Z: < 0 }, "slash pushes forward");
var delivered = await manager.BroadcastSamuraiCombatAsync(room.RoomId, slash);
Check(delivered == 6 && sent.Values.All(p => p.Count == 2), "damage and push reach every channel including caster");
Check(sent.Values.All(p => BitConverter.ToInt16(p[0]) == 184 && BitConverter.ToInt16(p[1]) == 162), "damage and knockback packet ids");
Check(!manager.TryActivateSamurai(room.RoomId, source, caster, samurai, 80, 3, out _), "server rejects repeated cast");
Check(!manager.TryActivateSamurai(room.RoomId, enemyChannel, caster, samurai, 81, 3, out _), "channel identity checked");
Check(!manager.TryActivateSamurai(room.RoomId, source, caster, samurai, 81, 5, out _), "claimed level checked");
Check(manager.TryActivateSamurai(room.RoomId, source, caster, samurai, 81, 3, out var step), "wind step");
Check(step.Damage.Select(a => a.VictimUid).Order().SequenceEqual(new[] { enemy, distant }), "step hits each enemy once");
Check(step.Moves.Single().Position.ZRaw == -7 * 256, "step follows facing for seven metres");
await manager.BroadcastSamuraiCombatAsync(room.RoomId, step);
Check(sent.Values.All(p => p.Count > 2), "step movement reaches peers");
manager.UpdateGamePosition(room.RoomId, caster, new(0, 0, 0, 0, 0, 0, DateTimeOffset.UtcNow));
Check(manager.TryActivateSamurai(room.RoomId, source, caster, samurai, 83, 3, out var guard), "manager guard");
Check(guard.Buffs.Single().Buff == 69, "guard uses client buff 69");
await manager.BroadcastSamuraiCombatAsync(room.RoomId, guard);
Check(sent.Values.All(p => p.Last() is { Length: 11 } frame && BitConverter.ToInt16(frame) == 162 && frame[9] == 69), "guard VFX packet reaches all players");
var hit = await manager.BroadcastGameDamageAsync(room.RoomId, enemyChannel, enemy, 500, clientTargetUid: caster);
Check(hit.Damage == 200 && hit.VictimHealth == 1800, "guard reduces incoming weapon damage by sixty percent");
manager.TryGetGamePlayerHealth(room.RoomId, enemy, out var enemyHealth, out _);
Check(enemyHealth == 1000, "guard counter applies 250 damage once");
var secondHit = await manager.BroadcastGameDamageAsync(room.RoomId, enemyChannel, enemy, 100, clientTargetUid: caster);
Check(secondHit.Damage == 100, "second hit consumes no second guard");
Check(sent[caster].Any(f => BitConverter.ToInt16(f) == 160 && f[3] == SamuraiSkills.CounterSlot), "counter activation reaches its owner");
Check(sent.Where(p => p.Key != caster).All(p => p.Value.All(f => BitConverter.ToInt16(f) != 160)), "counter never activates a peer's skill slot");
var kill = await manager.BroadcastGameDamageAsync(room.RoomId, source, caster, 2000, clientTargetUid: enemy);
Check(kill.Killed, "weapon kill");
var bonus = await manager.BroadcastGameDamageAsync(room.RoomId, source, caster, 100, clientTargetUid: distant);
Check(bonus.Damage == 114, "kill enables level three bushido");
Check(sent.Values.All(p => p.Any(f => f.Length == 11 && BitConverter.ToInt16(f) == 162 && f[9] == 89)), "bushido VFX broadcasts");
var dead = await manager.BroadcastGameDamageAsync(room.RoomId, enemyChannel, distant, 2000, clientTargetUid: caster);
Check(dead.Killed, "caster dies");
Check(!manager.TryActivateSamurai(room.RoomId, source, caster, samurai, 82, 3, out _), "dead caster cannot cast");
manager.UpdateGamePlayerState(room.RoomId, caster, 0, 2000);
var respawnHit = await manager.BroadcastGameDamageAsync(room.RoomId, source, caster, 100, clientTargetUid: distant);
Check(respawnHit.Damage == 100, "death removes bushido");
// Drive the packet136 handler itself, then verify that 152 cannot replay the effect.
var activate = typeof(PracticeRoomChannelProtocol).GetMethod("HandlePacket136GameSkillActivateAsync", BindingFlags.Instance | BindingFlags.NonPublic)!;
var release = typeof(PracticeRoomChannelProtocol).GetMethod("HandlePacket152GameSkillCastAsync", BindingFlags.Instance | BindingFlags.NonPublic)!;
var guardSlot = samurai.GetGameLoadoutItems().Single(i => i.SkillId == 83).Slot;
samurai.SetSkillLevel(83, 1);
await (Task)activate.Invoke(source, new object[] { new PacketReader(new[] { guardSlot }) })!;
Check(sent[caster].Any(f => BitConverter.ToInt16(f) == 160 && f[3] == guardSlot), "136 acknowledgement uses actual hotkey");
var beforeReplay = sent.Values.Sum(p => p.Count);
await (Task)release.Invoke(source, new object[] { new PacketReader(new byte[] { 1, guardSlot, 0, 0 }) })!;
await (Task)activate.Invoke(source, new object[] { new PacketReader(new[] { guardSlot }) })!;
Check(sent.Values.Sum(p => p.Count) == beforeReplay, "152 and cooldown replay cannot repeat VFX or damage");
var closes = sent[caster].Count(f => BitConverter.ToInt16(f) == 155 && f[6] == 69);
await Task.Delay(5250);
Check(sent[caster].Count(f => BitConverter.ToInt16(f) == 155 && f[6] == 69) == closes + 1, "guard expiry closes once despite stale earlier timer");
Check(manager.UnregisterGameChannel(room.RoomId, source, out _), "leave channel");
Check(!manager.TryActivateSamurai(room.RoomId, source, caster, samurai, 82, 3, out _), "left channel cannot cast");
Console.WriteLine($"PASS: {checks} Samurai checks (geometry, cooldown, persistence, combat and broadcasts).");
await AiTests.Run(config, Check);
await SkillOwnershipTests.Run(config, Check);
AiCrowdTests.Run(config, Check);
AiFillTests.Run(config, Check);
await KillFeedTests.Run(config, Check);
await AiReplicationTests.Run(config, Check);
await GameScoreTests.Run(config, Check);
await KillStreakTests.Run(config, Check);
await MatchEndTests.Run(config, Check);
ImportedMapTests.Run(root, Check);
ImportedActorTests.Run(root, config, Check);
WeaponQualityTests.Run(config, Check);
Console.WriteLine($"PASS: {checks} total checks including AI navigation, professions, permissions, combat, respawn and cleanup.");
