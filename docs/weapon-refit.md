# 强化武器（refit）协议与实现

本文记录「强化武器」面板的封包链路与数值规则，依据是台服（真实服务器）抓包
`log-2026-10-14.txt` 里 18:43:40~18:44:25 一段完整、成功强化 4 次武器的会话。

## 回包/发包一览（局外 RPC，opcode 0x00）

```text
client -> server   refit_detail {}
server -> client   规则常量表（sameItemRate / fixReelRate / grades / expList ...）

client -> server   refit_need { itemId = <被强化武器的 pid> }
server -> client   面板数值（currentLevel / currentRefitExp / 本等级经验 / 材料需求 list）

client -> server   refit_finish { playerItemId, materialItemId, useFixReel, useHeirloom }
server -> client   0x20 push "updatePlayer" × 2   # 刷新金币/等级显示
server -> client   result=0                       # 0=成功
```

RPC 帧仍然是 `[0x00][int32 payloadLen][int32 nameLen][name][int32 keyLen][key][int32 valLen][val]...`
（按 key 循环的 `int32` 本身就是长度，0 长度即结束）。

## 规则常量（refit_detail）

```lua
sameItemRate    = 1.5   -- 目标与材料同 sid 时的经验倍率
fixReelRate     = 2     -- 勾选“幸运齿轮”时的经验倍率
noHeirloomRate  = 0.01  -- 不勾传承时，材料自身强化经验的折算率
useHeirloomRate = 0.8   -- 勾传承且材料/目标等级不同时的折算率
maxHeirloomRate = 0.81  -- 勾传承且材料/目标等级相同时的上限折算率
minHeirloomRate = 0.5

grades = { {grade=2,exp=300}, {grade=3,exp=1250}, {grade=4,exp=6000}, {grade=5,exp=12000} }
-- 材料武器按自身 grade 提供强化经验

expList = { {grade="2", exp="[{1=500}, {2=800}, ...]"}, ... }
-- 每一级所需经验；客户端收到后自己做累加得到「到达该等级所需总经验」
```

客户端 `scripts/lobby/personalInfo.lua:5117` 会把 `expList[i].exp` 字符串清洗后
`load_result` 成数组并累加进 `refitLevelExp[grade]`，所以 `exp` 必须是
`[{1=500}, {2=800}, ...]` 这种文本。

## 面板数值（refit_need）

```text
maxLevel=20  refitNum=0  type=2  grade=3  subType=2

ownFixReelNum=7   fixReelId="113"  fixReelGrade=3  fixReelCategory=3  fixReelResource="intensify_luck"
ownHeirloomNum=0  heirloomId="440"  heirloomGrade=3  heirloomCategory=6  heirloomResource="intensify_translation"

plusGP=3000  xOutPutMin=0.01  xOutPutMax=0.01
fixReelNum=2  heirloomNum=1  grades=00110

currentLevel=0  currentRefitExp=900
currentExpCurrentLevelOffset=900  currentExpNextLevelOffset=1000

list = {
    { itemId="109", ownNum=10, needNum=3, grade=2, category=108,
      resource="wim_steel",     displayName="id_datalist_Alloy_Steel" },
    { itemId="111", ownNum=18, needNum=3, grade=2, category=110,
      resource="wim_composite", displayName="id_datalist_Composites" },
}
```

要点：

- `plusGP` 是本次强化的金币花费（面板 `ui.refit_cost.Text = data.plusGP`）；抓包里每次强化
  gp 都是 `-3000`（121697 → 118697 → 115697 → 112697），与 `plusGP` 一致。
- `grades` 是十进制**位掩码**：位 i（从右往左，1 起）代表「等级 i 的武器可以当材料」。
  `personalInfo.lua:3898` 用 `arr={1,10,100,1000,10000,100000}` 从 i=6 递减解析，
  `00110` → 材料等级 {2,3}，随后被当作材料列表的 `grade` 过滤串 "3,2," 发给
  `storage_item_filter`。
- `fixReelNum=2` / `heirloomNum=1` 是“幸运齿轮 / 传承齿轮”的消耗数量，`own*Num` 是玩家持有量；
  持有量不足时客户端自动禁用对应勾选框。
- `currentExpCurrentLevelOffset` / `currentExpNextLevelOffset` 由「累计经验表」换算：
  grade3 到 1 级需要 1000，1→2 需要 1500。抓包实测 2150 经验 = 1 级 + 省内 1150，完全吻合。

## 结算规则（refit_finish）

`refit_finish` 的参数：`playerItemId`（被强化武器）、`materialItemId`（材料武器，整件消耗）、
`useFixReel`、`useHeirloom`（"Y"/"N"）。

每次成功强化：

```text
- 3000 金币
- 3 × 合金钢 (wim_steel)
- 3 × 复合材料 (wim_composite)
- 1 件材料武器（整件消耗，必须未装备）
- 可选 2 × 幸运齿轮 (intensify_luck，useFixReel=Y)
- 可选 1 × 传承齿轮 (intensify_translation，useHeirloom=Y)

support = grades[material.grade].exp
if useFixReel:                 support *= 2
if target.sid == material.sid: support *= 1.5
support += material.refitTotalExp * (useHeirloom ? 0.8 : 0.01)

newTotalExp = min(target.refitTotalExp + support, 满级总经验)
newLevel    = 由累计经验表换算
```

