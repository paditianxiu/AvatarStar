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
    private int _nextCharacterId = 1;

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
            var player = new PlayerState(CharacterInfo.Create(id, name, occupation));
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
            int Sid);

        public sealed record GameLoadoutItem(
            byte Slot,
            byte ItemType,
            long ItemId,
            string Resource,
            byte Grade,
            string DisplayName,
            byte Subtype);

        public sealed record GameIndependentTrinketItem(
            int Slot,
            string Resource,
            InventoryItem? BackpackItem);

        public CharacterInfo Character { get; set; }
        public int Gp { get; set; } = 100000;
        public int Mb { get; set; } = 0;
        public int Tb { get; set; } = 0;

        // (sid, priceId) -> purchased count (用于限购显示/校验)
        public Dictionary<(int Sid, int PriceId), int> ShopPurchasedCounts { get; } = new();

        // storageType(t) -> slot -> item
        public Dictionary<int, Dictionary<int, InventoryItem>> Storages { get; } = new();
        public Dictionary<int, string> EquippedItemsByType { get; } = new();
        public string? EquippedAvatarPid { get; set; }
        private readonly Dictionary<int, HotKeySlot> _hotKeySlots = new();
        private const int HotKeySlotCount = 12;
        private const int MaxWeaponHotKeyCount = 3;
        public int NextPid { get; set; } = 1;
        private bool _ensuringStarterInventory;

        public PlayerState(CharacterInfo character)
        {
            Character = character;
        }

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
            IReadOnlyDictionary<string, double>? attributes = null)
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
                Category: 0,
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
                        resource = entry.Resource,
                        grade = entry.Grade,
                        quantity = entry.Quantity,
                        unitType = entry.UnitType,
                        unit = entry.Unit,
                        subtype = entry.Subtype,
                        sid = entry.Sid
                    };
                }
                else
                {
                    result[i - 1] = new { slot = i, type = 0 };
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
                Grade: item.Grade,
                Quantity: item.Quantity,
                UnitType: item.UnitType,
                Unit: item.Unit,
                Subtype: item.Subtype,
                Sid: item.Sid);
            SyncEquipmentEquipFlags();
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

        public string GetGameLoadoutSource()
        {
            EnsureStarterInventory();
            NormalizeHotKeySlots();

            return _hotKeySlots.Values.Any(slot =>
                slot.Type == (int)ShopItemDatabase.ItemType.Equipment &&
                IsBattleLoadoutResource(slot.Resource))
                ? "hotkey"
                : "backpack-fallback";
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

        public bool TryPurchaseToInventory(
            ShopItemDatabase.ShopItem shopItem,
            int quantity,
            ShopItemDatabase.ShopPrice? price = null)
        {
            EnsureStarterInventory();

            var storageType = shopItem.Type switch
            {
                ShopItemDatabase.ItemType.Equipment => 2,
                ShopItemDatabase.ItemType.Item => 3,
                ShopItemDatabase.ItemType.Gesture => 4,
                ShopItemDatabase.ItemType.AvatarCard => 5,
                ShopItemDatabase.ItemType.SkinCard => 6,
                _ => 3
            };

            const int maxSlots = 36;
            if (!Storages.TryGetValue(storageType, out var slots))
            {
                slots = new Dictionary<int, InventoryItem>();
                Storages[storageType] = slots;
            }

            var slot = Enumerable.Range(1, maxSlots).FirstOrDefault(i => !slots.ContainsKey(i));
            if (slot == 0) return false;

            var avatarId = GetAvatarIdFrom(Character.EquipAvatar) ?? "0";
            var avatar = shopItem.Type is ShopItemDatabase.ItemType.AvatarCard or ShopItemDatabase.ItemType.SkinCard
                ? EnsureAvatarHasAvatarId(shopItem.Avatar, avatarId) ?? shopItem.Avatar
                : shopItem.Avatar;
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

            AddItem(
                storageType,
                slot,
                resource: string.IsNullOrWhiteSpace(shopItem.Resource) && avatar is not null
                    ? (shopItem.Subtype == 2 ? "herocard" : "humancard")
                    : shopItem.Resource,
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
