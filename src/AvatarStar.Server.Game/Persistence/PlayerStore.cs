using System.Globalization;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;
using System.Reflection;
using System.Text.Json;

namespace AvatarStar.Server.Game;

internal sealed class PlayerStore
{
    private readonly object _lock = new();
    private readonly Dictionary<int, PlayerState> _players = new();
    private readonly Dictionary<long, HashSet<int>> _characterIdsByAccount = new();
    private int _nextCharacterId = 1;

    public void LoadAccount(long accountId, PlayerStoreSnapshot? snapshot)
    {
        lock (_lock)
        {
            if (accountId <= 0)
            {
                throw new ArgumentOutOfRangeException(nameof(accountId));
            }

            if (_characterIdsByAccount.TryGetValue(accountId, out var previousCharacterIds))
            {
                foreach (var characterId in previousCharacterIds)
                {
                    _players.Remove(characterId);
                }
            }

            var characterIds = new HashSet<int>();
            if (snapshot is not null)
            {
                _nextCharacterId = Math.Max(_nextCharacterId, snapshot.NextCharacterId);
                foreach (var playerSnapshot in snapshot.Players)
                {
                    var player = PlayerState.FromSnapshot(playerSnapshot);
                    _players[player.Character.Id] = player;
                    characterIds.Add(player.Character.Id);
                }
            }

            _characterIdsByAccount[accountId] = characterIds;
            _nextCharacterId = Math.Max(_nextCharacterId, _players.Keys.DefaultIfEmpty(0).Max() + 1);
        }
    }

    public void EnsureNextCharacterIdAtLeast(int nextCharacterId)
    {
        lock (_lock)
        {
            _nextCharacterId = Math.Max(_nextCharacterId, nextCharacterId);
        }
    }

    public PlayerStoreSnapshot CreateSnapshot(long accountId)
    {
        lock (_lock)
        {
            var characterIds = _characterIdsByAccount.TryGetValue(accountId, out var ids)
                ? ids
                : new HashSet<int>();

            return new PlayerStoreSnapshot
            {
                NextCharacterId = Math.Max(_nextCharacterId, _players.Keys.DefaultIfEmpty(0).Max() + 1),
                Players = characterIds
                    .Select(characterId => _players.TryGetValue(characterId, out var player) ? player : null)
                    .Where(player => player is not null)
                    .Select(player => player!)
                    .OrderBy(player => player.Character.Id)
                    .Select(player => player.ToSnapshot())
                    .ToList()
            };
        }
    }

    public IReadOnlyList<CharacterInfo> ListCharacters()
    {
        lock (_lock)
        {
            return _players.Values
                .OrderBy(p => p.Character.Id)
                .Select(p => p.Character)
                .ToList();
        }
    }

    public IReadOnlyList<CharacterInfo> ListCharacters(long accountId)
    {
        lock (_lock)
        {
            if (!_characterIdsByAccount.TryGetValue(accountId, out var characterIds))
            {
                return Array.Empty<CharacterInfo>();
            }

            return characterIds
                .Select(characterId => _players.TryGetValue(characterId, out var player) ? player : null)
                .Where(player => player is not null)
                .Select(player => player!)
                .OrderBy(p => p.Character.Id)
                .Select(p => p.Character)
                .ToList();
        }
    }

    public bool CharacterNameExists(string name)
    {
        var normalizedName = NormalizeCharacterName(name);
        if (normalizedName.Length == 0)
        {
            return false;
        }

        lock (_lock)
        {
            return CharacterNameExistsCore(normalizedName);
        }
    }

    public PlayerState GetOrCreate(int characterId)
    {
        lock (_lock)
        {
            if (_players.TryGetValue(characterId, out var existing))
            {
                return existing;
            }

            var name = $"Player{characterId}";
            var created = new PlayerState(CharacterInfo.Create(characterId, name, occupation: 0));
            _players[characterId] = created;
            return created;
        }
    }

    public PlayerState CreateCharacter(
        long accountId,
        string name,
        int occupation,
        SysAvatarPayloadConfig? avatarConfig = null,
        object? equipAvatar = null,
        string? avatarId = null,
        string? starterCardDisplay = null,
        string? starterCardDesigner = null)
    {
        lock (_lock)
        {
            var normalizedName = NormalizeCharacterName(name);
            if (normalizedName.Length == 0)
            {
                throw new ArgumentException("Character name cannot be empty.", nameof(name));
            }

            if (CharacterNameExistsCore(normalizedName))
            {
                throw new InvalidOperationException("Character name already exists.");
            }

            var id = _nextCharacterId++;
            var player = new PlayerState(CharacterInfo.Create(id, normalizedName, occupation));
            var resolvedAvatarId = string.IsNullOrWhiteSpace(avatarId)
                ? GetDefaultAvatarId(occupation, avatarConfig)
                : avatarId!;
            var resolvedEquipAvatar = equipAvatar ?? BuildDefaultEquipAvatar(resolvedAvatarId);
            player.Character = player.Character with { EquipAvatar = resolvedEquipAvatar };
            player.InitializeStarterInventory(
                occupation,
                avatarConfig,
                resolvedEquipAvatar,
                resolvedAvatarId,
                cardDisplay: starterCardDisplay,
                cardDesigner: starterCardDesigner);
            _players[id] = player;
            if (accountId > 0)
            {
                if (!_characterIdsByAccount.TryGetValue(accountId, out var characterIds))
                {
                    characterIds = new HashSet<int>();
                    _characterIdsByAccount[accountId] = characterIds;
                }

                characterIds.Add(id);
            }
            return player;
        }
    }

    public PlayerState CreateCharacter(
        string name,
        int occupation,
        SysAvatarPayloadConfig? avatarConfig = null,
        object? equipAvatar = null,
        string? avatarId = null,
        string? starterCardDisplay = null,
        string? starterCardDesigner = null)
    {
        return CreateCharacter(
            accountId: 0,
            name,
            occupation,
            avatarConfig,
            equipAvatar,
            avatarId,
            starterCardDisplay,
            starterCardDesigner);
    }

    private bool CharacterNameExistsCore(string normalizedName)
    {
        return _players.Values.Any(player =>
            string.Equals(player.Character.Name.Trim(), normalizedName, StringComparison.OrdinalIgnoreCase));
    }

    private static string NormalizeCharacterName(string name)
    {
        return name.Trim();
    }

    private static string GetDefaultAvatarId(int occupation, SysAvatarPayloadConfig? avatarConfig)
    {
        var profession = avatarConfig?.OfficialCatalog?.Professions.FirstOrDefault(p => p.Occupation == occupation);
        return profession?.Presets?.Male?.AvatarId
            ?? profession?.Presets?.Female?.AvatarId
            ?? GetOccupationDefaultAvatarId(occupation);
    }

    private static string GetOccupationDefaultAvatarId(int occupation)
    {
        // Keep aligned with the male avatarId values in Config/SysAvatarPayloads.
        return occupation switch
        {
            0 => "100001",
            1 => "100005",
            2 => "100003",
            3 => "100127",
            _ => "100001"
        };
    }

    private static object BuildDefaultEquipAvatar(string avatarId)
    {
        return new
        {
            avatarId,
            skin = "{}",
            eye = "{}",
            mouth = "{}",
            nose = "{}",
            ear = "{}",
            beard = "{}",
            hair = "{}",
            helmet = "{}",
            underwear = "{}",
            outerwear = "{}",
            trousers = "{}",
            glove = "{}",
            shoes = "{}",
            decal = "{}",
            movable = "{}",
            immobile = "{}",
            immobileUp = "{}",
            immobileDown = "{}"
        };
    }

    private static int StableSid(int itemType, string resource)
    {
        unchecked
        {
            const uint fnvOffset = 2166136261;
            const uint fnvPrime = 16777619;
            var source = itemType.ToString(CultureInfo.InvariantCulture) + ":" + resource;
            uint hash = fnvOffset;
            foreach (var ch in source)
            {
                hash ^= ch;
                hash *= fnvPrime;
            }

            return 90000000 + (int)(hash % 9000000);
        }
    }

    public bool DeleteCharacter(int characterId)
    {
        lock (_lock)
        {
            return _players.Remove(characterId);
        }
    }

    public bool DeleteCharacter(long accountId, int characterId)
    {
        lock (_lock)
        {
            if (!_characterIdsByAccount.TryGetValue(accountId, out var characterIds) ||
                !characterIds.Remove(characterId))
            {
                return false;
            }

            return _players.Remove(characterId);
        }
    }

    public sealed class PlayerState
    {
        private sealed record HotKeySlot(
            int Slot,
            int Type,
            string ItemId,
            string Resource,
            int Grade,
            int Quantity,
            int UnitType,
            int Unit,
            int Subtype,
            int Sid,
            int SkillId = 0,
            int RefitLevel = 0,
            int PlusLevel = 0,
            int RefitTotalExp = 0);

        public sealed record GameLoadoutItem(
            byte Slot,
            byte ItemType,
            long ItemId,
            string Resource,
            byte Grade,
            string DisplayName,
            byte Subtype,
            int SkillId = 0,
            int SkillLevel = 0);

        public sealed record GameIndependentTrinketItem(
            int Slot,
            string Resource,
            InventoryItem? BackpackItem);

        public CharacterInfo Character { get; set; }
        public int Gp { get; set; } = 99999999;
        public int Mb { get; set; } = 99999999;
        public int Tb { get; set; } = 99999999;
        public Dictionary<int, int> BoxPoints { get; } = new();
        public Dictionary<int, Dictionary<int, int>> BoxPointClaimCounts { get; } = new();
        public string CheckinMonthKey { get; private set; } = string.Empty;
        public HashSet<int> CheckinDays { get; } = new();
        public HashSet<int> CheckinClaimedRewardIds { get; } = new();

        // 一次性发放标记（例如初始强化材料），与 PlayerStateSnapshot.RewardFlags 对应。
        public HashSet<string> RewardFlags { get; } = new();

        // (sid, priceId) -> purchased count (用于限购显示/校验)
        public Dictionary<(int Sid, int PriceId), int> ShopPurchasedCounts { get; } = new();

        // storageType(t) -> slot -> item
        public Dictionary<int, Dictionary<int, InventoryItem>> Storages { get; } = new();
        public Dictionary<int, string> EquippedItemsByType { get; } = new();
        // skillId -> invested level (0..MaxSkillLevel); absent means unlearned.
        public Dictionary<int, int> SkillLevels { get; } = new();
        public string? EquippedAvatarPid { get; set; }
        private readonly Dictionary<int, HotKeySlot> _hotKeySlots = new();
        // PlayerState is shared by every connection of the account (lobby RPC + in-game channel) and the
        // room protocol resolves the loadout of every snapshot from async continuations and timers. The
        // mutable quick bar and skill levels are therefore only touched while this lock is held; without it
        // concurrent reads/writes corrupt the dictionaries and a later read trips over a null entry (see
        // NormalizeHotKeySlots).
        private readonly object _stateLock = new();
        private const int HotKeySlotCount = 12;
        // The lobby quick-slot panel only lists 12 entries, but the in-game character equipment
        // block addresses the full retail quick bar (its last two profession skills sit on 0x0D and
        // 0x0E), so the internal quick bar accepts a couple of extra slots while the lobby keeps
        // reporting HotKeySlotCount entries.
        private const int HotKeySlotCapacity = 14;
        // Slots 1..3 are the battle weapon quick slots, so default profession skills start at 4.
        private const int DefaultSkillHotKeySlotStart = 4;
        private const int MaxWeaponHotKeyCount = 3;
        private const long SkillLoadoutItemIdBase = 1_110_210_000_000_000_000L;
        // Skill points handed out to every character. The retail formula derives this from the
        // character level (floor((level + 1) / 2)); a flat value lets any profession level all of
        // its skills while iterating on the skill system.
        private const int TotalSkillPoints = 15;
        public int NextPid { get; set; } = 1;
        private bool _ensuringStarterInventory;

        public PlayerState(CharacterInfo character)
        {
            Character = character;
        }

        public int GetSkillLevel(int skillId)
        {
            lock (_stateLock)
            {
                return SkillLevels.TryGetValue(skillId, out var level) ? level : 0;
            }
        }

        /// <summary>
        /// Stores an invested skill level, clamping to the legal range and dropping
        /// unlearned (level &lt;= 0) entries so snapshots stay compact.
        /// </summary>
        public int SetSkillLevel(int skillId, int level)
        {
            lock (_stateLock)
            {
                var clamped = Math.Clamp(level, 0, SkillCatalog.MaxSkillLevel);
                if (clamped <= 0)
                {
                    SkillLevels.Remove(skillId);
                }
                else
                {
                    SkillLevels[skillId] = clamped;
                }

                return clamped;
            }
        }

