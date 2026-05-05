namespace AvatarStar.Server.Game;

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
        IReadOnlyDictionary<string, double>? Attributes = null)
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
}