抓包数据验证（目标：sid=254 grade=3，材料等级 2/3）：

| 次 | 材料 grade | 结果 |
| --- | --- | --- |
| 1 | 2 | 0 → 300 |
| 2 | 2 | 300 → 600 |
| 3 | 2 | 600 → 900 |
| 4 | 3 | 900 → 2150（升级到 1 级，省内 1150） |

成功后官方会先推 2 次 `0x20` 的 `updatePlayer`，再回 `result=0`。

## 服务端实现

- `Clients/GameClient.Refit.cs`：三个 RPC 的处理、经验表、材料需求与结算。
- `Models/InventoryItem.cs`：新增 `RefitTotalExp` / `RefitLevel` / `PlusLevel`，随
  `item_json` 自动持久化。
- `Clients/GameClient.Inventory.cs`：背包列表下发真实的 `plusLevel` / `refitTotalExp` /
  `refitLevel`，并支持 `refitFilterItemId`（把被强化的武器从材料列表剔除）。
- `Clients/GameClient.Rpc.cs`：`tip_player_item` 下发真实的 `refitedNum` / `refitLevel` /
  `refitTotalExp` / `plusLevel`（`tip.lua:603` 用 `refitedNum` 显示强化等级角标）。
- `Persistence/PlayerStore.cs`：物品按 pid 定位/整件消耗/写入强化进度；一次性发放初始强化材料
  （标记 `starter_refit_materials_v1`，存在 `PlayerStateSnapshot.RewardFlags` 里）。
- `Resources/shop_config.json`：新增 `Item_refit_material` 分类，把 `wim_steel`(sid 109) 与
  `wim_composite`(sid 111) 做成可购买道具（subtype=100，和 `intensify_luck` 同一个商城分页）。

## 已知差异 / 未做

- 材料的“传承折算”没有按 `baseRank` 精确计算（服务端没有 baseRank 数据），只用
  等级相同/不同的两档近似；材料武器一般没有强化经验，影响很小。
- `grades` 掩码规则按“材料等级 ∈ [2, min(目标等级,5)]”推断（抓包样本只有 grade=3 目标 → {2,3}；
  等级 5 以上的材料没有经验数据，所以不开放）。
- `xOutPutMin/xOutPutMax` 与强化带来的属性成长没有实现（面板只显示，不影响流程）。

## 验证步骤

1. 重启服务端（会重新拷贝 `Resources/shop_config.json`）。
2. 客户端进大厅 → 角色 → 强化 → 第三个页签（强化武器）。
3. 选一把武器，右侧应显示 `合金钢 x/3`、`复合材料 y/3`、`3000` 金币花费。
4. 拖一件低等级武器到材料槽 → 点强化：
   - 金币 -3000，合金钢/复合材料各 -3，材料武器消失；
   - 武器 `refitTotalExp` 增长（等级 2 材料 +300，等级 3 材料 +1250）；
   - 达到阈值后等级 +1，物品列表与 tooltip 的强化等级角标同步更新。

## 补充说明（材料列表 / 错误码 / 初始材料）

- **材料列表的 grade 过滤**：客户端下发的 `grade` 是「逗号分隔 + 结尾逗号」（抓包里是 `"3,2,"`），
  和 `subType` 的 `"id,count;"` 形式不是一回事。早期实现直接复用了 `subType` 的解析器，只能取到
  `3`，导致 2 级材料武器被过滤掉；现在用 `ParseGradeFilterArg` 同时按 `;` 和 `,` 切分
  （`Clients/GameClient.Inventory.cs`）。
- **金币不足的错误码**：`refit_finish` 里唯一客户端无法预判的条件是金币，所以金币不够时回
  `error = "msgbox_common_conditionkey_128"`（`sys/moneyLessKey.lua` 里 gold 对应的键），
  客户端会弹「金币不足」提示并复位强化界面；材料不足仍旧回 `result=1`（客户端的
  `isEnough` 已经拦过一次）。满级误点回 `result=3`，客户端据此跳过刷新。
- **材料被消耗后的快捷栏**：材料武器整件消失后，若它还挂在快捷栏上会留下悬空 pid
  （`GetGameLoadoutItems` 会拿同 resource 的另一把武器顶上），`TryRemoveInventoryItemByPid`
  现在会同时摘掉这些快捷栏槽位。已装备（`isEquip="Y"`，快捷栏武器也是 Y）的武器依旧拒绝当材料。
- **初始材料**：首次进入时一次性发放（标记 `starter_refit_materials_v1`）
  99 合金钢 + 99 复合材料 + 10 幸运齿轮 + 10 传承齿轮，
  以及 3 件 2 级武器（`smg_02` / `sniperrifle_02` / `shotgun_02`）和 3 件 3 级武器
  （`smg_05` / `sniperrifle_05` / `shotgun_05`）——因为强化材料必须是 2/3 级武器，而新号初始武器
  全是 1 级，否则材料面板会是空的。这些都是商城 1 金币一把的道具，用完了可以继续买。