        /// <summary>
        /// Total skill points the character can invest. The client shows `leftpoints` as
        /// total - invested, and only allows investing while a point is left.
        /// </summary>
        public int GetTotalSkillPoints()
        {
            return TotalSkillPoints;
        }

        public int GetSpentSkillPoints()
        {
            lock (_stateLock)
            {
                var spent = 0;
                foreach (var level in SkillLevels.Values)
                {
                    if (level > 0)
                    {
                        spent += level;
                    }
                }

                return spent;
            }
        }

        public int GetLeftSkillPoints()
        {
            return Math.Max(0, GetTotalSkillPoints() - GetSpentSkillPoints());
        }

        /// <summary>
        /// Charges <paramref name="cost"/> of the given currency id (1 = gold, 2 = diamond, 4 = ticket).
        /// A non-positive cost always succeeds; otherwise the balance has to cover it.
        /// </summary>
        public bool TrySpendCurrency(int currency, int cost)
        {
            if (cost <= 0)
            {
                return true;
            }

            switch ((ShopItemDatabase.CurrencyType)currency)
            {
                case ShopItemDatabase.CurrencyType.Gold:
                    if (Gp < cost) return false;
                    Gp -= cost;
                    return true;
                case ShopItemDatabase.CurrencyType.Diamond:
                    if (Mb < cost) return false;
                    Mb -= cost;
                    return true;
                case ShopItemDatabase.CurrencyType.Ticket:
                    if (Tb < cost) return false;
                    Tb -= cost;
                    return true;
                default:
                    return false;
            }
        }

        /// <summary>
        /// Refunds every invested skill point and clears the skill hotbar, mirroring the
        /// client "reset" button (`skill_reset`).
        /// </summary>
        public void ResetSkillLevels()
        {
            lock (_stateLock)
            {
                SkillLevels.Clear();

                var skillSlots = _hotKeySlots
                    .Where(pair => pair.Value is not null && pair.Value.Type == (int)ShopItemDatabase.ItemType.Skill)
                    .Select(pair => pair.Key)
                    .ToArray();
                foreach (var slot in skillSlots)
                {
                    _hotKeySlots.Remove(slot);
                }
            }
        }

        public PlayerStateSnapshot ToSnapshot()
        {
            return new PlayerStateSnapshot
            {
                Character = Character,
                Gp = Gp,
                Mb = Mb,
                Tb = Tb,
                NextPid = NextPid,
                EquippedAvatarPid = EquippedAvatarPid,
                BoxPoints = new Dictionary<int, int>(BoxPoints),
                BoxPointClaimCounts = BoxPointClaimCounts.ToDictionary(
                    pair => pair.Key,
                    pair => new Dictionary<int, int>(pair.Value)),
                CheckinMonthKey = CheckinMonthKey,
                CheckinDays = new HashSet<int>(CheckinDays),
                CheckinClaimedRewardIds = new HashSet<int>(CheckinClaimedRewardIds),
                RewardFlags = new HashSet<string>(RewardFlags),
                ShopPurchasedCounts = ShopPurchasedCounts.ToDictionary(
                    pair => $"{pair.Key.Sid}:{pair.Key.PriceId}",
                    pair => pair.Value),
                Storages = Storages.ToDictionary(
                    pair => pair.Key,
                    pair => pair.Value.ToDictionary(slot => slot.Key, slot => slot.Value)),
                EquippedItemsByType = new Dictionary<int, string>(EquippedItemsByType),
                SkillLevels = SnapshotSkillLevels(),
                HotKeySlots = SnapshotHotKeySlots()
            };
        }

        private Dictionary<int, int> SnapshotSkillLevels()
        {
            lock (_stateLock)
            {
                return new Dictionary<int, int>(SkillLevels);
            }
        }

        /// <summary>
        /// Copies the quick bar for persistence. The save path can run on a different thread than the
        /// connection handlers, so the copy is taken under the state lock.
        /// </summary>
        private Dictionary<int, HotKeySlotSnapshot> SnapshotHotKeySlots()
        {
            lock (_stateLock)
            {
                return _hotKeySlots
                    .Where(pair => pair.Value is not null)
                    .ToDictionary(
                        pair => pair.Key,
                        pair => new HotKeySlotSnapshot(
                            pair.Value.Slot,
                            pair.Value.Type,
                            pair.Value.ItemId,
                            pair.Value.Resource,
                            pair.Value.Grade,
                            pair.Value.Quantity,
                            pair.Value.UnitType,
                            pair.Value.Unit,
                            pair.Value.Subtype,
                            pair.Value.Sid,
                            pair.Value.SkillId,
                            pair.Value.RefitLevel,
                            pair.Value.PlusLevel,
                            pair.Value.RefitTotalExp));
            }
        }

