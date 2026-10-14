using System.Globalization;
using AvatarStar.Server.Game.Resources;
using Serilog;

namespace AvatarStar.Server.Game;

/// <summary>
/// 强化武器 (weapon refit)。
///
/// 协议来自台服抓包（log-2026-10-14 18:43 段）：
///   OUT refit_detail {}                                                        -> 规则常量表
///   OUT refit_need   { itemId }                                                -> 面板数值 + 材料需求
///   OUT refit_finish { playerItemId, materialItemId, useFixReel, useHeirloom } -> result=0 (+2 次 updatePlayer 推送)
///
/// 每次成功强化消耗：3 合金钢 + 3 复合材料 + 3000 金币 + 一件材料武器（整件），
/// 可选再消耗 2 幸运齿轮 (useFixReel=Y) / 1 传承齿轮 (useHeirloom=Y)。
/// 材料提供的经验 = grades[material.grade].exp；与目标同 sid ×1.5，幸运齿轮 ×2，
/// 之后按官方规则叠加材料自身的强化经验（不勾传承时 ×0.01，勾选时 ×0.8）。
/// </summary>
internal partial class GameClient
{
    private const string RefitSteelResource = "wim_steel";
    private const string RefitCompositeResource = "wim_composite";
    private const string RefitLuckResource = "intensify_luck";
    private const string RefitTranslationResource = "intensify_translation";
    private const string RefitSteelDisplay = "id_datalist_Alloy_Steel";
    private const string RefitCompositeDisplay = "id_datalist_Composites";

    private const int RefitSteelFallbackSid = 109;
    private const int RefitCompositeFallbackSid = 111;
    private const int RefitLuckFallbackSid = 20628;
    private const int RefitTranslationFallbackSid = 20631;

    private const int RefitStorageType = 3;
    private const int RefitMaxLevel = 20;
    private const int RefitGpCost = 3000;
    private const int RefitNeedSteel = 3;
    private const int RefitNeedComposite = 3;
    private const int RefitNeedFixReel = 2;
    private const int RefitNeedHeirloom = 1;
    private const int RefitMinMaterialGrade = 2;
    private const int RefitMaxMaterialGrade = 5;

    /// <summary>客户端 L_MoneyLessKey 里「金币不足」的错误键（见 sys/moneyLessKey.lua）。</summary>
    private const string MoneyLessGoldKey = "msgbox_common_conditionkey_128";

    private const double RefitSameItemRate = 1.5d;
    private const double RefitFixReelRate = 2d;
    private const double RefitNoHeirloomRate = 0.01d;
    private const double RefitUseHeirloomRate = 0.8d;
    private const double RefitMaxHeirloomRate = 0.81d;
    private const double RefitMinHeirloomRate = 0.5d;

    /// <summary>各等级武器作为材料时提供的强化经验（官方 refit_detail.grades）。</summary>
    private static readonly Dictionary<int, int> RefitMaterialExp = new()
    {
        [2] = 300,
        [3] = 1250,
        [4] = 6000,
        [5] = 12000
    };

    /// <summary>每一级所需经验（官方 refit_detail.expList；客户端会自行累加成总表）。</summary>


    private static readonly Dictionary<int, int[]> RefitLevelStepExp = new()
    {
        [2] = new[] { 5, 8, 11, 14, 17, 26, 36, 45, 55, 65, 96, 127, 158, 189, 220, 320, 419, 519, 619, 719 },
        [3] = new[] { 10, 15, 20, 25, 30, 50, 75, 100, 125, 145, 260, 375, 485, 600, 710, 1250, 1790, 2330, 2865, 3405 },
        [4] = new[] { 20, 30, 40, 50, 60, 120, 180, 240, 310, 370, 770, 1170, 1560, 1960, 2360, 4870, 7380, 9900, 12410, 14920 },
        [5] = new[] { 40, 60, 80, 100, 120, 280, 440, 600, 760, 920, 2000, 3080, 4160, 5240, 6320, 14960, 23600, 32240, 40880, 49520 }
    };

