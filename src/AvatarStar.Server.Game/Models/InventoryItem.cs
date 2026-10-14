namespace AvatarStar.Server.Game;


//背包物品
internal sealed record InventoryItem
{
    public InventoryItem()
    {
    }

    public InventoryItem(
        string Pid,
        int Slot,
        string Resource,
        int Subtype,
        int SubType,
        int Grade,
        int Quantity,
        int UnitType,
        int Unit,
        int Remain,
        bool IsRenew,
        int Category,
        string IsBind,
        string IsEquip,
        int Sid,
        int Type,
        object? Avatar = null,
        int? Position = null,
        string Display = "",
        string Designer = "",
        string Description = "",
        IReadOnlyDictionary<string, double>? Attributes = null,
        int RefitTotalExp = 0,
        int RefitLevel = 0,
        int PlusLevel = 0)
    {
        this.Pid = Pid;
        this.Slot = Slot;
        this.Resource = Resource;
        this.Subtype = Subtype;
        this.SubType = SubType;
        this.Grade = Grade;
        this.Quantity = Quantity;
        this.UnitType = UnitType;
        this.Unit = Unit;
        this.Remain = Remain;
        this.IsRenew = IsRenew;
        this.Category = Category;
        this.IsBind = IsBind;
        this.IsEquip = IsEquip;
        this.Sid = Sid;
        this.Type = Type;
        this.Avatar = Avatar;
        this.Position = Position;
        this.Display = Display;
        this.Designer = Designer;
        this.Description = Description;
        this.Attributes = Attributes;
        this.RefitTotalExp = RefitTotalExp;
        this.RefitLevel = RefitLevel;
        this.PlusLevel = PlusLevel;
    }

    public string Pid { get; init; } = string.Empty;
    public int Slot { get; init; }
    public string Resource { get; init; } = string.Empty;
    public int Subtype { get; init; }
    public int SubType { get; init; }
    public int Grade { get; init; }
    public int Quantity { get; init; }
    public int UnitType { get; init; }
    public int Unit { get; init; }
    public int Remain { get; init; }
    public bool IsRenew { get; init; }
    public int Category { get; init; }
    public string IsBind { get; init; } = "N";
    public string IsEquip { get; init; } = "N";
    public int Sid { get; init; }
    public int Type { get; init; }
    public object? Avatar { get; init; }
    public int? Position { get; init; }
    public string Display { get; init; } = string.Empty;
    public string Designer { get; init; } = string.Empty;
    public string Description { get; init; } = string.Empty;
    public IReadOnlyDictionary<string, double>? Attributes { get; init; }

    // 强化武器 (weapon refit) progress. RefitTotalExp is the accumulated enhancement
    // exp, RefitLevel the resulting level (0..20) and PlusLevel the mirror value the
    // client shows on the item payload (`plusLevel`).
    public int RefitTotalExp { get; init; }
    public int RefitLevel { get; init; }
    public int PlusLevel { get; init; }
}
