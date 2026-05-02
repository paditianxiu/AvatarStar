using System.Net;
using System.Text.Json;
using Serilog;

namespace AvatarStar.Server.Game;

internal sealed class PracticeRoomManager
{
    private const byte DefaultHostSlotIndex = 1;
    private const byte MaxRoomSlotIndex = 24;
    private const byte GameTeamBlue = 1;
    private const byte GameTeamSpectator = 2;
    private const int DefaultGamePlayerHealth = 1000;
    private const int GameAutoRespawnDelayMilliseconds = 3000;
    private const float MovementRawCoordinateScale = 100f;
    private const float ActionPoseRawCoordinateScale = 256f;
    private const float FacingRawAngleScale = 8192f;
    private const float ShootVectorEpsilon = 0.001f;
    private const string LobbyLevelInfoConfigFileName = "lobby_levelinfo.json";

    private static readonly Lazy<IReadOnlyList<BattleLevelChoice>> RandomBattleLevelChoices = new(LoadRandomBattleLevelChoices);
    private static readonly BattleLevelChoice[] FallbackRandomBattleLevels =
    [
        new(1, "id_datalist_Belfry_Square_level1"),
        new(2, "id_datalist_Hero_Relics_level2"),
        new(5, "id_datalist_Hill_Top_Old_Town_level5"),
        new(7, "id_datalist_Shipwreck_Island_level7"),
        new(8, "id_datalist_Windy_Old_Town_level8"),
        new(10, "id_datalist_Night_Town_level10"),
        new(13, "id_datalist_Cape_of_Aegean_level13"),
        new(16, "id_datalist_City_of_Aegean_level16"),
        new(17, "id_datalist_Space_Battlefield_level17"),
        new(26, "id_datalist_Hazard_Town_level26"),
        new(27, "id_datalist_Aegean_Courtyard_level27")
    ];

    private readonly object _lock = new();
    private readonly Dictionary<int, PracticeRoomSession> _roomsById = new();
    private readonly Dictionary<int, int> _roomIdByChannelToken = new();
    private readonly Dictionary<long, int> _roomIdByHostCharacterId = new();
    private readonly Dictionary<int, HashSet<PracticeRoomChannelProtocol>> _roomChannelsByRoomId = new();
    private readonly Dictionary<int, Dictionary<PracticeRoomChannelProtocol, long>> _roomCharacterByChannelByRoomId = new();
    private readonly Dictionary<int, Dictionary<PracticeRoomChannelProtocol, byte>> _gameChannelsByRoomId = new();
    private readonly Dictionary<int, Dictionary<byte, GamePlayerRuntime>> _gamePlayersByRoomId = new();
    private readonly Dictionary<int, Dictionary<byte, GameMovementDelta>> _gameMovementByRoomId = new();
    private readonly Dictionary<int, HashSet<byte>> _retiredGameUidsByRoomId = new();
    private readonly Dictionary<PendingChannelJoinKey, Queue<PendingChannelJoin>> _pendingChannelJoins = new();
    private readonly Dictionary<long, GameClient> _gameClientsByCharacterId = new();

    private int _nextRoomId = 1;
    private int _nextChannelToken = 1;
    private int _nextContextId = 1;
    private int _nextTransientCharacterId = 1_000_000;
    private readonly string? _configuredChannelHost;

    public PracticeRoomManager()
    {
        ChannelPort = ParsePositiveInt("AS_CHANNEL_PORT", 9533);
        _configuredChannelHost = Environment.GetEnvironmentVariable("AS_CHANNEL_HOST");
    }

    public int ChannelPort { get; }

    public void RegisterGameClient(long characterId, GameClient client)
    {
        if (characterId == 0)
        {
            return;
        }

        lock (_lock)
        {
            _gameClientsByCharacterId[characterId] = client;
        }
    }

    public void UnregisterGameClient(long characterId, GameClient client)
    {
        if (characterId == 0)
        {
            return;
        }

        lock (_lock)
        {
            if (_gameClientsByCharacterId.TryGetValue(characterId, out var existing) &&
                ReferenceEquals(existing, client))
            {
                _gameClientsByCharacterId.Remove(characterId);
            }
        }
    }

    public string ResolveChannelHost(IPAddress lobbyLocalAddress)
    {
        if (!string.IsNullOrWhiteSpace(_configuredChannelHost))
        {
            return _configuredChannelHost!;
        }

        if (IPAddress.IsLoopback(lobbyLocalAddress) || Equals(lobbyLocalAddress, IPAddress.Any))
        {
            return IPAddress.Loopback.ToString();
        }

        return lobbyLocalAddress.ToString();
    }

    public PracticeRoomSession CreateOrReplaceRoom(PracticeRoomCreateRequest request)
    {
        lock (_lock)
        {
            if (_roomIdByHostCharacterId.TryGetValue(request.HostCharacterId, out var previousRoomId))
            {
                RemoveRoomNoLock(previousRoomId);
            }

            var roomId = _nextRoomId++;
            var channelToken = _nextChannelToken++;
            var roomUid = (channelToken << 16) | (roomId & 0xFFFF);

            var room = new PracticeRoomSession(
                roomId: roomId,
                roomUid: roomUid,
                channelToken: channelToken,
                hostCharacterId: request.HostCharacterId,
                hostName: request.HostName,
                roomName: request.RoomName,
                mapName: request.MapName,
                usePassword: request.UsePassword,
                password: request.Password,
                levelId: request.LevelId,
                gameType: request.GameType,
                maxClientNum: request.MaxClientNum,
                spawnTime: request.SpawnTime,
                joinHalfWay: request.JoinHalfWay,
                checkBalance: request.CheckBalance,
                canBeWatched: request.CanBeWatched,
                matching: request.Matching,
                enterLimit: request.EnterLimit,
                hostLevel: request.HostLevel,
                hostOccupation: request.HostOccupation,
                hostRankType: request.HostRankType,
                hostRankLevel: request.HostRankLevel,
                hostVipLevel: request.HostVipLevel);

            _roomsById[roomId] = room;
            _roomIdByChannelToken[channelToken] = roomId;
            _roomIdByHostCharacterId[request.HostCharacterId] = roomId;
            room.RefreshCurrentClientNum();
            return room;
        }
    }

    public IReadOnlyList<PracticeRoomLobbyEntry> ListLobbyRooms(int maxCount = AvatarStarClientProtocol.LobbyRoomListMaxCount)
    {
        lock (_lock)
        {
            return _roomsById.Values
                .Where(room => room.RoomState == 1 || room.JoinHalfWay)
                .OrderBy(room => room.RoomId)
                .Take(Math.Max(0, maxCount))
                .Select(room =>
                {
                    room.RefreshCurrentClientNum();
                    return new PracticeRoomLobbyEntry(
                        RoomUid: room.RoomUid,
                        RoomState: room.RoomState,
                        RoomName: room.RoomName,
                        MapName: room.MapName,
                        HostName: room.HostName,
                        UsePassword: room.UsePassword,
                        Password: room.Password,
                        LevelId: room.LevelId,
                        HostCharacterId: room.HostCharacterId,
                        GameType: room.GameType,
                        MaxClientNum: room.MaxClientNum,
                        CurrentClientNum: room.CurrentClientNum,
                        JoinHalfWay: room.JoinHalfWay,
                        CheckBalance: room.CheckBalance,
                        Matching: room.Matching,
                        CanBeWatched: room.CanBeWatched,
                        EnterLimit: room.EnterLimit);
                })
                .ToArray();
        }
    }

    public bool TryGetByChannelToken(int channelToken, out PracticeRoomSession room)
    {
        lock (_lock)
        {
            if (_roomIdByChannelToken.TryGetValue(channelToken, out var roomId) &&
                _roomsById.TryGetValue(roomId, out room!))
            {
                return true;
            }

            room = null!;
            return false;
        }
    }

    public bool TryGetByRoomUid(int roomUid, out PracticeRoomSession room)
    {
        lock (_lock)
        {
            var roomId = roomUid & 0xFFFF;
            if (_roomsById.TryGetValue(roomId, out room!) && room.RoomUid == roomUid)
            {
                return true;
            }

            room = null!;
            return false;
        }
    }

    public void RegisterPendingChannelJoin(
        int channelToken,
        IPAddress remoteAddress,
        PracticeRoomEnterRequest request)
    {
        lock (_lock)
        {
            RemoveExpiredPendingChannelJoinsNoLock(DateTimeOffset.UtcNow);

            if (!_roomIdByChannelToken.TryGetValue(channelToken, out var roomId))
            {
                return;
            }

            var key = new PendingChannelJoinKey(channelToken, NormalizeAddress(remoteAddress));
            if (!_pendingChannelJoins.TryGetValue(key, out var queue))
            {
                queue = new Queue<PendingChannelJoin>();
                _pendingChannelJoins[key] = queue;
            }

            queue.Enqueue(new PendingChannelJoin(
                roomId,
                request,
                DateTimeOffset.UtcNow.AddSeconds(30)));
        }
    }

