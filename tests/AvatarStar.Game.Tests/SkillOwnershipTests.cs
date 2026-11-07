using System.Net;
using System.Reflection;
using AvatarStar.Server;
using AvatarStar.Server.Game;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Utilities;

internal static class SkillOwnershipTests
{
    internal static async Task Run(SysAvatarPayloadConfig config, Action<bool, string> check)
    {
        var store = new PlayerStore();
        var a = store.CreateCharacter(10, "Caster-A", 2, config);
        var b = store.CreateCharacter(10, "Teammate-B", 2, config);
        foreach (var player in new[] { a, b }) { player.SetSkillLevel(2, 3); player.SetSkillLevel(11, 3); }
        var manager = new PracticeRoomManager();
        var room = manager.CreateOrReplaceRoom(new(a.Character.Id, a.Character.Name, "skill isolation", "LEVEL53", false,
            "", 400022, 4, 16, 3, true, false, 0, false, 0, 30, 2, 0, 0, 0));
        room.TryUpsertMember(new(b.Character.Id, b.Character.Name, 30, 2, 0, 0, 0), out _);
        var channels = new List<(PracticeRoomChannelProtocol Channel, byte Uid, List<byte[]> Packets, PlayerStore.PlayerState Player)>();
        foreach (var player in new[] { a, b })
        {
            uint state = 0; var packets = new List<byte[]>();
            var channel = new PracticeRoomChannelProtocol(manager, store, p =>
            {
                var bytes = p.ToArray(); XorNetworkCodec.DecodeInPlace(bytes, ref state); packets.Add(bytes); return Task.CompletedTask;
            }, IPAddress.Loopback, "skill-isolation");
            var uid = manager.RegisterGameChannel(room.RoomId, channel, player.Character.Id, player.Character.Name);
            foreach (var (name, value) in new (string, object)[] { ("_currentGameRoom", room), ("_localGameUid", uid), ("_currentCharacterId", (long)player.Character.Id) })
                typeof(PracticeRoomChannelProtocol).GetField(name, BindingFlags.NonPublic | BindingFlags.Instance)!.SetValue(channel, value);
            manager.UpdateGamePlayerState(room.RoomId, uid, 0, 2300);
            channels.Add((channel, uid, packets, player));
        }
        var handler = typeof(PracticeRoomChannelProtocol).GetMethod("HandlePacket136GameSkillActivateAsync", BindingFlags.Instance | BindingFlags.NonPublic)!;
        foreach (var skill in new[] { 2, 11 }) foreach (var caster in channels)
        {
            foreach (var c in channels) c.Packets.Clear();
            var slot = caster.Player.GetGameLoadoutItems().Single(i => i.ItemType == 1 && i.SkillId == skill).Slot;
            await (Task)handler.Invoke(caster.Channel, new object[] { new PacketReader(new[] { slot }) })!;
            var peer = channels.Single(c => c.Uid != caster.Uid);
            check(caster.Packets.Count(p => BitConverter.ToInt16(p) == 160 && p[2] == caster.Uid && p[3] == slot) == 1, "stealth/sprint acknowledges caster once");
            check(peer.Packets.All(p => BitConverter.ToInt16(p) != 160), "teammate does not activate own skill slot");
            var effects = peer.Packets.Where(p => BitConverter.ToInt16(p) == 162).ToArray();
            check(effects.Length == 1 && effects.All(p => p[6] == caster.Uid && p[7] == caster.Uid), "peer stealth/sprint targets caster only");
            check(peer.Packets.Where(p => BitConverter.ToInt16(p) == 155).All(p => p[2] == caster.Uid), "ability close never targets teammate");
            var before = peer.Packets.Count;
            await peer.Channel.SendPacket160GameSkillActivateAsync(caster.Uid, slot, "foreign-caster-test");
            check(peer.Packets.Count == before, "activation sender rejects a foreign owner");
        }
        manager.RemoveRoom(room.RoomId);
    }
}