    // private static readonly Dictionary<int, int[]> RefitLevelStepExp = new()
    // {
    //     [2] = new[] { 500, 800, 1100, 1400, 1700, 2600, 3600, 4500, 5500, 6500, 9600, 12700, 15800, 18900, 22000, 32000, 41900, 51900, 61900, 71900 },
    //     [3] = new[] { 1000, 1500, 2000, 2500, 3000, 5000, 7500, 10000, 12500, 14500, 26000, 37500, 48500, 60000, 71000, 125000, 179000, 233000, 286500, 340500 },
    //     [4] = new[] { 2000, 3000, 4000, 5000, 6000, 12000, 18000, 24000, 31000, 37000, 77000, 117000, 156000, 196000, 236000, 487000, 738000, 990000, 1241000, 1492000 },
    //     [5] = new[] { 4000, 6000, 8000, 10000, 12000, 28000, 44000, 60000, 76000, 92000, 200000, 308000, 416000, 524000, 632000, 1496000, 2360000, 3224000, 4088000, 4952000 }
    // };

    /// <summary>累计经验表：RefitLevelTotalExp[grade][level-1] = 到达该等级需要的总经验。</summary>
    private static readonly Dictionary<int, int[]> RefitLevelTotalExp = BuildRefitLevelTotalExp();

    private static Dictionary<int, int[]> BuildRefitLevelTotalExp()
    {
        var table = new Dictionary<int, int[]>();
        foreach (var (grade, steps) in RefitLevelStepExp)
        {
            var totals = new int[steps.Length];
            var sum = 0;
            for (var i = 0; i < steps.Length; i++)
            {
                sum += steps[i];
                totals[i] = sum;
            }

            table[grade] = totals;
        }

        return table;
    }

    private static int[] ResolveRefitLevelTable(int grade)
    {
        return RefitLevelTotalExp.TryGetValue(grade, out var totals)
            ? totals
            : RefitLevelTotalExp[3];
    }

    /// <summary>由累计经验换算强化等级 (0..20)。</summary>
    private static int ResolveRefitLevel(int grade, int totalExp)
    {
        var totals = ResolveRefitLevelTable(grade);
        var level = 0;
        for (var i = 0; i < totals.Length && i < RefitMaxLevel; i++)
        {
            if (totalExp < totals[i])
            {
                break;
            }

            level = i + 1;
        }

        return level;
    }

    /// <summary>当前等级内已累积的经验 / 升下一级还需的经验。</summary>
    private static (int CurrentOffset, int NextOffset) ResolveRefitLevelOffsets(int grade, int totalExp)
    {
        var totals = ResolveRefitLevelTable(grade);
        var level = ResolveRefitLevel(grade, totalExp);
        var baseExp = level <= 0 ? 0 : totals[level - 1];
        var nextTotal = level >= totals.Length ? totals[^1] : totals[level];
        return (Math.Max(0, totalExp - baseExp), Math.Max(0, nextTotal - baseExp));
    }

    /// <summary>
    /// 官方用十进制位掩码描述「哪些等级的武器可以当材料」：位 i（从右往左，1 起）代表等级 i。
    /// 例：目标 grade=3 -> 材料 grade {2,3} -> 110（官方原文写作 00110）。
    /// </summary>
    private static int ResolveRefitMaterialGradeMask(int grade)
    {
        var highest = Math.Clamp(Math.Max(grade, RefitMinMaterialGrade), RefitMinMaterialGrade, RefitMaxMaterialGrade);
        var mask = 0;
        var place = 1;
        for (var materialGrade = 1; materialGrade <= highest; materialGrade++)
        {
            if (materialGrade >= RefitMinMaterialGrade)
            {
                mask += place;
            }

            place *= 10;
        }

        return mask;
    }

    private static int ResolveRefitSid(string resource, int fallbackSid)
    {
        return ShopItemDatabase.TryGetShopItemByResource(resource, out var shopItem) && shopItem.Sid > 0
            ? shopItem.Sid
            : fallbackSid;
    }

    private static string FormatRefitNumber(double value)
    {
        return value.ToString("0.##########", CultureInfo.InvariantCulture);
    }