    public bool TryConsumePendingChannelJoin(
        int channelToken,
        IPAddress remoteAddress,
        int roomId,
        out PracticeRoomEnterRequest request)
    {
        lock (_lock)
        {
            RemoveExpiredPendingChannelJoinsNoLock(DateTimeOffset.UtcNow);

            var key = new PendingChannelJoinKey(channelToken, NormalizeAddress(remoteAddress));
            if (_pendingChannelJoins.TryGetValue(key, out var queue))
            {
                while (queue.Count > 0)
                {
                    var pending = queue.Dequeue();
                    if (queue.Count == 0)
                    {
                        _pendingChannelJoins.Remove(key);
                    }

                    if (pending.RoomId == roomId)
                    {
                        request = pending.Request;
                        return true;
                    }
                }
            }

            request = default;
            return false;
        }
    }

    public bool TryGetByRoomId(int roomId, out PracticeRoomSession room)
    {
        lock (_lock)
        {
            return _roomsById.TryGetValue(roomId, out room!);
        }
    }

    public bool TryLeaveRoom(
        int roomId,
        long characterId,
        out PracticeRoomSession? room,
        out bool roomRemoved)
    {
        lock (_lock)
        {
            roomRemoved = false;
            if (!_roomsById.TryGetValue(roomId, out var currentRoom))
            {
                room = null;
                return false;
            }

            room = currentRoom;
            if (characterId == 0 || characterId == currentRoom.HostCharacterId)
            {
                RemoveRoomNoLock(roomId);
                roomRemoved = true;
                return true;
            }

            if (IsCharacterConnectedToRoomNoLock(roomId, characterId))
            {
                currentRoom.RefreshCurrentClientNum();
                return true;
            }

            currentRoom.RemoveMember(characterId);
            currentRoom.RefreshCurrentClientNum();
            return true;
        }
    }

    public int AllocateTransientCharacterId()
    {
        lock (_lock)
        {
            return _nextTransientCharacterId++;
        }
    }

