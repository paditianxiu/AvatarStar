using System.Globalization;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;
using AvatarStar.Server.Persistence;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Threading;
using System.Text.Json;

namespace AvatarStar.Server.Game;

internal sealed class PlayerStore
{
    private readonly object _lock = new();
    private readonly Dictionary<int, PlayerState> _players = new();
    private readonly string _dbPath = AvatarStarDatabase.ResolveDatabasePath();
    private int _nextCharacterId = 1;
    private readonly AsyncLocal<long> _currentAccountId = new();

    private static readonly string[] AvatarPartKeys =
    [
        "skin",
        "eye",
        "mouth",
        "nose",
        "ear",
        "beard",
        "hair",
        "helmet",
        "underwear",
        "outerwear",
        "trousers",
        "glove",
        "shoes",
        "decal",
        "movable",
        "immobile",
        "immobileUp",
        "immobileDown"
    ];

    private static readonly string[] RequiredAvatarModelKeys =
    [
        "skin",
        "outerwear",
        "glove",
        "shoes"
    ];

    private long CurrentAccountId => _currentAccountId.Value > 0 ? _currentAccountId.Value : 1;

    public void SetCurrentAccount(long accountId)
    {
        _currentAccountId.Value = accountId <= 0 ? 1 : accountId;
    }

    public IReadOnlyList<CharacterInfo> ListCharacters()
    {
        lock (_lock)
        {
            using var db = new AvatarStarDbContext(_dbPath);
            EnsureDefaultCharacterNoLock(db);
            LoadAccountCharactersNoLock(db);
            return db.Characters
                .Where(x => x.AccountId == CurrentAccountId && x.DeletedAt == null)
                .OrderBy(x => x.Id)
                .Select(x => new CharacterInfo(
                    x.Id,
                    x.Name,
                    x.Level,
                    x.Occupation,
                    x.BattleForce,
                    EnsureCompleteEquipAvatar(DeserializeAvatar(x.EquipAvatarJson), x.Occupation, null),
                    x.MaxHealth))
                .ToList();
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

            using (var db = new AvatarStarDbContext(_dbPath))
            {
                var loaded = LoadCharacterNoLock(db, characterId);
                if (loaded is not null)
                {
                    _players[characterId] = loaded;
                    return loaded;
                }
            }

            var name = $"Player{characterId}";
            var created = new PlayerState(CharacterInfo.Create(characterId, name, occupation: 0));
            created.Character = created.Character with
            {
                EquipAvatar = EnsureCompleteEquipAvatar(created.Character.EquipAvatar, created.Character.Occupation)
            };
            _players[characterId] = created;
            SaveCharacterNoLock(created);
            return created;
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
        lock (_lock)
        {
            var id = _nextCharacterId++;
            using (var db = new AvatarStarDbContext(_dbPath))
            {
                var maxId = db.Characters.Any() ? db.Characters.Max(x => x.Id) : 0;
                id = Math.Max(id, maxId + 1);
                _nextCharacterId = id + 1;
            }
            var player = new PlayerState(CharacterInfo.Create(id, name, occupation));
            var resolvedAvatarId = string.IsNullOrWhiteSpace(avatarId)
                ? GetDefaultAvatarId(occupation, avatarConfig)
                : avatarId!;
            var resolvedEquipAvatar = EnsureCompleteEquipAvatar(
                equipAvatar ?? BuildDefaultEquipAvatar(occupation, resolvedAvatarId),
                occupation,
                resolvedAvatarId);
            player.Character = player.Character with { EquipAvatar = resolvedEquipAvatar };
            player.InitializeStarterInventory(
                occupation,
                avatarConfig,
                resolvedEquipAvatar,
                resolvedAvatarId,
                cardDisplay: starterCardDisplay,
                cardDesigner: starterCardDesigner);
            _players[id] = player;
            SaveCharacterNoLock(player);
            return player;
        }
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
        return BuildDefaultEquipAvatar(0, avatarId);
    }

    private static object BuildDefaultEquipAvatar(int occupation, string? avatarId = null)
    {
        if (TryLoadDefaultEquipAvatarFromLua(occupation, avatarId, out var luaAvatar))
        {
            return luaAvatar;
        }

        var resolvedAvatarId = string.IsNullOrWhiteSpace(avatarId)
            ? GetOccupationDefaultAvatarId(occupation)
            : avatarId!;

        return BuildEmptyEquipAvatar(resolvedAvatarId);
    }

    private static object BuildEmptyEquipAvatar(string avatarId)
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

    private static object EnsureCompleteEquipAvatar(object? avatar, int occupation, string? preferredAvatarId = null)
    {
        var resolvedAvatarId = FirstNonEmpty(
            preferredAvatarId,
            GetAvatarValue(avatar, "avatarId"),
            GetOccupationDefaultAvatarId(occupation));

        _ = TryLoadDefaultEquipAvatarFromLua(occupation, resolvedAvatarId, out var defaults);
        var defaultMap = defaults.Count > 0
            ? defaults
            : ToAvatarStringMap(BuildEmptyEquipAvatar(resolvedAvatarId));
        var result = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["avatarId"] = resolvedAvatarId
        };

        foreach (var key in AvatarPartKeys)
        {
            var current = GetAvatarValue(avatar, key);
            if (IsEmptyAvatarPart(current) &&
                defaultMap.TryGetValue(key, out var defaultValue) &&
                !string.IsNullOrWhiteSpace(defaultValue))
            {
                current = defaultValue;
            }

            result[key] = string.IsNullOrWhiteSpace(current) ? "{}" : current!;
        }

        return result;
    }

    private static bool TryLoadDefaultEquipAvatarFromLua(
        int occupation,
        string? avatarId,
        out Dictionary<string, string> avatar)
    {
        avatar = new Dictionary<string, string>(StringComparer.Ordinal);
        var payloadPath = GetSysAvatarPayloadCandidates(occupation).FirstOrDefault(File.Exists);
        if (payloadPath is null)
        {
            return false;
        }

        var payload = File.ReadAllText(payloadPath);
        foreach (Match match in Regex.Matches(
                     payload,
                     @"avatar\s*=\s*\{(?<body>.*?)^\s*\},",
                     RegexOptions.Singleline | RegexOptions.Multiline))
        {
            var candidate = ParseLuaAvatarBlock(match.Groups["body"].Value);
            if (candidate.Count == 0)
            {
                continue;
            }

            var candidateAvatarId = candidate.GetValueOrDefault("avatarId");
            if (string.IsNullOrWhiteSpace(avatarId) ||
                string.Equals(candidateAvatarId, avatarId, StringComparison.Ordinal))
            {
                avatar = candidate;
                return true;
            }

            if (avatar.Count == 0)
            {
                avatar = candidate;
            }
        }

        return avatar.Count > 0;
    }

    private static IEnumerable<string> GetSysAvatarPayloadCandidates(int occupation)
    {
        var jobId = Math.Clamp(occupation, 0, 3) + 1;
        var fileNamePrefix = jobId.ToString(CultureInfo.InvariantCulture) + "_";
        var directories = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Config", "SysAvatarPayloads"),
            Path.Combine(Directory.GetCurrentDirectory(), "Config", "SysAvatarPayloads"),
            Path.Combine(Directory.GetCurrentDirectory(), "src", "AvatarStar.Server.Game", "Config", "SysAvatarPayloads")
        };