    /// <summary>官方 refit_detail 回包（常量规则 + 经验表）。</summary>
    private static string BuildRefitDetailPayload()
    {
        var grades = RefitMaterialExp
            .OrderBy(x => x.Key)
            .Select(x => $"\t{{\tgrade={x.Key},\r\n\t\texp={x.Value},\r\n\t}},")
            .ToArray();

        var expList = RefitLevelStepExp
            .OrderBy(x => x.Key)
            .Select(entry =>
            {
                var steps = entry.Value;
                var parts = new string[steps.Length];
                for (var i = 0; i < steps.Length; i++)
                {
                    parts[i] = $"{{{i + 1}={steps[i]}}}";
                }

                // 客户端按字符串清洗后 load_result，格式必须保持 "[{1=500}, {2=800}, ...]"。
                var text = "[" + string.Join(", ", parts) + "]";
                return $"\t{{\r\n\t\tgrade=\"{entry.Key}\",\r\n\t\texp=\"{text}\",\r\n\t}},";
            })
            .ToArray();

        return
            $"sameItemRate={FormatRefitNumber(RefitSameItemRate)}\r\n" +
            $"fixReelRate={FormatRefitNumber(RefitFixReelRate)}\r\n" +
            $"noHeirloomRate={FormatRefitNumber(RefitNoHeirloomRate)}\r\n" +
            $"useHeirloomRate={FormatRefitNumber(RefitUseHeirloomRate)}\r\n" +
            $"maxHeirloomRate={FormatRefitNumber(RefitMaxHeirloomRate)}\r\n" +
            $"minHeirloomRate={FormatRefitNumber(RefitMinHeirloomRate)}\r\n" +
            "\r\n" +
            "grades={\r\n\t\r\n" + string.Join("\r\n\t\r\n", grades) + "\r\n\t\r\n}\r\n\r\n" +
            "expList={\r\n\t\r\n" + string.Join("\r\n\t\r\n", expList) + "\r\n\t\r\n}";
    }

    private async Task HandleRefitDetailAsync(PacketWriter writer)
    {
        writer.WriteString(BuildRefitDetailPayload());
        await SendAsync(writer);
    }

    private async Task HandleRefitNeedAsync(
        PacketWriter writer,
        IReadOnlyDictionary<string, string> args)
    {
        var player = GetActivePlayerStateOrDefault();
        var pid = args.GetValueOrDefault("itemId");
        var item = player.FindInventoryItemByPid(pid);
        if (item is null)
        {
            // 客户端 DealRefitNeed 会直接索引 currentLevel/currentRefitExp，
            // 缺字段会抛 Lua 错误，所以这里仍然回一份合法（但空）的面板数据。
            Log.Warning("refit_need: item not found pid={Pid}", pid);
        }

        var grade = item?.Grade ?? 3;
        var totalExp = Math.Max(0, item?.RefitTotalExp ?? 0);
        var (currentOffset, nextOffset) = ResolveRefitLevelOffsets(grade, totalExp);

        var steelSid = ResolveRefitSid(RefitSteelResource, RefitSteelFallbackSid);
        var compositeSid = ResolveRefitSid(RefitCompositeResource, RefitCompositeFallbackSid);
        var luckSid = ResolveRefitSid(RefitLuckResource, RefitLuckFallbackSid);
        var translationSid = ResolveRefitSid(RefitTranslationResource, RefitTranslationFallbackSid);

        var steelOwn = player.GetStorageResourceCount(RefitStorageType, RefitSteelResource);
        var compositeOwn = player.GetStorageResourceCount(RefitStorageType, RefitCompositeResource);
        var luckOwn = player.GetStorageResourceCount(RefitStorageType, RefitLuckResource);
        var translationOwn = player.GetStorageResourceCount(RefitStorageType, RefitTranslationResource);

        var payload =
            $"maxLevel = {RefitMaxLevel}\n" +
            "refitNum = 0\n" +
            $"type = {item?.Type ?? 2}\n" +
            $"grade = {grade}\n" +
            $"subType = {item?.Subtype ?? 0}\n" +
            "\n" +
            $"ownFixReelNum = {luckOwn}\n" +
            $"fixReelId = \"{luckSid}\"\n" +
            "fixReelGrade = 3\n" +
            "fixReelCategory = 3\n" +
            $"fixReelResource = \"{RefitLuckResource}\"\n" +
            "\n" +
            $"ownHeirloomNum = {translationOwn}\n" +
            $"heirloomId = \"{translationSid}\"\n" +
            "heirloomGrade = 3\n" +
            "heirloomCategory = 6\n" +
            $"heirloomResource = \"{RefitTranslationResource}\"\n" +
            "\n" +
            $"plusGP = {RefitGpCost}\n" +
            "xOutPutMin = 0.01\n" +
            "xOutPutMax = 0.01\n" +
            $"fixReelNum = {RefitNeedFixReel}\n" +
            $"heirloomNum = {RefitNeedHeirloom}\n" +
            $"grades = {ResolveRefitMaterialGradeMask(grade)}\n" +
            "\n" +
            $"currentLevel = {ResolveRefitLevel(grade, totalExp)}\n" +
            $"currentRefitExp = {totalExp}\n" +
            $"currentExpCurrentLevelOffset = {currentOffset}\n" +
            $"currentExpNextLevelOffset = {nextOffset}\n" +
            "\n" +
            "list = {\n" +
            "\t{\n" +
            $"\t\titemId = \"{steelSid}\",\n" +
            $"\t\townNum = {steelOwn},\n" +
            $"\t\tneedNum = {RefitNeedSteel},\n" +
            "\t\tgrade = 2,\n" +
            "\t\tcategory = 108,\n" +
            $"\t\tresource = \"{RefitSteelResource}\",\n" +
            $"\t\tdisplayName = \"{RefitSteelDisplay}\",\n" +
            "\t},\n" +
            "\n" +
            "\t{\n" +
            $"\t\titemId = \"{compositeSid}\",\n" +
            $"\t\townNum = {compositeOwn},\n" +
            $"\t\tneedNum = {RefitNeedComposite},\n" +
            "\t\tgrade = 2,\n" +
            "\t\tcategory = 110,\n" +
            $"\t\tresource = \"{RefitCompositeResource}\",\n" +
            $"\t\tdisplayName = \"{RefitCompositeDisplay}\",\n" +
            "\t},\n" +
            "}";

        Log.Debug(
            "refit_need: pid={Pid} sid={Sid} grade={Grade} exp={Exp} level={Level} steel={Steel} composite={Composite}",
            pid,
            item?.Sid ?? 0,
            grade,
            totalExp,
            ResolveRefitLevel(grade, totalExp),
            steelOwn,
            compositeOwn);

        writer.WriteString(payload);
        await SendAsync(writer);
    }