    public bool TryEnterRoom(
        int roomId,
        string password,
        PracticeRoomEnterRequest request,
        out PracticeRoomSession room,
        out int resultCode)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room!))
            {
                resultCode = 1;
                return false;
            }

            if (room.UsePassword && !string.Equals(room.Password, password, StringComparison.Ordinal))
            {
                resultCode = 2;
                return false;
            }

            room.EnsureHostMember(room.GetHostSlotIndexOrDefault(DefaultHostSlotIndex));
            if (!room.TryUpsertMember(request, out _))
            {
                resultCode = 3;
                return false;
            }

            if (room.ContextId == 0)
            {
                room.ContextId = _nextContextId++;
            }

            room.RefreshCurrentClientNum();
            resultCode = 0;
            return true;
        }
    }

    public bool TryUpdateRoomOptions(int roomId, PracticeRoomUpdateRequest request, out PracticeRoomSession room, out int resultCode)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room!))
            {
                resultCode = 1;
                return false;
            }

            room.RoomName = request.RoomName;
            room.UsePassword = request.UsePassword;
            room.Password = request.Password;
            room.LevelId = request.LevelId;
            room.GameType = request.GameType;
            room.MaxClientNum = request.MaxClientNum;
            room.SpawnTime = request.SpawnTime;
            room.JoinHalfWay = request.JoinHalfWay;
            room.CheckBalance = request.CheckBalance;
            room.Matching = request.Matching;
            room.CanBeWatched = request.CanBeWatched;
            room.EnterLimit = request.EnterLimit;
            if (!string.IsNullOrWhiteSpace(request.MapName))
            {
                room.MapName = request.MapName;
            }

            room.EnsureHostMember(room.GetHostSlotIndexOrDefault(DefaultHostSlotIndex));
            room.RefreshCurrentClientNum();

            resultCode = 0;
            return true;
        }
    }

    public void RemoveRoom(int roomId)
    {
        lock (_lock)
        {
            RemoveRoomNoLock(roomId);
        }
    }

    public bool TryMoveMemberSlot(int roomId, long characterId, byte slotIndex, out PracticeRoomSession room, out int resultCode)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room!))
            {
                resultCode = 1;
                return false;
            }

            if (slotIndex is 0 or > 24)
            {
                resultCode = 2;
                return false;
            }

            if (characterId <= 0)
            {
                resultCode = 1;
                return false;
            }

            room.EnsureHostMember(room.GetHostSlotIndexOrDefault(DefaultHostSlotIndex));
            var member = room.Members.FirstOrDefault(member => member.CharacterId == characterId);
            if (member is null)
            {
                resultCode = 1;
                return false;
            }

            if (room.Members.Any(candidate =>
                    candidate.SlotIndex == slotIndex &&
                    candidate.CharacterId != characterId))
            {
                resultCode = 3;
                return false;
            }

            member.SlotIndex = slotIndex;
            room.RefreshCurrentClientNum();
            resultCode = 0;
            return true;
        }
    }

    public bool TrySetMemberReady(int roomId, long characterId, bool ready, out PracticeRoomSession room, out int resultCode)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room!))
            {
                resultCode = 1;
                return false;
            }

            var currentRoom = room;
            currentRoom.EnsureHostMember(currentRoom.GetHostSlotIndexOrDefault(DefaultHostSlotIndex));
            var member = currentRoom.Members.FirstOrDefault(member => member.CharacterId == characterId);
            if (member is null)
            {
                resultCode = 1;
                return false;
            }

            member.Ready = ready;
            currentRoom.RefreshCurrentClientNum();
            resultCode = 0;
            return true;
        }
    }

    public bool TryStartGame(int roomId, out PracticeRoomSession room, out int resultCode)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room!))
            {
                resultCode = 1;
                return false;
            }

            room.EnsureHostMember(room.GetHostSlotIndexOrDefault(DefaultHostSlotIndex));
            AssignRandomBattleLevelNoLock(room);
            room.RoomState = 2;
            foreach (var member in room.Members)
            {
                if (member.CharacterId != 0)
                {
                    member.Ready = true;
                    member.InGame = true;
                }
            }

            room.RefreshCurrentClientNum();
            resultCode = 0;
            return true;
        }
    }

    public bool TryEnterGame(int roomId, long characterId, out PracticeRoomSession room, out int resultCode)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room!))
            {
                resultCode = 1;
                return false;
            }

            if (room.RoomState != 2)
            {
                resultCode = 1;
                return false;
            }

            room.EnsureHostMember(room.GetHostSlotIndexOrDefault(DefaultHostSlotIndex));
            AssignRandomBattleLevelNoLock(room);
            var gameMember = room.Members.FirstOrDefault(member => member.CharacterId == characterId);
            if (gameMember is null)
            {
                resultCode = 1;
                return false;
            }

            gameMember.Ready = true;
            gameMember.InGame = true;
            room.RefreshCurrentClientNum();
            resultCode = 0;
            return true;
        }
    }

    public byte RegisterGameChannel(
        int roomId,
        PracticeRoomChannelProtocol channel,
        long characterId,
        string characterName)
    {
        lock (_lock)
        {
            if (!_roomsById.ContainsKey(roomId))
            {
                return 1;
            }

            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                channels = new Dictionary<PracticeRoomChannelProtocol, byte>();
                _gameChannelsByRoomId[roomId] = channels;
            }

            var room = _roomsById[roomId];
            if (channels.TryGetValue(channel, out var existingUid))
            {
                UpsertGamePlayerNoLock(roomId, existingUid, characterId, characterName);
                return existingUid;
            }

            var used = channels.Values.ToHashSet();
            _retiredGameUidsByRoomId.TryGetValue(roomId, out var retiredUids);
            var preferredUid = ResolvePreferredGameUidNoLock(room, characterId);
            if (preferredUid != 0 &&
                !used.Contains(preferredUid) &&
                retiredUids?.Contains(preferredUid) != true)
            {
                channels[channel] = preferredUid;
                UpsertGamePlayerNoLock(roomId, preferredUid, characterId, characterName);
                return preferredUid;
            }

            for (var uid = 1; uid <= byte.MaxValue; uid++)
            {
                var candidate = (byte)uid;
                if (used.Contains(candidate))
                {
                    continue;
                }

                if (retiredUids?.Contains(candidate) == true)
                {
                    continue;
                }

                channels[channel] = candidate;
                UpsertGamePlayerNoLock(roomId, candidate, characterId, characterName);
                return candidate;
            }

            for (var uid = 1; uid <= byte.MaxValue; uid++)
            {
                var candidate = (byte)uid;
                if (used.Contains(candidate))
                {
                    continue;
                }

                channels[channel] = candidate;
                UpsertGamePlayerNoLock(roomId, candidate, characterId, characterName);
                return candidate;
            }

            return 1;
        }
    }

    public IReadOnlyList<GamePlayerSnapshot> ListGamePlayers(int roomId)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out var room))
            {
                return [];
            }

            _gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid);
            var playersByCharacterId = playersByUid?.Values
                .Where(player => player.CharacterId != 0)
                .GroupBy(player => player.CharacterId)
                .ToDictionary(group => group.Key, group => group.First());

            var usedUids = new HashSet<byte>();
            var snapshots = new List<GamePlayerSnapshot>();
            foreach (var member in OrderedGameMembers(room))
            {
                if (member.CharacterId == 0)
                {
                    continue;
                }

                GamePlayerRuntime? runtime = null;
                playersByCharacterId?.TryGetValue(member.CharacterId, out runtime);

                var uid = runtime?.Uid ?? ResolvePreferredGameUidNoLock(room, member.CharacterId);
                if (uid == 0 || usedUids.Contains(uid))
                {
                    uid = AllocateFirstFreeGameUid(usedUids);
                }

                usedUids.Add(uid);
                snapshots.Add(new GamePlayerSnapshot(
                    uid,
                    member.CharacterId,
                    string.IsNullOrWhiteSpace(runtime?.CharacterName) ? member.CharacterName : runtime!.CharacterName,
                    runtime?.LastPosition));
            }

            return snapshots;
        }
    }

    public bool HasRoomChannel(int roomId)
    {
        lock (_lock)
        {
            return _roomChannelsByRoomId.TryGetValue(roomId, out var channels) && channels.Count > 0;
        }
    }

    public void RegisterRoomChannel(int roomId, PracticeRoomChannelProtocol channel, long characterId)
    {
        lock (_lock)
        {
            if (!_roomsById.ContainsKey(roomId))
            {
                return;
            }

            if (!_roomChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                channels = [];
                _roomChannelsByRoomId[roomId] = channels;
            }

            channels.Add(channel);

            if (!_roomCharacterByChannelByRoomId.TryGetValue(roomId, out var charactersByChannel))
            {
                charactersByChannel = new Dictionary<PracticeRoomChannelProtocol, long>();
                _roomCharacterByChannelByRoomId[roomId] = charactersByChannel;
            }

            charactersByChannel[channel] = characterId;
        }
    }

    public void UnregisterRoomChannel(int roomId, PracticeRoomChannelProtocol channel)
    {
        lock (_lock)
        {
            if (!_roomChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return;
            }

            channels.Remove(channel);
            if (channels.Count == 0)
            {
                _roomChannelsByRoomId.Remove(roomId);
            }

            if (_roomCharacterByChannelByRoomId.TryGetValue(roomId, out var charactersByChannel))
            {
                charactersByChannel.Remove(channel);
                if (charactersByChannel.Count == 0)
                {
                    _roomCharacterByChannelByRoomId.Remove(roomId);
                }
            }
        }
    }

    public async Task<int> BroadcastRoomSnapshotAsync(int roomId)
    {
        var targets = GetRoomChannelTargets(roomId, out var room);
        if (room is null)
        {
            return 0;
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendRoomSnapshotAsync(room);
                sent++;
            }
            catch
            {
                UnregisterRoomChannel(roomId, target);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGameStartAsync(int roomId, PracticeRoomChannelProtocol except)
    {
        var targets = GetRoomChannelTargets(roomId, out var room)
            .Where(target => !ReferenceEquals(target, except))
            .ToArray();
        if (room is null)
        {
            return 0;
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendRemoteGameStartAsync(room);
                sent++;
            }
            catch
            {
                UnregisterRoomChannel(roomId, target);
            }
        }

        return sent;
    }

    public bool UnregisterGameChannel(int roomId, PracticeRoomChannelProtocol channel, out byte removedUid)
    {
        lock (_lock)
        {
            return UnregisterGameChannelNoLock(roomId, channel, out removedUid);
        }
    }

    public bool TryLeaveGame(
        int roomId,
        long characterId,
        PracticeRoomChannelProtocol channel,
        out PracticeRoomSession room,
        out byte removedUid)
    {
        lock (_lock)
        {
            UnregisterGameChannelNoLock(roomId, channel, out removedUid);
            if (!_roomsById.TryGetValue(roomId, out room!))
            {
                return false;
            }

            var member = room.Members.FirstOrDefault(member => member.CharacterId == characterId);
            if (member is not null && !IsCharacterConnectedToGameNoLock(roomId, characterId))
            {
                member.Ready = false;
                member.InGame = false;
            }

            room.RefreshCurrentClientNum();
            return true;
        }
    }

    public async Task<int> SendKnifeRearmForLobbyRawBlobAsync(long characterId, string trigger)
    {
        if (characterId == 0)
        {
            return 0;
        }

        int roomId;
        PracticeRoomChannelProtocol[] targets;
        lock (_lock)
        {
            if (!TryResolveRoomIdByCharacterNoLock(characterId, out roomId) ||
                !_gameChannelsByRoomId.TryGetValue(roomId, out var channels) ||
                !_roomCharacterByChannelByRoomId.TryGetValue(roomId, out var charactersByChannel))
            {
                return 0;
            }

            targets = channels.Keys
                .Where(channel =>
                    charactersByChannel.TryGetValue(channel, out var channelCharacterId) &&
                    channelCharacterId == characterId)
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                sent += await target.SendKnifeWeaponRearmAsync(trigger);
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        if (sent > 0)
        {
            Log.Information(
                "Practice room packet40 raw blob knife rearm: characterId={CharacterId} roomId={RoomId} channelCount={ChannelCount} itemCount={ItemCount}",
                characterId,
                roomId,
                targets.Length,
                sent);
        }

        return sent;
    }

    public async Task<int> BroadcastLobbyRawBlobAsync(
        long sourceCharacterId,
        byte[] payload,
        string trigger)
    {
        if (sourceCharacterId == 0 || payload.Length == 0)
        {
            return 0;
        }

        int roomId;
        GameClient[] targets;
        lock (_lock)
        {
            if (!TryResolveRoomIdByCharacterNoLock(sourceCharacterId, out roomId) ||
                !_roomsById.TryGetValue(roomId, out var room))
            {
                return 0;
            }

            targets = room.Members
                .Where(member => member.CharacterId != sourceCharacterId)
                .Select(member => _gameClientsByCharacterId.TryGetValue(member.CharacterId, out var client)
                    ? client
                    : null)
                .Where(client => client is not null)
                .Cast<GameClient>()
                .Distinct()
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket40RawBlobAsync(payload, trigger);
                sent++;
            }
            catch
            {
            }
        }

        if (sent > 0)
        {
            Log.Information(
                "Practice room packet40 raw blob broadcast: sourceCharacterId={CharacterId} roomId={RoomId} payloadBytes={PayloadBytes} targetCount={TargetCount} sent={Sent} trigger={Trigger}",
                sourceCharacterId,
                roomId,
                payload.Length,
                targets.Length,
                sent,
                trigger);
        }

        return sent;
    }

    public void UpdateGameMovement(int roomId, GameMovementDelta movement)
    {
        lock (_lock)
        {
            if (!_roomsById.ContainsKey(roomId))
            {
                return;
            }

            if (!_gameMovementByRoomId.TryGetValue(roomId, out var movementByUid))
            {
                movementByUid = new Dictionary<byte, GameMovementDelta>();
                _gameMovementByRoomId[roomId] = movementByUid;
            }

            movementByUid[movement.Uid] = movement;
        }
    }

    public void UpdateGamePosition(int roomId, byte uid, GamePosition position)
    {
        lock (_lock)
        {
            if (!_roomsById.ContainsKey(roomId))
            {
                return;
            }

            if (!_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) ||
                !playersByUid.TryGetValue(uid, out var player))
            {
                UpsertGamePlayerNoLock(roomId, uid, 0, $"uid:{uid}");
                player = _gamePlayersByRoomId[roomId][uid];
            }

            player.LastPosition = position;
        }
    }

    public void UpdateGamePlayerState(int roomId, byte uid, byte teamId, int maxHealth)
    {
        lock (_lock)
        {
            if (!_roomsById.ContainsKey(roomId))
            {
                return;
            }

            if (!_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) ||
                !playersByUid.TryGetValue(uid, out var player))
            {
                UpsertGamePlayerNoLock(roomId, uid, 0, $"uid:{uid}");
                player = _gamePlayersByRoomId[roomId][uid];
            }

            player.TeamId = teamId;
            player.MaxHealth = Math.Max(1, maxHealth);
            if (player.CurrentHealth <= 0 || player.CurrentHealth > player.MaxHealth)
            {
                player.CurrentHealth = player.MaxHealth;
            }
        }
    }

    public bool TryFindGamePlayerPositionByName(
        int roomId,
        string characterName,
        out GamePlayerPosition playerPosition)
    {
        lock (_lock)
        {
            if (_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid))
            {
                foreach (var player in playersByUid.Values)
                {
                    if (player.LastPosition is null)
                    {
                        continue;
                    }

                    if (string.Equals(player.CharacterName, characterName, StringComparison.OrdinalIgnoreCase))
                    {
                        playerPosition = new GamePlayerPosition(
                            player.Uid,
                            player.CharacterId,
                            player.CharacterName,
                            player.LastPosition.Value);
                        return true;
                    }
                }
            }

            if (byte.TryParse(characterName, out var uid) &&
                playersByUid is not null &&
                playersByUid.TryGetValue(uid, out var uidPlayer) &&
                uidPlayer.LastPosition is not null)
            {
                playerPosition = new GamePlayerPosition(
                    uidPlayer.Uid,
                    uidPlayer.CharacterId,
                    uidPlayer.CharacterName,
                    uidPlayer.LastPosition.Value);
                return true;
            }
        }

        playerPosition = default;
        return false;
    }

    public async Task<int> BroadcastGameMovementAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        GameMovementDelta movement)
    {
        PracticeRoomChannelProtocol[] targets;

        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            targets = channels.Keys
                .Where(channel => !ReferenceEquals(channel, source))
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket110GameMovementAsync(movement);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGameShootAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        GameShootAction shoot)
    {
        PracticeRoomChannelProtocol[] targets;

        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            if (_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) &&
                playersByUid.TryGetValue(shoot.Uid, out var player))
            {
                player.LastShoot = shoot;
            }

            targets = channels.Keys
                .Where(channel => !ReferenceEquals(channel, source))
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket113RemoteShootAsync(shoot);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<GameDamageBroadcastResult> BroadcastGameDamageAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte attackerUid,
        int damage,
        GameDamageHitRule? hitRule = null,
        byte clientTargetUid = 0)
    {
        PracticeRoomChannelProtocol[] targets;
        GameDamageAttempt damageAttempt;

        lock (_lock)
        {
            damageAttempt = TryApplyEnemyDamageNoLock(roomId, attackerUid, damage, hitRule, clientTargetUid);
            if (damageAttempt.Action is null ||
                !_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return CreateGameDamageNotAppliedResult(damageAttempt);
            }

            targets = channels.Keys.ToArray();
        }

        var sent = 0;
        var deathSent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket184RemoteDamageHitAsync(damageAttempt.Action.Value);
                sent++;
                if (damageAttempt.Action.Value.Killed)
                {
                    deathSent++;
                }
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        if (damageAttempt.Action.Value.Killed)
        {
            _ = RespawnGamePlayerAfterDelayAsync(
                roomId,
                damageAttempt.Action.Value.VictimUid,
                GameAutoRespawnDelayMilliseconds,
                "auto-respawn-after-kill");
        }

        return new GameDamageBroadcastResult(
            Applied: true,
            BroadcastCount: sent,
            VictimUid: damageAttempt.Action.Value.VictimUid,
            VictimHealth: damageAttempt.Action.Value.VictimHealth,
            VictimMaxHealth: damageAttempt.Action.Value.VictimMaxHealth,
            Damage: damageAttempt.Action.Value.Damage,
            Killed: damageAttempt.Action.Value.Killed,
            DeathBroadcastCount: deathSent,
            Reason: damageAttempt.Reason,
            CandidateCount: damageAttempt.CandidateCount,
            PositionedCandidateCount: damageAttempt.PositionedCandidateCount,
            AttackerTeamId: damageAttempt.AttackerTeamId,
            BestHitScore: damageAttempt.BestHitScore);
    }

    public async Task<int> BroadcastGamePlayerLeftAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte actorUid)
    {
        PracticeRoomChannelProtocol[] targets;

        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            targets = channels.Keys
                .Where(channel => !ReferenceEquals(channel, source))
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket108GamePlayerLeaveAsync(actorUid, "remote-player-leave");
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGamePlayerEnteredAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte actorUid,
        byte teamId)
    {
        PracticeRoomChannelProtocol[] targets;
        PracticeRoomSession? room;
        long characterId;

        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room) ||
                !_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            characterId = _gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) &&
                playersByUid.TryGetValue(actorUid, out var player)
                    ? player.CharacterId
                    : 0;

            targets = channels.Keys
                .Where(channel => !ReferenceEquals(channel, source))
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                if (characterId != 0)
                {
                    await target.SendRemoteGamePlayerEnteredAsync(
                        room,
                        characterId,
                        actorUid,
                        teamId,
                        "remote-player-enter");
                }
                else
                {
                    await target.SendPacket107GamePlayerEnterAsync(actorUid, teamId, "remote-player-enter");
                }

                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGamePlayerRespawnAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte actorUid)
    {
        PracticeRoomChannelProtocol[] targets;
        PracticeRoomSession? room;
        long characterId;

        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room) ||
                !_gameChannelsByRoomId.TryGetValue(roomId, out var channels) ||
                !_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) ||
                !playersByUid.TryGetValue(actorUid, out var player))
            {
                return 0;
            }

            characterId = player.CharacterId;
            if (characterId == 0)
            {
                return 0;
            }

            targets = channels.Keys
                .Where(channel => !ReferenceEquals(channel, source))
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendRemoteGamePlayerRespawnAsync(
                    room,
                    characterId,
                    actorUid,
                    "remote-player-respawn");
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    private async Task RespawnGamePlayerAfterDelayAsync(
        int roomId,
        byte actorUid,
        int delayMilliseconds,
        string trigger)
    {
        try
        {
            await Task.Delay(delayMilliseconds);
            var sent = await RespawnGamePlayerAsync(roomId, actorUid, trigger);
            Log.Information(
                "Channel auto respawn processed: roomId={RoomId} uid={Uid} trigger={Trigger} broadcastCount={BroadcastCount}",
                roomId,
                actorUid,
                trigger,
                sent);
        }
        catch (Exception ex)
        {
            Log.Warning(
                ex,
                "Channel auto respawn failed: roomId={RoomId} uid={Uid} trigger={Trigger}",
                roomId,
                actorUid,
                trigger);
        }
    }

    private async Task<int> RespawnGamePlayerAsync(
        int roomId,
        byte actorUid,
        string trigger)
    {
        KeyValuePair<PracticeRoomChannelProtocol, byte>[] targets;
        PracticeRoomSession? room;
        long characterId;

        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room) ||
                !_gameChannelsByRoomId.TryGetValue(roomId, out var channels) ||
                !_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) ||
                !playersByUid.TryGetValue(actorUid, out var player))
            {
                return 0;
            }

            if (player.CurrentHealth > 0)
            {
                return 0;
            }

            player.CurrentHealth = Math.Max(1, player.MaxHealth);
            characterId = player.CharacterId;
            if (characterId == 0)
            {
                return 0;
            }

            targets = channels.ToArray();
        }

        var sent = 0;
        foreach (var (target, targetUid) in targets)
        {
            try
            {
                if (targetUid == actorUid)
                {
                    await target.SendLocalGamePlayerRespawnAsync(room, trigger);
                }
                else
                {
                    await target.SendRemoteGamePlayerRespawnAsync(
                        room,
                        characterId,
                        actorUid,
                        trigger);
                }

                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGameReloadActionAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte actorUid,
        byte weaponSlot)
    {
        PracticeRoomChannelProtocol[] targets;

        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            targets = channels.Keys
                .Where(channel => !ReferenceEquals(channel, source))
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket128RemoteWeaponSlotAsync(actorUid, weaponSlot, "packet117-reload");
                await target.SendPacket117RemoteReloadActionAsync(actorUid);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGameDropWeaponAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte actorUid)
    {
        PracticeRoomChannelProtocol[] targets;

        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            targets = channels.Keys
                .Where(channel => !ReferenceEquals(channel, source))
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket118RemoteDropWeaponAsync(actorUid);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGameWeaponSlotAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte actorUid,
        byte weaponSlot,
        string trigger)
    {
        PracticeRoomChannelProtocol[] targets;

        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            targets = channels.Keys
                .Where(channel => !ReferenceEquals(channel, source))
                .ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket128RemoteWeaponSlotAsync(actorUid, weaponSlot, trigger);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    private void RemoveRoomNoLock(int roomId)
    {
        if (!_roomsById.TryGetValue(roomId, out var room))
        {
            return;
        }

        _roomsById.Remove(roomId);
        _roomIdByChannelToken.Remove(room.ChannelToken);
        _roomIdByHostCharacterId.Remove(room.HostCharacterId);
        _gameChannelsByRoomId.Remove(roomId);
        _roomChannelsByRoomId.Remove(roomId);
        _roomCharacterByChannelByRoomId.Remove(roomId);
        _gamePlayersByRoomId.Remove(roomId);
        _gameMovementByRoomId.Remove(roomId);
        _retiredGameUidsByRoomId.Remove(roomId);
        foreach (var key in _pendingChannelJoins.Keys
                     .Where(key => key.ChannelToken == room.ChannelToken)
                     .ToArray())
        {
            _pendingChannelJoins.Remove(key);
        }
    }

    private PracticeRoomChannelProtocol[] GetRoomChannelTargets(
        int roomId,
        out PracticeRoomSession? room)
    {
        lock (_lock)
        {
            if (!_roomsById.TryGetValue(roomId, out room))
            {
                return [];
            }

            return _roomChannelsByRoomId.TryGetValue(roomId, out var channels)
                ? channels.ToArray()
                : [];
        }
    }

    private bool UnregisterGameChannelNoLock(int roomId, PracticeRoomChannelProtocol channel, out byte removedUid)
    {
        removedUid = 0;
        if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
        {
            return false;
        }

        if (!channels.TryGetValue(channel, out removedUid))
        {
            return false;
        }

        if (_gameMovementByRoomId.TryGetValue(roomId, out var movementByUid))
        {
            movementByUid.Remove(removedUid);
            if (movementByUid.Count == 0)
            {
                _gameMovementByRoomId.Remove(roomId);
            }
        }

        if (_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid))
        {
            playersByUid.Remove(removedUid);
            if (playersByUid.Count == 0)
            {
                _gamePlayersByRoomId.Remove(roomId);
            }
        }

        if (!_retiredGameUidsByRoomId.TryGetValue(roomId, out var retiredUids))
        {
            retiredUids = [];
            _retiredGameUidsByRoomId[roomId] = retiredUids;
        }

        retiredUids.Add(removedUid);

        channels.Remove(channel);
        if (channels.Count == 0)
        {
            _gameChannelsByRoomId.Remove(roomId);
            _retiredGameUidsByRoomId.Remove(roomId);
        }

        return true;
    }

    private bool IsCharacterConnectedToRoomNoLock(int roomId, long characterId)
    {
        if (characterId == 0 ||
            !_roomCharacterByChannelByRoomId.TryGetValue(roomId, out var charactersByChannel))
        {
            return false;
        }

        return charactersByChannel.Values.Any(connectedCharacterId => connectedCharacterId == characterId);
    }

    private bool IsCharacterConnectedToGameNoLock(int roomId, long characterId)
    {
        if (characterId == 0 ||
            !_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid))
        {
            return false;
        }

        return playersByUid.Values.Any(player => player.CharacterId == characterId);
    }

    private void UpsertGamePlayerNoLock(int roomId, byte uid, long characterId, string characterName)
    {
        if (!_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid))
        {
            playersByUid = new Dictionary<byte, GamePlayerRuntime>();
            _gamePlayersByRoomId[roomId] = playersByUid;
        }

        var normalizedName = string.IsNullOrWhiteSpace(characterName)
            ? $"uid:{uid}"
            : characterName.Trim();

        if (playersByUid.TryGetValue(uid, out var existing))
        {
            existing.CharacterId = characterId;
            existing.CharacterName = normalizedName;
            return;
        }

        playersByUid[uid] = new GamePlayerRuntime(uid, characterId, normalizedName);
    }

    private GameDamageAttempt TryApplyEnemyDamageNoLock(
        int roomId,
        byte attackerUid,
        int damage,
        GameDamageHitRule? hitRule,
        byte clientTargetUid)
    {
        if (damage <= 0)
        {
            return GameDamageAttempt.NotApplied("invalid-damage");
        }

        if (!_roomsById.TryGetValue(roomId, out var room))
        {
            return GameDamageAttempt.NotApplied("room-missing");
        }

        if (!_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid))
        {
            return GameDamageAttempt.NotApplied("player-state-missing");
        }

        if (!playersByUid.TryGetValue(attackerUid, out var attacker))
        {
            return GameDamageAttempt.NotApplied("attacker-missing");
        }

        var attackerTeamId = ResolveGamePlayerTeamId(room, attacker);
        if (attackerTeamId == GameTeamSpectator)
        {
            return GameDamageAttempt.NotApplied("attacker-spectator", attackerTeamId: attackerTeamId);
        }

        var candidates = playersByUid.Values
            .Where(player =>
                player.Uid != attackerUid &&
                player.CurrentHealth > 0 &&
                IsEnemyTeam(attackerTeamId, ResolveGamePlayerTeamId(room, player)))
            .ToArray();
        var positionedCandidateCount = candidates.Count(player => player.LastPosition is not null);
        if (candidates.Length == 0)
        {
            return GameDamageAttempt.NotApplied("no-enemy-candidates", attackerTeamId: attackerTeamId);
        }

        if (clientTargetUid == 0 &&
            hitRule is { RequireShootHit: true, UseProximityHit: false })
        {
            return GameDamageAttempt.NotApplied(
                "no-client-hit-target",
                candidates.Length,
                positionedCandidateCount,
                attackerTeamId);
        }

        float bestHitScore;
        var victim = clientTargetUid == 0
            ? null
            : candidates.FirstOrDefault(candidate => candidate.Uid == clientTargetUid);
        if (clientTargetUid != 0 && victim is null)
        {
            return GameDamageAttempt.NotApplied(
                "client-target-not-enemy",
                candidates.Length,
                positionedCandidateCount,
                attackerTeamId);
        }

        var reason = "client-hit";
        if (victim is null)
        {
            victim = hitRule is { RequireShootHit: true, UseProximityHit: true } proximityRule
                ? SelectProximityHitVictim(attacker, candidates, proximityRule, out bestHitScore)
                : hitRule is { RequireShootHit: true } rule
                    ? SelectShootHitVictim(attacker, candidates, rule, out bestHitScore)
                    : SelectDamageVictim(attacker, candidates, out bestHitScore);
            reason = "hit";
        }
        else
        {
            bestHitScore = ComputeDamageTargetScore(attacker, victim);
        }

        if (victim is null)
        {
            reason = positionedCandidateCount == 0
                ? "no-positioned-candidates"
                : hitRule is { RequireShootHit: true } && attacker.LastShoot is null
                    ? "attacker-shoot-missing"
                    : "miss";
            return GameDamageAttempt.NotApplied(
                reason,
                candidates.Length,
                positionedCandidateCount,
                attackerTeamId,
                bestHitScore);
        }

        var previousHealth = victim.CurrentHealth;
        var maxHealth = Math.Max(1, victim.MaxHealth);
        var appliedDamage = Math.Clamp(damage, 1, maxHealth);
        victim.CurrentHealth = Math.Max(0, victim.CurrentHealth - appliedDamage);
        var killed = previousHealth > 0 && victim.CurrentHealth == 0;

        return new GameDamageAttempt(
            new GameDamageAction(
                AttackerUid: attackerUid,
                VictimUid: victim.Uid,
                Damage: appliedDamage,
                VictimHealth: victim.CurrentHealth,
                VictimMaxHealth: maxHealth,
                Killed: killed),
            reason,
            candidates.Length,
            positionedCandidateCount,
            attackerTeamId,
            bestHitScore);
    }

    private static GamePlayerRuntime? SelectProximityHitVictim(
        GamePlayerRuntime attacker,
        IReadOnlyList<GamePlayerRuntime> candidates,
        GameDamageHitRule rule,
        out float bestScore)
    {
        var scoredCandidates = candidates
            .Select(candidate => new
            {
                Player = candidate,
                Hit = TryComputeProximityHitScore(attacker, candidate, rule, out var score),
                Score = score
            })
            .ToArray();
        bestScore = scoredCandidates.Length == 0 ? float.MaxValue : scoredCandidates.Min(candidate => candidate.Score);
        return scoredCandidates
            .Where(candidate => candidate.Hit)
            .OrderBy(candidate => candidate.Score)
            .ThenBy(candidate => candidate.Player.Uid)
            .Select(candidate => candidate.Player)
            .FirstOrDefault();
    }

    private static bool TryComputeProximityHitScore(
        GamePlayerRuntime attacker,
        GamePlayerRuntime candidate,
        GameDamageHitRule rule,
        out float score)
    {
        score = float.MaxValue;
        if (candidate.LastPosition is not { } candidatePosition)
        {
            return false;
        }

        var source = attacker.LastShoot is { } shoot
            ? ShootOriginToWorld(shoot)
            : attacker.LastPosition is { } attackerPosition
                ? MovementPositionToWorld(attackerPosition)
                : default;
        if (!float.IsFinite(source.X) || !float.IsFinite(source.Y) || !float.IsFinite(source.Z))
        {
            return false;
        }

        var target = MovementPositionToWorld(candidatePosition);
        var maxDistance = MathF.Max(0.1f, rule.MaxRange + rule.HitRadius);
        var maxDistanceSquared = maxDistance * maxDistance;
        var bestScore = float.MaxValue;
        var hit = false;
        foreach (var targetY in new[] { target.Y, target.Y + 0.8f, target.Y + 1.6f })
        {
            var distanceSquared = DistanceSquared(source.X, source.Y, source.Z, target.X, targetY, target.Z);
            bestScore = MathF.Min(bestScore, distanceSquared);
            hit |= distanceSquared <= maxDistanceSquared;
        }

        score = bestScore;
        return hit;
    }

    private static GamePlayerRuntime? SelectShootHitVictim(
        GamePlayerRuntime attacker,
        IReadOnlyList<GamePlayerRuntime> candidates,
        GameDamageHitRule rule,
        out float bestScore)
    {
        var scoredCandidates = candidates
            .Select(candidate => new
            {
                Player = candidate,
                Hit = TryComputeShootHitScore(attacker, candidate, rule, out var score),
                Score = score
            })
            .ToArray();
        bestScore = scoredCandidates.Length == 0 ? float.MaxValue : scoredCandidates.Min(candidate => candidate.Score);
        return scoredCandidates
            .Where(candidate => candidate.Hit)
            .OrderBy(candidate => candidate.Score)
            .ThenBy(candidate => candidate.Player.Uid)
            .Select(candidate => candidate.Player)
            .FirstOrDefault();
    }

    private static bool TryComputeShootHitScore(
        GamePlayerRuntime attacker,
        GamePlayerRuntime candidate,
        GameDamageHitRule rule,
        out float score)
    {
        score = float.MaxValue;
        if (attacker.LastShoot is not { } shoot ||
            candidate.LastPosition is not { } candidatePosition)
        {
            return false;
        }

        var direction = ResolveShootDirection(shoot);
        if (direction.LengthSquared <= 0f)
        {
            return false;
        }

        var origin = ShootOriginToWorld(shoot);
        var target = MovementPositionToWorld(candidatePosition);
        var maxRange = MathF.Max(0.1f, rule.MaxRange);
        var hitRadius = MathF.Max(0.1f, rule.HitRadius);
        var hitRadiusSquared = hitRadius * hitRadius;
        var bestScore = float.MaxValue;
        var hit = false;

        // Approximate the player as a small vertical capsule; positions are usually feet/root.
        foreach (var targetY in new[] { target.Y, target.Y + 0.8f, target.Y + 1.6f })
        {
            var toTargetX = target.X - origin.X;
            var toTargetY = targetY - origin.Y;
            var toTargetZ = target.Z - origin.Z;
            var projection = Dot(toTargetX, toTargetY, toTargetZ, direction.X, direction.Y, direction.Z);
            if (projection < -0.25f || projection > maxRange)
            {
                continue;
            }

            var closestX = origin.X + (direction.X * projection);
            var closestY = origin.Y + (direction.Y * projection);
            var closestZ = origin.Z + (direction.Z * projection);
            var distanceSquared = DistanceSquared(target.X, targetY, target.Z, closestX, closestY, closestZ);
            bestScore = MathF.Min(bestScore, distanceSquared);
            hit |= distanceSquared <= hitRadiusSquared;
        }

        score = bestScore;
        return hit;
    }

    private static bool IsEnemyTeam(byte sourceTeamId, byte targetTeamId)
    {
        return sourceTeamId != GameTeamSpectator &&
               targetTeamId != GameTeamSpectator &&
               sourceTeamId != targetTeamId;
    }

    private static GamePlayerRuntime SelectDamageVictim(
        GamePlayerRuntime attacker,
        IReadOnlyList<GamePlayerRuntime> candidates,
        out float bestScore)
    {
        var scoredCandidates = candidates
            .Select(candidate => new
            {
                Player = candidate,
                Score = ComputeDamageTargetScore(attacker, candidate)
            })
            .ToArray();
        bestScore = scoredCandidates.Min(candidate => candidate.Score);
        return scoredCandidates
            .OrderBy(candidate => candidate.Score)
            .ThenBy(candidate => candidate.Player.Uid)
            .Select(candidate => candidate.Player)
            .First();
    }

    public bool HasGamePosition(int roomId, byte uid)
    {
        lock (_lock)
        {
            return _gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) &&
                   playersByUid.TryGetValue(uid, out var player) &&
                   player.LastPosition is not null;
        }
    }

    public void UpdateGamePositionIfMissing(int roomId, byte uid, GamePosition position)
    {
        lock (_lock)
        {
            if (!_roomsById.ContainsKey(roomId))
            {
                return;
            }

            if (!_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) ||
                !playersByUid.TryGetValue(uid, out var player))
            {
                UpsertGamePlayerNoLock(roomId, uid, 0, $"uid:{uid}");
                player = _gamePlayersByRoomId[roomId][uid];
            }

            player.LastPosition ??= position;
        }
    }

    private readonly record struct GameDamageAttempt(
        GameDamageAction? Action,
        string Reason,
        int CandidateCount,
        int PositionedCandidateCount,
        byte AttackerTeamId,
        float BestHitScore)
    {
        public static GameDamageAttempt NotApplied(
            string reason,
            int candidateCount = 0,
            int positionedCandidateCount = 0,
            byte attackerTeamId = GameTeamSpectator,
            float bestHitScore = float.MaxValue)
        {
            return new GameDamageAttempt(
                null,
                reason,
                candidateCount,
                positionedCandidateCount,
                attackerTeamId,
                bestHitScore);
        }
    }

    private static GameDamageBroadcastResult CreateGameDamageNotAppliedResult(GameDamageAttempt attempt)
    {
        return new GameDamageBroadcastResult(
            Applied: false,
            BroadcastCount: 0,
            VictimUid: 0,
            VictimHealth: 0,
            VictimMaxHealth: 0,
            Damage: 0,
            Killed: false,
            DeathBroadcastCount: 0,
            Reason: attempt.Reason,
            CandidateCount: attempt.CandidateCount,
            PositionedCandidateCount: attempt.PositionedCandidateCount,
            AttackerTeamId: attempt.AttackerTeamId,
            BestHitScore: attempt.BestHitScore);
    }


    private static float ComputeDamageTargetScore(GamePlayerRuntime attacker, GamePlayerRuntime candidate)
    {
        if (attacker.LastShoot is { } shoot &&
            candidate.LastPosition is { } candidatePosition)
        {
            var origin = ShootOriginToWorld(shoot);
            var direction = ResolveShootDirection(shoot);
            var target = MovementPositionToWorld(candidatePosition);
            if (direction.LengthSquared > 0f)
            {
                var toTargetX = target.X - origin.X;
                var toTargetY = target.Y - origin.Y;
                var toTargetZ = target.Z - origin.Z;
                var projection = Dot(toTargetX, toTargetY, toTargetZ, direction.X, direction.Y, direction.Z);
                var closestX = origin.X + (direction.X * projection);
                var closestY = origin.Y + (direction.Y * projection);
                var closestZ = origin.Z + (direction.Z * projection);
                var rayDistance = DistanceSquared(target.X, target.Y, target.Z, closestX, closestY, closestZ);
                var behindPenalty = projection < 0f ? MathF.Abs(projection) * 1000f : 0f;
                return rayDistance + behindPenalty;
            }
        }

        if (attacker.LastPosition is { } attackerPosition &&
            candidate.LastPosition is { } targetPosition)
        {
            var source = MovementPositionToWorld(attackerPosition);
            var target = MovementPositionToWorld(targetPosition);
            return DistanceSquared(source.X, source.Y, source.Z, target.X, target.Y, target.Z);
        }

        return candidate.Uid;
    }

    private static (float X, float Y, float Z, float LengthSquared) ResolveShootDirection(GameShootAction shoot)
    {
        var direction = NormalizeOrZero(shoot.VectorX, shoot.VectorY, shoot.VectorZ);
        if (direction.LengthSquared > 0f)
        {
            return direction;
        }

        var yaw = shoot.Facing0Raw / FacingRawAngleScale;
        var pitch = shoot.Facing1Raw / FacingRawAngleScale;
        var cosPitch = MathF.Cos(pitch);
        return NormalizeOrZero(
            MathF.Sin(yaw) * cosPitch,
            MathF.Sin(pitch),
            -MathF.Cos(yaw) * cosPitch);
    }

    private static (float X, float Y, float Z) ShootOriginToWorld(GameShootAction shoot)
    {
        return (
            shoot.OriginXRaw / ActionPoseRawCoordinateScale,
            shoot.OriginYRaw / ActionPoseRawCoordinateScale,
            shoot.OriginZRaw / ActionPoseRawCoordinateScale);
    }

    private static (float X, float Y, float Z) MovementPositionToWorld(GamePosition position)
    {
        return (
            position.XRaw / MovementRawCoordinateScale,
            position.YRaw / MovementRawCoordinateScale,
            position.ZRaw / MovementRawCoordinateScale);
    }

    private static (float X, float Y, float Z, float LengthSquared) NormalizeOrZero(float x, float y, float z)
    {
        var lengthSquared = (x * x) + (y * y) + (z * z);
        if (!float.IsFinite(lengthSquared) || lengthSquared <= 0.000001f)
        {
            return (0f, 0f, 0f, 0f);
        }

        var length = MathF.Sqrt(lengthSquared);
        return (x / length, y / length, z / length, 1f);
    }

    private static float Dot(float ax, float ay, float az, float bx, float by, float bz)
    {
        return (ax * bx) + (ay * by) + (az * bz);
    }

    private static float DistanceSquared(float ax, float ay, float az, float bx, float by, float bz)
    {
        var dx = ax - bx;
        var dy = ay - by;
        var dz = az - bz;
        return (dx * dx) + (dy * dy) + (dz * dz);
    }

    private static byte ResolveGamePlayerTeamId(PracticeRoomSession room, GamePlayerRuntime player)
    {
        var member = room.Members.FirstOrDefault(candidate => candidate.CharacterId == player.CharacterId);
        return member is null ? player.TeamId : ResolveGameTeamId(member);
    }

    private static byte ResolveGameTeamId(PracticeRoomMember? member)
    {
        return member?.SlotIndex switch
        {
            >= 9 and <= 16 => GameTeamBlue,
            >= 17 and <= 24 => GameTeamSpectator,
            _ => 0
        };
    }

    private static IEnumerable<PracticeRoomMember> OrderedGameMembers(PracticeRoomSession room)
    {
        return room.Members
            .Where(member => member.CharacterId != 0 && member.InGame)
            .OrderBy(member => member.Host ? 0 : 1)
            .ThenBy(member => member.SlotIndex)
            .ThenBy(member => member.CharacterId);
    }

    private static byte ResolvePreferredGameUidNoLock(PracticeRoomSession room, long characterId)
    {
        if (characterId == 0)
        {
            return 0;
        }

        var index = 0;
        foreach (var member in OrderedGameMembers(room))
        {
            index++;
            if (member.CharacterId == characterId && index <= byte.MaxValue)
            {
                return (byte)index;
            }
        }

        return 0;
    }

    private static byte AllocateFirstFreeGameUid(HashSet<byte> usedUids)
    {
        for (var uid = 1; uid <= byte.MaxValue; uid++)
        {
            var candidate = (byte)uid;
            if (!usedUids.Contains(candidate))
            {
                return candidate;
            }
        }

        return 1;
    }

    private bool TryResolveRoomIdByCharacterNoLock(long characterId, out int roomId)
    {
        if (_roomIdByHostCharacterId.TryGetValue(characterId, out roomId))
        {
            return true;
        }

        foreach (var pair in _roomsById)
        {
            if (pair.Value.Members.Any(member => member.CharacterId == characterId))
            {
                roomId = pair.Key;
                return true;
            }
        }

        roomId = 0;
        return false;
    }

    private static void AssignRandomBattleLevelNoLock(PracticeRoomSession room)
    {
        if (room.LevelId > 0)
        {
            return;
        }

        var choices = RandomBattleLevelChoices.Value;
        var choice = choices[Random.Shared.Next(choices.Count)];
        room.LevelId = choice.LevelId;
        room.MapName = choice.MapName;
    }

    private static IReadOnlyList<BattleLevelChoice> LoadRandomBattleLevelChoices()
    {
        var configPath = ResolveLobbyLevelInfoConfigPath();
        if (string.IsNullOrWhiteSpace(configPath))
        {
            return FallbackRandomBattleLevels;
        }

        try
        {
            var json = File.ReadAllText(configPath);
            var map = JsonSerializer.Deserialize<Dictionary<string, string>>(json);
            var choices = map?
                .Select(entry => TryParseLevelKey(entry.Key, out var levelId)
                    ? new BattleLevelChoice(levelId, string.IsNullOrWhiteSpace(entry.Value) ? entry.Key : entry.Value)
                    : (BattleLevelChoice?)null)
                .Where(choice => choice is { LevelId: > 0 and < 10000 })
                .Select(choice => choice!.Value)
                .OrderBy(choice => choice.LevelId)
                .ToArray();

            return choices is { Length: > 0 } ? choices : FallbackRandomBattleLevels;
        }
        catch
        {
            return FallbackRandomBattleLevels;
        }
    }

    private static string? ResolveLobbyLevelInfoConfigPath()
    {
        var envPath = Environment.GetEnvironmentVariable("AS_LOBBY_LEVELINFO_PATH");
        if (!string.IsNullOrWhiteSpace(envPath) && File.Exists(envPath))
        {
            return envPath;
        }

        var candidates = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Config", LobbyLevelInfoConfigFileName),
            Path.Combine(Directory.GetCurrentDirectory(), "Config", LobbyLevelInfoConfigFileName),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Config", LobbyLevelInfoConfigFileName),
        };

        return candidates.FirstOrDefault(File.Exists);
    }

    private static bool TryParseLevelKey(string key, out long levelId)
    {
        var digits = new string(key.Where(char.IsDigit).ToArray());
        return long.TryParse(digits, out levelId);
    }

    private void RemoveExpiredPendingChannelJoinsNoLock(DateTimeOffset now)
    {
        foreach (var key in _pendingChannelJoins.Keys.ToArray())
        {
            var queue = _pendingChannelJoins[key];
            while (queue.Count > 0 && queue.Peek().ExpiresAt <= now)
            {
                queue.Dequeue();
            }

            if (queue.Count == 0)
            {
                _pendingChannelJoins.Remove(key);
            }
        }
    }

    private static string NormalizeAddress(IPAddress address)
    {
        return address.IsIPv4MappedToIPv6
            ? address.MapToIPv4().ToString()
            : address.ToString();
    }

    private static int ParsePositiveInt(string name, int fallback)
    {
        return int.TryParse(Environment.GetEnvironmentVariable(name), out var value) && value > 0
            ? value
            : fallback;
    }

    private readonly record struct BattleLevelChoice(long LevelId, string MapName);

    internal readonly record struct PracticeRoomLobbyEntry(
        int RoomUid,
        byte RoomState,
        string RoomName,
        string MapName,
        string HostName,
        bool UsePassword,
        string Password,
        long LevelId,
        long HostCharacterId,
        byte GameType,
        byte MaxClientNum,
        byte CurrentClientNum,
        bool JoinHalfWay,
        bool CheckBalance,
        bool Matching,
        byte CanBeWatched,
        byte EnterLimit);

    private readonly record struct PendingChannelJoinKey(int ChannelToken, string RemoteAddress);

    private readonly record struct PendingChannelJoin(
        int RoomId,
        PracticeRoomEnterRequest Request,
        DateTimeOffset ExpiresAt);

    internal readonly record struct PracticeRoomEnterRequest(
        long CharacterId,
        string CharacterName,
        int Level,
        int Occupation,
        byte RankType,
        int RankLevel,
        byte VipLevel);

    internal sealed record GameMovementDelta(
        byte Uid,
        byte Tick,
        byte Flags,
        byte[] OptionalPayload,
        DateTimeOffset LastSeenAt);

    internal readonly record struct GameShootAction(
        byte Uid,
        byte Action,
        byte SlotOneBased,
        short OriginXRaw,
        short OriginYRaw,
        short OriginZRaw,
        short Facing0Raw,
        short Facing1Raw,
        float VectorX,
        float VectorY,
        float VectorZ);

    internal readonly record struct GameDamageHitRule(
        bool RequireShootHit,
        bool UseProximityHit,
        float HitRadius,
        float MaxRange);

    internal readonly record struct GameDamageAction(
        byte AttackerUid,
        byte VictimUid,
        int Damage,
        int VictimHealth,
        int VictimMaxHealth,
        bool Killed);

    internal readonly record struct GameDamageBroadcastResult(
        bool Applied,
        int BroadcastCount,
        byte VictimUid,
        int VictimHealth,
        int VictimMaxHealth,
        int Damage,
        bool Killed,
        int DeathBroadcastCount,
        string Reason,
        int CandidateCount,
        int PositionedCandidateCount,
        byte AttackerTeamId,
        float BestHitScore)
    {
        public static GameDamageBroadcastResult NotApplied { get; } = new(
            false,
            0,
            0,
            0,
            0,
            0,
            false,
            0,
            "not-applied",
            0,
            0,
            GameTeamSpectator,
            float.MaxValue);
    }

    internal readonly record struct GamePlayerSnapshot(
        byte Uid,
        long CharacterId,
        string CharacterName,
        GamePosition? LastPosition);

    internal readonly record struct GamePosition(
        short XRaw,
        short YRaw,
        short ZRaw,
        short? YawRaw,
        short? Facing0Raw,
        short? Facing1Raw,
        DateTimeOffset LastSeenAt);

    internal readonly record struct GamePlayerPosition(
        byte Uid,
        long CharacterId,
        string CharacterName,
        GamePosition Position);

    private sealed class GamePlayerRuntime
    {
        public GamePlayerRuntime(byte uid, long characterId, string characterName)
        {
            Uid = uid;
            CharacterId = characterId;
            CharacterName = characterName;
        }

        public byte Uid { get; }
        public long CharacterId { get; set; }
        public string CharacterName { get; set; }
        public byte TeamId { get; set; }
        public int MaxHealth { get; set; } = DefaultGamePlayerHealth;
        public int CurrentHealth { get; set; } = DefaultGamePlayerHealth;
        public GamePosition? LastPosition { get; set; }
        public GameShootAction? LastShoot { get; set; }
    }

    internal sealed class PracticeRoomSession
    {
        private readonly List<PracticeRoomMember> _members = [];

        public PracticeRoomSession(
            int roomId,
            int roomUid,
            int channelToken,
            long hostCharacterId,
            string hostName,
            string roomName,
            string mapName,
            bool usePassword,
            string password,
            long levelId,
            byte gameType,
            byte maxClientNum,
            short spawnTime,
            bool joinHalfWay,
            bool checkBalance,
            byte canBeWatched,
            bool matching,
            byte enterLimit,
            int hostLevel,
            int hostOccupation,
            byte hostRankType,
            int hostRankLevel,
            byte hostVipLevel)
        {
            RoomId = roomId;
            RoomUid = roomUid;
            ChannelToken = channelToken;
            HostCharacterId = hostCharacterId;
            HostName = hostName;
            RoomName = roomName;
            MapName = mapName;
            UsePassword = usePassword;
            Password = password;
            LevelId = levelId;
            GameType = gameType;
            MaxClientNum = maxClientNum;
            SpawnTime = spawnTime;
            JoinHalfWay = joinHalfWay;
            CheckBalance = checkBalance;
            CanBeWatched = canBeWatched;
            Matching = matching;
            EnterLimit = enterLimit;
            EnsureHostMember(
                DefaultHostSlotIndex,
                hostLevel,
                (byte)hostOccupation,
                hostRankType,
                hostRankLevel,
                hostVipLevel);
        }

        public int RoomId { get; }
        public int RoomUid { get; }
        public int ChannelToken { get; }
        public long HostCharacterId { get; }
        public string HostName { get; }
        public string RoomName { get; set; }
        public string MapName { get; set; }
        public bool UsePassword { get; set; }
        public string Password { get; set; }
        public long LevelId { get; set; }
        public byte GameType { get; set; }
        public byte MaxClientNum { get; set; }
        public short SpawnTime { get; set; }
        public bool JoinHalfWay { get; set; }
        public bool CheckBalance { get; set; }
        public byte CanBeWatched { get; set; }
        public byte RoomState { get; set; } = 1;
        public bool Matching { get; set; }
        public byte CurrentClientNum { get; set; }
        public byte EnterLimit { get; set; }
        public int ContextId { get; set; }

        public IReadOnlyList<PracticeRoomMember> Members => _members;

        public byte GetHostSlotIndexOrDefault(byte defaultSlotIndex)
        {
            var existing = _members.FirstOrDefault(m => m.CharacterId == HostCharacterId);
            return existing?.SlotIndex is > 0 and <= 24
                ? existing.SlotIndex
                : defaultSlotIndex;
        }

        public void EnsureHostMember(
            byte slotIndex,
            int? hostLevel = null,
            byte? hostOccupation = null,
            byte? hostRankType = null,
            int? hostRankLevel = null,
            byte? hostVipLevel = null)
        {
            var existing = _members.FirstOrDefault(m => m.CharacterId == HostCharacterId);
            if (existing is not null)
            {
                existing.SlotIndex = slotIndex;
                existing.CharacterName = HostName;
                existing.Host = true;
                if (hostOccupation.HasValue)
                {
                    existing.Career = hostOccupation.Value;
                }

                if (hostLevel.HasValue)
                {
                    existing.Level = hostLevel.Value;
                }

                if (hostRankType.HasValue)
                {
                    existing.RankType = hostRankType.Value;
                }

                if (hostRankLevel.HasValue)
                {
                    existing.RankLevel = hostRankLevel.Value;
                }

                if (hostVipLevel.HasValue)
                {
                    existing.VipLevel = hostVipLevel.Value;
                }

                return;
            }

            _members.Add(new PracticeRoomMember(
                characterId: HostCharacterId,
                characterName: HostName,
                slotIndex: slotIndex,
                career: hostOccupation ?? 0,
                ready: false,
                inGame: false,
                host: true,
                level: hostLevel ?? 1,
                rankType: hostRankType ?? 0,
                rankLevel: hostRankLevel ?? 0,
                vipLevel: hostVipLevel ?? 0,
                extraValue0: 0,
                extraValue1: 0));
        }

        public bool TryUpsertMember(PracticeRoomEnterRequest request, out PracticeRoomMember member)
        {
            if (request.CharacterId == HostCharacterId)
            {
                EnsureHostMember(
                    GetHostSlotIndexOrDefault(DefaultHostSlotIndex),
                    request.Level,
                    (byte)request.Occupation,
                    request.RankType,
                    request.RankLevel,
                    request.VipLevel);

                member = _members.First(m => m.CharacterId == HostCharacterId);
                return true;
            }

            var existing = _members.FirstOrDefault(m => m.CharacterId == request.CharacterId);
            if (existing is not null)
            {
                existing.CharacterName = request.CharacterName;
                existing.Career = (byte)request.Occupation;
                existing.Level = request.Level;
                existing.RankType = request.RankType;
                existing.RankLevel = request.RankLevel;
                existing.VipLevel = request.VipLevel;
                existing.Host = false;
                member = existing;
                return true;
            }

            var capacity = ResolveMemberCapacity();
            var usedSlots = _members.Select(m => m.SlotIndex).ToHashSet();
            for (byte slotIndex = 1; slotIndex <= capacity; slotIndex++)
            {
                if (usedSlots.Contains(slotIndex))
                {
                    continue;
                }

                member = new PracticeRoomMember(
                    characterId: request.CharacterId,
                    characterName: request.CharacterName,
                    slotIndex: slotIndex,
                    career: (byte)request.Occupation,
                    ready: false,
                    inGame: false,
                    host: false,
                    level: request.Level,
                    rankType: request.RankType,
                    rankLevel: request.RankLevel,
                    vipLevel: request.VipLevel,
                    extraValue0: 0,
                    extraValue1: 0);
                _members.Add(member);
                return true;
            }

            member = null!;
            return false;
        }

        public bool RemoveMember(long characterId)
        {
            var removed = _members.RemoveAll(member => member.CharacterId == characterId && !member.Host);
            return removed > 0;
        }

        public void RefreshCurrentClientNum()
        {
            CurrentClientNum = (byte)Math.Clamp(_members.Count(m => m.CharacterId != 0), 0, byte.MaxValue);
        }

        private byte ResolveMemberCapacity()
        {
            var requested = MaxClientNum == 0 ? MaxRoomSlotIndex : MaxClientNum;
            return (byte)Math.Clamp((int)requested, 1, MaxRoomSlotIndex);
        }
    }

    internal sealed record PracticeRoomCreateRequest(
        long HostCharacterId,
        string HostName,
        string RoomName,
        string MapName,
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
        byte EnterLimit,
        int HostLevel,
        int HostOccupation,
        byte HostRankType,
        int HostRankLevel,
        byte HostVipLevel);

    internal sealed record PracticeRoomUpdateRequest(
        string RoomName,
        bool UsePassword,
        string Password,
        long LevelId,
        byte GameType,
        byte MaxClientNum,
        short SpawnTime,
        bool JoinHalfWay,
        bool CheckBalance,
        bool Matching,
        byte CanBeWatched,
        string MapName,
        byte EnterLimit);

    internal sealed class PracticeRoomMember
    {
        public PracticeRoomMember(
            long characterId,
            string characterName,
            byte slotIndex,
            byte career,
            bool ready,
            bool inGame,
            bool host,
            int level,
            byte rankType,
            int rankLevel,
            byte vipLevel,
            int extraValue0,
            int extraValue1)
        {
            CharacterId = characterId;
            CharacterName = characterName;
            SlotIndex = slotIndex;
            Career = career;
            Ready = ready;
            InGame = inGame;
            Host = host;
            Level = level;
            RankType = rankType;
            RankLevel = rankLevel;
            VipLevel = vipLevel;
            ExtraValue0 = extraValue0;
            ExtraValue1 = extraValue1;
        }

        public long CharacterId { get; }
        public string CharacterName { get; set; }
        public byte SlotIndex { get; set; }
        public byte Career { get; set; }
        public bool Ready { get; set; }
        public bool InGame { get; set; }
        public bool Host { get; set; }
        public int Level { get; set; }
        public byte RankType { get; set; }
        public int RankLevel { get; set; }
        public byte VipLevel { get; set; }
        public int ExtraValue0 { get; set; }
        public int ExtraValue1 { get; set; }
    }
}