- **持久化**：物品的 `refitTotalExp` / `refitLevel` / `plusLevel` 随 `item_json` 存库，
  发放标记随 `PlayerStateSnapshot.RewardFlags` 存库，重启服务端不会重复发放。

## 补充说明（物品栏翻页 / 强化列表翻页 / 快捷栏等级）

- **物品栏按槽位容量分页**（`storage_storage_list` / `_no_empty`，`Clients/GameClient.Inventory.cs`）：
  仓库是「槽位网格」，客户端 `DealDepotList` 用 `dptDt[v.slot]` 索引页内图标
  （`weapon_p_1..weapon_p_{s}`），页数直接取服务端下发的 `pages`（`ui.pb_depot.PageCount`），
  所以页数由槽位容量决定。官方抓包 `storage_storage_list {t=2,s=24,p=1}` 回 `page=1 / pages=5`，
  即每个仓库固定 5 页：容量 = `s × 5`（t=2 → 120 格）；已用槽位超出容量（发放/扩容）时
  再按实际槽位扩容。同一个官方账号在局内 `storage` 里只带了 5 件物品却依旧报 `pages=5`，
  可确认页数来自容量而不是件数。空仓库同样报 5 页，否则新号的翻页条只有 1 页。
- **`slot` 是「绝对槽位 − 页偏移」**：过滤列表第 2 页能抓到 `slot = -1 / 0 / 4 / 16`
  （对应绝对槽位 11 / 12 / 16 / 28），仓库列表第 1 页正好是 1..24。仓库侧客户端用
  `ui["weapon_p_" .. v.slot]` 定位图标，所以每页的 `slot` 必须落在 1..`s`。
- **强化武器 / 材料列表按 `grade` 降序 → 槽位升序**（`storage_item_filter`，t=2），按件数分页：
  抓包 page1（29 件、`s=12` → `pages=3`）的顺序是槽位 1,2,3,10,13,18,19,20（3 级）→ 8,22（2 级）
  → 6,9（1 级）；材料列表（`grade="3,2,"`，9 件）同样是 7 件 3 级在前、2 件 2 级在后。
  道具/宝石列表（t=3，`s=36`）仍是槽位升序（抓包：槽位 22,23,24 的 1/2/2 级宝石按槽位下发），
  所以排序只在「t=2 且非仓库列表」时按 grade 优先。
- **快捷栏 `slot_get` 下发 `refitLevel`**：官方 `slot_get` 的武器条目带 `refitLevel`
  （`DealHotKeyList` 里 `ComFuc.ShowUpgradeLevel(v, v.type, hot_key_level_N, ...)` 用它画等级角标）。
  快捷栏快照（`HotKeySlot` / `HotKeySlotSnapshot`）新增 `RefitLevel` / `PlusLevel` /
  `RefitTotalExp`，下发时按 pid 读背包实物，因此强化成功后角标立即刷新。

- **列表下发 `baseRank`（装备评分）**：官方列表里每件装备都带 `baseRank`（1 级新手武器 270/300、
  2 级 300、3 级强化版 315、4 级 386，宝石 grade×6），客户端的「传承」加成预览会拿
  `menDt.baseRank` / `menDt2.baseRank` 比较（`personalInfo.lua:1893`），缺字段时 Lua 会拿 nil
  比数字直接抛错，所以 `GetStorageItems` 现在一并下发。服务端没有真实评分，`ResolveBaseRank()`
  按单位类型/品质给近似值，`ResolveRefitSupportExp` 的传承折算也用同一个函数，保证预览与结算一致
  （同品质：材料评分 ≥ 目标评分 → 全额继承，否则 `0.81 - 0.01×评分差`（下限 0.5）；不同品质 0.8；
  不勾传承 0.01）。

### 验证步骤（本轮）

1. 重启服务端。2. 大厅 → 角色 → 物品栏（仓库）：翻页条应是 5 页，第 1 页显示槽位 1..24 的物品，
   强化过的武器带等级角标。3. 强化 → 强化武器页签：列表按品质从高到低排列、可翻页（件数 > 12 时
   `pages` > 1）。4. 把强化过的武器拖到快捷栏（`slot_equip`）：快捷栏图标右上角出现等级角标。

## 强化等级带进局内（第 27 轮补充）

强化过的武器进局时，等级信息走 packet103 装备块里武器尾部的两个字节：`refitLevel`（强化等级）与
`grade`（品质）。`GameLoadoutItem` 新增 `RefitLevel`，由 `CreateHotKeyLoadoutItem` /
`CreateBattleLoadoutItem` 从背包实物读取，`WriteBasicWeaponEquipmentPayload`（subtype 1/2/4/10/11/12/14/16）
与 `WriteCompactGameEquipmentPayload`（subtype 6/13）写出。抓包证据、改动位置与验证步骤见
`docs/ingame-skill-release.md` 的「第 27 轮」。
