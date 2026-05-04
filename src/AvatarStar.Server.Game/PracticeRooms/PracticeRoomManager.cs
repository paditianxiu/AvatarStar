using System.Net;
using System.Text.Json;
using AvatarStar.Server.Persistence;
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
    private const short GameBuffTypeEnergy = 1;
    private const short GameBuffTypeVitals = 5;
    private const short GameBuffTypePoison = 7;
    private const short GameBuffTypeShield = 8;
    private const short GameBuffTypeTransfer = 10;
    private const short GameBuffTypeHeavy = 11;
    private const short GameBuffTypeTenacity = 12;
    private const short GameBuffTypeLurk = 15;
    private const short GameBuffTypePiercing = 16;
    private const short GameBuffTypeSnare = 19;
    private const short GameBuffTypePlague = 64;
    private const short GameBuffTypePoisoned = 65;
    private const short GameBuffTypeGasBomb = 70;
    private const short GameBuffTypePlaguePassive = 71;
    private const short GameBuffTypeSuckBlood = 72;
    private const short GameBuffTypeFeudMark = 127;
    private const short GameBuffTypeFeudAnger = 128;
    private const byte GameDropTypeSnare = 1;
    private const byte GameDropTypeEnergy = 2;
    private const byte GameSkillTypePiercing = 5;
    private const byte GameSkillTypeVitals = 6;
    private const byte GameSkillTypeTenacity = 7;
    private const byte GameSkillTypePoison = 8;
    private const byte GameSkillTypeHeavy = 10;
    private const byte GameSkillTypeTransfer = 12;
    private const byte GameSkillTypeSuckBlood = 39;
    private const byte GameSkillTypePlague = 40;
    private const byte GameSkillTypeGasBomb = 41;
    private const byte GameSkillTypeFeud = 76;
    private const float ActionPoseRawCoordinateScale = 256f;
    private const float MovementRawCoordinateScale = ActionPoseRawCoordinateScale;
    private const float FacingRawAngleScale = 8192f;
    private const float ShootVectorEpsilon = 0.001f;
    private const float SnareTriggerRadius = 3f;
    private const float SnareDamageRadius = 8f;
    private const float EnergyHealRadius = 5f;
    private const float TransferTriggerRadius = 3f;
    private const float TransferDamageRadius = 8f;
    private const float SpurtSkillRange = 8f;
    private const float SpurtSkillHitRadius = 2.2f;
    private const int VitalsDamageTakenBonusPercent = 20;
    private const int SuckBloodDefaultHealPercent = 10;
    private const string LobbyLevelInfoConfigFileName = "lobby_levelinfo.json";
    private static readonly int[] TenacityDamageReductionPercents = [3, 4, 5, 7, 9, 17];
    private static readonly int[] TenacityHealPerTickValues = [40, 60, 80, 100, 120, 200];
    private static readonly int[] TransferChargePercents = [3, 3, 4, 4, 5, 10];
    private static readonly int[] TransferReleaseDamageValues = [350, 420, 500, 590, 700, 1000];
    private static readonly int[] VitalsChancePercents = [8, 10, 12, 15, 20, 30];
    private static readonly int[] PiercingCriticalChancePercents = [3, 5, 8, 11, 15, 20];
    private static readonly int[] PiercingCriticalDamageBonusPercents = [20, 26, 32, 40, 50, 100];
    private static readonly int[] PoisonChancePercents = [10, 15, 20, 25, 30, 100];
    private static readonly int[] PoisonDamagePerTickValues = [80, 110, 150, 200, 260, 390];
    private static readonly int[] PoisonResistPercents = [10, 15, 20, 25, 30, 100];
    private static readonly int[] SuckBloodHealPercents = [10, 12, 14, 16, 20, 30];
    private static readonly int[] PlagueChancePercents = [10, 12, 15, 18, 22, 30];
    private static readonly int[] PlagueDamagePerTickValues = [60, 80, 100, 130, 170, 240];
    private static readonly int[] GasBombChancePercents = [20, 25, 30, 35, 45, 100];
    private static readonly int[] GasBombDamagePerTickValues = [50, 70, 90, 120, 160, 220];
    private static readonly int[] FeudDamageBonusPercents = [10, 15, 20, 25, 30, 50];
    private static readonly TimeSpan TransferStoredDamageBuffDuration = TimeSpan.FromSeconds(20);
    private static readonly TimeSpan PeriodicBuffTickInterval = TimeSpan.FromSeconds(2);

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
    private readonly Dictionary<int, Dictionary<byte, GameDropItemRuntime>> _gameDropItemsByRoomId = new();
    private readonly Dictionary<int, HashSet<byte>> _retiredGameUidsByRoomId = new();
    private readonly Dictionary<int, Dictionary<long, PlayerSkillRuntime>> _gameSkillRuntimeByRoomId = new();
    private readonly Dictionary<int, Dictionary<byte, Dictionary<short, GameBuffRuntime>>> _gameBuffsByRoomId = new();
    private readonly Dictionary<int, List<GameBuffStartAction>> _pendingBuffStartActionsByRoomId = new();
    private readonly Dictionary<PendingChannelJoinKey, Queue<PendingChannelJoin>> _pendingChannelJoins = new();
    private readonly Dictionary<long, GameClient> _gameClientsByCharacterId = new();
    private readonly Dictionary<long, GameClientRpcActivity> _gameClientRpcActivityByCharacterId = new();

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
                _gameClientRpcActivityByCharacterId.Remove(characterId);
            }
        }
    }

    public void MarkGameClientRpcActivity(long characterId, string rpcName)
    {
        if (characterId <= 0)
        {
            return;
        }

        lock (_lock)
        {
            _gameClientRpcActivityByCharacterId[characterId] = new GameClientRpcActivity(
                DateTimeOffset.UtcNow,
                rpcName);
        }
    }

    public bool TryGetGameClientRpcActivity(long characterId, out GameClientRpcActivity activity)
    {
        lock (_lock)
        {
            return _gameClientRpcActivityByCharacterId.TryGetValue(characterId, out activity);
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

    public void UpdateGamePlayerState(
        int roomId,
        byte uid,
        byte teamId,
        int maxHealth,
        long characterId = 0,
        PlayerSkillRuntime? skills = null)
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
            if (characterId > 0)
            {
                player.CharacterId = characterId;
            }

            player.MaxHealth = Math.Max(1, maxHealth);
            if (player.CurrentHealth <= 0 || player.CurrentHealth > player.MaxHealth)
            {
                player.CurrentHealth = player.MaxHealth;
            }

            if (skills is not null)
            {
                if (!_gameSkillRuntimeByRoomId.TryGetValue(roomId, out var skillsByCharacterId))
                {
                    skillsByCharacterId = new Dictionary<long, PlayerSkillRuntime>();
                    _gameSkillRuntimeByRoomId[roomId] = skillsByCharacterId;
                }

                var runtimeCharacterId = characterId > 0 ? characterId : player.CharacterId;
                if (runtimeCharacterId > 0)
                {
                    skillsByCharacterId[runtimeCharacterId] = skills.Value;
                }
            }
        }
    }

    public bool TrySetGamePlayerHealth(
        int roomId,
        byte uid,
        int health,
        out GameDamageAction action)
    {
        lock (_lock)
        {
            action = default;
            if (!_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) ||
                !playersByUid.TryGetValue(uid, out var player))
            {
                return false;
            }

            var clampedHealth = Math.Clamp(health, 1, 100000);
            player.MaxHealth = clampedHealth;
            player.CurrentHealth = clampedHealth;
            action = new GameDamageAction(
                AttackerUid: uid,
                VictimUid: uid,
                Damage: 0,
                VictimHealth: clampedHealth,
                VictimMaxHealth: clampedHealth,
                Killed: false);
            return true;
        }
    }

    public bool TryGetGamePlayerHealth(
        int roomId,
        byte uid,
        out int currentHealth,
        out int maxHealth)
    {
        lock (_lock)
        {
            currentHealth = 0;
            maxHealth = 0;
            if (!_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid) ||
                !playersByUid.TryGetValue(uid, out var player))
            {
                return false;
            }

            currentHealth = player.CurrentHealth;
            maxHealth = player.MaxHealth;
            return true;
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
                ClearBreakableStealthNoLock(roomId, shoot.Uid);
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

    public async Task<int> BroadcastGameUseAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte actorUid,
        byte slot,
        byte success,
        byte usedNum)
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
                await target.SendPacket160GameUseAsync(actorUid, slot, success, usedNum);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGameBuffStartAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte fromUid,
        byte targetUid,
        short buffType,
        float duration,
        byte cooldownLock,
        float value1,
        float value2)
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
                await target.SendPacket162BuffStartAsync(
                    fromUid,
                    targetUid,
                    buffType,
                    duration,
                    cooldownLock,
                    value1,
                    value2);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        lock (_lock)
        {
            RegisterGameBuffNoLock(roomId, targetUid, fromUid, buffType, duration, value1, value2);
        }

        return sent;
    }

    public void ClearGameBuff(int roomId, byte targetUid, short buffType)
    {
        lock (_lock)
        {
            if (_gameBuffsByRoomId.TryGetValue(roomId, out var buffsByUid) &&
                buffsByUid.TryGetValue(targetUid, out var buffs))
            {
                buffs.Remove(buffType);
                if (buffs.Count == 0)
                {
                    buffsByUid.Remove(targetUid);
                }
            }
        }
    }

    public async Task<int> BroadcastGameSkillFeedbackAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte fromUid,
        byte targetUid,
        byte skillCode)
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
                await target.SendPacket162GameSkillFeedbackAsync(
                    fromUid,
                    targetUid,
                    skillCode);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGameBuffStartsAsync(
        int roomId,
        IReadOnlyList<GameBuffStartAction> actions)
    {
        if (actions.Count == 0)
        {
            return 0;
        }

        PracticeRoomChannelProtocol[] targets;
        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            targets = channels.Keys.ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                foreach (var action in actions)
                {
                    await target.SendPacket162BuffStartAsync(
                        action.FromUid,
                        action.TargetUid,
                        action.BuffType,
                        action.Duration,
                        action.CooldownLock,
                        action.Value1,
                        action.Value2);
                    sent++;
                }
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public async Task<int> BroadcastGameThrowDropItemAsync(
        int roomId,
        PracticeRoomChannelProtocol source,
        byte actorUid,
        byte dropType,
        byte dropId,
        byte slot,
        short positionXRaw,
        short positionYRaw,
        short positionZRaw,
        short directionXRaw,
        short directionYRaw,
        short directionZRaw,
        short value)
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
                await target.SendPacket185ThrowDropItemAsync(
                    actorUid,
                    dropType,
                    dropId,
                    slot,
                    positionXRaw,
                    positionYRaw,
                    positionZRaw,
                    directionXRaw,
                    directionYRaw,
                    directionZRaw,
                    value);
                sent++;
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
    }

    public void RegisterGameDropItem(
        int roomId,
        byte dropId,
        byte ownerUid,
        byte dropType,
        byte slot,
        short positionXRaw = 0,
        short positionYRaw = 0,
        short positionZRaw = 0,
        int value = 0,
        int secondaryValue = 0)
    {
        if (roomId <= 0 || dropId == 0)
        {
            return;
        }

        lock (_lock)
        {
            if (!_roomsById.ContainsKey(roomId))
            {
                return;
            }

            if (!_gameDropItemsByRoomId.TryGetValue(roomId, out var dropItemsById))
            {
                dropItemsById = new Dictionary<byte, GameDropItemRuntime>();
                _gameDropItemsByRoomId[roomId] = dropItemsById;
            }

            dropItemsById[dropId] = new GameDropItemRuntime(
                dropId,
                ownerUid,
                dropType,
                slot,
                new GamePosition(
                    positionXRaw,
                    positionYRaw,
                positionZRaw,
                null,
                null,
                null,
                DateTimeOffset.UtcNow),
                value,
                secondaryValue,
                DateTimeOffset.UtcNow,
                DateTimeOffset.UtcNow,
                false);
        }
    }

    public async Task<GameAreaEffectBroadcastResult> TriggerSnareDropItemsNearEnemiesAsync(int roomId)
    {
        PracticeRoomChannelProtocol[] targets = [];
        GameDamageAction[] actions;
        GameDamageAction[] periodicActions;
        GameBuffStartAction[] buffStartActions;
        var hasChannels = false;

        lock (_lock)
        {
            actions = TriggerSnareDropItemsNearEnemiesNoLock(roomId);
            periodicActions = ProcessGamePeriodicEffectsNoLock(roomId);
            buffStartActions = DrainPendingBuffStartActionsNoLock(roomId);
            if (_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                hasChannels = true;
                targets = channels.Keys.ToArray();
            }
        }

        if (periodicActions.Length > 0)
        {
            actions = actions.Concat(periodicActions).ToArray();
        }

        if (!hasChannels)
        {
            return new GameAreaEffectBroadcastResult(
                false,
                0,
                0,
                0,
                "no-channels");
        }

        if (actions.Length == 0)
        {
            var buffSent = await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
            return new GameAreaEffectBroadcastResult(
                buffSent > 0,
                buffSent,
                0,
                0,
                buffSent > 0 ? "buff-start" : "no-targets");
        }

        var sent = await BroadcastDamageActionsToTargetsAsync(roomId, targets, actions);
        sent += await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
        var killed = actions.Count(action => action.Killed);
        foreach (var action in actions.Where(action => action.Killed))
        {
            _ = RespawnGamePlayerAfterDelayAsync(
                roomId,
                action.VictimUid,
                GameAutoRespawnDelayMilliseconds,
                "auto-respawn-after-snare");
        }

        return new GameAreaEffectBroadcastResult(true, sent, actions.Length, killed, "snare");
    }

    public async Task<GameAreaEffectBroadcastResult> ProcessGamePeriodicEffectsAsync(int roomId)
    {
        PracticeRoomChannelProtocol[] targets = [];
        GameDamageAction[] actions;
        GameBuffStartAction[] buffStartActions;
        var hasChannels = false;

        lock (_lock)
        {
            actions = ProcessGamePeriodicEffectsNoLock(roomId);
            buffStartActions = DrainPendingBuffStartActionsNoLock(roomId);
            if (_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                hasChannels = true;
                targets = channels.Keys.ToArray();
            }
        }

        if (actions.Length == 0 || !hasChannels)
        {
            var buffSent = await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
            return new GameAreaEffectBroadcastResult(
                buffSent > 0,
                buffSent,
                0,
                0,
                buffSent > 0 ? "buff-start" : actions.Length == 0 ? "no-effects" : "no-channels");
        }

        var sent = await BroadcastDamageActionsToTargetsAsync(roomId, targets, actions);
        sent += await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
        var killed = actions.Count(action => action.Killed);
        foreach (var action in actions.Where(action => action.Killed))
        {
            _ = RespawnGamePlayerAfterDelayAsync(
                roomId,
                action.VictimUid,
                GameAutoRespawnDelayMilliseconds,
                "auto-respawn-after-periodic-effect");
        }

        return new GameAreaEffectBroadcastResult(true, sent, actions.Length, killed, "periodic");
    }

    private GameDamageAction[] ProcessGamePeriodicEffectsNoLock(int roomId)
    {
        if (!_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid))
        {
            return [];
        }

        var now = DateTimeOffset.UtcNow;
        var actions = new List<GameDamageAction>();
        actions.AddRange(ProcessEnergyDropItemsNoLock(roomId, playersByUid, now));
        if (!_gameBuffsByRoomId.TryGetValue(roomId, out var buffsByUid))
        {
            return actions.ToArray();
        }

        foreach (var (targetUid, buffs) in buffsByUid.ToArray())
        {
            if (!playersByUid.TryGetValue(targetUid, out var target))
            {
                buffsByUid.Remove(targetUid);
                continue;
            }

            foreach (var (buffType, buff) in buffs.ToArray())
            {
                if (buff.ExpiresAt <= now)
                {
                    buffs.Remove(buffType);
                    continue;
                }

                if (now - buff.LastTickAt < PeriodicBuffTickInterval)
                {
                    continue;
                }

                switch (buffType)
                {
                    case GameBuffTypePoison:
                    case GameBuffTypePoisoned:
                    case GameBuffTypePlague:
                    case GameBuffTypeGasBomb:
                        if (target.CurrentHealth > 0)
                        {
                            var damage = Math.Max(1, (int)MathF.Round(buff.Value1));
                            if ((buffType == GameBuffTypePoison || buffType == GameBuffTypePoisoned) &&
                                TryResolvePoisonResistPercentNoLock(roomId, target, out var poisonResistPercent))
                            {
                                damage = Math.Max(1, (int)MathF.Round(damage * (100 - poisonResistPercent) / 100f));
                            }

                            var action = ApplyPeriodicDamageNoLock(target, buff.SourceUid, damage);
                            actions.Add(action);
                            var extraActions = new List<GameDamageAction>();
                            ChargeTransferNoLock(roomId, target, buff.SourceUid, action.Damage, extraActions);
                            if (action.Killed &&
                                playersByUid.TryGetValue(action.AttackerUid, out var attacker) &&
                                attacker.Uid != target.Uid)
                            {
                                ApplyKillSkillEffectsNoLock(roomId, attacker, target, extraActions);
                            }

                            actions.AddRange(extraActions);
                        }

                        buffs[buffType] = buff with { LastTickAt = now };
                        break;

                    case GameBuffTypeEnergy:
                        if (target.CurrentHealth > 0)
                        {
                            var tickHeal = Math.Max(1, (int)MathF.Round(buff.Value1));
                            var totalRemaining = buff.Value2 <= 0f ? tickHeal : Math.Max(0, (int)MathF.Round(buff.Value2));
                            var heal = Math.Min(tickHeal, totalRemaining);
                            if (heal > 0)
                            {
                                ApplySelfHealNoLock(target, heal, actions);
                                var nextRemaining = totalRemaining - heal;
                                if (nextRemaining <= 0)
                                {
                                    buffs.Remove(buffType);
                                }
                                else
                                {
                                    buffs[buffType] = buff with { LastTickAt = now, Value2 = nextRemaining };
                                }
                            }
                        }

                        break;

                    case GameBuffTypeTenacity:
                        ApplyTenacityPeriodicHealNoLock(roomId, target, actions);
                        buffs[buffType] = buff with { LastTickAt = now };
                        break;
                }
            }

            if (buffs.Count == 0)
            {
                buffsByUid.Remove(targetUid);
            }
        }

        return actions.ToArray();
    }

    private GameDamageAction[] ProcessEnergyDropItemsNoLock(
        int roomId,
        Dictionary<byte, GamePlayerRuntime> playersByUid,
        DateTimeOffset now)
    {
        if (!_roomsById.TryGetValue(roomId, out var room) ||
            !_gameDropItemsByRoomId.TryGetValue(roomId, out var dropItemsById))
        {
            return [];
        }

        var actions = new List<GameDamageAction>();
        foreach (var currentDropItem in dropItemsById.Values.OrderBy(item => item.DropId).ToArray())
        {
            var dropItem = currentDropItem;
            if (dropItem.Triggered ||
                dropItem.DropType != GameDropTypeEnergy ||
                !playersByUid.TryGetValue(dropItem.OwnerUid, out var owner))
            {
                continue;
            }

            var ownerTeamId = ResolveGamePlayerTeamId(room, owner);
            if (ownerTeamId == GameTeamSpectator)
            {
                continue;
            }

            if (dropItem.LastTickAt == dropItem.CreatedAt)
            {
                QueueEnergyDropAreaBuffStartsNoLock(roomId, room, playersByUid, dropItemsById, dropItem, ownerTeamId, now);
                dropItem = dropItemsById[dropItem.DropId];
            }

            var totalRemaining = dropItem.Value <= 0 ? dropItem.SecondaryValue : dropItem.Value;
            var tickHeal = Math.Max(1, dropItem.SecondaryValue);
            var heal = Math.Min(tickHeal, totalRemaining);
            if (heal <= 0)
            {
                dropItemsById.Remove(dropItem.DropId);
                continue;
            }

            var dropPosition = MovementPositionToWorld(dropItem.Position);
            actions.AddRange(ApplyAreaHealAtNoLock(
                room,
                playersByUid,
                dropItem.OwnerUid,
                ownerTeamId,
                dropPosition,
                heal,
                EnergyHealRadius));

            var nextRemaining = totalRemaining - heal;
            if (nextRemaining <= 0)
            {
                dropItemsById.Remove(dropItem.DropId);
            }
            else
            {
                dropItemsById[dropItem.DropId] = dropItem with
                {
                    Value = nextRemaining,
                    LastTickAt = now
                };
            }
        }

        if (dropItemsById.Count == 0)
        {
            _gameDropItemsByRoomId.Remove(roomId);
        }

        return actions.ToArray();
    }

    private void QueueEnergyDropAreaBuffStartsNoLock(
        int roomId,
        PracticeRoomSession room,
        Dictionary<byte, GamePlayerRuntime> playersByUid,
        Dictionary<byte, GameDropItemRuntime> dropItemsById,
        GameDropItemRuntime dropItem,
        byte ownerTeamId,
        DateTimeOffset now)
    {
        var duration = Math.Max(
            (float)PeriodicBuffTickInterval.TotalSeconds,
            dropItem.Value / (float)Math.Max(1, dropItem.SecondaryValue) * (float)PeriodicBuffTickInterval.TotalSeconds);
        var dropPosition = MovementPositionToWorld(dropItem.Position);
        var radiusSquared = EnergyHealRadius * EnergyHealRadius;
        foreach (var player in playersByUid.Values.OrderBy(player => player.Uid))
        {
            if (player.CurrentHealth <= 0 ||
                ResolveGamePlayerTeamId(room, player) != ownerTeamId ||
                !TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) ||
                DistanceSquared(dropPosition.X, dropPosition.Y, dropPosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) > radiusSquared)
            {
                continue;
            }

            QueueBuffStartActionNoLock(
                roomId,
                dropItem.OwnerUid,
                player.Uid,
                GameBuffTypeEnergy,
                duration,
                0,
                Math.Max(1, dropItem.SecondaryValue),
                Math.Max(1, dropItem.Value));
        }

        dropItemsById[dropItem.DropId] = dropItem with { LastTickAt = now };
    }

    private GameDamageAction ApplyPeriodicDamageNoLock(GamePlayerRuntime target, byte sourceUid, int damage)
    {
        var maxHealth = Math.Max(1, target.MaxHealth);
        var appliedDamage = Math.Clamp(damage, 1, maxHealth);
        var previousHealth = target.CurrentHealth;
        target.CurrentHealth = Math.Max(0, target.CurrentHealth - appliedDamage);
        return new GameDamageAction(
            AttackerUid: sourceUid == 0 ? target.Uid : sourceUid,
            VictimUid: target.Uid,
            Damage: appliedDamage,
            VictimHealth: target.CurrentHealth,
            VictimMaxHealth: maxHealth,
            Killed: previousHealth > 0 && target.CurrentHealth == 0);
    }

    private void ApplyTenacityPeriodicHealNoLock(int roomId, GamePlayerRuntime target, List<GameDamageAction> actions)
    {
        var runtime = ResolvePlayerSkillRuntimeNoLock(roomId, target);
        if (!runtime.HasSkill(GameSkillTypeTenacity) ||
            !TrySkillLevel(runtime, GameSkillTypeTenacity, out var level) ||
            target.CurrentHealth <= 0)
        {
            return;
        }

        var maxHealth = Math.Max(1, target.MaxHealth);
        if (target.CurrentHealth >= maxHealth / 2)
        {
            return;
        }

        var heal = GetLevelValue(TenacityHealPerTickValues, level);
        ApplySelfHealNoLock(target, heal, actions);
        QueueBuffStartActionNoLock(roomId, target.Uid, target.Uid, GameBuffTypeTenacity, 2f, 0, heal, 0f);
    }

    private GameDamageAction[] TriggerSnareDropItemsNearEnemiesNoLock(int roomId)
    {
        if (!_roomsById.TryGetValue(roomId, out var room) ||
            !_gameDropItemsByRoomId.TryGetValue(roomId, out var dropItemsById) ||
            !_gamePlayersByRoomId.TryGetValue(roomId, out var playersByUid))
        {
            return [];
        }

        var actions = new List<GameDamageAction>();
        foreach (var dropItem in dropItemsById.Values.OrderBy(item => item.DropId).ToArray())
        {
            if (dropItem.Triggered ||
                dropItem.DropType != GameDropTypeSnare ||
                !playersByUid.TryGetValue(dropItem.OwnerUid, out var owner))
            {
                continue;
            }

            var ownerTeamId = ResolveGamePlayerTeamId(room, owner);
            if (ownerTeamId == GameTeamSpectator)
            {
                continue;
            }

            var dropPosition = MovementPositionToWorld(dropItem.Position);
            var triggerRadiusSquared = SnareTriggerRadius * SnareTriggerRadius;
            var hasEnemyInTrigger = playersByUid.Values.Any(player =>
                player.Uid != dropItem.OwnerUid &&
                player.CurrentHealth > 0 &&
                IsEnemyTeam(ownerTeamId, ResolveGamePlayerTeamId(room, player)) &&
                TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) &&
                DistanceSquared(dropPosition.X, dropPosition.Y, dropPosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) <= triggerRadiusSquared);

            if (!hasEnemyInTrigger)
            {
                continue;
            }

            dropItemsById[dropItem.DropId] = dropItem with { Triggered = true };
            actions.AddRange(ApplyAreaDamageAtNoLock(
                roomId,
                dropItem.OwnerUid,
                dropPosition,
                Math.Max(1, dropItem.Value),
                SnareDamageRadius));
        }

        return actions.ToArray();
    }

    public bool HasRecentGameDropItem(
        int roomId,
        byte ownerUid,
        byte slot,
        TimeSpan maxAge)
    {
        lock (_lock)
        {
            if (!_gameDropItemsByRoomId.TryGetValue(roomId, out var dropItemsById))
            {
                return false;
            }

            var now = DateTimeOffset.UtcNow;
            return dropItemsById.Values.Any(dropItem =>
                dropItem.OwnerUid == ownerUid &&
                dropItem.Slot == slot &&
                now - dropItem.CreatedAt <= maxAge);
        }
    }

    public byte[] ListGameAreaAllyUids(
        int roomId,
        byte sourceUid,
        float radius,
        bool includeSelf)
    {
        lock (_lock)
        {
            if (!TryGetRoomPlayerContextNoLock(roomId, sourceUid, out var room, out var playersByUid, out var source))
            {
                return [];
            }

            var sourceTeamId = ResolveGamePlayerTeamId(room, source);
            if (sourceTeamId == GameTeamSpectator ||
                !TryResolveProximityWorldPosition(source, preferShoot: false, out var sourcePosition))
            {
                return [];
            }

            var radiusSquared = MathF.Max(0.1f, radius) * MathF.Max(0.1f, radius);
            return playersByUid.Values
                .Where(player =>
                    (includeSelf || player.Uid != sourceUid) &&
                    player.CurrentHealth > 0 &&
                    ResolveGamePlayerTeamId(room, player) == sourceTeamId &&
                    TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) &&
                    DistanceSquared(sourcePosition.X, sourcePosition.Y, sourcePosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) <= radiusSquared)
                .OrderBy(player => player.Uid)
                .Select(player => player.Uid)
                .ToArray();
        }
    }

    public byte[] ListGameAreaEnemyUids(
        int roomId,
        byte sourceUid,
        float radius)
    {
        lock (_lock)
        {
            if (!TryGetRoomPlayerContextNoLock(roomId, sourceUid, out var room, out var playersByUid, out var source))
            {
                return [];
            }

            var sourceTeamId = ResolveGamePlayerTeamId(room, source);
            if (sourceTeamId == GameTeamSpectator ||
                !TryResolveProximityWorldPosition(source, preferShoot: false, out var sourcePosition))
            {
                return [];
            }

            var radiusSquared = MathF.Max(0.1f, radius) * MathF.Max(0.1f, radius);
            return playersByUid.Values
                .Where(player =>
                    player.Uid != sourceUid &&
                    player.CurrentHealth > 0 &&
                    IsEnemyTeam(sourceTeamId, ResolveGamePlayerTeamId(room, player)) &&
                    TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) &&
                    DistanceSquared(sourcePosition.X, sourcePosition.Y, sourcePosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) <= radiusSquared)
                .OrderBy(player => player.Uid)
                .Select(player => player.Uid)
                .ToArray();
        }
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
        GameDamageAction[] periodicActions;
        GameBuffStartAction[] buffStartActions;

        lock (_lock)
        {
            damageAttempt = TryApplyEnemyDamageNoLock(roomId, attackerUid, damage, hitRule, clientTargetUid);
            if (damageAttempt.Action is null ||
                !_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return CreateGameDamageNotAppliedResult(damageAttempt);
            }

            periodicActions = ProcessGamePeriodicEffectsNoLock(roomId);
            buffStartActions = DrainPendingBuffStartActionsNoLock(roomId);
            targets = channels.Keys.ToArray();
        }

        var actions = damageAttempt.ExtraActions.Count == 0
            ? [damageAttempt.Action.Value]
            : damageAttempt.ExtraActions.Prepend(damageAttempt.Action.Value).ToArray();
        if (periodicActions.Length > 0)
        {
            actions = actions.Concat(periodicActions).ToArray();
        }
        var sent = 0;
        var deathSent = 0;
        foreach (var target in targets)
        {
            try
            {
                foreach (var action in actions)
                {
                    await target.SendPacket184RemoteDamageHitAsync(action);
                    sent++;
                    if (action.Killed)
                    {
                        deathSent++;
                    }
                }
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }
        sent += await BroadcastGameBuffStartsAsync(roomId, buffStartActions);

        foreach (var action in actions.Where(action => action.Killed))
        {
            _ = RespawnGamePlayerAfterDelayAsync(
                roomId,
                action.VictimUid,
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

    public async Task<GameAreaEffectBroadcastResult> BroadcastGameAreaHealAsync(
        int roomId,
        byte healerUid,
        int heal,
        float radius,
        bool includeSelf)
    {
        PracticeRoomChannelProtocol[] targets = [];
        GameDamageAction[] actions;
        GameDamageAction[] periodicActions;
        GameBuffStartAction[] buffStartActions;
        var hasChannels = false;

        lock (_lock)
        {
            actions = ApplyAreaHealNoLock(roomId, healerUid, heal, radius, includeSelf);
            periodicActions = ProcessGamePeriodicEffectsNoLock(roomId);
            buffStartActions = DrainPendingBuffStartActionsNoLock(roomId);
            if (_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                hasChannels = true;
                targets = channels.Keys.ToArray();
            }
        }

        if (periodicActions.Length > 0)
        {
            actions = actions.Concat(periodicActions).ToArray();
        }

        if (actions.Length == 0 || !hasChannels)
        {
            var buffSent = await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
            return new GameAreaEffectBroadcastResult(
                buffSent > 0,
                buffSent,
                0,
                0,
                buffSent > 0 ? "buff-start" : actions.Length == 0 ? "no-targets" : "no-channels");
        }

        var sent = await BroadcastDamageActionsToTargetsAsync(roomId, targets, actions);
        sent += await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
        return new GameAreaEffectBroadcastResult(true, sent, actions.Length, 0, "heal");
    }

    public async Task<GameAreaEffectBroadcastResult> BroadcastGameAreaDamageAsync(
        int roomId,
        byte attackerUid,
        int damage,
        float radius)
    {
        PracticeRoomChannelProtocol[] targets = [];
        GameDamageAction[] actions;
        GameDamageAction[] periodicActions;
        GameBuffStartAction[] buffStartActions;
        var hasChannels = false;

        lock (_lock)
        {
            actions = ApplyAreaDamageNoLock(roomId, attackerUid, damage, radius);
            periodicActions = ProcessGamePeriodicEffectsNoLock(roomId);
            buffStartActions = DrainPendingBuffStartActionsNoLock(roomId);
            if (_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                hasChannels = true;
                targets = channels.Keys.ToArray();
            }
        }

        if (periodicActions.Length > 0)
        {
            actions = actions.Concat(periodicActions).ToArray();
        }

        if (actions.Length == 0 || !hasChannels)
        {
            var buffSent = await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
            return new GameAreaEffectBroadcastResult(
                buffSent > 0,
                buffSent,
                0,
                0,
                buffSent > 0 ? "buff-start" : actions.Length == 0 ? "no-targets" : "no-channels");
        }

        var sent = await BroadcastDamageActionsToTargetsAsync(roomId, targets, actions);
        sent += await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
        var killed = actions.Count(action => action.Killed);
        foreach (var action in actions.Where(action => action.Killed))
        {
            _ = RespawnGamePlayerAfterDelayAsync(
                roomId,
                action.VictimUid,
                GameAutoRespawnDelayMilliseconds,
                "auto-respawn-after-area-skill");
        }

        return new GameAreaEffectBroadcastResult(true, sent, actions.Length, killed, "damage");
    }

    public async Task<GameAreaEffectBroadcastResult> BroadcastGameSpurtDamageAsync(
        int roomId,
        byte attackerUid,
        int damage)
    {
        PracticeRoomChannelProtocol[] targets = [];
        GameDamageAction[] actions;
        GameDamageAction[] periodicActions;
        GameBuffStartAction[] buffStartActions;
        var hasChannels = false;

        lock (_lock)
        {
            actions = ApplySpurtDamageNoLock(roomId, attackerUid, damage, SpurtSkillRange, SpurtSkillHitRadius);
            periodicActions = ProcessGamePeriodicEffectsNoLock(roomId);
            buffStartActions = DrainPendingBuffStartActionsNoLock(roomId);
            if (_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                hasChannels = true;
                targets = channels.Keys.ToArray();
            }
        }

        if (periodicActions.Length > 0)
        {
            actions = actions.Concat(periodicActions).ToArray();
        }

        if (actions.Length == 0 || !hasChannels)
        {
            var buffSent = await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
            return new GameAreaEffectBroadcastResult(
                buffSent > 0,
                buffSent,
                0,
                0,
                buffSent > 0 ? "buff-start" : actions.Length == 0 ? "no-targets" : "no-channels");
        }

        var sent = await BroadcastDamageActionsToTargetsAsync(roomId, targets, actions);
        sent += await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
        var killed = actions.Count(action => action.Killed);
        foreach (var action in actions.Where(action => action.Killed))
        {
            _ = RespawnGamePlayerAfterDelayAsync(
                roomId,
                action.VictimUid,
                GameAutoRespawnDelayMilliseconds,
                "auto-respawn-after-spurt");
        }

        return new GameAreaEffectBroadcastResult(true, sent, actions.Length, killed, "spurt");
    }

    public async Task<GameAreaEffectBroadcastResult> BroadcastGameSkillTriggeredAreaDamageAsync(
        int roomId,
        byte attackerUid,
        int damage,
        float radius)
    {
        PracticeRoomChannelProtocol[] targets = [];
        GameDamageAction[] actions;
        GameDamageAction[] periodicActions;
        GameBuffStartAction[] buffStartActions;
        var hasChannels = false;

        lock (_lock)
        {
            actions = ApplyAreaDamageNoLock(roomId, attackerUid, damage, radius, applySkillModifiers: false);
            periodicActions = ProcessGamePeriodicEffectsNoLock(roomId);
            buffStartActions = DrainPendingBuffStartActionsNoLock(roomId);
            if (_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                hasChannels = true;
                targets = channels.Keys.ToArray();
            }
        }

        if (periodicActions.Length > 0)
        {
            actions = actions.Concat(periodicActions).ToArray();
        }

        if (actions.Length == 0 || !hasChannels)
        {
            var buffSent = await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
            return new GameAreaEffectBroadcastResult(
                buffSent > 0,
                buffSent,
                0,
                0,
                buffSent > 0 ? "buff-start" : actions.Length == 0 ? "no-targets" : "no-channels");
        }

        var sent = await BroadcastDamageActionsToTargetsAsync(roomId, targets, actions);
        sent += await BroadcastGameBuffStartsAsync(roomId, buffStartActions);
        var killed = actions.Count(action => action.Killed);
        foreach (var action in actions.Where(action => action.Killed))
        {
            _ = RespawnGamePlayerAfterDelayAsync(
                roomId,
                action.VictimUid,
                GameAutoRespawnDelayMilliseconds,
                "auto-respawn-after-triggered-area-skill");
        }

        return new GameAreaEffectBroadcastResult(true, sent, actions.Length, killed, "damage");
    }

    private async Task<int> BroadcastDamageActionsToTargetsAsync(
        int roomId,
        IReadOnlyList<PracticeRoomChannelProtocol> targets,
        IReadOnlyList<GameDamageAction> actions)
    {
        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                foreach (var action in actions)
                {
                    await target.SendPacket184RemoteDamageHitAsync(action);
                    sent++;
                }
            }
            catch
            {
                UnregisterGameChannel(roomId, target, out _);
            }
        }

        return sent;
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

    public async Task<int> BroadcastGameDamageHitAsync(
        int roomId,
        GameDamageAction action)
    {
        PracticeRoomChannelProtocol[] targets;
        lock (_lock)
        {
            if (!_gameChannelsByRoomId.TryGetValue(roomId, out var channels))
            {
                return 0;
            }

            targets = channels.Keys.ToArray();
        }

        var sent = 0;
        foreach (var target in targets)
        {
            try
            {
                await target.SendPacket184RemoteDamageHitAsync(action);
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
        _gameDropItemsByRoomId.Remove(roomId);
        _gameSkillRuntimeByRoomId.Remove(roomId);
        _gameBuffsByRoomId.Remove(roomId);
        _pendingBuffStartActionsByRoomId.Remove(roomId);
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
            var characterId = playersByUid.TryGetValue(removedUid, out var removedPlayer)
                ? removedPlayer.CharacterId
                : 0;
            playersByUid.Remove(removedUid);
            if (playersByUid.Count == 0)
            {
                _gamePlayersByRoomId.Remove(roomId);
            }

            if (characterId > 0 &&
                _gameSkillRuntimeByRoomId.TryGetValue(roomId, out var skillsByCharacterId))
            {
                skillsByCharacterId.Remove(characterId);
                if (skillsByCharacterId.Count == 0)
                {
                    _gameSkillRuntimeByRoomId.Remove(roomId);
                }
            }
        }

        if (_gameBuffsByRoomId.TryGetValue(roomId, out var buffsByUid))
        {
            buffsByUid.Remove(removedUid);
            if (buffsByUid.Count == 0)
            {
                _gameBuffsByRoomId.Remove(roomId);
            }
        }

        if (_gameDropItemsByRoomId.TryGetValue(roomId, out var dropItemsById))
        {
            var uidToRemove = removedUid;
            foreach (var dropId in dropItemsById
                         .Where(pair => pair.Value.OwnerUid == uidToRemove)
                         .Select(pair => pair.Key)
                         .ToArray())
            {
                dropItemsById.Remove(dropId);
            }

            if (dropItemsById.Count == 0)
            {
                _gameDropItemsByRoomId.Remove(roomId);
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
            _gameSkillRuntimeByRoomId.Remove(roomId);
            _gameBuffsByRoomId.Remove(roomId);
            _pendingBuffStartActionsByRoomId.Remove(roomId);
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
        var positionedCandidateCount = candidates.Count(HasAnyGamePosition);
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

        var runtime = ResolvePlayerSkillRuntimeNoLock(roomId, victim);
        damage = ApplyDamageModifiersNoLock(roomId, attacker, victim, damage);
        damage = ApplyShieldAbsorbNoLock(roomId, victim.Uid, damage, out var absorbedDamage);
        var previousHealth = victim.CurrentHealth;
        var maxHealth = Math.Max(1, victim.MaxHealth);
        var appliedDamage = damage <= 0 ? 0 : Math.Clamp(damage, 1, maxHealth);
        victim.CurrentHealth = Math.Max(0, victim.CurrentHealth - appliedDamage);
        var killed = previousHealth > 0 && victim.CurrentHealth == 0;
        var extraActions = new List<GameDamageAction>();
        ApplyPostDamageSkillEffectsNoLock(roomId, attacker, victim, appliedDamage, extraActions);

        if (!killed && runtime.HasSkill(GameSkillTypeTenacity) &&
            TrySkillLevel(runtime, GameSkillTypeTenacity, out var healLevel) &&
            victim.CurrentHealth > 0 &&
            victim.CurrentHealth < (maxHealth / 2))
        {
            var heal = GetLevelValue(TenacityHealPerTickValues, healLevel);
            victim.CurrentHealth = Math.Min(maxHealth, victim.CurrentHealth + heal);
            RegisterGameBuffNoLock(roomId, victim.Uid, victim.Uid, GameBuffTypeTenacity, 2f, heal, 0f);
            QueueBuffStartActionNoLock(roomId, victim.Uid, victim.Uid, GameBuffTypeTenacity, 2f, 0, heal, 0f);
        }

        ChargeTransferNoLock(roomId, victim, attackerUid, appliedDamage + absorbedDamage, extraActions);
        if (killed)
        {
            ApplyKillSkillEffectsNoLock(roomId, attacker, victim, extraActions);
        }

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
            bestHitScore,
            extraActions);
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

    private GameDamageAction[] ApplyAreaHealNoLock(
        int roomId,
        byte healerUid,
        int heal,
        float radius,
        bool includeSelf)
    {
        if (heal <= 0 ||
            !TryGetRoomPlayerContextNoLock(roomId, healerUid, out var room, out var playersByUid, out var healer))
        {
            return [];
        }

        var healerTeamId = ResolveGamePlayerTeamId(room, healer);
        if (healerTeamId == GameTeamSpectator ||
            !TryResolveProximityWorldPosition(healer, preferShoot: false, out var healerPosition))
        {
            return [];
        }

        var radiusSquared = MathF.Max(0.1f, radius) * MathF.Max(0.1f, radius);
        var actions = new List<GameDamageAction>();
        foreach (var player in playersByUid.Values.OrderBy(player => player.Uid))
        {
            if ((!includeSelf && player.Uid == healerUid) ||
                player.CurrentHealth <= 0 ||
                ResolveGamePlayerTeamId(room, player) != healerTeamId ||
                !TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) ||
                DistanceSquared(healerPosition.X, healerPosition.Y, healerPosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) > radiusSquared)
            {
                continue;
            }

            var maxHealth = Math.Max(1, player.MaxHealth);
            var previousHealth = player.CurrentHealth;
            player.CurrentHealth = Math.Min(maxHealth, player.CurrentHealth + heal);
            if (player.CurrentHealth == previousHealth)
            {
                continue;
            }

            actions.Add(new GameDamageAction(
                AttackerUid: healerUid,
                VictimUid: player.Uid,
                Damage: 0,
                VictimHealth: player.CurrentHealth,
                VictimMaxHealth: maxHealth,
                Killed: false));
        }

        return actions.ToArray();
    }

    private static GameDamageAction[] ApplyAreaHealAtNoLock(
        PracticeRoomSession room,
        Dictionary<byte, GamePlayerRuntime> playersByUid,
        byte healerUid,
        byte healerTeamId,
        (float X, float Y, float Z) sourcePosition,
        int heal,
        float radius)
    {
        if (heal <= 0 || healerTeamId == GameTeamSpectator)
        {
            return [];
        }

        var radiusSquared = MathF.Max(0.1f, radius) * MathF.Max(0.1f, radius);
        var actions = new List<GameDamageAction>();
        foreach (var player in playersByUid.Values.OrderBy(player => player.Uid))
        {
            if (player.CurrentHealth <= 0 ||
                ResolveGamePlayerTeamId(room, player) != healerTeamId ||
                !TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) ||
                DistanceSquared(sourcePosition.X, sourcePosition.Y, sourcePosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) > radiusSquared)
            {
                continue;
            }

            var maxHealth = Math.Max(1, player.MaxHealth);
            var previousHealth = player.CurrentHealth;
            player.CurrentHealth = Math.Min(maxHealth, player.CurrentHealth + heal);
            if (player.CurrentHealth == previousHealth)
            {
                continue;
            }

            actions.Add(new GameDamageAction(
                AttackerUid: healerUid,
                VictimUid: player.Uid,
                Damage: 0,
                VictimHealth: player.CurrentHealth,
                VictimMaxHealth: maxHealth,
                Killed: false));
        }

        return actions.ToArray();
    }

    private GameDamageAction[] ApplyAreaDamageNoLock(
        int roomId,
        byte attackerUid,
        int damage,
        float radius,
        bool applySkillModifiers = false)
    {
        if (damage <= 0 ||
            !TryGetRoomPlayerContextNoLock(roomId, attackerUid, out var room, out var playersByUid, out var attacker))
        {
            return [];
        }

        var attackerTeamId = ResolveGamePlayerTeamId(room, attacker);
        if (attackerTeamId == GameTeamSpectator ||
            !TryResolveProximityWorldPosition(attacker, preferShoot: false, out var attackerPosition))
        {
            return [];
        }

        var radiusSquared = MathF.Max(0.1f, radius) * MathF.Max(0.1f, radius);
        var actions = new List<GameDamageAction>();
        foreach (var player in playersByUid.Values.OrderBy(player => player.Uid))
        {
            if (player.Uid == attackerUid ||
                player.CurrentHealth <= 0 ||
                !IsEnemyTeam(attackerTeamId, ResolveGamePlayerTeamId(room, player)) ||
                !TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) ||
                DistanceSquared(attackerPosition.X, attackerPosition.Y, attackerPosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) > radiusSquared)
            {
                continue;
            }

            var effectiveDamage = applySkillModifiers
                ? ApplyDamageModifiersNoLock(roomId, attacker, player, damage)
                : ApplyIncomingDamageModifiersNoLock(roomId, player, damage);
            var mitigatedDamage = ApplyShieldAbsorbNoLock(roomId, player.Uid, effectiveDamage, out var absorbedDamage);
            var maxHealth = Math.Max(1, player.MaxHealth);
            var appliedDamage = mitigatedDamage <= 0 ? 0 : Math.Clamp(mitigatedDamage, 1, maxHealth);
            var previousHealth = player.CurrentHealth;
            player.CurrentHealth = Math.Max(0, player.CurrentHealth - appliedDamage);
            var killed = previousHealth > 0 && player.CurrentHealth == 0;
            var extraActions = new List<GameDamageAction>();
            if (applySkillModifiers)
            {
                ApplyPostDamageSkillEffectsNoLock(roomId, attacker, player, appliedDamage, extraActions);
            }

            ChargeTransferNoLock(roomId, player, attackerUid, appliedDamage + absorbedDamage, extraActions);
            if (killed)
            {
                ApplyKillSkillEffectsNoLock(roomId, attacker, player, extraActions);
            }

            actions.Add(new GameDamageAction(
                AttackerUid: attackerUid,
                VictimUid: player.Uid,
                Damage: appliedDamage,
                VictimHealth: player.CurrentHealth,
                VictimMaxHealth: maxHealth,
                Killed: killed));
            actions.AddRange(extraActions);
        }

        return actions.ToArray();
    }

    private GameDamageAction[] ApplySpurtDamageNoLock(
        int roomId,
        byte attackerUid,
        int damage,
        float maxRange,
        float hitRadius)
    {
        if (damage <= 0 ||
            !TryGetRoomPlayerContextNoLock(roomId, attackerUid, out var room, out var playersByUid, out var attacker))
        {
            return [];
        }

        var attackerTeamId = ResolveGamePlayerTeamId(room, attacker);
        if (attackerTeamId == GameTeamSpectator ||
            !TryResolveMovementWorldPosition(attacker, out var attackerPosition))
        {
            return [];
        }

        var direction = ResolveSpurtDirection(attacker);
        if (direction.LengthSquared <= 0f)
        {
            return [];
        }

        var runtime = ResolvePlayerSkillRuntimeNoLock(roomId, attacker);
        var poisonLevel = 0;
        var hasPoisonSkill = runtime.HasSkill(GameSkillTypePoison) &&
            TrySkillLevel(runtime, GameSkillTypePoison, out poisonLevel);
        var poisonDamage = hasPoisonSkill ? GetLevelValue(PoisonDamagePerTickValues, poisonLevel) : 0;
        var actions = new List<GameDamageAction>();

        var scoredTargets = new List<(GamePlayerRuntime Player, float Score)>();
        foreach (var player in playersByUid.Values)
        {
            if (player.Uid == attackerUid ||
                player.CurrentHealth <= 0 ||
                !IsEnemyTeam(attackerTeamId, ResolveGamePlayerTeamId(room, player)) ||
                !TryResolveMovementWorldPosition(player, out var targetPosition) ||
                !TryComputeSpurtHitScore(attackerPosition, direction, targetPosition, maxRange, hitRadius, out var score))
            {
                continue;
            }

            scoredTargets.Add((player, score));
        }

        foreach (var candidate in scoredTargets
            .OrderBy(candidate => candidate.Score)
            .ThenBy(candidate => candidate.Player.Uid))
        {
            var player = candidate.Player;
            if (player.CurrentHealth <= 0 ||
                !TryResolveMovementWorldPosition(player, out _))
            {
                continue;
            }

            var effectiveDamage = ApplyIncomingDamageModifiersNoLock(roomId, player, damage);
            var mitigatedDamage = ApplyShieldAbsorbNoLock(roomId, player.Uid, effectiveDamage, out var absorbedDamage);
            var maxHealth = Math.Max(1, player.MaxHealth);
            var appliedDamage = mitigatedDamage <= 0 ? 0 : Math.Clamp(mitigatedDamage, 1, maxHealth);
            var previousHealth = player.CurrentHealth;
            player.CurrentHealth = Math.Max(0, player.CurrentHealth - appliedDamage);
            var killed = previousHealth > 0 && player.CurrentHealth == 0;
            var extraActions = new List<GameDamageAction>();

            if (appliedDamage > 0 &&
                player.CurrentHealth > 0 &&
                hasPoisonSkill &&
                poisonDamage > 0)
            {
                RegisterGameBuffNoLock(
                    roomId,
                    player.Uid,
                    attackerUid,
                    GameBuffTypePoison,
                    12f,
                    poisonDamage,
                    0f);
                QueueBuffStartActionNoLock(roomId, attackerUid, player.Uid, GameBuffTypePoison, 12f, 0, poisonDamage, 0f);
            }

            ChargeTransferNoLock(roomId, player, attackerUid, appliedDamage + absorbedDamage, extraActions);
            if (killed)
            {
                ApplyKillSkillEffectsNoLock(roomId, attacker, player, extraActions);
            }

            actions.Add(new GameDamageAction(
                AttackerUid: attackerUid,
                VictimUid: player.Uid,
                Damage: appliedDamage,
                VictimHealth: player.CurrentHealth,
                VictimMaxHealth: maxHealth,
                Killed: killed));
            actions.AddRange(extraActions);
        }

        return actions.ToArray();
    }

    private GameDamageAction[] ApplyAreaDamageAtNoLock(
        int roomId,
        byte attackerUid,
        (float X, float Y, float Z) sourcePosition,
        int damage,
        float radius,
        bool applySkillModifiers = false)
    {
        if (damage <= 0 ||
            !TryGetRoomPlayerContextNoLock(roomId, attackerUid, out var room, out var playersByUid, out var attacker))
        {
            return [];
        }

        var attackerTeamId = ResolveGamePlayerTeamId(room, attacker);
        if (attackerTeamId == GameTeamSpectator)
        {
            return [];
        }

        var radiusSquared = MathF.Max(0.1f, radius) * MathF.Max(0.1f, radius);
        var actions = new List<GameDamageAction>();
        foreach (var player in playersByUid.Values.OrderBy(player => player.Uid))
        {
            if (player.Uid == attackerUid ||
                player.CurrentHealth <= 0 ||
                !IsEnemyTeam(attackerTeamId, ResolveGamePlayerTeamId(room, player)) ||
                !TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) ||
                DistanceSquared(sourcePosition.X, sourcePosition.Y, sourcePosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) > radiusSquared)
            {
                continue;
            }

            var effectiveDamage = applySkillModifiers
                ? ApplyDamageModifiersNoLock(roomId, attacker, player, damage)
                : ApplyIncomingDamageModifiersNoLock(roomId, player, damage);
            var mitigatedDamage = ApplyShieldAbsorbNoLock(roomId, player.Uid, effectiveDamage, out var absorbedDamage);
            var maxHealth = Math.Max(1, player.MaxHealth);
            var appliedDamage = mitigatedDamage <= 0 ? 0 : Math.Clamp(mitigatedDamage, 1, maxHealth);
            var previousHealth = player.CurrentHealth;
            player.CurrentHealth = Math.Max(0, player.CurrentHealth - appliedDamage);
            var killed = previousHealth > 0 && player.CurrentHealth == 0;
            var extraActions = new List<GameDamageAction>();
            if (applySkillModifiers)
            {
                ApplyPostDamageSkillEffectsNoLock(roomId, attacker, player, appliedDamage, extraActions);
            }

            ChargeTransferNoLock(roomId, player, attackerUid, appliedDamage + absorbedDamage, extraActions);
            if (killed)
            {
                ApplyKillSkillEffectsNoLock(roomId, attacker, player, extraActions);
            }

            actions.Add(new GameDamageAction(
                AttackerUid: attackerUid,
                VictimUid: player.Uid,
                Damage: appliedDamage,
                VictimHealth: player.CurrentHealth,
                VictimMaxHealth: maxHealth,
                Killed: killed));
            actions.AddRange(extraActions);
        }

        return actions.ToArray();
    }

    private static bool TryComputeProximityHitScore(
        GamePlayerRuntime attacker,
        GamePlayerRuntime candidate,
        GameDamageHitRule rule,
        out float score)
    {
        score = float.MaxValue;
        if (!TryResolveProximityWorldPosition(attacker, preferShoot: true, out var source) ||
            !TryResolveProximityWorldPosition(candidate, preferShoot: false, out var target))
        {
            return false;
        }

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

    private bool TryGetRoomPlayerContextNoLock(
        int roomId,
        byte uid,
        out PracticeRoomSession room,
        out Dictionary<byte, GamePlayerRuntime> playersByUid,
        out GamePlayerRuntime player)
    {
        if (_roomsById.TryGetValue(roomId, out room!) &&
            _gamePlayersByRoomId.TryGetValue(roomId, out playersByUid!) &&
            playersByUid.TryGetValue(uid, out player!))
        {
            return true;
        }

        room = null!;
        playersByUid = null!;
        player = null!;
        return false;
    }

    private PlayerSkillRuntime ResolvePlayerSkillRuntimeNoLock(int roomId, GamePlayerRuntime player)
    {
        var runtime = player.CharacterId > 0 &&
               _gameSkillRuntimeByRoomId.TryGetValue(roomId, out var skillsByCharacterId) &&
               skillsByCharacterId.TryGetValue(player.CharacterId, out var foundRuntime)
            ? foundRuntime
            : PlayerSkillRuntime.Empty;
        if (runtime.SkillResources.Count == 0 && runtime.SkillLevels.Count == 0)
        {
            return runtime;
        }

        var normalized = new Dictionary<byte, int>(runtime.SkillLevels);
        AddSkillAlias(runtime, normalized, "vitals", GameSkillTypeVitals);
        AddSkillAlias(runtime, normalized, "tenacity", GameSkillTypeTenacity);
        AddSkillAlias(runtime, normalized, "transfer", GameSkillTypeTransfer);
        AddSkillAlias(runtime, normalized, "piercing", GameSkillTypePiercing);
        AddSkillAlias(runtime, normalized, "poison", GameSkillTypePoison);
        AddSkillAlias(runtime, normalized, "heavy", GameSkillTypeHeavy);
        AddSkillAlias(runtime, normalized, "suckblood", GameSkillTypeSuckBlood);
        AddSkillAlias(runtime, normalized, "plague", GameSkillTypePlague);
        AddSkillAlias(runtime, normalized, "gasbomb", GameSkillTypeGasBomb);
        AddSkillAlias(runtime, normalized, "feud", GameSkillTypeFeud);
        return new PlayerSkillRuntime(normalized, runtime.SkillResources);
    }

    private static void AddSkillAlias(
        PlayerSkillRuntime runtime,
        IDictionary<byte, int> skillLevels,
        string resource,
        byte skillType)
    {
        if (!skillLevels.ContainsKey(skillType) &&
            runtime.HasSkillResource(resource))
        {
            skillLevels[skillType] = 1;
        }
    }

    private static bool TrySkillLevel(PlayerSkillRuntime runtime, byte skillType, out int level)
    {
        if (runtime.SkillLevels.TryGetValue(skillType, out level))
        {
            level = Math.Clamp(level, 1, 6);
            return true;
        }

        level = 0;
        return false;
    }

    private bool TryResolvePoisonResistPercentNoLock(int roomId, GamePlayerRuntime player, out int resistPercent)
    {
        var runtime = ResolvePlayerSkillRuntimeNoLock(roomId, player);
        if (runtime.HasSkill(GameSkillTypePoison) &&
            TrySkillLevel(runtime, GameSkillTypePoison, out var level))
        {
            resistPercent = GetLevelValue(PoisonResistPercents, level);
            return resistPercent > 0;
        }

        resistPercent = 0;
        return false;
    }

    private static int GetLevelValue(IReadOnlyList<int> values, int level)
    {
        if (values.Count == 0)
        {
            return 0;
        }

        return values[Math.Clamp(level, 1, values.Count) - 1];
    }

    private static bool ShouldTriggerSkillChance(byte sourceUid, byte targetUid, int chancePercent)
    {
        if (chancePercent >= 100)
        {
            return true;
        }

        if (chancePercent <= 0)
        {
            return false;
        }

        var seed = HashCode.Combine(sourceUid, targetUid, DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() / 250);
        var roll = Math.Abs(seed % 100);
        return roll < chancePercent;
    }

    private int ApplyDamageModifiersNoLock(
        int roomId,
        GamePlayerRuntime attacker,
        GamePlayerRuntime victim,
        int damage)
    {
        if (damage <= 0)
        {
            return 0;
        }

        var runtime = ResolvePlayerSkillRuntimeNoLock(roomId, attacker);
        if (runtime.HasSkill(GameSkillTypeVitals) &&
            TrySkillLevel(runtime, GameSkillTypeVitals, out var vitalsLevel) &&
            IsRifleAttack(attacker.LastShoot) &&
            ShouldTriggerSkillChance(attacker.Uid, victim.Uid, GetLevelValue(VitalsChancePercents, vitalsLevel)))
        {
            RegisterGameBuffNoLock(roomId, victim.Uid, attacker.Uid, GameBuffTypeVitals, 3f, 0f, 0f);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, victim.Uid, GameBuffTypeVitals, 3f, 0, 0f, 0f);
        }

        if (runtime.HasSkill(GameSkillTypePiercing) &&
            TrySkillLevel(runtime, GameSkillTypePiercing, out var piercingLevel) &&
            IsSniperAttack(attacker.LastShoot) &&
            ShouldTriggerSkillChance(attacker.Uid, victim.Uid, GetLevelValue(PiercingCriticalChancePercents, piercingLevel)))
        {
            damage = ApplyPercentBonus(damage, GetLevelValue(PiercingCriticalDamageBonusPercents, piercingLevel));
            RegisterGameBuffNoLock(roomId, attacker.Uid, attacker.Uid, GameBuffTypePiercing, 1f, damage, 0f);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, attacker.Uid, GameBuffTypePiercing, 1f, 0, damage, 0f);
        }

        if (runtime.HasSkill(GameSkillTypeHeavy) &&
            TrySkillLevel(runtime, GameSkillTypeHeavy, out var heavyLevel) &&
            IsMachineGunAttack(attacker.LastShoot))
        {
            RegisterGameBuffNoLock(roomId, attacker.Uid, attacker.Uid, GameBuffTypeHeavy, 1f, heavyLevel, 0f);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, attacker.Uid, GameBuffTypeHeavy, 1f, 0, heavyLevel, 0f);
        }

        if (runtime.HasSkill(GameSkillTypeFeud) &&
            TrySkillLevel(runtime, GameSkillTypeFeud, out var feudLevel) &&
            victim.LastKillerUid == attacker.Uid)
        {
            damage = ApplyPercentBonus(damage, GetLevelValue(FeudDamageBonusPercents, feudLevel));
            RegisterGameBuffNoLock(roomId, attacker.Uid, attacker.Uid, GameBuffTypeFeudAnger, 3f, GetLevelValue(FeudDamageBonusPercents, feudLevel), 0f);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, attacker.Uid, GameBuffTypeFeudAnger, 3f, 0, GetLevelValue(FeudDamageBonusPercents, feudLevel), 0f);
        }

        return ApplyIncomingDamageModifiersNoLock(roomId, victim, damage);
    }

    private int ApplyIncomingDamageModifiersNoLock(int roomId, GamePlayerRuntime victim, int damage)
    {
        if (damage <= 0)
        {
            return 0;
        }

        if (_gameBuffsByRoomId.TryGetValue(roomId, out var buffsByUid) &&
            buffsByUid.TryGetValue(victim.Uid, out var buffs))
        {
            var now = DateTimeOffset.UtcNow;
            if (buffs.TryGetValue(GameBuffTypeVitals, out var vitals) && vitals.ExpiresAt > now)
            {
                damage = ApplyPercentBonus(damage, VitalsDamageTakenBonusPercent);
            }

        }

        var runtime = ResolvePlayerSkillRuntimeNoLock(roomId, victim);
        if (runtime.HasSkill(GameSkillTypeTenacity) &&
            TrySkillLevel(runtime, GameSkillTypeTenacity, out var tenacityLevel))
        {
            var reductionPercent = GetLevelValue(TenacityDamageReductionPercents, tenacityLevel);
            damage = Math.Max(1, (int)MathF.Round(damage * (100 - reductionPercent) / 100f));
        }

        return Math.Max(0, damage);
    }

    private void ApplyPostDamageSkillEffectsNoLock(
        int roomId,
        GamePlayerRuntime attacker,
        GamePlayerRuntime victim,
        int appliedDamage,
        List<GameDamageAction> extraActions)
    {
        if (appliedDamage <= 0 || victim.CurrentHealth <= 0)
        {
            return;
        }

        var runtime = ResolvePlayerSkillRuntimeNoLock(roomId, attacker);
        if (runtime.HasSkill(GameSkillTypePoison) &&
            TrySkillLevel(runtime, GameSkillTypePoison, out var poisonLevel) &&
            IsKnifeAttack(attacker.LastShoot) &&
            ShouldTriggerSkillChance(attacker.Uid, victim.Uid, GetLevelValue(PoisonChancePercents, poisonLevel)))
        {
            var poisonDamage = GetLevelValue(PoisonDamagePerTickValues, poisonLevel);
            RegisterGameBuffNoLock(
                roomId,
                victim.Uid,
                attacker.Uid,
                GameBuffTypePoison,
                12f,
                poisonDamage,
                0f);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, victim.Uid, GameBuffTypePoison, 12f, 0, poisonDamage, 0f);
        }

        if (runtime.HasSkill(GameSkillTypePlague) &&
            TrySkillLevel(runtime, GameSkillTypePlague, out var plagueLevel) &&
            ShouldTriggerSkillChance(attacker.Uid, victim.Uid, GetLevelValue(PlagueChancePercents, plagueLevel)))
        {
            var plagueDamage = GetLevelValue(PlagueDamagePerTickValues, plagueLevel);
            RegisterGameBuffNoLock(
                roomId,
                victim.Uid,
                attacker.Uid,
                GameBuffTypePlague,
                12f,
                plagueDamage,
                0f);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, victim.Uid, GameBuffTypePlague, 12f, 0, plagueDamage, 0f);
        }

        if (runtime.HasSkill(GameSkillTypeGasBomb) &&
            TrySkillLevel(runtime, GameSkillTypeGasBomb, out var gasBombLevel) &&
            ShouldTriggerSkillChance(attacker.Uid, victim.Uid, GetLevelValue(GasBombChancePercents, gasBombLevel)))
        {
            var gasBombDamage = GetLevelValue(GasBombDamagePerTickValues, gasBombLevel);
            RegisterGameBuffNoLock(
                roomId,
                victim.Uid,
                attacker.Uid,
                GameBuffTypeGasBomb,
                8f,
                gasBombDamage,
                0f);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, victim.Uid, GameBuffTypeGasBomb, 8f, 0, gasBombDamage, 0f);
        }

        if (runtime.HasSkill(GameSkillTypeSuckBlood) &&
            TrySkillLevel(runtime, GameSkillTypeSuckBlood, out var suckBloodLevel))
        {
            var heal = Math.Max(1, (int)MathF.Round(appliedDamage * GetLevelValue(SuckBloodHealPercents, suckBloodLevel) / 100f));
            ApplySelfHealNoLock(attacker, heal, extraActions);
            RegisterGameBuffNoLock(roomId, attacker.Uid, attacker.Uid, GameBuffTypeSuckBlood, 1f, heal, 0f);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, attacker.Uid, GameBuffTypeSuckBlood, 1f, 0, heal, 0f);
        }
    }

    private void ApplyKillSkillEffectsNoLock(
        int roomId,
        GamePlayerRuntime attacker,
        GamePlayerRuntime victim,
        List<GameDamageAction> extraActions)
    {
        victim.LastKillerUid = attacker.Uid;

        var victimRuntime = ResolvePlayerSkillRuntimeNoLock(roomId, victim);
        if (victimRuntime.HasSkill(GameSkillTypeFeud) &&
            TrySkillLevel(victimRuntime, GameSkillTypeFeud, out var victimFeudLevel))
        {
            var feudBonus = GetLevelValue(FeudDamageBonusPercents, victimFeudLevel);
            RegisterGameBuffNoLock(
                roomId,
                victim.Uid,
                attacker.Uid,
                GameBuffTypeFeudMark,
                60f,
                attacker.Uid,
                feudBonus);
            QueueBuffStartActionNoLock(roomId, attacker.Uid, victim.Uid, GameBuffTypeFeudMark, 60f, 0, attacker.Uid, feudBonus);
        }

        if (attacker.LastKillerUid != victim.Uid)
        {
            return;
        }

        attacker.LastKillerUid = 0;
        var attackerRuntime = ResolvePlayerSkillRuntimeNoLock(roomId, attacker);
        if (!attackerRuntime.HasSkill(GameSkillTypeFeud) ||
            !TrySkillLevel(attackerRuntime, GameSkillTypeFeud, out var attackerFeudLevel))
        {
            return;
        }

        var heal = Math.Max(1, GetLevelValue(FeudDamageBonusPercents, attackerFeudLevel) * 10);
        ApplySelfHealNoLock(attacker, heal, extraActions);
        RegisterGameBuffNoLock(
            roomId,
            attacker.Uid,
            attacker.Uid,
            GameBuffTypeFeudAnger,
            5f,
            GetLevelValue(FeudDamageBonusPercents, attackerFeudLevel),
            heal);
        QueueBuffStartActionNoLock(
            roomId,
            attacker.Uid,
            attacker.Uid,
            GameBuffTypeFeudAnger,
            5f,
            0,
            GetLevelValue(FeudDamageBonusPercents, attackerFeudLevel),
            heal);
    }

    private void ChargeTransferNoLock(
        int roomId,
        GamePlayerRuntime victim,
        byte sourceUid,
        int chargedDamage,
        List<GameDamageAction> extraActions)
    {
        if (chargedDamage <= 0 || victim.TransferReleasing)
        {
            return;
        }

        var runtime = ResolvePlayerSkillRuntimeNoLock(roomId, victim);
        if (!runtime.HasSkill(GameSkillTypeTransfer) ||
            !TrySkillLevel(runtime, GameSkillTypeTransfer, out var transferLevel))
        {
            return;
        }

        victim.TransferChargePercent += GetLevelValue(TransferChargePercents, transferLevel);
        RegisterGameBuffNoLock(
            roomId,
            victim.Uid,
            sourceUid,
            GameBuffTypeTransfer,
            (float)TransferStoredDamageBuffDuration.TotalSeconds,
            chargedDamage,
            victim.TransferChargePercent);
        QueueBuffStartActionNoLock(
            roomId,
            sourceUid == 0 ? victim.Uid : sourceUid,
            victim.Uid,
            GameBuffTypeTransfer,
            (float)TransferStoredDamageBuffDuration.TotalSeconds,
            0,
            chargedDamage,
            victim.TransferChargePercent);
        if (victim.TransferChargePercent < 100 ||
            !HasEnemyInRadiusNoLock(roomId, victim.Uid, TransferTriggerRadius))
        {
            return;
        }

        victim.TransferChargePercent = 0;
        victim.TransferReleasing = true;
        try
        {
            extraActions.AddRange(ApplyAreaDamageNoLock(
                roomId,
                victim.Uid,
                GetLevelValue(TransferReleaseDamageValues, transferLevel),
                TransferDamageRadius));
        }
        finally
        {
            victim.TransferReleasing = false;
        }
    }

    private void ApplySelfHealNoLock(GamePlayerRuntime player, int heal, List<GameDamageAction> actions)
    {
        if (heal <= 0 || player.CurrentHealth <= 0)
        {
            return;
        }

        var maxHealth = Math.Max(1, player.MaxHealth);
        var previousHealth = player.CurrentHealth;
        player.CurrentHealth = Math.Min(maxHealth, player.CurrentHealth + heal);
        if (player.CurrentHealth == previousHealth)
        {
            return;
        }

        actions.Add(new GameDamageAction(
            AttackerUid: player.Uid,
            VictimUid: player.Uid,
            Damage: 0,
            VictimHealth: player.CurrentHealth,
            VictimMaxHealth: maxHealth,
            Killed: false));
    }

    private bool HasEnemyInRadiusNoLock(int roomId, byte sourceUid, float radius)
    {
        if (!TryGetRoomPlayerContextNoLock(roomId, sourceUid, out var room, out var playersByUid, out var source))
        {
            return false;
        }

        var sourceTeamId = ResolveGamePlayerTeamId(room, source);
        if (sourceTeamId == GameTeamSpectator ||
            !TryResolveProximityWorldPosition(source, preferShoot: false, out var sourcePosition))
        {
            return false;
        }

        var radiusSquared = MathF.Max(0.1f, radius) * MathF.Max(0.1f, radius);
        return playersByUid.Values.Any(player =>
            player.Uid != sourceUid &&
            player.CurrentHealth > 0 &&
            IsEnemyTeam(sourceTeamId, ResolveGamePlayerTeamId(room, player)) &&
            TryResolveProximityWorldPosition(player, preferShoot: false, out var targetPosition) &&
            DistanceSquared(sourcePosition.X, sourcePosition.Y, sourcePosition.Z, targetPosition.X, targetPosition.Y, targetPosition.Z) <= radiusSquared);
    }

    private static int ApplyPercentBonus(int value, int percent)
    {
        return Math.Max(1, (int)MathF.Round(value * (100 + Math.Max(0, percent)) / 100f));
    }

    private static bool IsSniperAttack(GameShootAction? shoot)
    {
        return shoot is { } action &&
            (action.WeaponSubtype == 2 ||
             action.WeaponResource.Contains("sniper", StringComparison.OrdinalIgnoreCase) ||
             action.WeaponResource.Contains("sniperrifle", StringComparison.OrdinalIgnoreCase));
    }

    private static bool IsKnifeAttack(GameShootAction? shoot)
    {
        return shoot is { } action &&
            (action.WeaponSubtype is 6 or 13 ||
             action.WeaponResource.StartsWith("knives_", StringComparison.OrdinalIgnoreCase) ||
             action.WeaponResource.Contains("knife", StringComparison.OrdinalIgnoreCase));
    }

    private static bool IsMachineGunAttack(GameShootAction? shoot)
    {
        return shoot is { } action &&
            (action.WeaponSubtype == 3 ||
             action.WeaponResource.Contains("machinegun", StringComparison.OrdinalIgnoreCase));
    }

    private static bool IsRifleAttack(GameShootAction? shoot)
    {
        return shoot is { } action &&
            (action.WeaponSubtype == 1 ||
             action.WeaponResource.Contains("rifle", StringComparison.OrdinalIgnoreCase) ||
             action.WeaponResource.StartsWith("smg_", StringComparison.OrdinalIgnoreCase));
    }

    private void RegisterGameBuffNoLock(
        int roomId,
        byte targetUid,
        byte sourceUid,
        short buffType,
        float duration,
        float value1,
        float value2)
    {
        if (roomId <= 0 || targetUid == 0)
        {
            return;
        }

        if (!_gameBuffsByRoomId.TryGetValue(roomId, out var buffsByUid))
        {
            buffsByUid = new Dictionary<byte, Dictionary<short, GameBuffRuntime>>();
            _gameBuffsByRoomId[roomId] = buffsByUid;
        }

        if (!buffsByUid.TryGetValue(targetUid, out var buffs))
        {
            buffs = new Dictionary<short, GameBuffRuntime>();
            buffsByUid[targetUid] = buffs;
        }

        var now = DateTimeOffset.UtcNow;
        var durationSeconds = float.IsFinite(duration) && duration > 0f ? duration : 0f;
        buffs[buffType] = new GameBuffRuntime(
            buffType,
            sourceUid,
            targetUid,
            now,
            durationSeconds <= 0f ? DateTimeOffset.MaxValue : now.AddSeconds(durationSeconds),
            now,
            value1,
            value2);
    }

    private void QueueBuffStartActionNoLock(
        int roomId,
        byte sourceUid,
        byte targetUid,
        short buffType,
        float duration,
        byte cooldownLock,
        float value1,
        float value2)
    {
        if (roomId <= 0 || sourceUid == 0 || targetUid == 0)
        {
            return;
        }

        if (!_pendingBuffStartActionsByRoomId.TryGetValue(roomId, out var actions))
        {
            actions = [];
            _pendingBuffStartActionsByRoomId[roomId] = actions;
        }

        actions.Add(new GameBuffStartAction(
            sourceUid,
            targetUid,
            buffType,
            duration,
            cooldownLock,
            value1,
            value2));
    }

    private GameBuffStartAction[] DrainPendingBuffStartActionsNoLock(int roomId)
    {
        if (!_pendingBuffStartActionsByRoomId.TryGetValue(roomId, out var actions) ||
            actions.Count == 0)
        {
            return [];
        }

        _pendingBuffStartActionsByRoomId.Remove(roomId);
        return actions.ToArray();
    }

    private void ClearBreakableStealthNoLock(int roomId, byte uid)
    {
        if (_gameBuffsByRoomId.TryGetValue(roomId, out var buffsByUid) &&
            buffsByUid.TryGetValue(uid, out var buffs))
        {
            buffs.Remove(GameBuffTypeLurk);
        }
    }

    private int ApplyShieldAbsorbNoLock(int roomId, byte victimUid, int damage, out int absorbed)
    {
        absorbed = 0;
        if (damage <= 0 ||
            !_gameBuffsByRoomId.TryGetValue(roomId, out var buffsByUid) ||
            !buffsByUid.TryGetValue(victimUid, out var buffs) ||
            !buffs.TryGetValue(GameBuffTypeShield, out var shield))
        {
            return damage;
        }

        var now = DateTimeOffset.UtcNow;
        if (shield.ExpiresAt <= now || shield.Value1 <= 0f)
        {
            buffs.Remove(GameBuffTypeShield);
            return damage;
        }

        var shieldValue = Math.Max(0, (int)MathF.Round(shield.Value1));
        if (shieldValue >= damage)
        {
            absorbed = damage;
            if (shieldValue == damage)
            {
                buffs.Remove(GameBuffTypeShield);
            }
            else
            {
                buffs[GameBuffTypeShield] = shield with { Value1 = shieldValue - damage };
            }

            return 0;
        }

        absorbed = Math.Min(shieldValue, damage);
        shieldValue -= absorbed;
        if (shieldValue <= 0)
        {
            buffs.Remove(GameBuffTypeShield);
        }
        else
        {
            buffs[GameBuffTypeShield] = shield with { Value1 = shieldValue };
        }

        return Math.Max(0, damage - absorbed);
    }

    private static bool HasAnyGamePosition(GamePlayerRuntime player)
    {
        return player.LastPosition is not null || player.LastShoot is not null;
    }

    private static bool TryResolveProximityWorldPosition(
        GamePlayerRuntime player,
        bool preferShoot,
        out (float X, float Y, float Z) position)
    {
        if (player.LastShoot is { } shoot &&
            (preferShoot ||
             player.LastPosition is null ||
             shoot.LastSeenAt >= player.LastPosition.Value.LastSeenAt))
        {
            position = ShootOriginToWorld(shoot);
            return IsFinitePosition(position);
        }

        if (player.LastPosition is { } movementPosition)
        {
            position = MovementPositionToWorld(movementPosition);
            return IsFinitePosition(position);
        }

        if (player.LastShoot is { } fallbackShoot)
        {
            position = ShootOriginToWorld(fallbackShoot);
            return IsFinitePosition(position);
        }

        position = default;
        return false;
    }

    private static bool TryResolveMovementWorldPosition(
        GamePlayerRuntime player,
        out (float X, float Y, float Z) position)
    {
        if (player.LastPosition is { } movementPosition)
        {
            position = MovementPositionToWorld(movementPosition);
            return IsFinitePosition(position);
        }

        if (player.LastShoot is { } fallbackShoot)
        {
            position = ShootOriginToWorld(fallbackShoot);
            return IsFinitePosition(position);
        }

        position = default;
        return false;
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

    private static bool TryComputeSpurtHitScore(
        (float X, float Y, float Z) source,
        (float X, float Y, float Z, float LengthSquared) direction,
        (float X, float Y, float Z) target,
        float maxRange,
        float hitRadius,
        out float score)
    {
        score = float.MaxValue;
        if (direction.LengthSquared <= 0f)
        {
            return false;
        }

        var hitRadiusSquared = MathF.Max(0.1f, hitRadius) * MathF.Max(0.1f, hitRadius);
        var bestScore = float.MaxValue;
        var hit = false;
        foreach (var targetY in new[] { target.Y, target.Y + 0.8f, target.Y + 1.6f })
        {
            var toTargetX = target.X - source.X;
            var toTargetY = targetY - source.Y;
            var toTargetZ = target.Z - source.Z;
            var projection = Dot(toTargetX, toTargetY, toTargetZ, direction.X, direction.Y, direction.Z);
            if (projection < -0.25f || projection > maxRange)
            {
                continue;
            }

            var closestX = source.X + (direction.X * projection);
            var closestY = source.Y + (direction.Y * projection);
            var closestZ = source.Z + (direction.Z * projection);
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
        float BestHitScore,
        IReadOnlyList<GameDamageAction> ExtraActions)
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
                bestHitScore,
                []);
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

    private static (float X, float Y, float Z, float LengthSquared) ResolveMovementDirection(GamePosition position)
    {
        if (position.Facing0Raw is not { } facing0Raw)
        {
            if (position.YawRaw is not { } yawRaw)
            {
                return (0f, 0f, 0f, 0f);
            }

            var yawFromPosition = yawRaw / FacingRawAngleScale;
            return NormalizeOrZero(
                MathF.Sin(yawFromPosition),
                0f,
                -MathF.Cos(yawFromPosition));
        }

        var yaw = facing0Raw / FacingRawAngleScale;
        return NormalizeOrZero(
            MathF.Sin(yaw),
            0f,
            -MathF.Cos(yaw));
    }

    private static (float X, float Y, float Z, float LengthSquared) ResolveSpurtDirection(GamePlayerRuntime attacker)
    {
        if (attacker.LastPosition is { } movementPosition)
        {
            var movementDirection = ResolveMovementDirection(movementPosition);
            if (movementDirection.LengthSquared > 0f)
            {
                return movementDirection;
            }
        }

        if (attacker.LastShoot is { } shoot)
        {
            var shootDirection = ResolveShootDirection(shoot);
            var flattenedDirection = NormalizeOrZero(shootDirection.X, 0f, shootDirection.Z);
            if (flattenedDirection.LengthSquared > 0f)
            {
                return flattenedDirection;
            }
        }

        return (0f, 0f, -1f, 1f);
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

    private static bool IsFinitePosition((float X, float Y, float Z) position)
    {
        return float.IsFinite(position.X) &&
               float.IsFinite(position.Y) &&
               float.IsFinite(position.Z);
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
        try
        {
            using var db = new AvatarStarDbContext();
            var dbChoices = db.LobbyLevels
                .Where(x => x.Enabled != 0)
                .OrderBy(x => x.Id)
                .Select(x => new BattleLevelChoice(x.Id, string.IsNullOrWhiteSpace(x.ShowName) ? x.Name : x.ShowName))
                .ToArray();
            if (dbChoices.Length > 0)
            {
                return dbChoices;
            }
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to load lobby levels from database; falling back to JSON/built-in map choices.");
        }

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
        float VectorZ,
        byte WeaponSubtype,
        string WeaponResource,
        DateTimeOffset LastSeenAt);

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

    internal readonly record struct GameAreaEffectBroadcastResult(
        bool Applied,
        int BroadcastCount,
        int TargetCount,
        int KillCount,
        string Reason);

    internal readonly record struct GameBuffStartAction(
        byte FromUid,
        byte TargetUid,
        short BuffType,
        float Duration,
        byte CooldownLock,
        float Value1,
        float Value2);

    internal readonly record struct PlayerSkillRuntime(
        IReadOnlyDictionary<byte, int> SkillLevels,
        IReadOnlySet<string> SkillResources)
    {
        public static PlayerSkillRuntime Empty { get; } = new(
            new Dictionary<byte, int>(),
            new HashSet<string>(StringComparer.OrdinalIgnoreCase));

        public bool HasSkill(byte skillType)
        {
            return SkillLevels.ContainsKey(skillType);
        }

        public bool HasSkillResource(string resource)
        {
            return SkillResources.Contains(resource);
        }
    }

    internal readonly record struct GamePlayerSnapshot(
        byte Uid,
        long CharacterId,
        string CharacterName,
        GamePosition? LastPosition);

    private readonly record struct GameBuffRuntime(
        short BuffType,
        byte SourceUid,
        byte TargetUid,
        DateTimeOffset StartedAt,
        DateTimeOffset ExpiresAt,
        DateTimeOffset LastTickAt,
        float Value1,
        float Value2);

    private readonly record struct GameDropItemRuntime(
        byte DropId,
        byte OwnerUid,
        byte DropType,
        byte Slot,
        GamePosition Position,
        int Value,
        int SecondaryValue,
        DateTimeOffset LastTickAt,
        DateTimeOffset CreatedAt,
        bool Triggered);

    internal readonly record struct GamePosition(
        short XRaw,
        short YRaw,
        short ZRaw,
        short? YawRaw,
        short? Facing0Raw,
        short? Facing1Raw,
        DateTimeOffset LastSeenAt);

    internal readonly record struct GameClientRpcActivity(
        DateTimeOffset LastSeenAt,
        string RpcName);

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
        public int TransferChargePercent { get; set; }
        public bool TransferReleasing { get; set; }
        public byte LastKillerUid { get; set; }
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
