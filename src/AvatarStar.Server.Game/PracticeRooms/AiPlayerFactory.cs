using System.Text.RegularExpressions;
using System.Text.Json;
using AvatarStar.Server.Game.Config;
using AvatarStar.Server.Game.Resources;

namespace AvatarStar.Server.Game;

internal static class AiPlayerFactory
{
    internal static PlayerStore.PlayerState Create(int id, int occupation, SysAvatarPayloadConfig config, Random random)
    {
        string[] names = ["护卫", "重装", "突击", "生化", "武士"];
        if (occupation is < 0 or > 4) throw new ArgumentOutOfRangeException(nameof(occupation));
        if (!config.SysAvatarListPayloads.TryGetValue(occupation + 1, out var payload))
            throw new InvalidOperationException("职业模型配置未加载");
        var bodies = Regex.Matches(payload, @"avatar\s*=\s*\{(.*?)^\s*\},", RegexOptions.Singleline | RegexOptions.Multiline);
        if (bodies.Count == 0) throw new InvalidOperationException("职业模型配置无效");
        var avatar = Regex.Matches(bodies[random.Next(bodies.Count)].Groups[1].Value, "(\\w+)\\s*=\\s*\"([^\"]*)\"")
            .ToDictionary(m => m.Groups[1].Value, m => m.Groups[2].Value);
        var cards = ShopItemDatabase.GetAllShopItems().Values
            .Where(c => c.Type == ShopItemDatabase.ItemType.AvatarCard &&
                c.Category == ShopItemDatabase.AvatarCardCategory && c.Avatar is not null &&
                (c.Occupation < 0 || c.Occupation == occupation))
            .ToArray();
        if (cards.Length == 0) throw new InvalidOperationException("商城造型卡配置未加载");
        var card = cards[random.Next(cards.Length)];
        var cardParts = JsonSerializer.SerializeToElement(card.Avatar);
        // Shop cards are full outfits. Empty parts deliberately clear the starter costume.
        foreach (var part in cardParts.EnumerateObject())
            if (part.Name != "avatarId" && part.Value.ValueKind == JsonValueKind.String)
                avatar[part.Name] = string.IsNullOrWhiteSpace(part.Value.GetString()) ? "{}" : part.Value.GetString()!;
        var profession = config.OfficialCatalog?.Professions.FirstOrDefault(p => p.Occupation == occupation)
            ?? throw new InvalidOperationException("职业武器配置未加载");
        var state = new PlayerStore.PlayerState(CharacterInfo.Create(id, $"AI-{names[occupation]}-{id % 1000:000}", occupation) with
        { EquipAvatar = avatar, MaxHealth = profession.BaseStats?.Life is > 0 ? profession.BaseStats.Life : CharacterInfo.ResolveDefaultMaxHealth(occupation) });
        state.InitializeStarterInventory(occupation, config, avatar, avatar["avatarId"],
            card.Display, card.Designer, card.Description);
        state.Storages[2].Clear();
        var slot = 1;
        foreach (var weapon in profession.Weapons.Take(3))
        {
            var subtype = int.Parse(weapon.SubType, System.Globalization.CultureInfo.InvariantCulture);
            var stem = weapon.Resource[..weapon.Resource.LastIndexOf('_')];
            var choices = ShopItemDatabase.GetAllShopItems().Values
                .Where(w => Regex.IsMatch(w.Resource ?? "", "^" + Regex.Escape(stem) + "_0[1-4]$") && w.Subtype == subtype)
                .DistinctBy(w => w.Resource).ToArray();
            var chosen = choices.Length > 0 ? choices[random.Next(choices.Length)] : null;
            state.AddItem(2, slot, chosen?.Resource ?? weapon.Resource, subtype, chosen?.Grade ?? 1, chosen?.Sid ?? 10000 + subtype, 2);
            state.TrySetHotKeySlot(slot, state.Storages[2][slot].Pid);
            slot++;
        }
        return state;
    }
}
