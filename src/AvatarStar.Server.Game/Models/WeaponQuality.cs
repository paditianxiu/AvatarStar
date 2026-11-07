namespace AvatarStar.Server.Game;

internal static class WeaponQuality
{
    // Tip.GetGradeColor(5) = ARGB(255, 255, 128, 0).
    internal const int Orange = 5;

    internal static int Resolve(int type, int subtype, int grade) =>
        type == 2 && subtype is >= 1 and <= 16 ? Orange : grade;
}
