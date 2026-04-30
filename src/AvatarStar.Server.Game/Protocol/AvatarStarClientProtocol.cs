using System.Text;

namespace AvatarStar.Server.Game;

internal static class AvatarStarClientProtocol
{
    public const int PracticeRoomSlotCount = 24;
    public const int LobbyRoomListMaxCount = 8;

    public const byte LobbyRoomListChanged = 51;
    public const byte LobbyRoomListRefreshResult = 36;
    public const byte LobbyRoomCreated = 54;
    public const byte LobbyChannelConnectResult = 3;

    public const short ChannelRoomInfoChanged = 2;
    public const short ChannelRoomOptionChanged = 4;
    public const short ChannelRoomEnterResult = 16;
    public const short ChannelRoomClientListSync = 18;
    public const short ChannelRoomInfoSync = 19;
    public const short ChannelSlotChanged = 26;

    private const int FullRoomDescriptorMask = 0x1FFFE;
    public readonly record struct LobbyCreateRoomPayload(
        string RoomName,
        bool UsePassword,
        string Password,
        long LevelId,
        byte GameType,
        byte MaxClientNum,
        short SpawnTime,
        bool JoinHalfWay,
        bool CheckBalance,
        byte CanBeWatched,
        bool Matching,
        string MapName,
        byte EnterLimit);

    public readonly record struct ChannelRoomEnterPayload(
        int RoomId,
        string Password,
        int Token,
        bool HasCapability,
        byte Capability);

    public readonly record struct ChannelRoomOptionChangePayload(
        string RoomName,
        bool UsePassword,
        string Password,
        long LevelId,
        byte GameType,
        byte MaxClientNum,
        short SpawnTime,
        bool JoinHalfWay,
        bool CheckBalance,
        byte CanBeWatched,
        bool Matching,
        string MapName,
        byte EnterLimit);

    public static bool TryReadLobbyCreateRoom(PacketReader reader, out LobbyCreateRoomPayload payload)
    {
        payload = default;

        if (!reader.TryReadString(out var roomName) ||
            !reader.TryReadByte(out var usePasswordByte) ||
            !reader.TryReadString(out var password) ||
            !reader.TryReadLong(out var levelId) ||
            !reader.TryReadByte(out var gameType) ||
            !reader.TryReadByte(out var maxClientNum) ||
            !reader.TryReadShort(out var spawnTime) ||
            !reader.TryReadByte(out var joinHalfWayByte) ||
            !reader.TryReadByte(out var checkBalanceByte) ||
            !reader.TryReadByte(out var canBeWatchedByte))
        {
            return false;
        }

        // The create-room tail is 6 bytes in the current client. The first byte
        // is not Lobby RoomInfo.Matching; setting Matching=true makes Lua hide
        // the room from the public list. Consume the tail but keep the room
        // visible unless a later, verified field mapping says otherwise.
        _ = reader.TryReadByte(out _);
        _ = reader.TryReadString(out _);
        var enterLimit = reader.TryReadByte(out var enterLimitByte) ? enterLimitByte : (byte)0;

        payload = new LobbyCreateRoomPayload(
            roomName,
            usePasswordByte != 0,
            password,
            levelId,
            gameType,
            maxClientNum,
            spawnTime,
            joinHalfWayByte != 0,
            checkBalanceByte != 0,
            canBeWatchedByte,
            false,
            string.Empty,
            enterLimit);
        return true;
    }

    public static bool TryReadChannelRoomEnter(PacketReader reader, out ChannelRoomEnterPayload payload)
    {
        payload = default;

        if (!reader.TryReadInt(out var roomId) ||
            !reader.TryReadString(out var password) ||
            !reader.TryReadInt(out var token))
        {
            return false;
        }

        var hasCapability = reader.TryReadByte(out var capability);
        payload = new ChannelRoomEnterPayload(roomId, password, token, hasCapability, capability);
        return true;
    }