    private async Task HandleRefitFinishAsync(
        PacketWriter writer,
        IReadOnlyDictionary<string, string> args)
    {
        var player = GetActivePlayerStateOrDefault();
        var targetPid = args.GetValueOrDefault("playerItemId");
        var materialPid = args.GetValueOrDefault("materialItemId");
        var useFixReel = string.Equals(args.GetValueOrDefault("useFixReel"), "Y", StringComparison.OrdinalIgnoreCase);
        var useHeirloom = string.Equals(args.GetValueOrDefault("useHeirloom"), "Y", StringComparison.OrdinalIgnoreCase);

        var target = player.FindInventoryItemByPid(targetPid);
        var material = player.FindInventoryItemByPid(materialPid);
        if (target is null || material is null ||
            string.IsNullOrWhiteSpace(targetPid) || string.IsNullOrWhiteSpace(materialPid) ||
            string.Equals(targetPid, materialPid, StringComparison.Ordinal))
        {
            Log.Warning(
                "refit_finish rejected: bad items target={Target} material={Material}",
                targetPid,
                materialPid);
            await SendRefitFinishResultAsync(writer, result: 1);
            return;
        }

        var grade = target.Grade;
        var totalExp = Math.Max(0, target.RefitTotalExp);
        var level = ResolveRefitLevel(grade, totalExp);
        if (level >= RefitMaxLevel)
        {
            Log.Information("refit_finish rejected: max level pid={Pid} level={Level}", target.Pid, level);
            await SendRefitFinishResultAsync(writer, result: 3);
            return;
        }

        if (string.Equals(material.IsEquip, "Y", StringComparison.Ordinal))
        {
            Log.Information("refit_finish rejected: material is equipped pid={Pid}", material.Pid);
            await SendRefitFinishResultAsync(writer, result: 1);
            return;
        }

        var steelOwn = player.GetStorageResourceCount(RefitStorageType, RefitSteelResource);
        var compositeOwn = player.GetStorageResourceCount(RefitStorageType, RefitCompositeResource);
        var luckOwn = player.GetStorageResourceCount(RefitStorageType, RefitLuckResource);
        var translationOwn = player.GetStorageResourceCount(RefitStorageType, RefitTranslationResource);

        if (player.Gp < RefitGpCost)
        {
            // 金币不足是客户端唯一没法自己预判的条件，回一个「金币不足」错误键，
            // 客户端 ErrorHandler 会弹提示并复位强化界面。
            Log.Information("refit_finish rejected: insufficient gp={Gp}", player.Gp);
            writer.WriteString("error = " + LuaEscape(MoneyLessGoldKey));
            await SendAsync(writer);
            return;
        }

        if (steelOwn < RefitNeedSteel ||
            compositeOwn < RefitNeedComposite ||
            (useFixReel && luckOwn < RefitNeedFixReel) ||
            (useHeirloom && translationOwn < RefitNeedHeirloom))
        {
            Log.Information(
                "refit_finish rejected: insufficient material steel={Steel} composite={Composite} luck={Luck} translation={Translation}",
                steelOwn,
                compositeOwn,
                luckOwn,
                translationOwn);
            await SendRefitFinishResultAsync(writer, result: 1);
            return;
        }

        var support = ResolveRefitSupportExp(target, material, useFixReel, useHeirloom);
        var levelTable = ResolveRefitLevelTable(grade);
        var newTotalExp = Math.Min(totalExp + support, levelTable[^1]);
        var newLevel = ResolveRefitLevel(grade, newTotalExp);

        // 所有前置校验都通过后再扣费/扣材料。
        player.TrySpendCurrency((int)ShopItemDatabase.CurrencyType.Gold, RefitGpCost);
        player.TryConsumeStorageResource(RefitStorageType, RefitSteelResource, RefitNeedSteel);
        player.TryConsumeStorageResource(RefitStorageType, RefitCompositeResource, RefitNeedComposite);
        if (useFixReel)
        {
            player.TryConsumeStorageResource(RefitStorageType, RefitLuckResource, RefitNeedFixReel);
        }

        if (useHeirloom)
        {
            player.TryConsumeStorageResource(RefitStorageType, RefitTranslationResource, RefitNeedHeirloom);
        }

        if (!player.TryRemoveInventoryItemByPid(materialPid, out _))
        {
            Log.Warning("refit_finish: material removal failed after validation pid={Pid}", materialPid);
        }

        player.TryApplyRefitProgress(targetPid, newTotalExp, newLevel);

        Log.Information(
            "refit_finish: pid={Pid} sid={Sid} materialSid={MaterialSid} materialGrade={MaterialGrade} support={Support} exp={OldExp}->{NewExp} level={Level} gp={Gp}",
            targetPid,
            target.Sid,
            material.Sid,
            material.Grade,
            support,
            totalExp,
            newTotalExp,
            newLevel,
            player.Gp);

        // 官方行为：先推两次 updatePlayer，再回 result=0。
        await SendRefitPlayerUpdatePushAsync(player);
        await SendRefitPlayerUpdatePushAsync(player);
        await SendRefitFinishResultAsync(writer, result: 0);
    }