        public static PlayerState FromSnapshot(PlayerStateSnapshot snapshot)
        {
            var character = snapshot.Character with
            {
                EquipAvatar = NormalizeAvatarPayload(snapshot.Character.EquipAvatar) ?? CharacterInfo.Create(0, string.Empty, snapshot.Character.Occupation).EquipAvatar
            };
            var player = new PlayerState(character)
            {
                Gp = snapshot.Gp,
                Mb = snapshot.Mb,
                Tb = snapshot.Tb,
                NextPid = Math.Max(1, snapshot.NextPid),
                EquippedAvatarPid = snapshot.EquippedAvatarPid
            };

            foreach (var (key, value) in snapshot.BoxPoints)
            {
                player.BoxPoints[key] = value;
            }

            foreach (var (category, thresholds) in snapshot.BoxPointClaimCounts)
            {
                player.BoxPointClaimCounts[category] = new Dictionary<int, int>(thresholds);
            }

            player.CheckinMonthKey = snapshot.CheckinMonthKey ?? string.Empty;
            foreach (var day in snapshot.CheckinDays)
            {
                player.CheckinDays.Add(day);
            }

            foreach (var rewardId in snapshot.CheckinClaimedRewardIds)
            {
                player.CheckinClaimedRewardIds.Add(rewardId);
            }

            if (snapshot.RewardFlags is { Count: > 0 })
            {
                foreach (var flag in snapshot.RewardFlags)
                {
                    player.RewardFlags.Add(flag);
                }
            }

            foreach (var (key, value) in snapshot.ShopPurchasedCounts)
            {
                var parts = key.Split(':', 2);
                if (parts.Length == 2 &&
                    int.TryParse(parts[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out var sid) &&
                    int.TryParse(parts[1], NumberStyles.Integer, CultureInfo.InvariantCulture, out var priceId))
                {
                    player.ShopPurchasedCounts[(sid, priceId)] = value;
                }
            }

            foreach (var (storageType, slots) in snapshot.Storages)
            {
                player.Storages[storageType] = slots.ToDictionary(
                    slot => slot.Key,
                    slot => NormalizeInventoryItem(slot.Value));
            }

            foreach (var (equipType, pid) in snapshot.EquippedItemsByType)
            {
                player.EquippedItemsByType[equipType] = pid;
            }

            foreach (var (skillId, level) in snapshot.SkillLevels)
            {
                player.SetSkillLevel(skillId, level);
            }

            foreach (var (slot, hotKey) in snapshot.HotKeySlots)
            {
                // A profile written by an older build can carry a null entry; skip it instead of
                // letting the whole load fail.
                if (hotKey is null)
                {
                    continue;
                }

                player._hotKeySlots[slot] = new HotKeySlot(
                    hotKey.Slot,
                    hotKey.Type,
                    hotKey.ItemId,
                    hotKey.Resource,
                    hotKey.Grade,
                    hotKey.Quantity,
                    hotKey.UnitType,
                    hotKey.Unit,
                    hotKey.Subtype,
                    hotKey.Sid,
                    hotKey.SkillId,
                    hotKey.RefitLevel,
                    hotKey.PlusLevel,
                    hotKey.RefitTotalExp);
            }

            return player;
        }

        private static InventoryItem NormalizeInventoryItem(InventoryItem item)
        {
            var normalizedAvatar = NormalizeAvatarPayload(item.Avatar);
            var normalizedSubType = item.SubType > 0 ? item.SubType : item.Subtype;
            var normalizedSubtype = item.Subtype > 0 ? item.Subtype : normalizedSubType;
            return item with
            {
                Avatar = normalizedAvatar,
                Subtype = normalizedSubtype,
                SubType = normalizedSubType,
                Resource = string.IsNullOrWhiteSpace(item.Resource) && item.Type is 5 or 6
                    ? (normalizedSubType == 2 ? "herocard" : "humancard")
                    : item.Resource,
                Position = item.Type is 5 or 6 ? item.Position ?? 1 : item.Position,
                Display = item.Display ?? string.Empty,
                Designer = item.Designer ?? string.Empty,
                Description = item.Description ?? string.Empty
            };
        }

        public sealed record RewardGrantSnapshot(
            int Gp,
            int Mb,
            int Tb,
            int NextPid,
            Dictionary<int, Dictionary<int, InventoryItem>> Storages);

        public int GetShopPurchasedCount(int sid, int priceId)
        {
            return ShopPurchasedCounts.TryGetValue((sid, priceId), out var v) ? v : 0;
        }

        public void AddShopPurchasedCount(int sid, int priceId, int delta)
        {
            if (delta <= 0) return;
            var key = (sid, priceId);
            ShopPurchasedCounts[key] = GetShopPurchasedCount(sid, priceId) + delta;
        }

        public int GetBoxPoint(int category)
        {
            if (category <= 0)
            {
                return 0;
            }

            return BoxPoints.TryGetValue(category, out var point) ? Math.Max(0, point) : 0;
        }

        public int AddBoxPoint(int category, int delta)
        {
            if (category <= 0 || delta == 0)
            {
                return GetBoxPoint(category);
            }

            var next = Math.Max(0, GetBoxPoint(category) + delta);
            BoxPoints[category] = next;
            return next;
        }

        public bool TryConsumeBoxPoint(int category, int cost, out int remainPoint)
        {
            remainPoint = GetBoxPoint(category);
            if (category <= 0 || cost <= 0)
            {
                return false;
            }

            if (remainPoint < cost)
            {
                return false;
            }

            remainPoint -= cost;
            BoxPoints[category] = remainPoint;
            return true;
        }

        public int GetBoxPointClaimCount(int category, int threshold)
        {
            if (category <= 0 || threshold <= 0)
            {
                return 0;
            }

            return BoxPointClaimCounts.TryGetValue(category, out var byThreshold) &&
                   byThreshold.TryGetValue(threshold, out var count)
                ? Math.Max(0, count)
                : 0;
        }

        public void AddBoxPointClaim(int category, int threshold)
        {
            if (category <= 0 || threshold <= 0)
            {
                return;
            }

            if (!BoxPointClaimCounts.TryGetValue(category, out var byThreshold))
            {
                byThreshold = new Dictionary<int, int>();
                BoxPointClaimCounts[category] = byThreshold;
            }

            byThreshold[threshold] = GetBoxPointClaimCount(category, threshold) + 1;
        }

        public void EnsureCheckinMonth(DateTime now)
        {
            var monthKey = now.ToString("yyyy-MM", CultureInfo.InvariantCulture);
            if (string.Equals(CheckinMonthKey, monthKey, StringComparison.Ordinal))
            {
                return;
            }

            CheckinMonthKey = monthKey;
            CheckinDays.Clear();
            CheckinClaimedRewardIds.Clear();
        }

        public IReadOnlyList<int> GetCheckinDaysOfMonth(DateTime now)
        {
            EnsureCheckinMonth(now);
            return CheckinDays.OrderBy(day => day).ToArray();
        }

        public int GetCheckinCount(DateTime now)
        {
            EnsureCheckinMonth(now);
            return CheckinDays.Count;
        }

        public bool HasCheckedInDay(DateTime now, int day)
        {
            EnsureCheckinMonth(now);
            return day > 0 && CheckinDays.Contains(day);
        }

        public bool HasCheckedInToday(DateTime now)
        {
            return HasCheckedInDay(now, now.Day);
        }

        public bool TryAddCheckinDay(DateTime now, int day)
        {
            EnsureCheckinMonth(now);
            if (day <= 0 || day > DateTime.DaysInMonth(now.Year, now.Month))
            {
                return false;
            }

            return CheckinDays.Add(day);
        }

        public bool HasClaimedCheckinReward(DateTime now, int checkinId)
        {
            EnsureCheckinMonth(now);
            return checkinId > 0 && CheckinClaimedRewardIds.Contains(checkinId);
        }

        public bool TryClaimCheckinReward(DateTime now, int checkinId)
        {
            EnsureCheckinMonth(now);
            return checkinId > 0 && CheckinClaimedRewardIds.Add(checkinId);
        }

        public RewardGrantSnapshot CaptureRewardGrantSnapshot()
        {
            EnsureStarterInventory();
            return new RewardGrantSnapshot(
                Gp,
                Mb,
                Tb,
                NextPid,
                Storages.ToDictionary(
                    storage => storage.Key,
                    storage => storage.Value.ToDictionary(slot => slot.Key, slot => slot.Value)));
        }

        public void RestoreRewardGrantSnapshot(RewardGrantSnapshot snapshot)
        {
            Gp = snapshot.Gp;
            Mb = snapshot.Mb;
            Tb = snapshot.Tb;
            NextPid = snapshot.NextPid;

            Storages.Clear();
            foreach (var (storageType, slots) in snapshot.Storages)
            {
                Storages[storageType] = slots.ToDictionary(slot => slot.Key, slot => slot.Value);
            }
        }

        public void EnsureStarterInventory()
        {
            if (_ensuringStarterInventory)
            {
                return;
            }

            _ensuringStarterInventory = true;
            try
            {
                if (Storages.Count == 0)
                {
                    InitializeStarterInventory(
                        occupation: Character.Occupation,
                        avatarConfig: null,
                        equipAvatar: Character.EquipAvatar,
                        avatarId: "0",
                        cardDisplay: Character.Name,
                        cardDesigner: Character.Name);
                }

                NormalizeLegacyStarterAvatarCard();
                EnsureStarterSkinCard();
                EnsureRefitMaterials();
            }
            finally
            {
                _ensuringStarterInventory = false;
            }
        }

        public void InitializeStarterInventory(
            int occupation,
            SysAvatarPayloadConfig? avatarConfig,
            object? equipAvatar,
            string? avatarId,
            string? cardDisplay = null,
            string? cardDesigner = null,
            string? cardDescription = null)
        {
            if (Storages.Count != 0) return;

            var profession = avatarConfig?.OfficialCatalog?.Professions.FirstOrDefault(p => p.Occupation == occupation);
            var slot = 1;
            var hasStarterWeapon = false;
            var resolvedAvatarId = string.IsNullOrWhiteSpace(avatarId) ? GetAvatarIdFrom(Character.EquipAvatar) : avatarId!;
            if (string.IsNullOrWhiteSpace(resolvedAvatarId) || string.Equals(resolvedAvatarId, "0", StringComparison.Ordinal))
            {
                resolvedAvatarId = PlayerStore.GetOccupationDefaultAvatarId(occupation);
            }
            var resolvedEquipAvatar = EnsureAvatarHasAvatarId(equipAvatar ?? Character.EquipAvatar, resolvedAvatarId) ?? equipAvatar ?? Character.EquipAvatar;
            Character = Character with { EquipAvatar = resolvedEquipAvatar };
            var resolvedCardDisplay = string.IsNullOrWhiteSpace(cardDisplay) ? Character.Name : cardDisplay!;
            var resolvedCardDesigner = string.IsNullOrWhiteSpace(cardDesigner) ? Character.Name : cardDesigner!;
            var resolvedCardDescription = cardDescription ?? string.Empty;

            foreach (var weapon in profession?.Weapons ?? Enumerable.Empty<OfficialWeapon>())
            {
                if (string.IsNullOrWhiteSpace(weapon.Resource))
                {
                    continue;
                }

                var subtype = int.TryParse(weapon.SubType, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsedSubtype)
                    ? parsedSubtype
                    : 0;
                var sid = StableSid(2, weapon.Resource);
                var grade = 1;
                if (ShopItemDatabase.TryGetShopItemByResource(weapon.Resource, out var shopWeapon))
                {
                    sid = shopWeapon.Sid;
                    grade = shopWeapon.Grade;
                }

                AddItem(
                    storageType: 2,
                    slot: slot++,
                    resource: weapon.Resource,
                    subtype: subtype,
                    grade: grade,
                    sid: sid,
                    type: 2,
                    quantity: 1);
                hasStarterWeapon = true;
            }

            if (!hasStarterWeapon)
            {
                AddItem(
                    storageType: 2,
                    slot: slot++,
                    resource: "smg_01",
                    subtype: 1,
                    grade: 1,
                    sid: StableSid(2, "smg_01"),
                    type: 2,
                    quantity: 1);
            }

            const string starterGrenadeResource = "grenade_01";
            var starterGrenadeSubtype = 10;
            var starterGrenadeGrade = 1;
            var starterGrenadeSid = StableSid(2, starterGrenadeResource);
            if (ShopItemDatabase.TryGetShopItemByResource(starterGrenadeResource, out var starterGrenade))
            {
                starterGrenadeSubtype = starterGrenade.Subtype > 0 ? starterGrenade.Subtype : starterGrenadeSubtype;
                starterGrenadeGrade = starterGrenade.Grade > 0 ? starterGrenade.Grade : starterGrenadeGrade;
                starterGrenadeSid = starterGrenade.Sid > 0 ? starterGrenade.Sid : starterGrenadeSid;
            }

            AddItem(
                storageType: 2,
                slot: slot,
                resource: starterGrenadeResource,
                subtype: starterGrenadeSubtype,
                grade: starterGrenadeGrade,
                sid: starterGrenadeSid,
                type: 2,
                quantity: 1);

            // Provide at least one "wing/back device" equipment so equipType=1 can be filled and
            // PersonalInfo UI paths (DoWingRes/independentTrinket) won't break.
            if (ShopItemDatabase.TryGetShopItemByResource("deco_angel_wings", out var wing))
            {
                AddItem(
                    storageType: 2,
                    slot: ++slot,
                    resource: wing.Resource,
                    subtype: wing.Subtype,
                    grade: wing.Grade > 0 ? wing.Grade : 1,
                    sid: wing.Sid,
                    type: (int)wing.Type,
                    quantity: Math.Max(1, wing.Quantity));
            }

            AddItem(
                storageType: 5,
                slot: 1,
                resource: "humancard",
                subtype: 1,
                grade: 1,
                sid: StableSid(5, $"official:{occupation}:{resolvedAvatarId}"),
                type: 5,
                quantity: 1,
                avatar: resolvedEquipAvatar,
                position: 1,
                subType: 1,
                display: resolvedCardDisplay,
                designer: resolvedCardDesigner,
                description: resolvedCardDescription);

            EquippedAvatarPid = Storages.TryGetValue(5, out var avatarSlots) && avatarSlots.TryGetValue(1, out var avatarCard)
                ? avatarCard.Pid
                : null;

            // Starter skin card (avatar-room "造型�?): avatar_d.lua requests storage_storage_list(t=6).
            // Without at least one entry, the avatar-room preview can hang/spin.
            AddItem(
                storageType: 6,
                slot: 1,
                resource: "humancard",
                subtype: 1,
                grade: 1,
                sid: StableSid(6, $"starter:{occupation}:{resolvedAvatarId}"),
                type: 6,
                quantity: 1,
                avatar: resolvedEquipAvatar,
                position: 1,
                subType: 1,
                display: resolvedCardDisplay,
                designer: resolvedCardDesigner,
                description: resolvedCardDescription);

            if (!string.IsNullOrWhiteSpace(EquippedAvatarPid))
            {
                _ = EquipAvatarCard(EquippedAvatarPid);
            }

            // Don't auto-equip starter items or hotkeys here; client UI will equip explicitly via RPCs.
        }

        private void EnsureStarterSkinCard()
        {
            // Backfill for older profiles / flows that created storages but didn't add t=6.
            if (Storages.TryGetValue(6, out var slots) && slots.Count > 0)
            {
                return;
            }

            if (!Storages.TryGetValue(6, out slots))
            {
                slots = new Dictionary<int, InventoryItem>();
                Storages[6] = slots;
            }

            const int maxSlots = 36;
            var slot = Enumerable.Range(1, maxSlots).FirstOrDefault(i => !slots.ContainsKey(i));
            if (slot == 0)
            {
                return;
            }

            var avatarId = GetAvatarIdFrom(Character.EquipAvatar) ?? "0";
            var equipAvatar = EnsureAvatarHasAvatarId(Character.EquipAvatar, avatarId) ?? Character.EquipAvatar;

            AddItem(
                storageType: 6,
                slot: slot,
                resource: "humancard",
                subtype: 1,
                grade: 1,
                sid: StableSid(6, $"starter:{Character.Occupation}:{avatarId}:{slot}"),
                type: 6,
                quantity: 1,
                avatar: equipAvatar,
                position: 1,
                subType: 1,
                display: Character.Name,
                designer: Character.Name);
        }

        private static string? GetAvatarIdFrom(object? avatar)
        {
            if (avatar is null)
            {
                return null;
            }

            if (avatar is IReadOnlyDictionary<string, object> roDict &&
                roDict.TryGetValue("avatarId", out var roVal) &&
                roVal is not null)
            {
                return Convert.ToString(roVal, CultureInfo.InvariantCulture);
            }

            if (avatar is Dictionary<string, object> dict &&
                dict.TryGetValue("avatarId", out var val) &&
                val is not null)
            {
                return Convert.ToString(val, CultureInfo.InvariantCulture);
            }

            if (avatar is Dictionary<string, string> strDict &&
                strDict.TryGetValue("avatarId", out var strVal) &&
                !string.IsNullOrWhiteSpace(strVal))
            {
                return strVal;
            }

            if (avatar is JsonElement el)
            {
                if (el.ValueKind == JsonValueKind.Object && el.TryGetProperty("avatarId", out var prop))
                {
                    return prop.ValueKind == JsonValueKind.String ? prop.GetString() : prop.GetRawText();
                }
            }

            var propInfo = avatar.GetType().GetProperty("avatarId");
            if (propInfo is not null)
            {
                var value = propInfo.GetValue(avatar);
                if (value is not null)
                {
                    return Convert.ToString(value, CultureInfo.InvariantCulture);
                }
            }

            return null;
        }

        private static object? NormalizeAvatarPayload(object? avatar)
        {
            if (avatar is null)
            {
                return null;
            }

            if (avatar is JsonElement element)
            {
                return ConvertJsonElement(element);
            }

            return avatar;
        }

        private static object? ConvertJsonElement(JsonElement element)
        {
            return element.ValueKind switch
            {
                JsonValueKind.Object => element.EnumerateObject()
                    .ToDictionary(property => property.Name, property => ConvertJsonElement(property.Value), StringComparer.OrdinalIgnoreCase),
                JsonValueKind.Array => element.EnumerateArray().Select(ConvertJsonElement).ToArray(),
                JsonValueKind.String => element.GetString(),
                JsonValueKind.Number when element.TryGetInt64(out var longValue) => longValue,
                JsonValueKind.Number when element.TryGetDouble(out var doubleValue) => doubleValue,
                JsonValueKind.True => true,
                JsonValueKind.False => false,
                _ => null
            };
        }

        private static object? EnsureAvatarHasAvatarId(object? avatar, string? avatarId)
        {
            if (avatar is null || string.IsNullOrWhiteSpace(avatarId))
            {
                return avatar;
            }

            avatar = NormalizeAvatarPayload(avatar);
            if (avatar is null)
            {
                return null;
            }

            var existingAvatarId = GetAvatarIdFrom(avatar);
            if (!string.IsNullOrWhiteSpace(existingAvatarId) &&
                !string.Equals(existingAvatarId, "0", StringComparison.Ordinal))
            {
                return avatar;
            }

            if (avatar is Dictionary<string, string> strDict)
            {
                var copy = new Dictionary<string, string>(strDict, StringComparer.OrdinalIgnoreCase)
                {
                    ["avatarId"] = avatarId!
                };
                return copy;
            }

            if (avatar is Dictionary<string, object> objDict)
            {
                var copy = new Dictionary<string, object>(objDict, StringComparer.OrdinalIgnoreCase)
                {
                    ["avatarId"] = avatarId!
                };
                return copy;
            }

            if (avatar is IReadOnlyDictionary<string, object> roDict)
            {
                var copy = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
                foreach (var (k, v) in roDict)
                {
                    copy[k] = v;
                }
                copy["avatarId"] = avatarId!;
                return copy;
            }

            // Anonymous/object payloads from character creation are immutable; clone to a mutable dictionary.
            var props = avatar.GetType().GetProperties(BindingFlags.Instance | BindingFlags.Public);
            if (props.Length > 0)
            {
                var dict = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
                foreach (var prop in props)
                {
                    if (prop.GetIndexParameters().Length > 0)
                    {
                        continue;
                    }

                    dict[prop.Name] = prop.GetValue(avatar) ?? string.Empty;
                }

                dict["avatarId"] = avatarId!;
                return dict;
            }

            return avatar;
        }

        public void AddItem(
            int storageType,
            int slot,
            string resource,
            int subtype,
            int grade,
            int sid,
            int type,
            int quantity = 1,
            object? avatar = null,
            int? position = null,
            int subType = 0,
            string display = "",
            string designer = "",
            string description = "",
            int? unitType = null,
            int? unit = null,
            int remain = 0,
            bool isRenew = false,
            IReadOnlyDictionary<string, double>? attributes = null,
            int category = 0)
        {
            if (!Storages.TryGetValue(storageType, out var slots))
            {
                slots = new Dictionary<int, InventoryItem>();
                Storages[storageType] = slots;
            }

            var pid = NextPid++.ToString(CultureInfo.InvariantCulture);
            slots[slot] = new InventoryItem(
                Pid: pid,
                Slot: slot,
                Resource: resource,
                Subtype: subtype,
                SubType: subType,
                Grade: grade,
                Quantity: quantity,
                UnitType: unitType ?? 1,
                Unit: unit ?? quantity,
                Remain: remain,
                IsRenew: isRenew,
                Category: category,
                IsBind: "N",
                IsEquip: "N",
                Sid: sid,
                Type: type,
                Avatar: avatar,
                Position: position,
                Display: display,
                Designer: designer,
                Description: description,
                Attributes: attributes);
        }

        private static int GetItemCountForConsume(InventoryItem item)
        {
            var countByQuantity = Math.Max(0, item.Quantity);
            var countByUnit = Math.Max(0, item.Unit);
            return item.UnitType == 1
                ? Math.Max(countByQuantity, countByUnit)
                : countByQuantity;
        }

        private static InventoryItem WithConsumedCount(InventoryItem item, int nextCount)
        {
            var normalized = Math.Max(0, nextCount);
            var quantity = item.Quantity;
            var unit = item.Unit;

            if (item.UnitType == 1)
            {
                quantity = normalized;
                unit = normalized;
            }
            else
            {
                quantity = normalized;
                unit = item.Unit;
            }

            return item with
            {
                Quantity = quantity,
                Unit = unit
            };
        }

        public int GetStorageResourceCount(int storageType, string resource)
        {
            EnsureStarterInventory();

            if (string.IsNullOrWhiteSpace(resource) ||
                !Storages.TryGetValue(storageType, out var slots) ||
                slots.Count == 0)
            {
                return 0;
            }

            var count = 0;
            foreach (var item in slots.Values)
            {
                if (!string.Equals(item.Resource, resource, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                count += GetItemCountForConsume(item);
            }

            return Math.Max(0, count);
        }

        public int GetStorageCountByCategory(int storageType, int category, int subtype)
        {
            EnsureStarterInventory();

            if (category <= 0 ||
                !Storages.TryGetValue(storageType, out var slots) ||
                slots.Count == 0)
            {
                return 0;
            }

            var count = 0;
            foreach (var item in slots.Values)
            {
                if (item.Category != category)
                {
                    continue;
                }

                var effectiveSubtype = item.SubType > 0 ? item.SubType : item.Subtype;
                if (effectiveSubtype != subtype)
                {
                    continue;
                }

                count += GetItemCountForConsume(item);
            }

            return Math.Max(0, count);
        }

        public bool TryConsumeStorageResource(int storageType, string resource, int amount)
        {
            EnsureStarterInventory();

            if (amount <= 0 || string.IsNullOrWhiteSpace(resource))
            {
                return false;
            }

            if (!Storages.TryGetValue(storageType, out var slots) || slots.Count == 0)
            {
                return false;
            }

            var candidates = slots
                .OrderBy(x => x.Key)
                .Where(x => string.Equals(x.Value.Resource, resource, StringComparison.OrdinalIgnoreCase))
                .Select(x => (Slot: x.Key, Item: x.Value, Count: GetItemCountForConsume(x.Value)))
                .Where(x => x.Count > 0)
                .ToArray();
            var totalCount = candidates.Sum(x => x.Count);
            if (totalCount < amount)
            {
                return false;
            }

            var remaining = amount;
            foreach (var candidate in candidates)
            {
                if (remaining <= 0)
                {
                    break;
                }

                var consume = Math.Min(candidate.Count, remaining);
                var nextCount = candidate.Count - consume;
                remaining -= consume;

                if (nextCount <= 0)
                {
                    slots.Remove(candidate.Slot);
                    continue;
                }

                slots[candidate.Slot] = WithConsumedCount(candidate.Item, nextCount);
            }

            return remaining == 0;
        }

        public bool TryConsumeStorageByCategory(int storageType, int category, int subtype, int amount)
        {
            EnsureStarterInventory();

            if (amount <= 0 || category <= 0)
            {
                return false;
            }

            if (!Storages.TryGetValue(storageType, out var slots) || slots.Count == 0)
            {
                return false;
            }

            var candidates = slots
                .OrderBy(x => x.Key)
                .Where(x =>
                {
                    var item = x.Value;
                    var effectiveSubtype = item.SubType > 0 ? item.SubType : item.Subtype;
                    return item.Category == category && effectiveSubtype == subtype;
                })
                .Select(x => (Slot: x.Key, Item: x.Value, Count: GetItemCountForConsume(x.Value)))
                .Where(x => x.Count > 0)
                .ToArray();
            var totalCount = candidates.Sum(x => x.Count);
            if (totalCount < amount)
            {
                return false;
            }

            var remaining = amount;
            foreach (var candidate in candidates)
            {
                if (remaining <= 0)
                {
                    break;
                }

                var consume = Math.Min(candidate.Count, remaining);
                var nextCount = candidate.Count - consume;
                remaining -= consume;

                if (nextCount <= 0)
                {
                    slots.Remove(candidate.Slot);
                    continue;
                }

                slots[candidate.Slot] = WithConsumedCount(candidate.Item, nextCount);
            }

            return remaining == 0;
        }

        private void NormalizeLegacyStarterAvatarCard()
        {
            if (!Storages.TryGetValue(6, out var avatarRoomSlots) || avatarRoomSlots.Count == 0)
            {
                return;
            }

            if (!Storages.TryGetValue(5, out var bagSlots))
            {
                bagSlots = new Dictionary<int, InventoryItem>();
                Storages[5] = bagSlots;
            }

            var toMove = avatarRoomSlots.Values
                .Where(x => x.Avatar is not null && string.IsNullOrWhiteSpace(x.Resource))
                .OrderBy(x => x.Slot)
                .ToList();

            if (toMove.Count == 0)
            {
                return;
            }

            foreach (var item in toMove)
            {
                var targetSlot = Enumerable.Range(1, 36).FirstOrDefault(i => !bagSlots.ContainsKey(i));
                if (targetSlot == 0)
                {
                    break;
                }

                var subType = item.SubType > 0 ? item.SubType : item.Subtype;
                bagSlots[targetSlot] = item with
                {
                    Slot = targetSlot,
                    Resource = subType == 2 ? "herocard" : "humancard",
                    Sid = item.Sid == 0 ? StableSid(5, $"legacy:{item.Pid}") : item.Sid,
                    Type = 5
                };

                avatarRoomSlots.Remove(item.Slot);

                if (string.Equals(EquippedAvatarPid, item.Pid, StringComparison.Ordinal))
                {
                    EquippedAvatarPid = bagSlots[targetSlot].Pid;
                }
            }
        }

        private void NormalizeHotKeySlots()
        {
            lock (_stateLock)
            {
                // A null entry can only come from a corrupted/legacy profile; drop it before every
                // other pass so the rest of this method (and every caller) sees usable slots only.
                var invalidSlots = _hotKeySlots
                    .Where(x => x.Key <= 0 || x.Key > HotKeySlotCapacity || x.Value is null)
                    .Select(x => x.Key)
                    .ToArray();
                foreach (var invalidSlot in invalidSlots)
                {
                    _hotKeySlots.Remove(invalidSlot);
                }

                var seenItemIds = new HashSet<string>(StringComparer.Ordinal);
                var seenSkillIds = new HashSet<int>();
                foreach (var pair in _hotKeySlots.OrderBy(x => x.Key).ToArray())
                {
                    if (pair.Value.Type == (int)ShopItemDatabase.ItemType.Skill)
                    {
                        // Skill slots are keyed by skill id rather than an inventory pid.
                        if (pair.Value.SkillId <= 0 || !seenSkillIds.Add(pair.Value.SkillId))
                        {
                            _hotKeySlots.Remove(pair.Key);
                        }

                        continue;
                    }

                    if (string.IsNullOrWhiteSpace(pair.Value.ItemId) || !seenItemIds.Add(pair.Value.ItemId))
                    {
                        _hotKeySlots.Remove(pair.Key);
                    }
                }

                var weaponSlots = _hotKeySlots.Values
                    .Where(x => x is not null && x.Type == 2)
                    .OrderBy(x => x.Slot)
                    .Select(x => x.Slot)
                    .ToArray();
                if (weaponSlots.Length <= MaxWeaponHotKeyCount)
                {
                    return;
                }

                foreach (var slot in weaponSlots.Skip(MaxWeaponHotKeyCount))
                {
                    _hotKeySlots.Remove(slot);
                }
            }
        }

        private void EnsureDefaultWeaponHotKeySlots()
        {
            lock (_stateLock)
            {
                if (_hotKeySlots.Values.Any(slot =>
                        slot is not null &&
                        slot.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                        IsBattleLoadoutResource(slot.Resource)))
                {
                    return;
                }

                if (!Storages.TryGetValue((int)ShopItemDatabase.ItemType.Equipment, out var equipmentStorage))
                {
                    return;
                }

                var slot = 1;
                foreach (var item in equipmentStorage.Values
                             .Where(IsBattleLoadoutItem)
                             .OrderBy(item => item.Slot)
                             .Take(MaxWeaponHotKeyCount))
                {
                    _hotKeySlots[slot] = new HotKeySlot(
                        Slot: slot,
                        Type: item.Type,
                        ItemId: item.Pid,
                        Resource: item.Resource,
                        Grade: item.Grade,
                        Quantity: item.Quantity,
                        UnitType: item.UnitType,
                        Unit: item.Unit,
                        Subtype: item.Subtype,
                        Sid: item.Sid,
                        RefitLevel: item.RefitLevel,
                        PlusLevel: item.PlusLevel,
                        RefitTotalExp: item.RefitTotalExp);
                    slot++;
                }
            }
        }

        private int CountWeaponHotKeys()
        {
            lock (_stateLock)
            {
                return _hotKeySlots.Values.Count(x => x is not null && x.Type == 2);
            }
        }

        /// <summary>
        /// Guarantees that every active profession skill owns a quick slot. A fresh character only
        /// receives weapon quick slots (see <see cref="EnsureDefaultWeaponHotKeySlots"/>), and the
        /// skill quick slots are otherwise only written when the player drags a skill onto the bar.
        /// Without them the in-game character equipment block carries no type-1 entries, the client
        /// builds an empty in-game skill bar and no key can trigger a skill.
        /// Weapon slots 1..3 stay untouched; profession skills take the lowest free slot from 4 up,
        /// which matches the retail layout (weapons first, then the profession skills).
        /// </summary>
        private void EnsureDefaultSkillHotKeySlots()
        {
            lock (_stateLock)
            {
                var occupation = Math.Clamp(Character.Occupation, 0, 3);
                var equippedSkillIds = new HashSet<int>(
                    _hotKeySlots.Values
                        .Where(slot => slot is not null && slot.Type == (int)ShopItemDatabase.ItemType.Skill)
                        .Select(slot => slot.SkillId));

                foreach (var definition in SkillCatalog.GetSkills(occupation))
                {
                    if (!definition.IsActive || !equippedSkillIds.Add(definition.Id))
                    {
                        continue;
                    }

                    var slot = FindFreeSkillHotKeySlot();
                    if (slot <= 0)
                    {
                        break;
                    }

                    _hotKeySlots[slot] = new HotKeySlot(
                        Slot: slot,
                        Type: (int)ShopItemDatabase.ItemType.Skill,
                        ItemId: string.Empty,
                        Resource: definition.Resource,
                        Grade: 0,
                        Quantity: 0,
                        UnitType: 0,
                        Unit: 0,
                        Subtype: 0,
                        Sid: 0,
                        SkillId: definition.Id);
                }
            }
        }

        private int FindFreeSkillHotKeySlot()
        {
            lock (_stateLock)
            {
                for (var slot = DefaultSkillHotKeySlotStart; slot <= HotKeySlotCapacity; slot++)
                {
                    if (!_hotKeySlots.ContainsKey(slot))
                    {
                        return slot;
                    }
                }

                return 0;
            }
        }

        private void RemoveHotKeyReferencesToItem(string itemId, int exceptSlot)
        {
            lock (_stateLock)
            {
                var duplicateSlots = _hotKeySlots
                    .Where(x => x.Key != exceptSlot &&
                                x.Value is not null &&
                                string.Equals(x.Value.ItemId, itemId, StringComparison.Ordinal))
                    .Select(x => x.Key)
                    .ToArray();

                foreach (var duplicateSlot in duplicateSlots)
                {
                    _hotKeySlots.Remove(duplicateSlot);
                }
            }
        }

        private HashSet<string> GetEquippedEquipmentPids()
        {
            var equippedPids = new HashSet<string>(StringComparer.Ordinal);
            foreach (var pid in EquippedItemsByType.Values)
            {
                if (!string.IsNullOrWhiteSpace(pid))
                {
                    equippedPids.Add(pid);
                }
            }

            lock (_stateLock)
            {
                foreach (var hotKey in _hotKeySlots.Values)
                {
                    if (hotKey is not null &&
                        hotKey.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                        !string.IsNullOrWhiteSpace(hotKey.ItemId))
                    {
                        equippedPids.Add(hotKey.ItemId);
                    }
                }
            }

            return equippedPids;
        }

        private void SyncEquipmentEquipFlags()
        {
            if (!Storages.TryGetValue((int)ShopItemDatabase.ItemType.Equipment, out var equipmentSlots))
            {
                return;
            }

            var equippedPids = GetEquippedEquipmentPids();
            foreach (var pair in equipmentSlots.ToArray())
            {
                var shouldEquip = equippedPids.Contains(pair.Value.Pid);
                var nextFlag = shouldEquip ? "Y" : "N";
                if (!string.Equals(pair.Value.IsEquip, nextFlag, StringComparison.OrdinalIgnoreCase))
                {
                    equipmentSlots[pair.Key] = pair.Value with { IsEquip = nextFlag };
                }
            }
        }

        public object[] GetHotKeySlots(int totalSlots = HotKeySlotCount)
        {
            lock (_stateLock)
            {
                EnsureStarterInventory();
                NormalizeHotKeySlots();
                EnsureDefaultWeaponHotKeySlots();
                EnsureDefaultSkillHotKeySlots();
                SyncEquipmentEquipFlags();

                totalSlots = totalSlots <= 0 ? HotKeySlotCount : Math.Clamp(totalSlots, 1, HotKeySlotCount);
                var result = new object[totalSlots];
                for (var i = 1; i <= totalSlots; i++)
                {
                    if (_hotKeySlots.TryGetValue(i, out var entry) && entry is not null)
                    {
                        if (entry.Type == (int)ShopItemDatabase.ItemType.Skill)
                        {
                            var definition = FindSkill(entry.SkillId);
                            result[i - 1] = new
                            {
                                slot = entry.Slot,
                                type = entry.Type,
                                itemid = ResolveSkillLoadoutItemId(entry.SkillId).ToString(CultureInfo.InvariantCulture),
                                display = definition?.ResolveDisplay(GetSkillLevel(entry.SkillId)) ?? string.Empty,
                                resource = string.IsNullOrWhiteSpace(definition?.Resource) ? entry.Resource : definition!.Resource,
                                quantity = 1
                            };
                            continue;
                        }

                        // 强化等级跟背包里的实物走（强化成功后快捷栏的等级角标要立刻更新），
                        // 读不到实物时再退回快捷栏缓存的快照字段。官方 slot_get 也会下发
                        // display/refitLevel（抓包：type=2 的武器带 refitLevel）。
                        var hotKeyItem = FindBackpackItemForHotKeySlot(entry);
                        result[i - 1] = new
                        {
                            slot = entry.Slot,
                            type = entry.Type,
                            itemid = entry.ItemId,
                            display = string.IsNullOrWhiteSpace(hotKeyItem?.Display) ? entry.Resource : hotKeyItem!.Display,
                            resource = entry.Resource,
                            grade = hotKeyItem?.Grade ?? entry.Grade,
                            quantity = entry.Quantity,
                            unitType = hotKeyItem?.UnitType ?? entry.UnitType,
                            unit = hotKeyItem?.Unit ?? entry.Unit,
                            subtype = hotKeyItem?.Subtype ?? entry.Subtype,
                            sid = hotKeyItem?.Sid ?? entry.Sid,
                            refitLevel = hotKeyItem?.RefitLevel ?? entry.RefitLevel,
                            plusLevel = hotKeyItem?.PlusLevel ?? entry.PlusLevel,
                            refitTotalExp = hotKeyItem?.RefitTotalExp ?? entry.RefitTotalExp
                        };
                    }
                    else
                    {
                        result[i - 1] = new
                        {
                            slot = i,
                            type = 0,
                            itemid = "0",
                            display = string.Empty,
                            resource = string.Empty,
                            quantity = 0
                        };
                    }
                }

                return result;
            }
        }

        private SkillDefinition? FindSkill(int skillId)
        {
            var occupation = Math.Clamp(Character.Occupation, 0, 3);
            foreach (var definition in SkillCatalog.GetSkills(occupation))
            {
                if (definition.Id == skillId)
                {
                    return definition;
                }
            }

            return null;
        }

        /// <summary>
        /// Equips an active profession skill onto a hotkey slot. Any other slot holding the
        /// same skill is cleared, mirroring how the client drags a skill onto the hotbar.
        /// </summary>
        public bool TrySetSkillHotKeySlot(int slot, int skillId)
        {
            lock (_stateLock)
            {
                if (slot <= 0 || slot > HotKeySlotCapacity)
                {
                    return false;
                }

                var definition = FindSkill(skillId);
                if (definition is null)
                {
                    return false;
                }

                var duplicates = _hotKeySlots
                    .Where(x => x.Key != slot &&
                                x.Value is not null &&
                                x.Value.Type == (int)ShopItemDatabase.ItemType.Skill &&
                                x.Value.SkillId == skillId)
                    .Select(x => x.Key)
                    .ToArray();
                foreach (var duplicate in duplicates)
                {
                    _hotKeySlots.Remove(duplicate);
                }

                _hotKeySlots[slot] = new HotKeySlot(
                    Slot: slot,
                    Type: (int)ShopItemDatabase.ItemType.Skill,
                    ItemId: string.Empty,
                    Resource: definition.Resource,
                    Grade: 0,
                    Quantity: 0,
                    UnitType: 0,
                    Unit: 0,
                    Subtype: 0,
                    Sid: 0,
                    SkillId: skillId);
                return true;
            }
        }

        public bool TrySetHotKeySlot(int slot, string? pid, out string? errorKey)
        {
            lock (_stateLock)
            {
                EnsureStarterInventory();
                NormalizeHotKeySlots();
                errorKey = null;

                if (slot <= 0 || slot > HotKeySlotCount || string.IsNullOrWhiteSpace(pid))
                {
                    errorKey = "msgbox_common_num_1306";
                    return false;
                }

                var item = FindInventoryItemByPid(pid);
                if (item is null)
                {
                    errorKey = "msgbox_common_num_1005";
                    return false;
                }

                RemoveHotKeyReferencesToItem(item.Pid, slot);

                if (item.Type == 2)
                {
                    var currentIsWeapon = _hotKeySlots.TryGetValue(slot, out var currentSlot) &&
                                          currentSlot is not null &&
                                          currentSlot.Type == 2;
                    if (!currentIsWeapon && CountWeaponHotKeys() >= MaxWeaponHotKeyCount)
                    {
                        // 快捷栏武器位上限�? 个）
                        errorKey = "UI_common_Insufficient_slot";
                        return false;
                    }
                }

                _hotKeySlots[slot] = new HotKeySlot(
                    Slot: slot,
                    Type: item.Type,
                    ItemId: item.Pid,
                    Resource: item.Resource,
                    Grade: item.Grade,
                    Quantity: item.Quantity,
                    UnitType: item.UnitType,
                    Unit: item.Unit,
                    Subtype: item.Subtype,
                    Sid: item.Sid,
                    RefitLevel: item.RefitLevel,
                    PlusLevel: item.PlusLevel,
                    RefitTotalExp: item.RefitTotalExp);
                SyncEquipmentEquipFlags();
                return true;
            }
        }

        public bool TrySetHotKeySlot(int slot, string? pid)
        {
            return TrySetHotKeySlot(slot, pid, out _);
        }

        public bool TryClearHotKeySlot(int slot)
        {
            lock (_stateLock)
            {
                EnsureStarterInventory();
                NormalizeHotKeySlots();

                if (slot <= 0 || slot > HotKeySlotCount)
                {
                    return false;
                }

                var removed = _hotKeySlots.Remove(slot);
                if (removed)
                {
                    SyncEquipmentEquipFlags();
                }

                return removed;
            }
        }

        public bool TrySwapHotKeySlots(int fromSlot, int toSlot)
        {
            lock (_stateLock)
            {
                EnsureStarterInventory();
                NormalizeHotKeySlots();

                if (fromSlot <= 0 || toSlot <= 0 || fromSlot > HotKeySlotCount || toSlot > HotKeySlotCount || fromSlot == toSlot)
                {
                    return false;
                }

                var fromExists = _hotKeySlots.TryGetValue(fromSlot, out var from) && from is not null;
                var toExists = _hotKeySlots.TryGetValue(toSlot, out var to) && to is not null;

                if (fromExists)
                {
                    _hotKeySlots[toSlot] = from! with { Slot = toSlot };
                }
                else
                {
                    _hotKeySlots.Remove(toSlot);
                }

                if (toExists)
                {
                    _hotKeySlots[fromSlot] = to! with { Slot = fromSlot };
                }
                else
                {
                    _hotKeySlots.Remove(fromSlot);
                }

                SyncEquipmentEquipFlags();
                return true;
            }
        }

        private InventoryItem? FindItemByPid(string? pid, params int[] storageTypes)
        {
            if (string.IsNullOrWhiteSpace(pid))
            {
                return null;
            }

            IEnumerable<KeyValuePair<int, Dictionary<int, InventoryItem>>> storages = Storages;
            if (storageTypes.Length > 0)
            {
                storages = storages.Where(x => storageTypes.Contains(x.Key));
            }

            foreach (var (_, slots) in storages)
            {
                foreach (var item in slots.Values)
                {
                    if (string.Equals(item.Pid, pid, StringComparison.Ordinal))
                    {
                        return item;
                    }
                }
            }

            return null;
        }

        public InventoryItem? FindInventoryItemByPid(string? pid)
        {
            EnsureStarterInventory();
            return FindItemByPid(pid);
        }

        /// <summary>
        /// 按 pid 定位物品所在的仓库与槽位，供强化武器等需要就地改写的流程使用。
        /// </summary>
        public bool TryLocateInventoryItem(string? pid, out int storageType, out int slot, out InventoryItem? item)
        {
            storageType = 0;
            slot = 0;
            item = null;
            if (string.IsNullOrWhiteSpace(pid))
            {
                return false;
            }

            EnsureStarterInventory();
            foreach (var (type, slots) in Storages)
            {
                foreach (var (key, value) in slots)
                {
                    if (!string.Equals(value.Pid, pid, StringComparison.Ordinal))
                    {
                        continue;
                    }

                    storageType = type;
                    slot = key;
                    item = value;
                    return true;
                }
            }

            return false;
        }

        /// <summary>
        /// 整件消耗物品（例如强化武器的材料武器）。已装备的物品不允许被消耗。
        /// </summary>
        public bool TryRemoveInventoryItemByPid(string? pid, out InventoryItem? removed)
        {
            removed = null;
            if (!TryLocateInventoryItem(pid, out var storageType, out var slot, out var item) || item is null)
            {
                return false;
            }

            if (string.Equals(item.IsEquip, "Y", StringComparison.Ordinal))
            {
                return false;
            }

            removed = item;
            lock (_stateLock)
            {
                if (Storages.TryGetValue(storageType, out var slots))
                {
                    slots.Remove(slot);
                }

                // 被消耗的武器如果还挂在快捷栏上会留下悬空引用（GetGameLoadoutItems 会拿同 resource
                // 的另一件武器顶上），这里一并摘掉，避免快捷栏悄悄换枪。
                var hotKeySlots = _hotKeySlots
                    .Where(x => x.Value is not null && string.Equals(x.Value.ItemId, item.Pid, StringComparison.Ordinal))
                    .Select(x => x.Key)
                    .ToArray();
                foreach (var hotKeySlot in hotKeySlots)
                {
                    _hotKeySlots.Remove(hotKeySlot);
                }

                SyncEquipmentEquipFlags();
            }

            return true;
        }

        /// <summary>
        /// 写入强化进度（累计经验 + 等级）。plusLevel 与 refitLevel 保持同值，
        /// 因为官方客户端在物品列表里把两者一起下发。
        /// </summary>
        public bool TryApplyRefitProgress(string? pid, int totalExp, int level)
        {
            if (!TryLocateInventoryItem(pid, out var storageType, out var slot, out var item) || item is null)
            {
                return false;
            }

            var normalizedExp = Math.Max(0, totalExp);
            var normalizedLevel = Math.Clamp(level, 0, 20);
            if (Storages.TryGetValue(storageType, out var slots))
            {
                slots[slot] = item with
                {
                    RefitTotalExp = normalizedExp,
                    RefitLevel = normalizedLevel,
                    PlusLevel = normalizedLevel
                };
            }

            return true;
        }

        private const string StarterRefitMaterialsFlag = "starter_refit_materials_v1";

        /// <summary>
        /// 一次性发放初始强化材料，让强化武器流程开箱即用；用持久化标记保证只发一次。
        /// </summary>
        private void EnsureRefitMaterials()
        {
            if (!RewardFlags.Add(StarterRefitMaterialsFlag))
            {
                return;
            }

            GrantRefitMaterialStack("wim_steel", 109, 999999, category: 108, display: "id_datalist_Alloy_Steel");
            GrantRefitMaterialStack("wim_composite", 111, 999999, category: 110, display: "id_datalist_Composites");
            GrantRefitMaterialStack("intensify_luck", 20628, 999999, category: 3, display: "id_datalist_intensify_luck");
            GrantRefitMaterialStack("intensify_translation", 20631, 999999, category: 6, display: "id_datalist_intensify_translation");
            GrantRefitMaterialWeapons();
        }

        /// <summary>
        /// 强化武器的材料必须是 2/3 级武器（官方 refit_detail.grades 的位掩码只覆盖 2..5 级），
        /// 而新号的初始武器全是 1 级，材料列表会空着。这里补几件 2/3 级武器，让强化面板开箱可用；
        /// 更多材料可以去商城按 1 金币一把购买。
        /// </summary>
        private void GrantRefitMaterialWeapons()
        {
            GrantRefitWeapon("smg_02", 20002, fallbackGrade: 2, fallbackSubtype: 1, fallbackDisplay: "id_datalist_Savage_Terminator");
            GrantRefitWeapon("sniperrifle_02", 20312, fallbackGrade: 2, fallbackSubtype: 2, fallbackDisplay: "id_datalist_Snakes_Touch");
            GrantRefitWeapon("shotgun_02", 20449, fallbackGrade: 2, fallbackSubtype: 4, fallbackDisplay: "id_datalist_Stalker");
            GrantRefitWeapon("smg_05", 20005, fallbackGrade: 3, fallbackSubtype: 1, fallbackDisplay: "id_datalist_Savage_Terminator_Enhanced_Edition");
            GrantRefitWeapon("sniperrifle_05", 20315, fallbackGrade: 3, fallbackSubtype: 2, fallbackDisplay: "id_datalist_Snakes_Touch_Enhanced_Edition");
            GrantRefitWeapon("shotgun_05", 20452, fallbackGrade: 3, fallbackSubtype: 4, fallbackDisplay: "id_datalist_Stalker_Enhanced_Edition");
        }

        private void GrantRefitWeapon(string resource, int fallbackSid, int fallbackGrade, int fallbackSubtype, string fallbackDisplay)
        {
            var sid = fallbackSid;
            var grade = fallbackGrade;
            var subtype = fallbackSubtype;
            var display = fallbackDisplay;
            if (ShopItemDatabase.TryGetShopItemByResource(resource, out var shopItem))
            {
                if (shopItem.Sid > 0)
                {
                    sid = shopItem.Sid;
                }

                if (shopItem.Grade > 0)
                {
                    grade = shopItem.Grade;
                }

                if (shopItem.Subtype > 0)
                {
                    subtype = shopItem.Subtype;
                }

                if (!string.IsNullOrWhiteSpace(shopItem.Display))
                {
                    display = shopItem.Display;
                }
            }

            TryGrantInventoryItem(
                type: (int)ShopItemDatabase.ItemType.Equipment,
                subtype: subtype,
                grade: grade,
                sid: sid,
                resource: resource,
                quantity: 1,
                unitType: 1,
                unit: 1,
                category: 0,
                display: display);
        }

        private void GrantRefitMaterialStack(string resource, int fallbackSid, int count, int category, string display)
        {
            var sid = fallbackSid;
            var subtype = 100;
            var grade = 2;
            if (ShopItemDatabase.TryGetShopItemByResource(resource, out var shopItem))
            {
                if (shopItem.Sid > 0)
                {
                    sid = shopItem.Sid;
                }

                if (shopItem.Subtype > 0)
                {
                    subtype = shopItem.Subtype;
                }

                if (shopItem.Grade > 0)
                {
                    grade = shopItem.Grade;
                }
            }

            TryGrantInventoryItem(
                type: (int)ShopItemDatabase.ItemType.Item,
                subtype: subtype,
                grade: grade,
                sid: sid,
                resource: resource,
                quantity: count,
                unitType: 1,
                unit: count,
                category: category,
                display: display,
                description: display + "_desc");
        }

        public IReadOnlyList<GameLoadoutItem> GetGameLoadoutItems()
        {
            lock (_stateLock)
            {
                EnsureStarterInventory();
                NormalizeHotKeySlots();
                EnsureDefaultWeaponHotKeySlots();
                EnsureDefaultSkillHotKeySlots();

                var hotKeyLoadout = _hotKeySlots.Values
                    .Where(slot => slot is not null && IsBattleLoadoutHotKeySlot(slot))
                    .OrderBy(slot => slot.Slot)
                    .Select(CreateHotKeyLoadoutItem)
                    .ToList();
                // Equipment items decide whether the quick bar counts as configured: a character whose
                // bar only holds profession skills still needs the backpack weapons merged in, but the
                // skill entries must survive that fallback.
                var hasEquipmentEntries = _hotKeySlots.Values.Any(slot =>
                    slot is not null &&
                    slot.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                    IsBattleLoadoutResource(slot.Resource));

                return hasEquipmentEntries
                    ? hotKeyLoadout
                    : MergeSkillLoadoutIntoBackpackFallback(GetBackpackGameLoadoutItems());
            }
        }

        /// <summary>
        /// The backpack fallback only knows about weapons, so the profession skills of the quick bar
        /// are appended to keep the in-game skill bar populated when the weapon quick slots are empty.
        /// </summary>
        private IReadOnlyList<GameLoadoutItem> MergeSkillLoadoutIntoBackpackFallback(
            IReadOnlyList<GameLoadoutItem> backpackItems)
        {
            lock (_stateLock)
            {
                var skillItems = _hotKeySlots.Values
                    .Where(slot => slot is not null && slot.Type == (int)ShopItemDatabase.ItemType.Skill)
                    .OrderBy(slot => slot.Slot)
                    .Select(CreateHotKeyLoadoutItem)
                    .ToArray();
                if (skillItems.Length == 0)
                {
                    return backpackItems;
                }

                var merged = new List<GameLoadoutItem>(backpackItems.Count + skillItems.Length);
                merged.AddRange(backpackItems);
                merged.AddRange(skillItems);
                return merged;
            }
        }

        public string GetGameLoadoutSource()
        {
            lock (_stateLock)
            {
                EnsureStarterInventory();
                NormalizeHotKeySlots();
                EnsureDefaultWeaponHotKeySlots();
                EnsureDefaultSkillHotKeySlots();

                return _hotKeySlots.Values.Any(slot =>
                    slot is not null &&
                    slot.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                    IsBattleLoadoutResource(slot.Resource))
                    ? "hotkey"
                    : "backpack-fallback";
            }
        }

        private GameLoadoutItem CreateHotKeyLoadoutItem(HotKeySlot slot)
        {
            if (slot.Type == (int)ShopItemDatabase.ItemType.Skill)
            {
                var definition = FindSkill(slot.SkillId);
                var skillResource = string.IsNullOrWhiteSpace(definition?.Resource) ? slot.Resource : definition!.Resource;
                var skillLevel = GetSkillLevel(slot.SkillId);
                return new GameLoadoutItem(
                    Slot: (byte)Math.Clamp(slot.Slot, 0, byte.MaxValue),
                    ItemType: (byte)ShopItemDatabase.ItemType.Skill,
                    ItemId: ResolveSkillLoadoutItemId(slot.SkillId),
                    Resource: skillResource,
                    Grade: 0,
                    DisplayName: definition?.ResolveDisplay(skillLevel) ?? skillResource,
                    Subtype: 1,
                    SkillId: slot.SkillId,
                    SkillLevel: skillLevel);
            }

            var backpackItem = FindBackpackItemForHotKeySlot(slot);
            var item = backpackItem ?? FindItemByPid(slot.ItemId);
            var resource = string.IsNullOrWhiteSpace(item?.Resource) ? slot.Resource : item!.Resource;
            return new GameLoadoutItem(
                Slot: (byte)Math.Clamp(slot.Slot, 0, byte.MaxValue),
                ItemType: (byte)Math.Clamp(item?.Type ?? slot.Type, 0, byte.MaxValue),
                ItemId: TryParsePidAsLong(item?.Pid ?? slot.ItemId),
                Resource: resource,
                Grade: (byte)Math.Clamp(item?.Grade ?? slot.Grade, 0, byte.MaxValue),
                DisplayName: string.IsNullOrWhiteSpace(item?.Display) ? resource : item!.Display,
                Subtype: (byte)Math.Clamp(item?.Subtype ?? slot.Subtype, 0, byte.MaxValue));
        }

        private InventoryItem? FindBackpackItemForHotKeySlot(HotKeySlot slot)
        {
            var item = FindItemByPid(slot.ItemId, (int)ShopItemDatabase.ItemType.Equipment);
            if (item is not null)
            {
                return item;
            }

            if (!Storages.TryGetValue((int)ShopItemDatabase.ItemType.Equipment, out var equipmentStorage))
            {
                return null;
            }

            return equipmentStorage.Values
                .Where(candidate =>
                    candidate.Type == slot.Type &&
                    string.Equals(candidate.Resource, slot.Resource, StringComparison.OrdinalIgnoreCase))
                .OrderBy(candidate => candidate.Slot)
                .FirstOrDefault();
        }

        public IReadOnlyList<GameLoadoutItem> GetBackpackGameLoadoutItems()
        {
            EnsureStarterInventory();

            if (!Storages.TryGetValue((int)ShopItemDatabase.ItemType.Equipment, out var equipmentStorage))
            {
                return Array.Empty<GameLoadoutItem>();
            }

            return equipmentStorage.Values
                .Where(IsBattleLoadoutItem)
                .OrderBy(item => item.Slot)
                .Take(MaxWeaponHotKeyCount)
                .Select((item, index) => CreateBattleLoadoutItem(item, index + 1))
                .ToList();
        }

        private static GameLoadoutItem CreateBattleLoadoutItem(InventoryItem item, int slot)
        {
            var resource = item.Resource;
            return new GameLoadoutItem(
                Slot: (byte)Math.Clamp(slot, 1, byte.MaxValue),
                ItemType: (byte)Math.Clamp(item.Type, 0, byte.MaxValue),
                ItemId: TryParsePidAsLong(item.Pid),
                Resource: resource,
                Grade: (byte)Math.Clamp(item.Grade, 0, byte.MaxValue),
                DisplayName: string.IsNullOrWhiteSpace(item.Display) ? resource : item.Display,
                Subtype: (byte)Math.Clamp(item.Subtype, 0, byte.MaxValue));
        }

        private static bool IsBattleLoadoutItem(InventoryItem? item)
        {
            if (item is null || item.Type != 2)
            {
                return false;
            }

            return IsBattleLoadoutResource(item.Resource);
        }

        private bool IsBattleLoadoutHotKeySlot(HotKeySlot slot)
        {
            if (slot.Type == (int)ShopItemDatabase.ItemType.Skill)
            {
                // Skill id 0 is the guardian's Battlefield Heal, so a "positive id" test would drop
                // the only heal of that profession; a resolved definition plus a resource key is the
                // real marker of a usable quick-slot skill.
                return FindSkill(slot.SkillId) is not null &&
                       !string.IsNullOrWhiteSpace(slot.Resource);
            }

            return slot.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                   IsBattleLoadoutResource(slot.Resource);
        }

        private static bool IsBattleLoadoutResource(string? resource)
        {
            if (string.IsNullOrWhiteSpace(resource))
            {
                return false;
            }

            return !resource.Contains("wing", StringComparison.OrdinalIgnoreCase) &&
                   !resource.StartsWith("badge", StringComparison.OrdinalIgnoreCase) &&
                   !resource.StartsWith("ring", StringComparison.OrdinalIgnoreCase) &&
                   !resource.StartsWith("deco_", StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsGrenadeLoadoutItem(InventoryItem item)
        {
            return item.Subtype is 10 or 102 or 103 ||
                   item.Resource.Contains("grenade", StringComparison.OrdinalIgnoreCase);
        }

        private static long TryParsePidAsLong(string pid)
        {
            return long.TryParse(pid, NumberStyles.Integer, CultureInfo.InvariantCulture, out var value)
                ? value
                : 0;
        }

        /// <summary>
        /// Deterministic synthetic item id for an equipped skill. Skills are not inventory
        /// items, so the in-match loadout carries an id derived from the skill id instead.
        /// </summary>
        private static long ResolveSkillLoadoutItemId(int skillId)
        {
            return SkillLoadoutItemIdBase + skillId;
        }

        public InventoryItem? FindAvatarItemByAvatarId(string? avatarId)
        {
            EnsureStarterInventory();

            if (string.IsNullOrWhiteSpace(avatarId))
            {
                return null;
            }

            if (!string.IsNullOrWhiteSpace(EquippedAvatarPid))
            {
                var equipped = FindItemByPid(EquippedAvatarPid, 5, 6);
                if (equipped is not null &&
                    string.Equals(GetAvatarIdFrom(equipped.Avatar), avatarId, StringComparison.Ordinal))
                {
                    return equipped;
                }
            }

            foreach (var storageType in new[] { 5, 6 })
            {
                if (!Storages.TryGetValue(storageType, out var slots))
                {
                    continue;
                }

                var found = slots.Values.FirstOrDefault(x =>
                    string.Equals(GetAvatarIdFrom(x.Avatar), avatarId, StringComparison.Ordinal));
                if (found is not null)
                {
                    return found;
                }
            }

            return null;
        }

        private InventoryItem? PickBestEquippedAvatarCandidate()
        {
            InventoryItem? ByPredicate(Func<InventoryItem, bool> predicate)
            {
                foreach (var storageType in new[] { 5, 6 })
                {
                    if (!Storages.TryGetValue(storageType, out var slots))
                    {
                        continue;
                    }

                    var found = slots.Values
                        .OrderBy(x => x.Slot)
                        .FirstOrDefault(predicate);
                    if (found is not null)
                    {
                        return found;
                    }
                }

                return null;
            }

            var byPid = FindItemByPid(EquippedAvatarPid, 5, 6);
            if (byPid is not null)
            {
                return byPid;
            }

            return ByPredicate(x => string.Equals(x.IsEquip, "Y", StringComparison.OrdinalIgnoreCase))
                ?? ByPredicate(x => x.Avatar is not null)
                ?? ByPredicate(_ => true);
        }

        private InventoryItem SyncEquippedAvatarState(InventoryItem equipped)
        {
            EquippedAvatarPid = equipped.Pid;
            if (equipped.Avatar is not null)
            {
                Character = Character with { EquipAvatar = equipped.Avatar };
            }

            foreach (var storageType in new[] { 5, 6 })
            {
                if (!Storages.TryGetValue(storageType, out var slots))
                {
                    continue;
                }

                foreach (var pair in slots.ToArray())
                {
                    var shouldEquip = pair.Value.Slot == equipped.Slot;
                    slots[pair.Key] = pair.Value with
                    {
                        IsEquip = shouldEquip ? "Y" : "N"
                    };
                }
            }

            return FindItemByPid(equipped.Pid, 5, 6) ?? equipped;
        }

        private void ReplaceItem(InventoryItem item)
        {
            if (!Storages.TryGetValue(item.Type == 5 || item.Type == 6 ? (item.Type == 5 ? 5 : 6) : item.Type, out var slots))
            {
                foreach (var storage in Storages.Values)
                {
                    if (storage.TryGetValue(item.Slot, out var existingSlotItem) && string.Equals(existingSlotItem.Pid, item.Pid, StringComparison.Ordinal))
                    {
                        storage[item.Slot] = item;
                        return;
                    }
                }

                return;
            }

            if (slots.TryGetValue(item.Slot, out var existingSlotItemInStorage) && string.Equals(existingSlotItemInStorage.Pid, item.Pid, StringComparison.Ordinal))
            {
                slots[item.Slot] = item;
                return;
            }

            foreach (var storage in Storages.Values)
            {
                foreach (var pair in storage)
                {
                    if (string.Equals(pair.Value.Pid, item.Pid, StringComparison.Ordinal))
                    {
                        storage[pair.Key] = item;
                        return;
                    }
                }
            }
        }

        public InventoryItem? GetEquippedAvatarItem()
        {
            EnsureStarterInventory();
            var equipped = PickBestEquippedAvatarCandidate();
            return equipped is null ? null : SyncEquippedAvatarState(equipped);
        }

        public object[] GetEquippedItems()
        {
            EnsureStarterInventory();

            var result = new List<object>();
            foreach (var (equipType, pid) in EquippedItemsByType.OrderBy(x => x.Key))
            {
                if (equipType is < 1 or > 4)
                {
                    continue;
                }

                var item = FindItemByPid(pid, 2);
                if (item is null || string.IsNullOrWhiteSpace(item.Resource))
                {
                    continue;
                }

                var pidNum = int.TryParse(item.Pid, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
                    ? parsed
                    : 0;
                var itemDef = ShopItemDatabase.GetShopItem(item.Sid);
                var effectiveSubType = item.SubType > 0 ? item.SubType : item.Subtype;
                var clientResource = ShopItemDatabase.GetClientResource(
                    itemDef,
                    item.Resource,
                    item.Type,
                    effectiveSubType);
                var occupation = itemDef?.Occupation ?? 0;
                if (occupation < 0)
                {
                    occupation = 0;
                }

                result.Add(new
                {
                    type = equipType,
                    itemId = pidNum,
                    pid = pidNum,
                    resource = clientResource,
                    grade = item.Grade,
                    unitType = item.UnitType,
                    unit = item.Unit,
                    quantity = item.Quantity,
                    subtype = item.Subtype,
                    subType = effectiveSubType,
                    level = itemDef?.Level ?? 0,
                    occupation
                });
            }

            return result.ToArray();
        }

        public IReadOnlyList<string> GetGameIndependentTrinketResources()
        {
            return GetGameIndependentTrinketItems()
                .Select(item => item.Resource)
                .ToArray();
        }

        public IReadOnlyList<GameIndependentTrinketItem> GetGameIndependentTrinketItems()
        {
            EnsureStarterInventory();

            const int independentTrinketSlotCount = 5;
            var resources = Enumerable.Range(1, independentTrinketSlotCount)
                .Select(slot => new GameIndependentTrinketItem(slot, string.Empty, null))
                .ToArray();
            foreach (var (equipType, pid) in EquippedItemsByType.OrderBy(x => x.Key))
            {
                if (equipType is < 1 or > independentTrinketSlotCount)
                {
                    continue;
                }

                var item = FindItemByPid(pid, (int)ShopItemDatabase.ItemType.Equipment);
                if (item is null || string.IsNullOrWhiteSpace(item.Resource))
                {
                    continue;
                }

                var itemDef = ShopItemDatabase.GetShopItem(item.Sid);
                var effectiveSubType = item.SubType > 0 ? item.SubType : item.Subtype;
                var clientResource = ShopItemDatabase.GetClientResource(
                    itemDef,
                    item.Resource,
                    item.Type,
                    effectiveSubType);
                resources[equipType - 1] = new GameIndependentTrinketItem(equipType, clientResource, item);
            }

            return resources;
        }

        public bool EquipAvatarCard(string? pid)
        {
            if (!_ensuringStarterInventory)
            {
                EnsureStarterInventory();
            }

            var item = FindItemByPid(pid, 5, 6);
            if (item is null || item.Avatar is null)
            {
                return false;
            }

            var fallbackAvatarId = GetAvatarIdFrom(Character.EquipAvatar);
            if (string.IsNullOrWhiteSpace(fallbackAvatarId) || string.Equals(fallbackAvatarId, "0", StringComparison.Ordinal))
            {
                fallbackAvatarId = PlayerStore.GetOccupationDefaultAvatarId(Character.Occupation);
            }

            var normalizedAvatar = EnsureAvatarHasAvatarId(item.Avatar, fallbackAvatarId) ?? item.Avatar;
            foreach (var storageType in new[] { 5, 6 })
            {
                if (!Storages.TryGetValue(storageType, out var slots) || !slots.TryGetValue(item.Slot, out var slotItem))
                {
                    continue;
                }

                slots[item.Slot] = slotItem with
                {
                    Avatar = normalizedAvatar,
                    Position = slotItem.Position ?? 1
                };
            }

            var normalizedItem = FindItemByPid(item.Pid, 5, 6) ?? item with { Avatar = normalizedAvatar };
            _ = SyncEquippedAvatarState(normalizedItem);
            return true;
        }

        public bool TrySaveAvatarCard(
            string? avatarPid,
            object? avatar,
            string? display,
            string? designer,
            string? description,
            int position,
            out string? errorKey)
        {
            EnsureStarterInventory();
            errorKey = null;

            var resolvedDisplay = string.IsNullOrWhiteSpace(display) ? Character.Name : display!;
            var resolvedDesigner = string.IsNullOrWhiteSpace(designer) ? Character.Name : designer!;
            var resolvedDescription = description ?? string.Empty;
            var avatarId = GetAvatarIdFrom(avatar) ?? GetAvatarIdFrom(Character.EquipAvatar) ?? "0";
            var resolvedAvatar = EnsureAvatarHasAvatarId(avatar ?? Character.EquipAvatar, avatarId) ?? avatar ?? Character.EquipAvatar;

            bool UpdateCardAtSlot(int storageType, int slot)
            {
                if (!Storages.TryGetValue(storageType, out var slots) || !slots.TryGetValue(slot, out var original))
                {
                    return false;
                }

                var effectiveSubType = original.SubType > 0 ? original.SubType : original.Subtype;
                var resolvedResource = string.IsNullOrWhiteSpace(original.Resource)
                    ? (effectiveSubType == 2 ? "herocard" : "humancard")
                    : original.Resource;

                slots[slot] = original with
                {
                    Resource = resolvedResource,
                    SubType = effectiveSubType,
                    Avatar = resolvedAvatar,
                    Position = position,
                    Display = resolvedDisplay,
                    Designer = resolvedDesigner,
                    Description = resolvedDescription
                };
                return true;
            }

            if (!string.IsNullOrWhiteSpace(avatarPid))
            {
                var existing = FindItemByPid(avatarPid, 5, 6);
                if (existing is not null)
                {
                    var slot = existing.Slot;
                    var updatedBag = UpdateCardAtSlot(5, slot);
                    var updatedRoom = UpdateCardAtSlot(6, slot);
                    var effectiveSubType = existing.SubType > 0 ? existing.SubType : existing.Subtype;
                    var effectiveGrade = existing.Grade > 0 ? existing.Grade : 1;
                    var effectiveQuantity = Math.Max(1, existing.Quantity);
                    var sidSeed = $"saved:{Character.Occupation}:{avatarId}:{slot}";

                    if (!updatedBag)
                    {
                        AddItem(
                            storageType: 5,
                            slot: slot,
                            resource: effectiveSubType == 2 ? "herocard" : "humancard",
                            subtype: effectiveSubType,
                            grade: effectiveGrade,
                            sid: existing.Sid > 0 ? existing.Sid : StableSid(5, sidSeed),
                            type: 5,
                            quantity: effectiveQuantity,
                            avatar: resolvedAvatar,
                            position: position,
                            subType: effectiveSubType,
                            display: resolvedDisplay,
                            designer: resolvedDesigner,
                            description: resolvedDescription);
                    }

                    if (!updatedRoom)
                    {
                        AddItem(
                            storageType: 6,
                            slot: slot,
                            resource: effectiveSubType == 2 ? "herocard" : "humancard",
                            subtype: effectiveSubType,
                            grade: effectiveGrade,
                            sid: existing.Sid > 0 ? existing.Sid : StableSid(6, sidSeed),
                            type: 6,
                            quantity: effectiveQuantity,
                            avatar: resolvedAvatar,
                            position: position,
                            subType: effectiveSubType,
                            display: resolvedDisplay,
                            designer: resolvedDesigner,
                            description: resolvedDescription);
                    }

                    if (Storages.TryGetValue(5, out var bagSlots) && bagSlots.TryGetValue(slot, out var bagCard))
                    {
                        _ = EquipAvatarCard(bagCard.Pid);
                    }
                    else if (existing.Type == 5)
                    {
                        _ = EquipAvatarCard(existing.Pid);
                    }

                    return true;
                }
            }

            if (!Storages.TryGetValue(5, out var cardsBag))
            {
                cardsBag = new Dictionary<int, InventoryItem>();
                Storages[5] = cardsBag;
            }

            if (!Storages.TryGetValue(6, out var cardsRoom))
            {
                cardsRoom = new Dictionary<int, InventoryItem>();
                Storages[6] = cardsRoom;
            }

            const int maxSlots = 36;
            var targetSlot = Enumerable.Range(1, maxSlots)
                .FirstOrDefault(i => !cardsBag.ContainsKey(i) && !cardsRoom.ContainsKey(i));
            if (targetSlot == 0)
            {
                errorKey = cardsRoom.Count >= maxSlots
                    ? "msgbox_avatar_model_limit"
                    : "msgbox_common_conditionkey_028";
                return false;
            }

            var sidSeedNew = $"saved:{Character.Occupation}:{avatarId}:{targetSlot}";
            AddItem(
                storageType: 5,
                slot: targetSlot,
                resource: "humancard",
                subtype: 1,
                grade: 1,
                sid: StableSid(5, sidSeedNew),
                type: 5,
                quantity: 1,
                avatar: resolvedAvatar,
                position: position,
                subType: 1,
                display: resolvedDisplay,
                designer: resolvedDesigner,
                description: resolvedDescription);

            AddItem(
                storageType: 6,
                slot: targetSlot,
                resource: "humancard",
                subtype: 1,
                grade: 1,
                sid: StableSid(6, sidSeedNew),
                type: 6,
                quantity: 1,
                avatar: resolvedAvatar,
                position: position,
                subType: 1,
                display: resolvedDisplay,
                designer: resolvedDesigner,
                description: resolvedDescription);

            if (cardsBag.TryGetValue(targetSlot, out var createdCard))
            {
                _ = EquipAvatarCard(createdCard.Pid);
            }

            return true;
        }

        public bool EquipInventoryItem(string? pid, int equipType)
        {
            if (!_ensuringStarterInventory)
            {
                EnsureStarterInventory();
            }

            var item = FindItemByPid(pid, 2);
            if (item is null)
            {
                return false;
            }

            EquippedItemsByType[equipType] = item.Pid;
            SyncEquipmentEquipFlags();
            return true;
        }

        public bool UnequipInventoryItem(int equipType)
        {
            if (!_ensuringStarterInventory)
            {
                EnsureStarterInventory();
            }

            if (!EquippedItemsByType.ContainsKey(equipType))
            {
                return false;
            }

            EquippedItemsByType.Remove(equipType);
            SyncEquipmentEquipFlags();

            return true;
        }

        private static int ResolveStorageTypeByItemType(int itemType)
        {
            return itemType switch
            {
                (int)ShopItemDatabase.ItemType.Equipment => 2,
                (int)ShopItemDatabase.ItemType.Item => 3,
                (int)ShopItemDatabase.ItemType.Gesture => 4,
                (int)ShopItemDatabase.ItemType.AvatarCard => 5,
                (int)ShopItemDatabase.ItemType.SkinCard => 6,
                _ => 3
            };
        }

        public bool TryGrantInventoryItem(
            int type,
            int subtype,
            int grade,
            int sid,
            string resource,
            int quantity,
            int unitType,
            int unit,
            int category = 0,
            object? avatar = null,
            int? position = null,
            string? display = null,
            string? designer = null,
            string? description = null)
        {
            EnsureStarterInventory();

            var storageType = ResolveStorageTypeByItemType(type);
            const int maxSlots = int.MaxValue;
            if (!Storages.TryGetValue(storageType, out var slots))
            {
                slots = new Dictionary<int, InventoryItem>();
                Storages[storageType] = slots;
            }

            var normalizedQuantity = Math.Max(1, quantity);
            var normalizedUnitType = unitType <= 0 ? 1 : unitType;
            var normalizedUnit = normalizedUnitType == 1
                ? Math.Max(1, unit <= 0 ? normalizedQuantity : unit)
                : Math.Max(1, unit);
            var effectiveSubType = subtype > 0 ? subtype : 0;
            var effectiveGrade = grade > 0 ? grade : 1;

            if (storageType == 3 && normalizedUnitType == 1)
            {
                var existing = slots
                    .OrderBy(x => x.Key)
                    .FirstOrDefault(x =>
                    {
                        var item = x.Value;
                        var itemSubType = item.SubType > 0 ? item.SubType : item.Subtype;
                        return itemSubType == effectiveSubType &&
                               item.Category == category &&
                               string.Equals(item.Resource, resource, StringComparison.OrdinalIgnoreCase);
                    });
                if (!existing.Equals(default(KeyValuePair<int, InventoryItem>)))
                {
                    var mergedCount = GetItemCountForConsume(existing.Value) + normalizedUnit;
                    slots[existing.Key] = existing.Value with
                    {
                        Quantity = mergedCount,
                        Unit = mergedCount,
                        UnitType = 1,
                        SubType = effectiveSubType,
                        Subtype = effectiveSubType,
                        Category = category
                    };
                    return true;
                }
            }

            var slot = Enumerable.Range(1, maxSlots).FirstOrDefault(i => !slots.ContainsKey(i));
            if (slot == 0)
            {
                return false;
            }

            AddItem(
                storageType: storageType,
                slot: slot,
                resource: resource,
                subtype: effectiveSubType,
                grade: effectiveGrade,
                sid: sid,
                type: type,
                quantity: normalizedQuantity,
                avatar: avatar,
                position: position,
                subType: effectiveSubType,
                display: display ?? string.Empty,
                designer: designer ?? string.Empty,
                description: description ?? string.Empty,
                unitType: normalizedUnitType,
                unit: normalizedUnit,
                category: category);
            return true;
        }

        public bool TryPurchaseToInventory(
            ShopItemDatabase.ShopItem shopItem,
            int quantity,
            ShopItemDatabase.ShopPrice? price = null)
        {
            EnsureStarterInventory();

            var storageType = ResolveStorageTypeByItemType((int)shopItem.Type);

            const int maxSlots = int.MaxValue;
            if (!Storages.TryGetValue(storageType, out var slots))
            {
                slots = new Dictionary<int, InventoryItem>();
                Storages[storageType] = slots;
            }

            var avatarId = GetAvatarIdFrom(Character.EquipAvatar) ?? "0";
            var avatar = shopItem.Type is ShopItemDatabase.ItemType.AvatarCard or ShopItemDatabase.ItemType.SkinCard
                ? EnsureAvatarHasAvatarId(shopItem.Avatar, avatarId) ?? shopItem.Avatar
                : shopItem.Avatar;
            var resource = string.IsNullOrWhiteSpace(shopItem.Resource) && avatar is not null
                ? (shopItem.Subtype == 2 ? "herocard" : "humancard")
                : shopItem.Resource;
            var instanceQuantity = Math.Max(1, quantity) * Math.Max(1, shopItem.Quantity);
            var instanceUnitType = price?.UnitType ?? 1;
            var instanceUnit = instanceUnitType == 1
                ? instanceQuantity
                : Math.Max(1, price?.Unit ?? instanceQuantity);
            var instanceSubType = shopItem.Type is
                ShopItemDatabase.ItemType.Equipment or
                ShopItemDatabase.ItemType.AvatarCard or
                ShopItemDatabase.ItemType.SkinCard
                    ? shopItem.Subtype
                    : 0;

            if (shopItem.Type == ShopItemDatabase.ItemType.Item &&
                storageType == 3 &&
                instanceUnitType == 1)
            {
                var existing = slots
                    .OrderBy(x => x.Key)
                    .FirstOrDefault(x =>
                    {
                        var item = x.Value;
                        return item.Type == (int)shopItem.Type &&
                               item.Sid == shopItem.Sid &&
                               string.Equals(item.Resource, resource, StringComparison.OrdinalIgnoreCase);
                    });
                if (!existing.Equals(default(KeyValuePair<int, InventoryItem>)))
                {
                    var mergedCount = GetItemCountForConsume(existing.Value) + instanceUnit;
                    slots[existing.Key] = existing.Value with
                    {
                        Quantity = mergedCount,
                        Unit = mergedCount,
                        UnitType = 1
                    };
                    return true;
                }
            }

            var slot = Enumerable.Range(1, maxSlots).FirstOrDefault(i => !slots.ContainsKey(i));
            if (slot == 0)
            {
                return false;
            }

            AddItem(
                storageType,
                slot,
                resource: resource,
                subtype: shopItem.Subtype,
                grade: shopItem.Grade,
                sid: shopItem.Sid,
                type: (int)shopItem.Type,
                quantity: instanceQuantity,
                avatar: avatar,
                position: avatar is null ? null : 1,
                subType: instanceSubType,
                display: shopItem.Display ?? string.Empty,
                designer: shopItem.Type is ShopItemDatabase.ItemType.AvatarCard or ShopItemDatabase.ItemType.SkinCard
                    ? "msgbox_common_conditionkey_146"
                    : string.Empty,
                description: shopItem.Description ?? string.Empty,
                unitType: instanceUnitType,
                unit: instanceUnit,
                remain: 0,
                isRenew: price?.IsRenew ?? false,
                attributes: CreateInventoryAttributeSnapshot(shopItem));
            return true;
        }

        private static IReadOnlyDictionary<string, double>? CreateInventoryAttributeSnapshot(ShopItemDatabase.ShopItem shopItem)
        {
            var attributes = new Dictionary<string, double>(StringComparer.OrdinalIgnoreCase);
            CopyTipNumberAttribute(shopItem.Tip, attributes, "coolDown");
            CopyTipNumberAttribute(shopItem.Tip, attributes, "explodeTime");
            CopyTipNumberAttribute(shopItem.Tip, attributes, "duration");
            CopyTipNumberAttribute(shopItem.Tip, attributes, "flyTime");
            CopyTipNumberAttribute(shopItem.Tip, attributes, "flightTime");
            return attributes.Count == 0 ? null : attributes;
        }

        private static void CopyTipNumberAttribute(
            object? tip,
            IDictionary<string, double> attributes,
            string key)
        {
            if (TryGetTipValue(tip, key, out var rawValue) &&
                TryReadFirstNumber(rawValue, out var number))
            {
                attributes[key] = number;
            }
        }

        private static bool TryGetTipValue(object? tip, string key, out object? value)
        {
            value = null;
            if (tip is IReadOnlyDictionary<string, object?> tipMap)
            {
                if (tipMap.TryGetValue(key, out value))
                {
                    return true;
                }

                foreach (var pair in tipMap)
                {
                    if (string.Equals(pair.Key, key, StringComparison.OrdinalIgnoreCase))
                    {
                        value = pair.Value;
                        return true;
                    }
                }

                return false;
            }

            if (tip is JsonElement element && element.ValueKind == JsonValueKind.Object)
            {
                foreach (var property in element.EnumerateObject())
                {
                    if (string.Equals(property.Name, key, StringComparison.OrdinalIgnoreCase))
                    {
                        value = property.Value;
                        return true;
                    }
                }
            }

            return false;
        }

        private static bool TryReadFirstNumber(object? rawValue, out double value)
        {
            switch (rawValue)
            {
                case null:
                    value = 0;
                    return false;
                case int intValue:
                    value = intValue;
                    return true;
                case long longValue:
                    value = longValue;
                    return true;
                case float floatValue:
                    value = floatValue;
                    return true;
                case double doubleValue:
                    value = doubleValue;
                    return true;
                case decimal decimalValue:
                    value = (double)decimalValue;
                    return true;
                case string stringValue:
                    return double.TryParse(stringValue, NumberStyles.Float, CultureInfo.InvariantCulture, out value);
                case JsonElement element:
                    return TryReadJsonNumber(element, out value);
                case System.Collections.IEnumerable sequence:
                    foreach (var item in sequence)
                    {
                        if (TryReadFirstNumber(item, out value))
                        {
                            return true;
                        }
                    }

                    value = 0;
                    return false;
                default:
                    value = 0;
                    return false;
            }
        }

        private static bool TryReadJsonNumber(JsonElement element, out double value)
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.Number:
                    return element.TryGetDouble(out value);
                case JsonValueKind.String:
                    return double.TryParse(element.GetString(), NumberStyles.Float, CultureInfo.InvariantCulture, out value);
                case JsonValueKind.Array:
                    foreach (var child in element.EnumerateArray())
                    {
                        if (TryReadJsonNumber(child, out value))
                        {
                            return true;
                        }
                    }

                    break;
            }

            value = 0;
            return false;
        }
    }
}