    public static bool TryReadChannelRoomOptionChange(
        PacketReader reader,
        out ChannelRoomOptionChangePayload payload)
    {
        payload = default;

        if (!reader.TryReadString(out var roomName) ||
            !reader.TryReadByte(out var usePasswordByte) ||
            !reader.TryReadString(out var password) ||
            !reader.TryReadLong(out var levelId) ||
            !reader.TryReadByte(out var gameType) ||
            !reader.TryReadByte(out var maxClientNum) ||
            !reader.TryReadShort(out var spawnTime) ||
            !reader.TryReadByte(out var joinHalfWayByte) ||
            !reader.TryReadByte(out var checkBalanceByte) ||
            !reader.TryReadByte(out var canBeWatchedByte) ||
            !reader.TryReadByte(out var matchingByte) ||
            !reader.TryReadString(out var mapName) ||
            !reader.TryReadByte(out var enterLimit))
        {
            return false;
        }

        payload = new ChannelRoomOptionChangePayload(
            roomName,
            usePasswordByte != 0,
            password,
            levelId,
            gameType,
            maxClientNum,
            spawnTime,
            joinHalfWayByte != 0,
            checkBalanceByte != 0,
            canBeWatchedByte,
            matchingByte != 0,
            mapName,
            enterLimit);
        return true;
    }

    public static void WriteLobbyRoomCreated(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession? room,
        int resultCode)
    {
        writer.WriteByte(LobbyRoomCreated);
        writer.WriteInt(resultCode);
        writer.WriteInt(room?.RoomUid ?? 0);
        writer.WriteByte(0);
    }

    public static void WriteLobbyChannelConnectResult(
        PacketWriter writer,
        int resultCode,
        string host,
        int port)
    {
        writer.WriteByte(LobbyChannelConnectResult);
        writer.WriteInt(resultCode);

        if (resultCode == 0)
        {
            // IDA Lobby_ConnectChannel_SelectTcpOrUdp reads: int result, int reserved, u16 port, string host.
            writer.WriteInt(0);
            writer.WriteShort((short)port);
            writer.WriteString(host);
        }
    }

    public static void WriteLobbyRoomListChanged(
        PacketWriter writer,
        IReadOnlyList<PracticeRoomManager.PracticeRoomLobbyEntry> rooms,
        int maxCount = LobbyRoomListMaxCount)
    {
        writer.WriteByte(LobbyRoomListChanged);

        foreach (var room in rooms.Take(Math.Max(0, maxCount)))
        {
            writer.WriteInt(room.RoomUid);
            writer.WriteByte(room.RoomState);
            WriteSizedString(writer, room.RoomName, 64);
            WriteSizedString(writer, room.MapName, 256);
            writer.WriteByte(room.GameType);
            WriteSizedString(writer, room.HostName, 64);
            writer.WriteByte(room.UsePassword ? (byte)1 : (byte)0);
            writer.WriteByte(room.MaxClientNum);
            writer.WriteByte(room.CurrentClientNum);
            writer.WriteLong(room.LevelId);
            writer.WriteByte(room.JoinHalfWay ? (byte)1 : (byte)0);
            writer.WriteByte(room.CheckBalance ? (byte)1 : (byte)0);
            writer.WriteByte(room.Matching ? (byte)1 : (byte)0);
            writer.WriteByte(room.CanBeWatched);
            writer.WriteByte(0);
            WriteSizedString(writer, room.Password, 128);
            writer.WriteByte(room.EnterLimit);
        }

        writer.WriteInt(0);
    }

    public static void WriteChannelRoomEnterResult(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession? room,
        int resultCode)
    {
        writer.WriteShort(ChannelRoomEnterResult);
        writer.WriteInt(resultCode);
        writer.WriteByte(0);

        if (resultCode == 0 && room is not null)
        {
            writer.WriteInt(room.ContextId);
            WritePracticeRoomDescriptorFull(writer, room, includeMode6ExtraTail: true);
        }
    }

    public static void WriteChannelRoomInfoSync(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room)
    {
        writer.WriteShort(ChannelRoomInfoSync);
        writer.WriteInt(room.ContextId);
        WritePracticeRoomDescriptorFull(writer, room, includeMode6ExtraTail: false);
    }

    public static int WriteChannelRoomClientListSync(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room)
    {
        writer.WriteShort(ChannelRoomClientListSync);

        var populatedSlotCount = 0;
        for (var slotIndex = 1; slotIndex <= PracticeRoomSlotCount; slotIndex++)
        {
            var member = room.Members.FirstOrDefault(m => m.SlotIndex == slotIndex);
            WritePracticeRoomSlot(writer, (byte)slotIndex, member);
            if (member is not null)
            {
                populatedSlotCount++;
            }
        }

        return populatedSlotCount;
    }