        foreach (var directory in directories.Distinct(StringComparer.OrdinalIgnoreCase))
        {
            if (!Directory.Exists(directory))
            {
                continue;
            }

            foreach (var file in Directory.EnumerateFiles(directory, fileNamePrefix + "*.lua").OrderBy(x => x))
            {
                yield return file;
            }
        }
    }

    private static Dictionary<string, string> ParseLuaAvatarBlock(string body)
    {
        var result = new Dictionary<string, string>(StringComparer.Ordinal);
        foreach (Match field in Regex.Matches(
                     body,
                     @"(?m)^\s*(?<key>avatarId|skin|eye|mouth|nose|ear|beard|hair|helmet|underwear|outerwear|trousers|glove|shoes|decal|movable|immobile|immobileUp|immobileDown)\s*=\s*""(?<value>[^""]*)"""))
        {
            result[field.Groups["key"].Value] = field.Groups["value"].Value;
        }

        return result;
    }

    private static Dictionary<string, string> ToAvatarStringMap(object avatar)
    {
        var result = new Dictionary<string, string>(StringComparer.Ordinal);
        result["avatarId"] = GetAvatarValue(avatar, "avatarId") ?? "0";
        foreach (var key in AvatarPartKeys)
        {
            result[key] = GetAvatarValue(avatar, key) ?? "{}";
        }

        return result;
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value) &&
                !string.Equals(value, "0", StringComparison.Ordinal))
            {
                return value!;
            }
        }

        return "0";
    }

    private static bool IsEmptyAvatarPart(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ||
               string.Equals(value.Trim(), "{}", StringComparison.Ordinal);
    }

    private static bool HasIncompleteEquipAvatar(object? avatar)
    {
        if (avatar is null)
        {
            return true;
        }

        return RequiredAvatarModelKeys.Any(key => IsEmptyAvatarPart(GetAvatarValue(avatar, key)));
    }

    private static string? GetAvatarValue(object? avatar, string key)
    {
        if (avatar is null)
        {
            return null;
        }

        if (avatar is IReadOnlyDictionary<string, string> stringMap &&
            stringMap.TryGetValue(key, out var stringValue))
        {
            return stringValue;
        }

        if (avatar is IReadOnlyDictionary<string, object?> objectMap &&
            objectMap.TryGetValue(key, out var objectValue))
        {
            return Convert.ToString(objectValue, CultureInfo.InvariantCulture);
        }

        if (avatar is JsonElement jsonElement &&
            jsonElement.ValueKind == JsonValueKind.Object &&
            jsonElement.TryGetProperty(key, out var property))
        {
            return property.ValueKind == JsonValueKind.String
                ? property.GetString()
                : property.ToString();
        }

        var propertyInfo = avatar.GetType().GetProperty(key);
        return propertyInfo is null
            ? null
            : Convert.ToString(propertyInfo.GetValue(avatar), CultureInfo.InvariantCulture);
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
            _players.Remove(characterId);
            using var db = new AvatarStarDbContext(_dbPath);
            var entity = db.Characters.Find(characterId);
            if (entity is null)
            {
                return false;
            }

            entity.DeletedAt = DateTimeOffset.UtcNow.ToString("O");
            entity.UpdatedAt = DateTimeOffset.UtcNow.ToString("O");
            db.SaveChanges();
            return true;
        }
    }

    public void SaveActiveCharacter(int characterId)
    {
        lock (_lock)
        {
            if (_players.TryGetValue(characterId, out var player))
            {
                SaveCharacterNoLock(player);
            }
        }
    }

    public void SaveAll()
    {
        lock (_lock)
        {
            foreach (var player in _players.Values)
            {
                SaveCharacterNoLock(player);
            }
        }
    }

    private void LoadAccountCharactersNoLock(AvatarStarDbContext db)
    {
        foreach (var character in db.Characters.Where(x => x.AccountId == CurrentAccountId && x.DeletedAt == null).ToArray())
        {
            if (_players.ContainsKey(character.Id)) continue;
            if (LoadCharacterNoLock(db, character.Id) is { } player)
            {
                _players[character.Id] = player;
            }
        }
    }

    private void EnsureDefaultCharacterNoLock(AvatarStarDbContext db)
    {
        if (db.Characters.Any(x => x.AccountId == CurrentAccountId && x.DeletedAt == null))
        {
            return;
        }

        var id = db.Characters.Any() ? db.Characters.Max(x => x.Id) + 1 : 1;
        _nextCharacterId = Math.Max(_nextCharacterId, id + 1);
        var player = new PlayerState(CharacterInfo.Create(id, $"Player{id}", occupation: 0));
        player.EnsureStarterInventory();
        _players[id] = player;
        SaveCharacterNoLock(player);
    }

    private PlayerState? LoadCharacterNoLock(AvatarStarDbContext db, int characterId)
    {
        var entity = db.Characters.FirstOrDefault(x => x.Id == characterId && x.DeletedAt == null);
        if (entity is null) return null;

        var rawEquipAvatar = DeserializeAvatar(entity.EquipAvatarJson);
        var needsAvatarBackfill = HasIncompleteEquipAvatar(rawEquipAvatar);

        var player = new PlayerState(new CharacterInfo(
            entity.Id,
            entity.Name,
            entity.Level,
            entity.Occupation,
            entity.BattleForce,
            EnsureCompleteEquipAvatar(rawEquipAvatar, entity.Occupation),
            entity.MaxHealth))
        {
            Gp = entity.Gp,
            Mb = entity.Mb,
            Tb = entity.Tb,
            NextPid = entity.NextPid,
            EquippedAvatarPid = entity.EquippedAvatarPid
        };

        foreach (var item in db.InventoryItems.Where(x => x.CharacterId == characterId).OrderBy(x => x.StorageType).ThenBy(x => x.Slot))
        {
            if (!player.Storages.TryGetValue(item.StorageType, out var slots))
            {
                slots = new Dictionary<int, InventoryItem>();
                player.Storages[item.StorageType] = slots;
            }

            slots[item.Slot] = new InventoryItem(
                item.Pid,
                item.Slot,
                item.Resource,
                item.Subtype,
                item.SubType,
                item.Grade,
                item.Quantity,
                item.UnitType,
                item.Unit,
                item.Remain,
                item.IsRenew != 0,
                item.Category,
                item.IsBind,
                item.IsEquip,
                item.Sid,
                item.Type,
                DeserializeNullableObject(item.AvatarJson),
                item.Position,
                item.Display,
                item.Designer,
                item.Description,
                DeserializeAttributes(item.AttributesJson));
        }

        foreach (var equip in db.EquippedItems.Where(x => x.CharacterId == characterId))
        {
            player.EquippedItemsByType[equip.EquipType] = equip.Pid;
        }

        foreach (var skill in db.CharacterSkillLevels.Where(x => x.CharacterId == characterId))
        {
            player.SkillLevels[skill.SkillId] = skill.Level;
        }

        foreach (var point in db.CharacterBoxPoints.Where(x => x.CharacterId == characterId))
        {
            player.BoxPoints[point.Category] = point.Points;
        }

        foreach (var claim in db.CharacterBoxPointClaims.Where(x => x.CharacterId == characterId))
        {
            if (!player.BoxPointClaimCounts.TryGetValue(claim.Category, out var byThreshold))
            {
                byThreshold = new Dictionary<int, int>();
                player.BoxPointClaimCounts[claim.Category] = byThreshold;
            }
            byThreshold[claim.Threshold] = claim.ClaimCount;
        }

        var monthKey = DateTime.Now.ToString("yyyy-MM", CultureInfo.InvariantCulture);
        player.SetCheckinMonthForPersistence(monthKey);
        foreach (var day in db.CharacterCheckinDays.Where(x => x.CharacterId == characterId && x.MonthKey == monthKey))
        {
            player.CheckinDays.Add(day.Day);
        }
        foreach (var claim in db.CharacterCheckinClaims.Where(x => x.CharacterId == characterId && x.MonthKey == monthKey))
        {
            player.CheckinClaimedRewardIds.Add(claim.CheckinId);
        }

        foreach (var purchase in db.CharacterShopPurchases.Where(x => x.CharacterId == characterId))
        {
            player.ShopPurchasedCounts[(purchase.Sid, purchase.PriceId)] = purchase.PurchaseCount;
        }

        var onlineRewardState = db.CharacterOnlineRewardStates.Find(characterId);
        if (onlineRewardState is not null)
        {
            player.LoadOnlineRewardStateFromPersistence(
                onlineRewardState.DayKey,
                onlineRewardState.ClaimedLevel,
                onlineRewardState.StageStartedUtc);
        }

        player.LoadHotKeySlotsFromPersistence(db.HotkeySlots.Where(x => x.CharacterId == characterId).ToArray());
        needsAvatarBackfill = needsAvatarBackfill || player.NeedsAvatarCardBackfill();
        if (needsAvatarBackfill)
        {
            player.EnsureStarterInventory();
            SaveCharacterNoLock(player);
        }

        return player;
    }

    private void SaveCharacterNoLock(PlayerState player)
    {
        using var db = new AvatarStarDbContext(_dbPath);
        using var tx = db.Database.BeginTransaction();
        var now = DateTimeOffset.UtcNow.ToString("O");
        var character = player.Character;
        var entity = db.Characters.Find(character.Id);
        if (entity is null)
        {
            entity = new CharacterEntity
            {
                Id = character.Id,
                AccountId = CurrentAccountId,
                CreatedAt = now
            };
            db.Characters.Add(entity);
        }

        if (entity.AccountId <= 0)
        {
            entity.AccountId = CurrentAccountId;
        }
        entity.Name = character.Name;
        entity.Level = character.Level;
        entity.Occupation = character.Occupation;
        entity.BattleForce = character.BattleForce;
        entity.MaxHealth = character.MaxHealth;
        entity.Gp = player.Gp;
        entity.Mb = player.Mb;
        entity.Tb = player.Tb;
        entity.NextPid = player.NextPid;
        entity.EquipAvatarJson = SerializeJson(character.EquipAvatar);
        entity.EquippedAvatarPid = player.EquippedAvatarPid;
        entity.UpdatedAt = now;
        entity.DeletedAt = null;

        db.InventoryItems.RemoveRange(db.InventoryItems.Where(x => x.CharacterId == character.Id));
        foreach (var storage in player.Storages)
        {
            foreach (var pair in storage.Value)
            {
                var item = pair.Value.Slot == pair.Key ? pair.Value : pair.Value with { Slot = pair.Key };
                db.InventoryItems.Add(new InventoryItemEntity
                {
                    CharacterId = character.Id,
                    Pid = item.Pid,
                    StorageType = storage.Key,
                    Slot = item.Slot,
                    Sid = item.Sid,
                    Type = item.Type,
                    Subtype = item.Subtype,
                    SubType = item.SubType,
                    Resource = item.Resource,
                    Display = item.Display,
                    Designer = item.Designer,
                    Description = item.Description,
                    Grade = item.Grade,
                    Quantity = item.Quantity,
                    UnitType = item.UnitType,
                    Unit = item.Unit,
                    Remain = item.Remain,
                    IsRenew = item.IsRenew ? 1 : 0,
                    Category = item.Category,
                    IsBind = item.IsBind,
                    IsEquip = item.IsEquip,
                    AvatarJson = item.Avatar is null ? null : SerializeJson(item.Avatar),
                    Position = item.Position,
                    AttributesJson = item.Attributes is null ? null : SerializeJson(item.Attributes),
                    CreatedAt = now,
                    UpdatedAt = now
                });
            }
        }

        db.EquippedItems.RemoveRange(db.EquippedItems.Where(x => x.CharacterId == character.Id));
        foreach (var equip in player.EquippedItemsByType)
        {
            db.EquippedItems.Add(new EquippedItemEntity { CharacterId = character.Id, EquipType = equip.Key, Pid = equip.Value });
        }

        db.HotkeySlots.RemoveRange(db.HotkeySlots.Where(x => x.CharacterId == character.Id));
        foreach (var slot in player.GetHotKeySlotEntitiesForPersistence())
        {
            slot.CharacterId = character.Id;
            db.HotkeySlots.Add(slot);
        }

        db.CharacterSkillLevels.RemoveRange(db.CharacterSkillLevels.Where(x => x.CharacterId == character.Id));
        foreach (var skill in player.SkillLevels.Where(x => x.Value > 0))
        {
            db.CharacterSkillLevels.Add(new CharacterSkillLevelEntity { CharacterId = character.Id, SkillId = skill.Key, Level = skill.Value });
        }

        db.CharacterBoxPoints.RemoveRange(db.CharacterBoxPoints.Where(x => x.CharacterId == character.Id));
        foreach (var point in player.BoxPoints)
        {
            db.CharacterBoxPoints.Add(new CharacterBoxPointEntity { CharacterId = character.Id, Category = point.Key, Points = point.Value });
        }

        db.CharacterBoxPointClaims.RemoveRange(db.CharacterBoxPointClaims.Where(x => x.CharacterId == character.Id));
        foreach (var (category, byThreshold) in player.BoxPointClaimCounts)
        {
            foreach (var (threshold, count) in byThreshold)
            {
                db.CharacterBoxPointClaims.Add(new CharacterBoxPointClaimEntity { CharacterId = character.Id, Category = category, Threshold = threshold, ClaimCount = count });
            }
        }

        var monthKey = DateTime.Now.ToString("yyyy-MM", CultureInfo.InvariantCulture);
        db.CharacterCheckinDays.RemoveRange(db.CharacterCheckinDays.Where(x => x.CharacterId == character.Id && x.MonthKey == monthKey));
        foreach (var day in player.CheckinDays)
        {
            db.CharacterCheckinDays.Add(new CharacterCheckinDayEntity { CharacterId = character.Id, MonthKey = monthKey, Day = day, CheckedAt = now });
        }

        db.CharacterCheckinClaims.RemoveRange(db.CharacterCheckinClaims.Where(x => x.CharacterId == character.Id && x.MonthKey == monthKey));
        foreach (var claim in player.CheckinClaimedRewardIds)
        {
            db.CharacterCheckinClaims.Add(new CharacterCheckinClaimEntity { CharacterId = character.Id, MonthKey = monthKey, CheckinId = claim, ClaimedAt = now });
        }

        db.CharacterShopPurchases.RemoveRange(db.CharacterShopPurchases.Where(x => x.CharacterId == character.Id));
        foreach (var purchase in player.ShopPurchasedCounts)
        {
            db.CharacterShopPurchases.Add(new CharacterShopPurchaseEntity
            {
                CharacterId = character.Id,
                Sid = purchase.Key.Sid,
                PriceId = purchase.Key.PriceId,
                PurchaseCount = purchase.Value,
                UpdatedAt = now
            });
        }

        var (onlineDayKey, onlineClaimedLevel, onlineStageStartedUtc) = player.GetOnlineRewardStateForPersistence();
        if (!string.IsNullOrWhiteSpace(onlineDayKey))
        {
            var onlineEntity = db.CharacterOnlineRewardStates.Find(character.Id);
            if (onlineEntity is null)
            {
                onlineEntity = new CharacterOnlineRewardStateEntity { CharacterId = character.Id };
                db.CharacterOnlineRewardStates.Add(onlineEntity);
            }

            onlineEntity.DayKey = onlineDayKey;
            onlineEntity.ClaimedLevel = onlineClaimedLevel;
            onlineEntity.StageStartedUtc = onlineStageStartedUtc;
            onlineEntity.UpdatedAt = now;
        }

        db.SaveChanges();
        tx.Commit();
    }

    private static string SerializeJson(object value)
    {
        return JsonSerializer.Serialize(value);
    }

    private static object DeserializeAvatar(string json)
    {
        return DeserializeNullableObject(json) ?? BuildDefaultEquipAvatar("0");
    }

    private static object? DeserializeNullableObject(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return null;
        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, object>>(json);
        }
        catch
        {
            return null;
        }
    }

    private static IReadOnlyDictionary<string, double>? DeserializeAttributes(string? json)
    {
        if (string.IsNullOrWhiteSpace(json)) return null;
        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, double>>(json);
        }
        catch
        {
            return null;
        }
    }

    public sealed class PlayerState
    {
        private sealed record HotKeySlot(
            int Slot,
            int Type,
            string ItemId,
            string Resource,
            string Display,
            int Grade,
            int Quantity,
            int UnitType,
            int Unit,
            int Subtype,
            int Sid,
            int Level);

        private sealed record SkillRuntimeDefinition(
            int Id,
            int Occupation,
            string Resource,
            string DisplayBase,
            bool IsActive,
            float CoolDown,
            float Range);

        private static readonly SkillRuntimeDefinition[] GameSkillDefinitions =
        [
            new(0, 0, "cure", "id_datalist_Battlefield_Heal_01", true, 20f, 8f),
            new(3, 0, "shock", "id_datalist_Shockwave_01", true, 20f, 8f),
            new(6, 0, "vitals", "id_datalist_Achilles_Heel_01", false, 0f, 0f),
            new(9, 0, "rain", "id_datalist_Arrow_Shower_01", true, 20f, 8f),
            new(14, 0, "energy", "id_datalist_Healing_Beacon_01", true, 20f, 8f),
            new(76, 0, "feud", "tips_buff_langwangshichou", false, 0f, 0f),

            new(1, 1, "shield", "id_datalist_Shield_01", true, 20f, 8f),
            new(4, 1, "gallop", "id_datalist_Haste_01", true, 20f, 8f),
            new(7, 1, "tenacity", "id_datalist_Perseverance_01", false, 0f, 0f),
            new(10, 1, "heavy", "id_datalist_Blitzkrieg_01", false, 0f, 0f),
            new(12, 1, "transfer", "id_datalist_Damage_Converter_01", false, 0f, 0f),

            new(2, 2, "latent", "id_datalist_Stealth_01", true, 20f, 8f),
            new(5, 2, "piercing", "id_datalist_Fatal_Shot_01", false, 0f, 0f),
            new(8, 2, "poison", "id_datalist_Poison_Pierce_01", false, 0f, 0f),
            new(11, 2, "spurt", "id_datalist_Deadly_Sprint_01", true, 20f, 8f),
            new(13, 2, "snare", "id_datalist_Trap_01", true, 20f, 8f),

            new(38, 3, "conduction", "id_datalist_shengmingchuandao_01", true, 20f, 8f),
            new(39, 3, "suckblood", "id_datalist_shengmingchouqu_01", false, 0f, 0f),
            new(40, 3, "plague", "id_datalist_wenyichuanbo_01", false, 0f, 0f),
            new(41, 3, "gasbomb", "id_datalist_duqidan_01", false, 0f, 0f),
            new(42, 3, "overreaction", "id_datalist_guojifanying_01", true, 20f, 8f)
        ];

        private static readonly object GameSkillDefinitionCacheLock = new();
        private static SkillRuntimeDefinition[]? DbGameSkillDefinitions;
        private static DateTime DbGameSkillDefinitionsLoadedUtc;

        public sealed record GameLoadoutItem(
            byte Slot,
            byte ItemType,
            long ItemId,
            string Resource,
            byte Grade,
            string DisplayName,
            byte Subtype);

        public sealed record GameSkillSlotItem(
            byte Slot,
            byte SkillType,
            string Resource,
            string DisplayName,
            bool Initiative,
            float CoolDown,
            float Range);

        public sealed record GameIndependentTrinketItem(
            int Slot,
            string Resource,
            InventoryItem? BackpackItem);

        public CharacterInfo Character { get; set; }
        public int Gp { get; set; } = 100000;
        public int Mb { get; set; } = 0;
        public int Tb { get; set; } = 0;
        public Dictionary<int, int> BoxPoints { get; } = new();
        public Dictionary<int, Dictionary<int, int>> BoxPointClaimCounts { get; } = new();
        public Dictionary<int, int> SkillLevels { get; } = new();
        public string CheckinMonthKey { get; private set; } = string.Empty;
        public HashSet<int> CheckinDays { get; } = new();
        public HashSet<int> CheckinClaimedRewardIds { get; } = new();
        public string OnlineRewardDayKey { get; private set; } = string.Empty;
        public int OnlineRewardClaimedLevel { get; private set; }
        private DateTime OnlineRewardStageStartedUtc { get; set; }

        // (sid, priceId) -> purchased count (用于限购显示/校验)
        public Dictionary<(int Sid, int PriceId), int> ShopPurchasedCounts { get; } = new();

        // storageType(t) -> slot -> item
        public Dictionary<int, Dictionary<int, InventoryItem>> Storages { get; } = new();
        public Dictionary<int, string> EquippedItemsByType { get; } = new();
        public string? EquippedAvatarPid { get; set; }
        private readonly Dictionary<int, HotKeySlot> _hotKeySlots = new();
        private const int HotKeySlotCount = 12;
        private const int MaxWeaponHotKeyCount = 3;
        private const int DefaultStoragePageCount = 100;
        private const int DefaultStoragePageSize = 24;
        private const int AvatarCardStoragePageSize = 10;
        public int NextPid { get; set; } = 1;
        private bool _ensuringStarterInventory;

        public PlayerState(CharacterInfo character)
        {
            Character = character;
        }

        internal void SetCheckinMonthForPersistence(string monthKey)
        {
            CheckinMonthKey = monthKey;
        }

        internal void LoadOnlineRewardStateFromPersistence(string? dayKey, int claimedLevel, string? stageStartedUtc)
        {
            OnlineRewardDayKey = dayKey ?? string.Empty;
            OnlineRewardClaimedLevel = Math.Max(0, claimedLevel);
            OnlineRewardStageStartedUtc = DateTime.TryParse(
                stageStartedUtc,
                CultureInfo.InvariantCulture,
                DateTimeStyles.RoundtripKind,
                out var parsed)
                ? parsed.ToUniversalTime()
                : default;
        }

        internal (string DayKey, int ClaimedLevel, string StageStartedUtc) GetOnlineRewardStateForPersistence()
        {
            return (
                OnlineRewardDayKey,
                OnlineRewardClaimedLevel,
                OnlineRewardStageStartedUtc == default
                    ? string.Empty
                    : OnlineRewardStageStartedUtc.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture));
        }

        internal void LoadHotKeySlotsFromPersistence(IEnumerable<HotkeySlotEntity> slots)
        {
            _hotKeySlots.Clear();
            foreach (var slot in slots)
            {
                _hotKeySlots[slot.Slot] = new HotKeySlot(
                    Slot: slot.Slot,
                    Type: slot.EntryType,
                    ItemId: slot.ItemId,
                    Resource: slot.Resource,
                    Display: slot.Display,
                    Grade: slot.Grade,
                    Quantity: slot.Quantity,
                    UnitType: slot.UnitType,
                    Unit: slot.Unit,
                    Subtype: slot.Subtype,
                    Sid: slot.Sid,
                    Level: slot.Level);
            }
        }

        internal IReadOnlyList<HotkeySlotEntity> GetHotKeySlotEntitiesForPersistence()
        {
            NormalizeHotKeySlots();
            return _hotKeySlots.Values
                .OrderBy(x => x.Slot)
                .Select(x => new HotkeySlotEntity
                {
                    Slot = x.Slot,
                    EntryType = x.Type,
                    ItemId = x.ItemId,
                    Resource = x.Resource,
                    Display = x.Display,
                    Grade = x.Grade,
                    Quantity = x.Quantity,
                    UnitType = x.UnitType,
                    Unit = x.Unit,
                    Subtype = x.Subtype,
                    Sid = x.Sid,
                    Level = x.Level
                })
                .ToArray();
        }

        public int GetSkillLevel(int skillId)
        {
            return SkillLevels.TryGetValue(skillId, out var level)
                ? Math.Clamp(level, 0, 5)
                : 0;
        }

        public int GetUsedSkillPoints()
        {
            return SkillLevels.Values.Sum(level => Math.Clamp(level, 0, 5));
        }

        public int GetLeftSkillPoints(int totalPoints = 15)
        {
            return Math.Max(0, totalPoints - GetUsedSkillPoints());
        }

        public bool TryAdjustSkills(
            string? adjustSkills,
            IReadOnlySet<int> validSkillIds,
            out string? errorKey)
        {
            errorKey = null;

            if (string.IsNullOrWhiteSpace(adjustSkills))
            {
                return true;
            }

            var nextLevels = new Dictionary<int, int>(SkillLevels);
            foreach (var entry in adjustSkills.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                var parts = entry.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                if (parts.Length != 2 ||
                    !int.TryParse(parts[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out var skillId) ||
                    !int.TryParse(parts[1], NumberStyles.Integer, CultureInfo.InvariantCulture, out var delta) ||
                    delta <= 0)
                {
                    errorKey = "id_abilities_bufuhetiaojian";
                    return false;
                }

                if (!validSkillIds.Contains(skillId))
                {
                    errorKey = "id_abilities_bufuhetiaojian";
                    return false;
                }

                var currentLevel = nextLevels.TryGetValue(skillId, out var existing)
                    ? Math.Clamp(existing, 0, 5)
                    : 0;
                var nextLevel = currentLevel + delta;
                if (nextLevel > 5)
                {
                    errorKey = "id_abilities_levelmax";
                    return false;
                }

                nextLevels[skillId] = nextLevel;
            }

            var usedPoints = nextLevels.Values.Sum(level => Math.Clamp(level, 0, 5));
            if (usedPoints > 15)
            {
                errorKey = "id_abilities_skillpointnotenough";
                return false;
            }

            SkillLevels.Clear();
            foreach (var (skillId, level) in nextLevels)
            {
                if (level > 0)
                {
                    SkillLevels[skillId] = Math.Clamp(level, 0, 5);
                }
            }

            return true;
        }

        public void ResetSkills()
        {
            SkillLevels.Clear();
            foreach (var slot in _hotKeySlots
                         .Where(pair => pair.Value.Type == 1)
                         .Select(pair => pair.Key)
                         .ToArray())
            {
                _hotKeySlots.Remove(slot);
            }
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

        public void EnsureOnlineRewardDay(DateTime now, DateTime utcNow)
        {
            var dayKey = now.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            if (string.Equals(OnlineRewardDayKey, dayKey, StringComparison.Ordinal))
            {
                if (OnlineRewardStageStartedUtc == default || OnlineRewardStageStartedUtc > utcNow)
                {
                    OnlineRewardStageStartedUtc = utcNow;
                }

                return;
            }

            OnlineRewardDayKey = dayKey;
            OnlineRewardClaimedLevel = 0;
            OnlineRewardStageStartedUtc = utcNow;
        }

        public int GetOnlineRewardStageElapsedSeconds(DateTime now, DateTime utcNow)
        {
            EnsureOnlineRewardDay(now, utcNow);
            var elapsed = utcNow - OnlineRewardStageStartedUtc;
            return Math.Max(0, (int)Math.Floor(elapsed.TotalSeconds));
        }

        public bool TryClaimOnlineRewardLevel(DateTime now, DateTime utcNow, int level)
        {
            EnsureOnlineRewardDay(now, utcNow);
            if (level <= 0 || level != OnlineRewardClaimedLevel + 1)
            {
                return false;
            }

            OnlineRewardClaimedLevel = level;
            OnlineRewardStageStartedUtc = utcNow;
            return true;
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

        public bool NeedsAvatarCardBackfill()
        {
            if (!Storages.TryGetValue(6, out var roomAvatarSlots) || roomAvatarSlots.Count == 0)
            {
                return true;
            }

            foreach (var storageType in new[] { 5, 6 })
            {
                if (!Storages.TryGetValue(storageType, out var slots))
                {
                    continue;
                }

                foreach (var item in slots.Values)
                {
                    if (item.Avatar is null || PlayerStore.HasIncompleteEquipAvatar(item.Avatar))
                    {
                        return true;
                    }
                }
            }

            return false;
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
                Character = Character with
                {
                    EquipAvatar = PlayerStore.EnsureCompleteEquipAvatar(
                        Character.EquipAvatar,
                        Character.Occupation)
                };

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
                NormalizeAvatarCardStorage();
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
            var completeEquipAvatar = PlayerStore.EnsureCompleteEquipAvatar(
                equipAvatar ?? Character.EquipAvatar,
                occupation,
                resolvedAvatarId);
            var resolvedEquipAvatar = EnsureAvatarHasAvatarId(completeEquipAvatar, resolvedAvatarId) ?? completeEquipAvatar;
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

            var slot = FindFirstEmptyStorageSlot(6, slots);
            if (slot == 0)
            {
                return;
            }

            var avatarId = GetAvatarIdFrom(Character.EquipAvatar) ?? "0";
            var completeAvatar = PlayerStore.EnsureCompleteEquipAvatar(
                Character.EquipAvatar,
                Character.Occupation,
                avatarId);
            var equipAvatar = EnsureAvatarHasAvatarId(completeAvatar, avatarId) ?? completeAvatar;

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

        private void NormalizeAvatarCardStorage()
        {
            foreach (var storageType in new[] { 5, 6 })
            {
                if (!Storages.TryGetValue(storageType, out var slots))
                {
                    continue;
                }

                foreach (var pair in slots.ToArray())
                {
                    var item = pair.Value;
                    var subType = item.SubType > 0 ? item.SubType : item.Subtype;
                    var effectiveSubType = subType > 0 ? subType : 1;
                    var normalizedAvatar = NormalizeAvatarForCharacter(item.Avatar);

                    slots[pair.Key] = item with
                    {
                        Avatar = normalizedAvatar,
                        Position = item.Position ?? 1,
                        Resource = string.IsNullOrWhiteSpace(item.Resource)
                            ? (effectiveSubType == 2 ? "herocard" : "humancard")
                            : item.Resource,
                        Subtype = effectiveSubType,
                        SubType = effectiveSubType,
                        Type = item.Type == 0 ? storageType : item.Type
                    };
                }
            }
        }

        private object NormalizeAvatarForCharacter(object? avatar, string? preferredAvatarId = null)
        {
            var resolvedAvatarId = GetAvatarIdFrom(avatar);
            if (string.IsNullOrWhiteSpace(resolvedAvatarId) ||
                string.Equals(resolvedAvatarId, "0", StringComparison.Ordinal))
            {
                resolvedAvatarId = preferredAvatarId;
            }

            if (string.IsNullOrWhiteSpace(resolvedAvatarId) ||
                string.Equals(resolvedAvatarId, "0", StringComparison.Ordinal))
            {
                resolvedAvatarId = GetAvatarIdFrom(Character.EquipAvatar);
            }

            if (string.IsNullOrWhiteSpace(resolvedAvatarId) ||
                string.Equals(resolvedAvatarId, "0", StringComparison.Ordinal))
            {
                resolvedAvatarId = PlayerStore.GetOccupationDefaultAvatarId(Character.Occupation);
            }

            var completeAvatar = PlayerStore.EnsureCompleteEquipAvatar(
                avatar ?? Character.EquipAvatar,
                Character.Occupation,
                resolvedAvatarId);
            return EnsureAvatarHasAvatarId(completeAvatar, resolvedAvatarId) ?? completeAvatar;
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

        private static object? EnsureAvatarHasAvatarId(object? avatar, string? avatarId)
        {
            if (avatar is null || string.IsNullOrWhiteSpace(avatarId))
            {
                return avatar;
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

            if (avatar is JsonElement el && el.ValueKind == JsonValueKind.Object)
            {
                var dict = new Dictionary<string, object>(StringComparer.OrdinalIgnoreCase);
                foreach (var prop in el.EnumerateObject())
                {
                    dict[prop.Name] = prop.Value.ValueKind == JsonValueKind.String
                        ? (object)(prop.Value.GetString() ?? string.Empty)
                        : prop.Value.GetRawText();
                }
                dict["avatarId"] = avatarId!;
                return dict;
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

        private static int GetStoragePageSize(int storageType)
        {
            return storageType == 5 ? AvatarCardStoragePageSize : DefaultStoragePageSize;
        }

        private static int GetStorageCapacity(int storageType)
        {
            return DefaultStoragePageCount * GetStoragePageSize(storageType);
        }

        private static int ToAbsoluteStorageSlot(int storageType, int page, int pageSlot)
        {
            var pageSize = GetStoragePageSize(storageType);
            var safePage = page <= 0 ? 1 : page;
            return ((safePage - 1) * pageSize) + pageSlot;
        }

        private static int FindFirstEmptyStorageSlot(int storageType, IReadOnlyDictionary<int, InventoryItem> slots)
        {
            var capacity = GetStorageCapacity(storageType);
            for (var i = 1; i <= capacity; i++)
            {
                if (!slots.ContainsKey(i))
                {
                    return i;
                }
            }

            return 0;
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
                var targetSlot = FindFirstEmptyStorageSlot(5, bagSlots);
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
            var invalidSlots = _hotKeySlots.Keys.Where(x => x <= 0 || x > HotKeySlotCount).ToArray();
            foreach (var invalidSlot in invalidSlots)
            {
                _hotKeySlots.Remove(invalidSlot);
            }

            var seenItemIds = new HashSet<string>(StringComparer.Ordinal);
            foreach (var pair in _hotKeySlots.OrderBy(x => x.Key).ToArray())
            {
                if (string.IsNullOrWhiteSpace(pair.Value.ItemId) || !seenItemIds.Add(pair.Value.ItemId))
                {
                    _hotKeySlots.Remove(pair.Key);
                }
            }

            var weaponSlots = _hotKeySlots.Values
                .Where(x => x.Type == 2)
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

        private void EnsureDefaultWeaponHotKeySlots()
        {
            if (_hotKeySlots.Values.Any(slot =>
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
                    Display: item.Display,
                    Grade: item.Grade,
                    Quantity: item.Quantity,
                    UnitType: item.UnitType,
                    Unit: item.Unit,
                    Subtype: item.Subtype,
                    Sid: item.Sid,
                    Level: 0);
                slot++;
            }
        }

        private int CountWeaponHotKeys()
        {
            return _hotKeySlots.Values.Count(x => x.Type == 2);
        }

        private void RemoveHotKeyReferencesToItem(string itemId, int exceptSlot)
        {
            var duplicateSlots = _hotKeySlots
                .Where(x => x.Key != exceptSlot && string.Equals(x.Value.ItemId, itemId, StringComparison.Ordinal))
                .Select(x => x.Key)
                .ToArray();

            foreach (var duplicateSlot in duplicateSlots)
            {
                _hotKeySlots.Remove(duplicateSlot);
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

            foreach (var hotKey in _hotKeySlots.Values)
            {
                if (hotKey.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                    !string.IsNullOrWhiteSpace(hotKey.ItemId))
                {
                    equippedPids.Add(hotKey.ItemId);
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
            EnsureStarterInventory();
            NormalizeHotKeySlots();
            EnsureDefaultWeaponHotKeySlots();
            SyncEquipmentEquipFlags();

            totalSlots = totalSlots <= 0 ? HotKeySlotCount : Math.Clamp(totalSlots, 1, HotKeySlotCount);
            var result = new object[totalSlots];
            for (var i = 1; i <= totalSlots; i++)
            {
                if (_hotKeySlots.TryGetValue(i, out var entry))
                {
                    result[i - 1] = new
                    {
                        slot = entry.Slot,
                        type = entry.Type,
                        itemid = entry.ItemId,
                        id = entry.Sid,
                        display = entry.Display,
                        resource = entry.Resource,
                        grade = entry.Grade,
                        quantity = entry.Quantity,
                        unitType = entry.UnitType,
                        unit = entry.Unit,
                        subtype = entry.Subtype,
                        sid = entry.Sid,
                        level = entry.Level
                    };
                }
                else
                {
                    result[i - 1] = new
                    {
                        slot = i,
                        type = 0,
                        itemid = "0",
                        id = 0,
                        display = string.Empty,
                        resource = string.Empty,
                        quantity = 0
                    };
                }
            }

            return result;
        }

        public bool TrySetHotKeySlot(int slot, string? pid, out string? errorKey)
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
                var currentIsWeapon = _hotKeySlots.TryGetValue(slot, out var currentSlot) && currentSlot.Type == 2;
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
                Display: item.Display,
                Grade: item.Grade,
                Quantity: item.Quantity,
                UnitType: item.UnitType,
                Unit: item.Unit,
                Subtype: item.Subtype,
                Sid: item.Sid,
                Level: 0);
            SyncEquipmentEquipFlags();
            return true;
        }

        public bool TrySetSkillHotKeySlot(
            int slot,
            int skillId,
            string resource,
            string display,
            bool isActive,
            out string? errorKey)
        {
            EnsureStarterInventory();
            NormalizeHotKeySlots();
            errorKey = null;

            if (slot <= 0 || slot > HotKeySlotCount)
            {
                errorKey = "msgbox_common_num_1306";
                return false;
            }

            if (skillId < 0 || string.IsNullOrWhiteSpace(resource) || string.IsNullOrWhiteSpace(display))
            {
                errorKey = "id_abilities_bufuhetiaojian";
                return false;
            }

            var level = GetSkillLevel(skillId);
            if (level <= 0)
            {
                errorKey = "id_abilities_skillpointnotenough";
                return false;
            }

            if (!isActive)
            {
                errorKey = "id_abilities_bufuhetiaojian";
                return false;
            }

            foreach (var existingSlot in _hotKeySlots
                         .Where(pair => pair.Value.Type == 1 && pair.Value.Sid == skillId)
                         .Select(pair => pair.Key)
                         .ToArray())
            {
                _hotKeySlots.Remove(existingSlot);
            }

            _hotKeySlots[slot] = new HotKeySlot(
                Slot: slot,
                Type: 1,
                ItemId: BuildSkillHotKeyItemId(skillId, level),
                Resource: resource,
                Display: display,
                Grade: 1,
                Quantity: 1,
                UnitType: 1,
                Unit: 1,
                Subtype: 1,
                Sid: skillId,
                Level: level);
            return true;
        }

        public bool TrySetHotKeySlot(int slot, string? pid)
        {
            return TrySetHotKeySlot(slot, pid, out _);
        }

        public bool TryClearHotKeySlot(int slot)
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

        public bool TrySwapHotKeySlots(int fromSlot, int toSlot)
        {
            EnsureStarterInventory();
            NormalizeHotKeySlots();

            if (fromSlot <= 0 || toSlot <= 0 || fromSlot > HotKeySlotCount || toSlot > HotKeySlotCount || fromSlot == toSlot)
            {
                return false;
            }

            var fromExists = _hotKeySlots.TryGetValue(fromSlot, out var from);
            var toExists = _hotKeySlots.TryGetValue(toSlot, out var to);

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

        public bool TryMoveStorageItem(
            int storageType,
            int fromPage,
            int fromSlot,
            int toPage,
            int toSlot,
            string? pid,
            out string? errorKey)
        {
            EnsureStarterInventory();
            errorKey = null;

            if (storageType <= 0 || fromSlot <= 0 || toSlot <= 0)
            {
                errorKey = "msgbox_common_num_1306";
                return false;
            }

            var fromAbsoluteSlot = ToAbsoluteStorageSlot(storageType, fromPage, fromSlot);
            var toAbsoluteSlot = ToAbsoluteStorageSlot(storageType, toPage, toSlot);
            if (fromAbsoluteSlot == toAbsoluteSlot)
            {
                return true;
            }

            var capacity = GetStorageCapacity(storageType);
            if (fromAbsoluteSlot <= 0 || fromAbsoluteSlot > capacity || toAbsoluteSlot <= 0 || toAbsoluteSlot > capacity)
            {
                errorKey = "msgbox_common_num_1306";
                return false;
            }

            if (!Storages.TryGetValue(storageType, out var slots))
            {
                errorKey = "msgbox_common_num_1005";
                return false;
            }

            if (!slots.TryGetValue(fromAbsoluteSlot, out var moving))
            {
                if (!string.IsNullOrWhiteSpace(pid))
                {
                    var byPid = slots
                        .OrderBy(x => x.Key)
                        .FirstOrDefault(x => string.Equals(x.Value.Pid, pid, StringComparison.Ordinal));
                    if (!byPid.Equals(default(KeyValuePair<int, InventoryItem>)))
                    {
                        fromAbsoluteSlot = byPid.Key;
                        moving = byPid.Value;
                    }
                }

                if (string.IsNullOrWhiteSpace(moving?.Pid))
                {
                    errorKey = "msgbox_common_num_1005";
                    return false;
                }
            }

            if (!string.IsNullOrWhiteSpace(pid) && !string.Equals(moving.Pid, pid, StringComparison.Ordinal))
            {
                errorKey = "msgbox_common_num_1005";
                return false;
            }

            var hasTarget = slots.TryGetValue(toAbsoluteSlot, out var target);
            slots[toAbsoluteSlot] = moving with { Slot = toAbsoluteSlot };

            if (hasTarget)
            {
                slots[fromAbsoluteSlot] = target! with { Slot = fromAbsoluteSlot };
            }
            else
            {
                slots.Remove(fromAbsoluteSlot);
            }

            if (storageType == (int)ShopItemDatabase.ItemType.Equipment)
            {
                SyncEquipmentEquipFlags();
            }

            return true;
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

        public IReadOnlyList<GameLoadoutItem> GetGameLoadoutItems()
        {
            EnsureStarterInventory();
            NormalizeHotKeySlots();
            EnsureDefaultWeaponHotKeySlots();

            var hotKeyLoadout = _hotKeySlots.Values
                .Where(slot =>
                    slot.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                    IsBattleLoadoutResource(slot.Resource))
                .OrderBy(slot => slot.Slot)
                .Select(CreateHotKeyLoadoutItem)
                .ToList();
            return hotKeyLoadout.Count == 0
                ? GetBackpackGameLoadoutItems()
                : hotKeyLoadout;
        }

        public IReadOnlyList<GameSkillSlotItem> GetGameSkillSlotItems()
        {
            EnsureStarterInventory();
            NormalizeHotKeySlots();

            var activeSlots = _hotKeySlots.Values
                .Where(slot =>
                    slot.Type == 1 &&
                    ResolveGameSkillSlotLevel(slot) > 0 &&
                    slot.Sid >= 0 &&
                    !string.IsNullOrWhiteSpace(slot.Resource))
                .OrderBy(slot => slot.Slot)
                .Select(CreateGameSkillSlotItem)
                .ToList();

            var equippedSkillIds = activeSlots
                .Select(slot => (int)slot.SkillType)
                .ToHashSet();
            var nextPassiveSlot = HotKeySlotCount + 1;
            foreach (var (skillId, level) in SkillLevels
                         .Where(pair => pair.Value > 0)
                         .OrderBy(pair => pair.Key))
            {
                if (equippedSkillIds.Contains(skillId))
                {
                    continue;
                }

                var definition = ResolveGameSkillDefinition(skillId, Character.Occupation);
                if (definition is null || definition.IsActive)
                {
                    continue;
                }

                if (nextPassiveSlot > 36)
                {
                    break;
                }

                activeSlots.Add(CreateGameSkillSlotItem(nextPassiveSlot++, definition, level));
            }

            return activeSlots
                .OrderBy(slot => slot.Slot)
                .ToArray();
        }

        public string GetGameLoadoutSource()
        {
            EnsureStarterInventory();
            NormalizeHotKeySlots();
            EnsureDefaultWeaponHotKeySlots();

            return _hotKeySlots.Values.Any(slot =>
                slot.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                IsBattleLoadoutResource(slot.Resource))
                ? "hotkey"
                : "backpack-fallback";
        }

        private GameSkillSlotItem CreateGameSkillSlotItem(HotKeySlot slot)
        {
            var definition = ResolveGameSkillDefinition(slot.Sid, slot.Resource);
            var effectiveLevel = ResolveGameSkillSlotLevel(slot);
            var display = string.IsNullOrWhiteSpace(slot.Display)
                ? GetGameSkillDisplay(definition, effectiveLevel, slot.Resource)
                : slot.Display;
            var skillId = definition?.Id ?? slot.Sid;

            return new GameSkillSlotItem(
                Slot: (byte)Math.Clamp(slot.Slot, 1, HotKeySlotCount),
                SkillType: (byte)Math.Clamp(skillId, 0, byte.MaxValue),
                Resource: string.IsNullOrWhiteSpace(definition?.Resource) ? slot.Resource : definition!.Resource,
                DisplayName: display,
                Initiative: definition?.IsActive ?? true,
                CoolDown: definition?.CoolDown ?? 20f,
                Range: definition?.Range ?? 8f);
        }

        private int ResolveGameSkillSlotLevel(HotKeySlot slot)
        {
            var learnedLevel = slot.Sid >= 0 ? GetSkillLevel(slot.Sid) : 0;
            if (learnedLevel > 0)
            {
                return learnedLevel;
            }

            if (slot.Level > 0)
            {
                return Math.Clamp(slot.Level, 1, 5);
            }

            var displayLevel = ResolveGameSkillDisplayLevel(slot.Display);
            return displayLevel > 0 ? displayLevel : 1;
        }

        private static GameSkillSlotItem CreateGameSkillSlotItem(
            int slot,
            SkillRuntimeDefinition definition,
            int level)
        {
            return new GameSkillSlotItem(
                Slot: (byte)Math.Clamp(slot, 1, 36),
                SkillType: (byte)Math.Clamp(definition.Id, 0, byte.MaxValue),
                Resource: definition.Resource,
                DisplayName: GetGameSkillDisplay(definition, level, definition.Resource),
                Initiative: definition.IsActive,
                CoolDown: definition.CoolDown,
                Range: definition.Range);
        }

        private static SkillRuntimeDefinition? ResolveGameSkillDefinition(int skillId, string resource)
        {
            var definitions = GetGameSkillDefinitions();
            return definitions.FirstOrDefault(skill => skill.Id == skillId)
                ?? definitions.FirstOrDefault(skill =>
                    string.Equals(skill.Resource, resource, StringComparison.OrdinalIgnoreCase));
        }

        private static SkillRuntimeDefinition? ResolveGameSkillDefinition(int skillId, int occupation)
        {
            var definitions = GetGameSkillDefinitions();
            return definitions.FirstOrDefault(skill => skill.Id == skillId && skill.Occupation == occupation)
                ?? definitions.FirstOrDefault(skill => skill.Id == skillId);
        }

        private static IReadOnlyList<SkillRuntimeDefinition> GetGameSkillDefinitions()
        {
            lock (GameSkillDefinitionCacheLock)
            {
                if (DbGameSkillDefinitions is not null &&
                    (DateTime.UtcNow - DbGameSkillDefinitionsLoadedUtc) < TimeSpan.FromSeconds(30))
                {
                    return DbGameSkillDefinitions;
                }

                try
                {
                    using var db = new AvatarStarDbContext();
                    var skills = db.SkillDefinitions
                        .OrderBy(x => x.Occupation)
                        .ThenBy(x => x.Id)
                        .Select(x => new SkillRuntimeDefinition(
                            x.Id,
                            x.Occupation,
                            x.Resource,
                            x.DisplayBase,
                            x.IsActive != 0,
                            x.CoolDown,
                            x.Range))
                        .ToArray();
                    if (skills.Length > 0)
                    {
                        DbGameSkillDefinitions = skills;
                        DbGameSkillDefinitionsLoadedUtc = DateTime.UtcNow;
                        return DbGameSkillDefinitions;
                    }
                }
                catch
                {
                    DbGameSkillDefinitions = null;
                }

                DbGameSkillDefinitionsLoadedUtc = DateTime.UtcNow;
                return GameSkillDefinitions;
            }
        }

        private static string GetGameSkillDisplay(SkillRuntimeDefinition? definition, int level, string fallbackResource)
        {
            if (definition is null)
            {
                return fallbackResource;
            }

            if (definition.DisplayBase.StartsWith("tips_", StringComparison.Ordinal))
            {
                return definition.DisplayBase;
            }

            var effectiveLevel = Math.Clamp(level <= 0 ? 1 : level, 1, 99);
            var marker = "_01";
            var idx = definition.DisplayBase.LastIndexOf(marker, StringComparison.Ordinal);
            return idx >= 0
                ? definition.DisplayBase[..idx] + $"_{effectiveLevel:00}"
                : definition.DisplayBase;
        }

        private static int ResolveGameSkillDisplayLevel(string? display)
        {
            if (string.IsNullOrWhiteSpace(display) || display.Length < 3 || display[^3] != '_')
            {
                return 0;
            }

            return int.TryParse(display.AsSpan(display.Length - 2, 2), NumberStyles.Integer, CultureInfo.InvariantCulture, out var level)
                ? Math.Clamp(level, 1, 5)
                : 0;
        }

        private GameLoadoutItem CreateHotKeyLoadoutItem(HotKeySlot slot)
        {
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

        private static string BuildSkillHotKeyItemId(int skillId, int level)
        {
            return string.Create(
                CultureInfo.InvariantCulture,
                $"1110260000000{100000 + Math.Max(0, skillId) * 100 + Math.Clamp(level, 0, 99):D6}");
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
            var normalizedAvatar = NormalizeAvatarForCharacter(equipped.Avatar);
            Character = Character with { EquipAvatar = normalizedAvatar };

            foreach (var storageType in new[] { 5, 6 })
            {
                if (!Storages.TryGetValue(storageType, out var slots))
                {
                    continue;
                }

                foreach (var pair in slots.ToArray())
                {
                    var shouldEquip = pair.Value.Slot == equipped.Slot;
                    var next = pair.Value with
                    {
                        IsEquip = shouldEquip ? "Y" : "N"
                    };

                    if (shouldEquip)
                    {
                        next = next with
                        {
                            Avatar = normalizedAvatar,
                            Position = next.Position ?? equipped.Position ?? 1
                        };
                    }

                    slots[pair.Key] = next;
                }
            }

            return FindItemByPid(equipped.Pid, 5, 6) ?? equipped with { Avatar = normalizedAvatar };
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

            var completeAvatar = PlayerStore.EnsureCompleteEquipAvatar(
                item.Avatar,
                Character.Occupation,
                fallbackAvatarId);
            var normalizedAvatar = EnsureAvatarHasAvatarId(completeAvatar, fallbackAvatarId) ?? completeAvatar;
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
            var completeAvatar = PlayerStore.EnsureCompleteEquipAvatar(
                avatar ?? Character.EquipAvatar,
                Character.Occupation,
                avatarId);
            var resolvedAvatar = EnsureAvatarHasAvatarId(completeAvatar, avatarId) ?? completeAvatar;

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

            var maxSlots = Math.Min(GetStorageCapacity(5), GetStorageCapacity(6));
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

            var slot = FindFirstEmptyStorageSlot(storageType, slots);
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

            if (!Storages.TryGetValue(storageType, out var slots))
            {
                slots = new Dictionary<int, InventoryItem>();
                Storages[storageType] = slots;
            }

            var avatarId = GetAvatarIdFrom(Character.EquipAvatar) ?? "0";
            var avatar = shopItem.Type is ShopItemDatabase.ItemType.AvatarCard or ShopItemDatabase.ItemType.SkinCard
                ? PlayerStore.EnsureCompleteEquipAvatar(
                    EnsureAvatarHasAvatarId(shopItem.Avatar, avatarId) ?? shopItem.Avatar,
                    Character.Occupation,
                    avatarId)
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

            var slot = FindFirstEmptyStorageSlot(storageType, slots);
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
