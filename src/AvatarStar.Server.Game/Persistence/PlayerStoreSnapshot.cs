namespace AvatarStar.Server.Game;

internal sealed class PlayerStoreSnapshot
{
    public List<PlayerStateSnapshot> Players { get; set; } = new();
    public int NextCharacterId { get; set; } = 1;
}

internal sealed class PlayerStateSnapshot
{
    public CharacterInfo Character { get; set; } = CharacterInfo.Create(1, "Player1", 0);
    public int Gp { get; set; }
    public int Mb { get; set; }
    public int Tb { get; set; }
    public int NextPid { get; set; }
    public string? EquippedAvatarPid { get; set; }
    public Dictionary<int, int> BoxPoints { get; set; } = new();
    public Dictionary<int, Dictionary<int, int>> BoxPointClaimCounts { get; set; } = new();
    public string CheckinMonthKey { get; set; } = string.Empty;
    public HashSet<int> CheckinDays { get; set; } = new();
    public HashSet<int> CheckinClaimedRewardIds { get; set; } = new();
    public Dictionary<string, int> ShopPurchasedCounts { get; set; } = new();
    public Dictionary<int, Dictionary<int, InventoryItem>> Storages { get; set; } = new();
    public Dictionary<int, string> EquippedItemsByType { get; set; } = new();
    public Dictionary<int, HotKeySlotSnapshot> HotKeySlots { get; set; } = new();
}

internal sealed record HotKeySlotSnapshot(
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