    public static void WriteChannelRoomInfoChanged(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room)
    {
        writer.WriteShort(ChannelRoomInfoChanged);
        writer.WriteInt(room.ContextId);
        WritePracticeRoomDescriptorDelta(writer, room, includeMode6ExtraTail: false);
    }

    public static void WriteChannelRoomOptionChanged(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room)
    {
        writer.WriteShort(ChannelRoomOptionChanged);
        writer.WriteInt(room.ContextId);
        WritePracticeRoomDescriptorDelta(writer, room, includeMode6ExtraTail: true);
    }

    public static void WriteChannelSlotChanged(
        PacketWriter writer,
        long characterId,
        byte slotIndex)
    {
        writer.WriteShort(ChannelSlotChanged);
        writer.WriteLong(characterId);
        writer.WriteByte(slotIndex);
        writer.WriteByte(0);
    }

    public static void WritePracticeRoomDescriptorFull(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room,
        bool includeMode6ExtraTail)
    {
        writer.WriteLong(room.HostCharacterId);
        WritePracticeRoomDescriptorBody(writer, room, includeMode6ExtraTail);
    }

    public static void WritePracticeRoomDescriptorDelta(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room,
        bool includeMode6ExtraTail)
    {
        writer.WriteLong(room.HostCharacterId);
        writer.WriteInt(FullRoomDescriptorMask);
        WritePracticeRoomDescriptorBody(writer, room, includeMode6ExtraTail);
    }

    private static void WritePracticeRoomDescriptorBody(
        PacketWriter writer,
        PracticeRoomManager.PracticeRoomSession room,
        bool includeMode6ExtraTail)
    {
        writer.WriteByte(room.RoomState);
        WriteSizedString(writer, room.RoomName, 64);
        WriteSizedString(writer, room.MapName, 256);
        writer.WriteByte(room.GameType);
        WriteSizedString(writer, room.HostName, 64);
        writer.WriteByte(room.UsePassword ? (byte)1 : (byte)0);
        writer.WriteByte(room.MaxClientNum);
        writer.WriteByte(room.CurrentClientNum);
        writer.WriteLong(room.LevelId);
        writer.WriteByte(room.JoinHalfWay ? (byte)1 : (byte)0);
        writer.WriteByte(room.CheckBalance ? (byte)1 : (byte)0);
        writer.WriteByte(room.Matching ? (byte)1 : (byte)0);

        // IDA Client_RoomContext_ReadDescriptor reads two u8 fields after Matching
        // before Password(128). Lua currently exposes only CanBeWatched, so the
        // second field stays reserved until its UI/native name is identified.
        writer.WriteByte(room.CanBeWatched);
        writer.WriteByte(0);

        WriteSizedString(writer, room.Password, 128);
        writer.WriteByte(room.EnterLimit);

        if (includeMode6ExtraTail)
        {
            WriteSizedString(writer, string.Empty, 64);
        }
    }

    private static void WritePracticeRoomSlot(
        PacketWriter writer,
        byte slotIndex,
        PracticeRoomManager.PracticeRoomMember? member)
    {
        writer.WriteByte(slotIndex);
        writer.WriteByte(0);
        writer.WriteByte(0);

        if (member is null)
        {
            writer.WriteLong(0);
            return;
        }

        writer.WriteLong(member.CharacterId);
        writer.WriteByte(member.Career);
        WriteSizedString(writer, member.CharacterName, 64);
        writer.WriteByte(member.Ready ? (byte)1 : (byte)0);
        writer.WriteByte(member.InGame ? (byte)1 : (byte)0);
        writer.WriteByte(member.Host ? (byte)1 : (byte)0);
        writer.WriteInt(member.Level);
        writer.WriteByte(member.RankType);
        writer.WriteInt(member.RankLevel);
        writer.WriteByte(member.VipLevel);
        writer.WriteInt(member.ExtraValue0);
        writer.WriteInt(member.ExtraValue1);
    }

    private static void WriteSizedString(PacketWriter writer, string value, int maxBytes)
    {
        if (string.IsNullOrEmpty(value))
        {
            writer.WriteInt(0);
            return;
        }

        var encoded = Encoding.UTF8.GetBytes(value);
        if (encoded.Length > maxBytes)
        {
            encoded = encoded.AsSpan(0, maxBytes).ToArray();
        }

        writer.WriteInt(encoded.Length);
        writer.WriteRaw(encoded);
    }

}
