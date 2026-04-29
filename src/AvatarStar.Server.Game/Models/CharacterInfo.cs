namespace AvatarStar.Server.Game;

internal sealed record CharacterInfo(int Id, string Name, int Level, int Occupation, string BattleForce, object EquipAvatar, int MaxHealth)
{
    public const int DefaultMaxHealth = 2300;

    public static int ResolveDefaultMaxHealth(int occupation)
    {
        return occupation switch
        {
            _ => DefaultMaxHealth
        };
    }

    public static CharacterInfo Create(int id, string name, int occupation)
    {
        // Provide the avatar table shape expected by ComFuc.DealAvatarEquip().
        // Client scripts treat these as strings (e.g. "{'onecolor_skin',...}" or "{}").
        var equipAvatar = new
        {
            avatarId = "0",
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

        return new CharacterInfo(
            Id: id,
            Name: name,
            Level: 1,
            Occupation: occupation,
            BattleForce: "0",
            EquipAvatar: equipAvatar,
            MaxHealth: ResolveDefaultMaxHealth(occupation));
    }
}