    private static int ResolveRefitSupportExp(
        InventoryItem target,
        InventoryItem material,
        bool useFixReel,
        bool useHeirloom)
    {
        var materialExp = RefitMaterialExp.TryGetValue(material.Grade, out var baseExp) ? baseExp : 0;
        double support = materialExp;

        if (useFixReel)
        {
            support *= RefitFixReelRate;
        }

        if (target.Sid > 0 && target.Sid == material.Sid)
        {
            support *= RefitSameItemRate;
        }

        var materialRefitExp = Math.Max(0, material.RefitTotalExp);
        // 官方还会按「传承」精确度结算材料自身的强化经验（与 baseRank 有关）；
        // 服务端没有 baseRank 数据，这里按等级相同/不同的两档近似，材料通常没有强化经验。
        support += useHeirloom
            ? materialRefitExp * RefitUseHeirloomRate
            : materialRefitExp * RefitNoHeirloomRate;

        return (int)Math.Round(support, MidpointRounding.AwayFromZero);
    }

    private async Task SendRefitFinishResultAsync(PacketWriter writer, int result)
    {
        writer.WriteString($"result={result}");
        await SendAsync(writer);
    }

    /// <summary>0x20 推送：客户端 push_cmd.lua 的 updatePlayer，用来刷新金币/等级显示。</summary>
    private async Task SendRefitPlayerUpdatePushAsync(PlayerStore.PlayerState player)
    {
        var character = player.Character;
        var lua =
            "cmd = \"updatePlayer\"\r\n" +
            $"playerId=\"{character.Id}\"\r\n" +
            $"playerName={LuaEscape(character.Name)}\r\n" +
            $"gp={player.Gp}\r\n" +
            $"mb={player.Mb}\r\n" +
            $"tb={player.Tb}\r\n" +
            "tk=0\r\n" +
            $"lv={character.Level}\r\n" +
            "exp=0\r\n" +
            "expPercent=0\r\n" +
            "expNextLevel=100";

        using var writer = new PacketWriter();
        writer.WriteByte(0x20);
        writer.WriteString(lua);
        await SendAsync(writer);
    }
}
