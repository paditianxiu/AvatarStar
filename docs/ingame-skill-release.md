# 局内技能释放协议（0x88 / 0x98 / 0x9B / 0xA0 / 0xA2 / 0xB9）

本文记录「把技能带到局内并真正释放」所需的封包链路，依据是台服（真实服务器）对局抓包
`log-2026-10-13.txt` 里 23:00:11~23:00:40 一段完整、成功释放技能的会话。

## 进局前的技能数据：packet103 的装备块

局内技能栏不是由 packet106 建立的，而是由 packet103（角色创建）里的**装备块**建立。
装备块结构：`int count` + count 条目：

```text
byte   slot        # 快捷栏槽位
byte   type        # 2=武器，1=职业技能
byte   sub/skillId # type=1 时是技能 id
int    resLen + string resource
int    dispLen + string display
float  cooldown    # 该技能当前等级的冷却
float  distance    # 该技能的作用距离
byte   usable      # 1=主动技能（可释放），0=被动
```

关键点：

- `usable` 必须按技能的主动/被动标记写。台服对被动技能（如突击的 piercing/poison）写 `0`。
- 技能 id `0`（护卫的 Battlefield Heal）是合法技能，任何 `skillId > 0` 的过滤都会把治疗丢掉。

## 释放流程（按台服抓包逐帧还原）

```text
client -> server  0x88 <slot>                     # 按下快捷栏，请求激活
server -> client  0xA0 0x40 <slot> 01 01          # 激活应答 packet160（立即）
server -> client  0xA2 00 <count> <castTime f32> 0x40 <slot> <abilityId> ...   # packet162（立即）
server -> client  0x9B 0x40 00 00 00 <abilityId> 00   # packet155：等 castTime 到了才发
client -> server  0x98 00 01 <slot> <12 bytes>    # packet152：需要落点的技能定位后释放
server -> client  0xB9 0x40 01 <packet152 的 13 字节 payload> 00*7   # packet185 广播（含自身）
```

台服时间线（同一名突击兵连续按 5 个技能）：

```text
23:00:24  client  88 00 04
23:00:24  server  A0 00 40 04 01 01
23:00:24  server  A2 00 01 01 80 0B 40 40 04 0F 00 00 00 A0 41 00 00 C0 40   # castTime≈2.18s
23:00:26  client  88 00 05
23:00:26  server  9B 00 40 00 00 00 0F 00      # ← 上一条技能（隐身 15）过了 2.18s 才生效
23:00:26  server  A0 00 40 05 01 01
23:00:26  server  A2 00 01 00 80 03 40 40 06 00 00 00 00 40   # castTime≈2.05s, buff 6
23:00:28  client  88 00 06
23:00:28  server  9B 00 40 00 00 00 06 00      # ← 上一条技能（冲刺 6）过了 2.05s 才生效
23:00:28  server  A0 00 40 06 01 01
23:00:28  client  98 00 01 06 65 E6 F1 00 48 14 DA 00 C8 00 74 FF
23:00:28  server  B9 00 40 01 01 06 65 E6 F1 00 48 14 DA 00 C8 00 74 FF 00 00 00 00 00 00 00
```

由此得到两条硬结论：

1. **packet155 是技能「生效」的那一步，而且它比 packet160/162 晚一个吟唱时间才发。**
   隐身（slot 4）的 castTime 2.18s、冲刺（slot 5）的 castTime 2.05s，与 packet155 的到达时间
   完全对应。服务端如果紧跟着 160/162 就发 155，客户端会把它当成「吟唱还没结束」的状态丢掉，
   表现就是「按技能没反应」。
2. **packet152 不是每个技能都发。** 需要落点的技能（地雷 slot 6）客户端会自己算好落点发
   `0x98`；自身增益（隐身、冲刺）不会发 152。台服对 152 只回 packet185，回包里没有 packet155。

## packet155 里的 id 是「局内能力（buff）」编号，不是槽位

台服抓包里每次技能生效都伴随 `9B 00 40 00 00 00 <id> 00`，其中 `<id>` **不是槽位，而是技能对应
的局内能力（buff）编号**：隐身=15、冲刺=6、陷阱=19、致命射击=16、毒穿刺=17。
这些编号可以从客户端资源 `AvatarStar_cache/buff/*.lua` 反推：每个 buff 文件绑定的图标/音效与
对应技能完全一致（`buff/15.lua` = latent.tga + cloakon，`buff/6.lua` = spurt.tga，
`buff/19.lua` = snare.tga，`buff/16.lua` = piercing.tga，`buff/17.lua` = POISON.tga）。
技能自己的 `skill/<resource>.lua` 只放施法特效（例如 `skill/snare.lua` 只有 trap 音效），
所以「按技能没反应」时先看 155 有没有按对 buff 编号、有没有在吟唱结束后发出去。

## packet162 的效果帧结构（已解出）

```text
A2 00 | count=1 | float castTime | 0x40 | byte slot | uint16 buffId | float...（技能附加参数）
```

例（隐身 skillId=2，槽位 4）：`A2 00 01 01 80 0B 40 40 04 0F 00 | 00 00 A0 41 00 00 C0 40`
即 castTime 约 2.18s、slot=4、buffId=15、附加参数 20.0f / 6.0f。
台服对陷阱（snare）根本没有发 packet162，说明 162 只影响表现，不是释放的必要条件；地雷靠
packet152/185 走落点。

## 技能到局内能力（buff）编号表

| 职业 | 技能 id / 名称 | buff |
| --- | --- | --- |
| 护卫 | 0 Battlefield Heal | 0 |
| 护卫 | 3 Shockwave | 4 |
| 护卫 | 6 Achilles Heel（被动） | 13 |
| 护卫 | 9 Arrow Shower | 3 |
| 护卫 | 14 Healing Beacon | 1 |
| 护卫 | 76 宿怨（被动） | 128 |
| 重装 | 1 Shield | 8 |
| 重装 | 4 Haste | 9 |
| 重装 | 7 Perseverance（被动） | 12 |
| 重装 | 10 Blitzkrieg（被动） | 11 |
| 重装 | 12 Damage Converter（被动） | 10 |
| 突击 | 2 Stealth | 15 |
| 突击 | 5 Fatal Shot（被动） | 16 |
| 突击 | 8 Poison Pierce（被动） | 17 |
| 突击 | 11 Deadly Sprint | 6 |
| 突击 | 13 Trap | 19 |
| 生化 | 38 生命传导 | 61 |
| 生化 | 39 生命抽取 | 72 |
| 生化 | 40 瘟疫传播 | 71 |
| 生化 | 41 毒气弹 | 70 |
| 生化 | 42 过激反应 | 68 |

生化专家的 buff 编号是从图标反推的近似值，尚未在真实服务器抓包中确认。

## 服务端实现位置

- `PracticeRoomChannelProtocol.HandlePacket136GameSkillActivateAsync`：回 packet160 → 回 packet162 →
  按该技能 162 帧里的 castTime 预约 packet155（`ScheduleSkillAbilityOpen`）。没有 162 帧的技能
  （地雷等落点技能）立刻发 155。
- `PracticeRoomChannelProtocol.HandlePacket152GameSkillCastAsync`：只把客户端 payload 用 packet185
  广播给房间内所有连接（含自己），不再补发 155。
- `SendPacket162SkillEffectOpenAsync`：用台服抓到的帧模板回放，只替换里面的槽位字节。

## 抓包开关 / 自检日志

- `AS_GAME_DUMP_PACKETS=1`：记录 9532（大厅/游戏连接）原始封包。
- `AS_CHANNEL_DUMP_PACKETS=1`：记录 9533（房间/channel 连接）原始封包；局内技能包走这条连接。
- 技能激活时服务端会打印一行可核对的信息：

```text
Channel packet136 <- ...: slot=4 activated (skillId=2,...); skillId=2 buffId=15
  packet160 ack sent, packet162 effectOpen=True, packet155 abilityOpen=True castSeconds=2.1796875, peerBroadcastCount=0
```

- 技能生效（跟台服一样晚一个吟唱时间）时会打印：

```text
Channel packet155 -> ...: ability state id=15 trigger=packet136-ability
```

- 客户端发出落点释放时会打印：

```text
Channel packet152 <- ...: skill release slot=6 (...) buffId=19 payloadBytes=13 hex=0106...; packet185 relayed to 1 channel(s)
```

## 对局初始化与移动回显（第 12 轮修复）

重新比对台服抓包后确认：技能包的形状早就对了，真正卡住的是**对局初始化 + 移动回显**。

1. **packet110 必须回显给发送者本人**
   台服里客户端每发一条带位移的 `0x69`（packet105），服务端都会把同一份 payload
   前面加一个 uid 字节原样回给发送者（`0x6E <uid> <tick> <flags> <payload...>`）。
   实测：该会话客户端发 130 条 105，服务端回 43 条 110，差额正好是 87 条
   `69 XX 00`（flags=0 的纯心跳）—— 也就是 **flags=0 的心跳不回显**。
   本地服务端以前只广播给「其它玩家」，自己永远收不到回显，客户端移动 tick 便一直停在
   2/3 反复重发，局内状态机走不完，技能自然没表现。

2. **packet160 / 155 / 185 的第二个字节是「玩家 uid」，不是固定值 0x40**
   台服那一局里该玩家 uid 恰好是 0x40，之前把它当常量写死了。本地 uid 是 1，
   客户端收到 `A0 00 40 <slot> 01 01` 与自己 uid 对不上，激活应答被丢弃 → 按技能没反应。
   现在统一写 `_localGameUid`。

3. **补上零售服务端的对局初始化帧**
   `106` 之后台服还会发 `146`（战斗状态）、`231`（比赛计时，每秒一条 float 秒数）、
   `165`（战斗标志），之后才发 `111` 出生包。

4. **packet157（加载完成）要回 packet151**
   台服：`client 0x9D` → `server 0x97 00 00 00 00`（清除进入遮罩）。以前 157 只打日志不回包。

改动：`PracticeRooms/PracticeRoomChannelProtocol.cs`、`PracticeRooms/PracticeRoomManager.cs`。
## 隐身/冲刺无效果：packet162 里的施法者 uid 没换成自己的（第 13 轮修复）

> 已被后面的结论推翻：真正原因是
> packet155 被当成「开技能」用了，见文末「第 15 轮」。



用户反馈：技能已经能释放，但隐身、冲刺没有实际效果，地雷（陷阱）正常。

对照台服抓包，三者走的是不同链路：

```text
地雷（slot 6）： 160 →（无 162）→ 客户端自己发 152 → 服务器回 185   ← 有效果
隐身/冲刺：      160 → 162 → 等 castTime 到点再发 155               ← 没有效果
```

关键：**packet162 里也带「施法者 uid」**。台服那一局该玩家的 uid 恰好是 `0x40`，
所以抓到的帧第 8 个字节是 `40`：

```text
A2 00 01 01 80 0B 40 40 04 0F 00 00 00 A0 41 00 00 C0 40   # 隐身 slot 4 buff 15
A2 00 01 00 80 03 40 40 06 00 00 00 00 40                   # 冲刺 slot 5 buff 6
       [castTime]  uid  ^
                        +-- 这一字节：隐身帧里是槽位 04；冲刺帧里放的是 spurt 的 buff 号 06
```

本地 uid 是 `1`，而回放模板时只替换了槽位字节、没换 uid → 客户端收到 `A0/A2 ... 40 ...`
与自身 uid 对不上，把 packet162 丢掉，技能就变成「有动作没效果」。地雷不需要 162，
所以不受影响，这正是它能生效的原因。

修复（`PracticeRooms/PracticeRoomChannelProtocol.cs`）：

- `CapturedSkillEffectFrames` 改为记录 `Template` + 抓包时的槽位 + 抓包时的 buff 号。
- 回放前先写 `frame[7] = _localGameUid`（uid 字节）。
- 只有当抓包帧里确实存放槽位/buff 时才改写该字节（冲刺那帧第 9 字节是 buff 6，
  硬按槽位改会写坏），其余字节原样回放。

预期日志（服务端）：

```text
Channel packet162 -> ...: skill effect open skillId=11 slot=5 trigger=packet136-local hex=A200010080034001060000000040
Channel packet155 -> ...: ability state id=6 trigger=packet136-ability
```

客户端「局内接收封包」应能看到同一串 hex，然后隐身/冲刺才真正生效。

## 第 14 轮：隐身/冲刺「有动作没效果」的真正原因——吟唱被下一个技能打断

> 已被第 15 轮推翻：吟唱只是巧合，真正原因是
> packet155 是关技能。见文末「第 15 轮」。


### 一、技能包本身没有问题

把台服抓包与本地抓包逐条对齐（台服 `log-2026-10-13.txt` 23:00:24~23:00:32，本地
`log-2026-10-14.txt` 11:18:00~11:18:03），技能链路上的字节完全一致，只有玩家局内 uid
不同（台服那局是 0x40，本地是 0x01）：

```text
按键      台服                                          本地
slot 4    A0 00 40 04 01 01 / A2 ... 40 40 04 0F ...   A0 00 01 04 01 01 / A2 ... 01 04 0F ...
slot 5    A0 00 40 05 01 01 / A2 ... 40 40 06 00 ...   A0 00 01 05 01 01 / A2 ... 01 06 00 ...
slot 6    A0 00 40 06 01 01 / B9 00 40 01 01 06 ...     A0 00 01 06 01 01 / B9 00 01 01 06 ...
155       9B 00 40 00 00 00 0F 00（隐身）                 9B 00 01 00 00 00 0F 00（隐身）
          9B 00 40 00 00 00 06 00（冲刺）                 9B 00 01 00 00 00 06 00（冲刺）
```

所以第 13 轮把 uid 当成原因是不成立的：这一轮的本地抓包里 uid 已经全部换成 0x01，
隐身、冲刺依然没效果，问题不在这些字节。

### 二、真正的差别是按键节奏

```text
台服：23:00:24 按 slot 4，23:00:26 按 slot 5，23:00:28 按 slot 6   ← 间隔 2.0s / 2.0s
本地：11:18:00 按 slot 4，11:18:01 按 slot 5，11:18:01 按 slot 6   ← 间隔 1.0s / 0.5s
```

packet162 里紧跟 opcode 的那个 float 是吟唱（chant）时间，由服务端下发：

- 隐身 slot 4：`01 80 0B 40` = 2.1796877s
- 冲刺 slot 5：`00 80 03 40` = 2.0546875s
- 这两个值与技能文本对得上（隐身 mode5 冷却 13s、持续 20s、被察觉 6m；
  冲刺 mode5 加速 3s），帧尾的 20.0 / 6.0 就是持续时间和被察觉距离。

客户端收到 packet162 后要吟唱这么久，吟唱没走完再按下一个快捷栏会打断前一个技能，
于是隐身/冲刺只有起手动作、没有实际效果。地雷（陷阱）走 0x98 / 0xB9 链路，没有 packet162、
吟唱 0 秒，按下去立刻生效——这就是它唯一正常的技能。

### 三、修复（PracticeRooms/PracticeRoomChannelProtocol.cs）

吟唱时间既然是服务端下发的，服务端就能改：

- 新增 `UseCapturedSkillEffectCastTime` / `GameSkillEffectCastTimeSeconds`（默认 0.3s）。
- `SendPacket162SkillEffectOpenAsync` 覆写帧内 offset 3 的吟唱 float。
- `ResolveSkillEffectCastTimeSeconds` 返回同一个值，保证 packet155 的开技时刻与 162 一致。

想恢复台服手感，把 `UseCapturedSkillEffectCastTime` 改成 true（那时必须等吟唱走完，连按会打断）。

### 四、复现验证

1. 重启服务端、进局。
2. 只按一个技能（例如隐身），等 3 秒：应看到人物半透明/隐身约 20 秒。
3. 再单独按冲刺：移动速度应有变化。
4. 服务端日志应看到：

```text
Channel packet136 <- ...: slot=4 activated (skillId=2,level=5,res=latent,...); buffId=15 packet162 effectOpen=True, packet155 abilityOpen=True castSeconds=0.3
Channel packet162 -> ...: skill effect open skillId=2 slot=4 trigger=packet136-local hex=A200019A99993E01040F000000A0410000C040
Channel packet155 -> ...: ability state id=15 trigger=packet136-ability
```

## 第 15 轮：隐身/冲刺没效果的真正原因——packet155 是「关技能」，不是「开技能」

第 13、14 轮的结论都不成立（第 13 轮的 uid 假设已被第 14 轮推翻，第 14 轮的「吟唱被打断」是巧合）。
重新比对台服抓包 `log-2026-10-13.txt`，有三条互相印证的证据说明 `0x9B`（packet155）是**关闭**
局内能力状态，而 `0xA2`（packet162）才是**开启**：

1. **一一配对**：23:00:21 按快捷栏 13/14 时服务端发了 3 个 packet162（能力 17、25 来自槽位 13，
   能力 16 来自槽位 14）；23:00:32 离开对局时服务端正好发了 3 个 packet155（16、17、25），
   数量和编号完全对应。如果 155 是「开技能」，离开对局时开三个技能无法解释。
2. **顺序**：按槽位 5（23:00:26）时 `9B 00 40 00 00 00 0F 00`（关隐身 15）排在
   `A0 00 40 05 01 01` **之前**；按槽位 6（23:00:28）时 `9B ... 06 00`（关冲刺 6）排在
   `A0 00 40 06 01 01` 之前。这正是服务端「先关掉上一个技能，再应答新技能」的顺序。
3. **参数不对称**：packet162 带完整参数（隐身的 20.0s 持续、6m 察觉距离），packet155 只带一个
   能力编号。开启一个能力需要参数，关闭只需要编号。

所以服务端在 packet136 之后立刻回 packet155，等于「刚被 packet162 打开的能力马上又被关掉」：
客户端会播起手动作（`skill/latent.lua` 的 `skill_13_cast_effect`），但状态立刻消失，表现就是
「有动作没效果」。地雷（陷阱）没有 packet162、也就没有能力状态可关，所以它一直是好的。

### 修复

`PracticeRooms/PracticeRoomChannelProtocol.cs`：

- packet162 打开的能力编号记入 `_openSkillAbilityIds`；下一次按快捷栏（packet136）时先用
  `CloseOpenSkillAbilitiesAsync` 发 packet155 关掉它们，再回 packet160/162，顺序与台服一致。
- 默认模式下**不再**在激活后紧跟 packet155；只有「没有 packet162 帧的技能」（地雷这类落点技能）
  保持原来的回复行为。
- packet162 帧恢复逐字节回放（只替换施法者 uid），不再改帧内的时间字段。
- 行为开关（改完重启服务端即可，不必重新编译）：

```text
AS_SKILL_ABILITY_MODE=cancel   默认。packet162 开技能，packet155 只关「上一个」技能（台服行为）
AS_SKILL_ABILITY_MODE=cast     第 14 轮行为：按 packet162 帧内时间延迟发 packet155
AS_SKILL_ABILITY_MODE=instant  第 12/13 轮行为：紧跟 packet160/162 就发 packet155
AS_SKILL_ABILITY_MODE=off      激活时完全不发 packet155
```

### 复现验证

1. 重启服务端进局，只按一次隐身（不要连按别的技能）：应很快半透明隐身并保持（约 20 秒的上限由
   客户端按帧内参数自己算）。此时服务端日志应为

```text
Channel packet136 <- ...: slot=4 activated (skillId=2,level=5,res=latent,...); skillId=2 buffId=15 mode=Cancel
  packet160 ack sent, packet162 effectOpen=True, closedAbilities=0, packet155 abilityStateReply=False replyDelaySeconds=0, peerBroadcastCount=0
Channel packet162 -> ...: skill effect open skillId=2 slot=4 trigger=packet136-local hex=A2000101800B4040040F000000A0410000C040
```

   而且**不再**有紧跟着的 `Channel packet155 -> ...: ability state id=15`；客户端「局内接收封包」
   里应能看到 `A2 ...` 而看不到 `9B 00 ... 0F 00`。
2. 再按冲刺：服务端先关掉隐身（packet155 id=15），再发槽位 5 的 packet160/162，冲刺生效。
3. 按地雷：packet155 只用来关掉上一个技能，地雷本身照旧走 `0x98` / `0xB9` 链路。

如果第 1 步隐身仍不出现，说明该端语义与台服不同：把 `AS_SKILL_ABILITY_MODE` 依次改成 `instant`、
`cast` 各试一次，并保留客户端 `log-*.txt` 与服务端日志，就能确定该端的实际含义。

## 第 16 轮：packet162 里「施法者/目标」两个身份字节都要换成自己的 uid

第 15 轮的结论（0x9B 关、0xA2 开）保留，但那一轮之后没有来得及实测，本轮补上第 13 轮
没做完的部分。

重新把台服 5 个 packet162 帧摆在一起看，帧里**有两个相邻的身份字节**，在那一局里都是 `0x40`
（该局玩家 uid 恰好是 `0x40`）：

```text
槽位13 能力17   A2 00 01 00 00 0B 40 40 0D 11 00
槽位14 能力16   A2 00 01 00 00 0B 40 40 0E 10 00
槽位 4 隐身15   A2 00 01 01 80 0B 40 40 04 0F 00 00 00 A0 41 00 00 C0 40
槽位 5 冲刺 6   A2 00 01 00 80 03 40 40 06 00 00 00 00 40
                            ^^^^^
                            两个身份字节（施法者 / 目标，自我增益时是同一个玩家）
```

这两个字节不是巧合：packet162 和本文件里已经在写的 113/184（远程开枪 / 远程受击）属于同一套
“远程对象 delta”结构 ——`<delta flags u32> <actor uid> <target uid> ...`。把 5 个抓包帧的前 4 字节
读成大端 u32：

```text
隐身 15   01 01 80 0B = 0x0101800B   低位 0x0B = bit0(actor uid) + bit1(target uid) + bit3(action)
冲刺  6   01 00 80 03 = 0x01008003   低位 0x03 = bit0(actor uid) + bit1(target uid)
能力17    01 00 00 0B = 0x0100000B   低位 0x0B = bit0 + bit1 + bit3
能力16    01 00 00 0B = 0x0100000B   同上
```

`bit0 = GameObjectDeltaActorUidFlag`、`bit1 = GameObjectDeltaTargetUidFlag`，正是这两个标志位让
**两个 uid 字节**跟在后面；自我增益时施法者 == 目标，所以两字节相同（那一局 uid = `0x40`）。

本地 uid = `0x01`，第 13 轮只替换了**后一个**（offset 7），前一个（offset 6）仍是抓包里的 `0x40`：
客户端拿 `0x40` 去自己的玩家表里找不到施法者，整帧被丢掉 → 快捷栏起手动作照放，但隐身/冲刺
不生效，地雷走 0x98/0xB9 链路所以一直正常。

本轮改动（`PracticeRooms/PracticeRoomChannelProtocol.cs`）：

- `GameSkillEffectOpenCasterUidOffset = 6`、`GameSkillEffectOpenTargetUidOffset = 7`，两个身份字节
  都写成 `_localGameUid`；其余字节逐字节回放（含 parameter float）。
- 开关 `AS_SKILL_UID_MODE=both|actor|target|none`（默认 `both`）：只改第一个 / 只改第二个 /
  一个都不改，用来在不开编译器的情况下对比。服务端日志会打印本次用的模式：

```text
Channel packet162 -> ...: skill effect open skillId=2 slot=4 trigger=packet136-local uidMode=Both hex=A2000101800B4001040F000000A0410000C040
```

- packet103 装备块里技能项的「距离」字段当时写死成 `0.0`：台服对隐身(13.0/0.0)、冲刺(21.0/0.0)、
  陷阱(25.0/0.0) 报的都是 0，本地以前按技能表写了隐身 6.0。第 17 轮改成写技能表里的真实距离
  （突击技能表本身没有距离，所以那一侧的数值不变）。
- `SendPayloadAsync` 兜住 `ObjectDisposedException`：延迟发包（packet155 ability state、
  进入遮罩重试、HUD 刷新）撞上已关闭的 socket 时直接把连接标记为断开，不再刷
  `Channel packet155 ... failed` 的 WRN 堆栈。

### 复现验证

1. 重新编译并**重启**服务端（`dotnet build src/AvatarStar.sln`），进房间。
2. 只按一次隐身（快捷栏 4），不要连按其它技能。客户端「局内接收封包」应看到
   `A2 00 01 01 80 0B 40 01 04 0F ...`（注意第 8 字节是本地 uid，不是 0x40），人物应半透明隐身。
3. 再按冲刺（快捷栏 5）：服务端先发 `9B 00 01 00 00 00 0F 00` 关掉隐身，再发槽位 5 的 160/162。
4. 若隐身仍无效果，按顺序做单变量实验（每次只改一个环境变量、重启服务端）：

```powershell
$env:AS_SKILL_UID_MODE="target"   # 退回第 15 轮行为：只改 offset 7
$env:AS_SKILL_UID_MODE="actor"    # 只改 offset 6
$env:AS_SKILL_UID_MODE="none"     # 两个身份字节都保持抓包里的 0x40
```

   哪一种能让隐身出现，就把它定为默认值（改 `DefaultSkillEffectUidMode`）。
## 第 17 轮：护卫兵局内技能（技能 0/6/9 的 packet162 帧 + 装备块距离）

依据：护卫兵的真实服务器抓包 `log-2026-10-14.txt`（12:50:11~12:50:31，该局 uid=0x40）。
该玩家把技能摆在快捷栏 4/5/6/7/13，逐次按下：

```text
12:50:18  client  88 00 0D                    # 13 = Achilles Heel（vitals，被动）
12:50:18  server  A0 00 40 0D 01 01
12:50:18  server  A2 00 01 00 00 0B 40 40 0D 0D 00        # 能力 13
12:50:19  client  88 00 04                    # 4 = Battlefield Heal（cure）
12:50:19  server  A0 00 40 04 01 01
12:50:19  server  A2 00 01 00 00 0B 40 40 04 00 00        # 能力 0
12:50:20  client  88 00 05                    # 5 = Shockwave（shock）
12:50:20  server  A0 00 40 05 01 01                        # 只有 A0，没有 A2
12:50:22  client  88 00 06                    # 6 = Arrow Shower（rain）
12:50:22  server  A0 00 40 06 01 01
12:50:22  server  A2 00 01 00 00 13 40 40 02 03 00        # 能力 3
12:50:22  client  78 00 02 / 6A ... / 8F / 75 / 8F          # 客户端连发两轮「射击」（0x6A）
12:50:22  server  80 00 40 02 / 71 ... / B0 ... / 9B 00 40 00 00 00 03 00 / 71 ... / B0 ...
12:50:23  client  88 00 07                    # 7 = Healing Beacon（energy）
12:50:24  server  A0 00 40 07 01 01
12:50:24  client  98 00 01 07 ...（落点释放）
12:50:24  server  B9 00 40 02 01 07 ...（广播）
```

结论：

- 护卫 5 个技能里只有 3 个带 packet162：Battlefield Heal（能力 0）、Achilles Heel（能力 13）、
  Arrow Shower（能力 3）。Shockwave 只有 A0（冲击波特效由客户端本地播），Healing Beacon 和突击的
  地雷一样走 `0x98`/`0xB9` 落点链路。
- 护卫帧里 offset 8 那个字节**不一定等于快捷栏槽位**：Arrow Shower 那一帧写的是 `02`（按下的是槽位
  6），和突击冲刺帧写 `06` 是同一种情况，所以回放时按抓包原样保留、不改写。
- 护卫的能力都不会「被下一次按键替换」：抓包里能力 0 和 13 一直开着，Arrow Shower 的能力 3 是在
  两轮箭雨后由 cast 状态关掉的（`9B ... 03 00`），不是下一次激活时关。所以
  `CloseOpenSkillAbilitiesAsync` 现在只关闭「真实抓包里确实会被替换」的能力（隐身 15、冲刺 6，见
  `CapturedSkillEffectFrame.ClosedOnReplace`），避免把护卫刚打开的治疗/被动效果立刻关掉。
- 装备块的距离字段不是常量 0：护卫抓包里 Battlefield Heal 8.0、Shockwave 6.0、Arrow Shower 0.0、
  Healing Beacon 5.0、Achilles Heel 0.0，与技能表一致；突击那边是 0.0，因为突击技能表本身没有距离。
  第 16 轮写死 0.0 会把护卫这三个带射程的技能一起清零，本轮改成写技能表里的真实距离。

本轮改动：

- `Models/SkillCatalog.cs`：Achilles Heel 的 BuffId `5` → `13`（`buff/13.lua` = VITALS.tga）；
  突击 Stealth 去掉 `Distances`（台服装备块报 0.0）。
- `PracticeRooms/PracticeRoomChannelProtocol.cs`：
  - `CapturedSkillEffectFrames` 增加护卫 3 帧（技能 0 / 6 / 9）。
  - `WriteGameSkillEquipmentEntry` 写 `definition.ResolveDistance(level)` 而不是常量 0。
  - `CapturedSkillEffectFrame` 增加 `ClosedOnReplace`，`HandlePacket136GameSkillActivateAsync` 只把
    这类能力放进「下次激活时关闭」的集合。

### 复现验证

1. 重新编译并重启服务端，用**护卫兵**进房（技能应落在快捷栏 4/5/6/7）。
2. 按 4（Battlefield Heal）：客户端应看到 `A2 00 01 00 00 0B 40 01 04 00 00`（两个身份字节都是本地
   uid），并出现治疗特效。
3. 按 5（Shockwave）：只有 `A0 00 01 05 01 01`，特效是本地施法特效（台服也没有 162）。
4. 按 6（Arrow Shower）：应看到能力 3 的 A2；之后客户端自己发 `0x6A`，服务端回 `0x71`（113），
   箭雨才会在落点出现。
5. 按 7（Healing Beacon）：客户端发 `0x98`，服务端回 `0xB9`（和地雷同一条链路）。
6. 若 Shockwave 仍无表现，用 `$env:AS_SKILL_ABILITY_MODE="off"` 重启再试（本地对没有 162 帧的技能
   会多回一条 `9B ... 04 00`，台服没有）；若箭雨的效果一直不结束，用
  `$env:AS_SKILL_ABILITY_MODE="cast"` 试（按 162 帧里的 castTime 关掉能力 3）。

## 第 18 轮：箭雨按技能等级放箭 + 活力振荡器不再变成地雷

第 17 轮把护卫三个技能送进局内后还剩两个表现问题：箭雨只放固定几支箭（不随等级），活力振荡器
（Healing Beacon）落点后生出来的是突击地雷的模型。两者都能从台服抓包 + 客户端自带文本表定死。

### 一、箭雨：packet162 帧里 offset 8 那个字节是「箭矢数」

护卫的 Arrow Shower 帧是 `A2 00 01 00 00 13 40 40 02 03 00`，其中 `40 40` 后面第一字节是 `02`；
第 17 轮只是「原样回放、不改写」，所以**任何等级都发 2**。

客户端自带的 `AvatarStar_cache/scripts/game_text.lua` 把箭矢数写在能力模式文案里：

```text
tips_abilities_Arrow_Shower_mode1 = "箭矢数：2。\n冷却时间：12秒。"
tips_abilities_Arrow_Shower_mode2 = "箭矢数：3。..."
tips_abilities_Arrow_Shower_mode3 = "箭矢数：4。..."
tips_abilities_Arrow_Shower_mode4 = "箭矢数：5。..."
tips_abilities_Arrow_Shower_mode5 = "箭矢数：6。..."
tips_abilities_Arrow_Shower_mode6 = "箭矢数：9。\n冷却时间：5秒。"
```

抓包那次是模式 1 的箭雨 → 帧里就是 `02`，和文案一一对应；也就是说这一字节是「这一发要射几支
箭」，由服务端按等级算好告诉客户端（客户端自己一支一箭发 `0x6A`，服务端再广播 `0x71`/113）。

本机角色（`game_player_profiles.snapshot_json` → `players[1]`，护卫 HUWEI）的 `skillLevels` 是
`{"0":5,"3":5,"9":4,"14":1}`，箭雨 = **4 级** → 模式 4 → **5 支箭**；上一轮固定发 2 支，所以看起来
「不按等级」。

### 二、活力振荡器变成地雷：packet185 的帧是「每个技能一套」

台服两条 `0xB9` 放一起对比（`0x40` = 台服 uid）：

```text
突击地雷（技能 13，快捷栏 6）: B9 00 40 01 01 06 <12 字节落点> 00 00 00 00 00 00 00
护卫活力振荡器（技能 14，快捷栏 7）: B9 00 40 02 01 07 <12 字节落点> B8 0B 00 00 00 00 00
```

`B9 00 <uid>` 之后那个字节（地雷 `01`、振荡器 `02`）就是客户端拿来判断「生成什么物件」的类型
字节，末尾 7 字节里的 u32 是能力参数：振荡器 3000 正好等于
`tips_abilities_Healing_Beacon_mode1 = "...治疗总量：3000点生命值..."`，而地雷没有参数（全 0）。

上一轮把地雷那一套常量（类型 1 + 全 0）套在**所有**落点技能上，所以振荡器按地雷生成。本机角色
的振荡器是 **1 级**（`skillLevels["14"] = 1`），刚好对上抓包那一帧的模式 1（3000）。

### 修复（PracticeRooms/PracticeRoomChannelProtocol.cs、PracticeRooms/PracticeRoomManager.cs）

- `CapturedSkillEffectFrame` 增加 `VolleyCounts`（按等级索引的箭矢数），箭雨帧填
  `[2, 3, 4, 5, 6, 9]`；`SendPacket162SkillEffectOpenAsync` 多收一个 `level`，
  帧里 offset 8 改成按等级算出的箭矢数（未加点的技能退回模式 1 的 2 支）。
- 新增 `CapturedSkillCastFrame`（类型字节 + 按等级索引的参数）与 `CapturedSkillCastFrames`：
  地雷 `[13] = (1, 无参数)`、活力振荡器 `[14] = (2, 3000/4000/5000/6000/8000)`。
- `HandlePacket152GameSkillCastAsync` 现在把落点技能 id 与等级一起交给
  `BroadcastGameSkillCastAsync` → `SendPacket185GameSkillCastAsync(uid, payload, skillId, level, ...)`，
  packet185 帧头字节和末尾 u32 按技能表写，落点 payload 仍是客户端原样。
- 日志：`packet136` 打 `level=`，`packet152` 打 `skillId=/level=`，`packet185` 打
  `kind=/parameter=`，便于直接核对帧内容。

### 复现验证

1. 重新编译并重启服务端，用护卫兵进房，按 6（箭雨）：packet162 日志里 `hex=` 应是
   `A20001000013<uid><uid>050300`（箭雨 4 级 → 5 支箭），客户端随后连发多条 `0x6A`，服务端各回一次
   `0x71`。
2. 按 7（活力振荡器）：packet185 日志应是 `kind=2 parameter=3000`，抓包帧形如
   `B9 00 <uid> 02 01 07 <落点> B8 0B 00 00 00 00 00`，落点里出现的是振荡器而不是地雷。
3. 突击兵回归：按 6（地雷）时 packet185 仍是 `kind=1 parameter=0`，帧与第 17 轮逐字节一致。

### 尚未实现（后续轮次）

- 开枪链路（`HandlePacket106GameActionPoseAsync` → packet113）本轮未改。台服每广播一次 113 就跟着
  一条 `B0 00 40 0C 00 00 00 00`（packet176），两轮箭雨之后还有 `AF 00 03`（packet175），本地目前
  不发这两条，而且 113 只发给房间内其它连接、不含施法者自己（台服会回给施法者）。
- 台服在离开对局时会用 155 关掉仍然开着的能力（突击抓包 23:00:32 关了 16/17/19），本地还没有这一
  步（`CloseOpenSkillAbilitiesAsync` 只在按技能时调用）。
- 装备块距离现在按技能表写：护卫（有抓包）与突击（0）都对得上，重装/生化还没有抓包核对；若那两
  个职业进局内后技能不可点，先怀疑 `SkillCatalog` 里的 `Distances` 与台服不一致。

## 第 19 轮：把技能同步给房间内的其他玩家

第 18 轮之前，技能只对**施法者自己**生效：台服是把一次技能释放拆成三条包广播给全房间，本地只回给
了施法者（或干脆没回），所以队友看不到任何效果。三条包各自负责一部分表现：

- **packet160**（`A0 00 <uid> <slot> 01 01`）：快捷栏高亮 / 动作起手，第 17 轮起已转发。
- **packet162**（`A2 00 <flags> <actor uid> <target uid> <param> <abilityId> ...`）：**真正打开能力**
  的那一帧。隐身 / 冲刺 / 治疗这类自增益只有收到它才会在身上出现光环、隐身与移动加成；队友没收到
  这一帧，所以「自己看得到、别人看不到」。第 18 轮只发了本地这一份。
- **packet155**（`9B 00 <uid> 00 00 00 <abilityId> 00`）：**关闭**能力状态。队友用 162 打开能力后，
  必须再收到一条对应 abilityId 的 155 才会让光环消失，否则队友那边会一直挂着施法者的隐身/冲刺。

### packet162 的两个身份字节必须写「施法者的 uid」

162 帧是「远端物件增量」格式，`flags` 的低位（0x01 actor / 0x02 target）决定紧跟的两个 uid 字节：
自增益的 actor == target。台服抓包时 uid 是 `0x40`，两个字节都是 `0x40`。

给**队友**转发时，这两个字节要写**施法者**的 uid（不是收包者自己的 uid）——写错了会把隐身/光环套到
队友自己身上。所以本地这一份和转发给队友那一份用两个不同的发送函数：

- `SendPacket162SkillEffectOpenAsync(...)`：本地用，两个字节覆盖成 `_localGameUid`。
- `SendPacket162RemoteSkillEffectOpenAsync(skillId, actorUid, slot, buffId, level, trigger)`：转发用，
  两个字节都写 `actorUid`（施法者）。技能没有 162 帧（地雷、振荡器这类落点技能）时返回 `false`，直接跳过。

### 落点技能（地雷 / 活力振荡器）本来就会同步

落点技能走 `packet152 -> packet185` 转发，`BroadcastGameSkillCastAsync` 本来就是发给全房间（含施法者），
所以第 18 轮已经把它们的表现同步了。本轮只是把 packet162 / packet155 补齐，让**自增益**也能同步。

### 修改（PracticeRooms/PracticeRoomChannelProtocol.cs、PracticeRooms/PracticeRoomManager.cs）

- `BroadcastGameSkillActivateAsync` 增加 `skillId / buffId / skillLevel` 三个参数：发完 packet160 后，
  若 `buffId >= 0` 就接着用 `SendPacket162RemoteSkillEffectOpenAsync` 把 162 帧转发给队友
  （`buffId >= 0` 而不是 `> 0`，因为护卫的治疗就是能力 0；武器/空槽位的 `buffId` 是 -1，直接跳过）。
- 新增 `BroadcastGameSkillCastStateAsync(roomId, source, actorUid, abilityId, trigger)`：把 packet155
  状态转发给队友（和 `BroadcastGameSkillCastAsync` 一样跳过 source，因为施法者本地已经先发过自己的）。
- `SendPacket155SkillCastStateAsync` 增加 `actorUid` 参数并写进包首（原来是写死本地 uid），
  这样队友收到的 155 指向的正是被 162 打开的那个**施法者**的能力。
- `CloseOpenSkillAbilitiesAsync` / `RunSkillAbilityOpenAsync` 在给本地发 155 之后，调用
  `BroadcastSkillCastStateToPeersAsync` 把同一条 155 转发给队友。这样两种关闭时机（按下别的快捷栏
  替换、落点技能的状态回包）都会同步。

### 复现验证（双开两个客户端进同一个房间）

1. 重新编译并重启服务端。
2. A 选突击兵，B 看 A 的屏幕：A 按隐身（4）时 B 应看到 A 变半透明 / 消失，A 再按别的技能时 B 那边
   的光环随之消失；A 按冲刺（5）时 B 看到 A 提速。
3. 换护卫兵：A 按治疗（4）、振荡器（7）时 B 都能看到落点与治疗特效；A 按箭雨（6）时 B 也看到箭雨。
4. 日志核对：队友连接上应出现 `packet162 -> ...: remote skill effect open actorUid=<A的uid> ...`，
   以及 A 关能力时的 `packet155 -> ...: ability state uid=<A的uid> ...`。

## 第 20 轮：治疗 / 振荡器不回血 + 放振荡器把敌方的雷弄没

两个症状都和「我们比台服多发/发错了一条帧」有关，逐条对台服抓包（护卫 `log-2026-10-14.txt`，
12:50:11~12:50:31，uid=0x40）核出来：

### 一、战地医疗（技能 0）的 packet162 帧多了一个字节

台服 12:50:19 按 4（战地医疗）后发的是：

```text
12:50:19  client  88 00 04
12:50:19  server  A0 00 40 04 01 01
12:50:19  server  A2 00 01 00 00 0B 40 40 04 00 00        # 11 字节，能力 0
```

本地 `CapturedSkillEffectFrames[0]` 存的是 `A2 00 01 00 00 0B 40 40 04 00 00 00`，**12 字节**，比台服多一个
尾部 `00`。这一族帧是「delta 块」，字段数必须和 flags 字对上，多出来的字节会让客户端整帧丢掉，于是
能力 0 根本没开：施法动画照播（那是客户端本地的 `skill/cure.lua` 音效），但既没有 cure 图标/特效，也
不回血。改成台服的 11 字节即可。

### 二、按技能时回 packet155 是错的，会把刚放下的东西关掉

第 17 轮留了一条「没有 162 帧的技能（震荡波、活力振荡器、地雷）立刻回一条 155」的兜底，原因是当时
以为 155 是「技能生效」。台服抓包否定这点：5 次按键里**只有箭雨**出现过一条 155（`9B ... 03 00`），
震荡波、活力振荡器**一条都没有**，战地医疗、阿喀琉斯之踵也没有。

而 155 关掉的能力编号正好是技能自己的局内能力（护卫的活力振荡器 = 能力 **1**，震荡波 = 4）。所以
按活力振荡器时我们先回 `9B 00 <uid> 00 00 00 01 00`，把刚放下去的振荡器的能力 1 关掉了：

- 振荡器不再治疗（**不回血**）；
- 客户端按这个能力编号去清理同一个编号的物件，把场上占用该编号的装置一起带走（**敌方的雷消失**）。

本轮把 `GameSkillAbilityMode.Cancel`（默认模式）改成**永远不用 155 回应按键**，只有调试开关
（`AS_SKILL_ABILITY_MODE=cast|instant`）还保留旧的立即回包行为。155 现在只用于台服也会用的时机：
「被下一个快捷栏替换」（隐身 15 / 冲刺 6，`CloseOpenSkillAbilitiesAsync`）。

### 修改（PracticeRooms/PracticeRoomChannelProtocol.cs）

- `CapturedSkillEffectFrames[0]`（战地医疗）12 → 11 字节，和台服逐字节一致。
- `HandlePacket136GameSkillActivateAsync`：`GameSkillAbilityMode.Cancel => false`（不再回 155），注释写明
  台服 5 次按键的实际行为。

### 复现验证

1. 重新编译并重启服务端，用护卫兵进房。
2. 先用 `/set health 800`（或被打几下）把血打下来，再按 4（战地医疗）：应看到 cure 图标/特效出现、
   血条回血（台服 mode1 = 600）。
3. 按 7（活力振荡器）：设备落点后应开始 2 秒一跳地治疗周围队友；同一局里另一个职业放的雷不应消失。
4. 突击兵回归：隐身（4）照旧生效；按冲刺（5）时隐身应被关掉（155 仍在，这是台服行为）；按 6 放地雷时
   服务器只回 185（不再有 `9B ... 13 00`），地雷应照旧落点、照旧能炸。

### 仍然没做（后续轮次）

- HP 的「权威值同步」：本机客户端的血条是服务端给的（packet111 / 184 / 106），治疗目前依赖客户端自己
  按能力/装置结算。若「治疗之后一挨打血又掉回去」，说明服务端也得把自己的 CurrentHealth 一起加回去，
  再用同一族帧同步；这需要一段**台服「受伤后治疗」**的抓包来定死用哪条帧（现有护卫抓包里玩家一直是满
  血，服务端一条同步都没发）。
- 台服离开对局时会用 155 关掉仍然开着的能力（本地还没有这一步）。

## 第 21 轮：护卫回血要服务端把血量推给本人 + 冲击波的受击反应帧

用户反馈「还是不能回血，护卫兵的冲击波技能也没用」。把两条链路逐帧重新核了一遍：治疗的**服务端结算**本身
没问题（第 20 轮已经把战地医疗的 packet162 帧修成 11 字节、去掉了「按键就回 155」），问题出在**结算之后的同步**
和**冲击波根本没有可对照的帧**上。

### 一、治疗：服务端算出来的血要同时用 packet111 推给本人

- `/set health` 这条链路发的是**两条**帧：`184`（`Channel packet184 -> ... damage-hit`，int 是结算后的血量）
  加 `111`（`Channel packet111 state refresh`）。第 20 轮的治疗只用 184 同步，本机客户端的 HUD 可能停在旧值，
  表现就是「服务端日志 applied=True，但血条不动」。
- 本轮让 `SendPacket111GameTeleportAsync` 真的写出传入的血量：以前 `healthOverride` 只被日志打印，
  写进包里的始终是最大血量。默认（`publishHealthOverride: false`）行为**完全不变**，仍然是最大血量，
  和台服抓包里 `6F 00 40 FC 08 00 00`(=2300) 一致，所以 `/set health` 锁血那条路一个字节都没动。
- 新增 `SendLocalHealthRefreshAsync(health, trigger)`（trigger=`skill-heal`）：`HealGamePlayersAroundAsync` 在给
  每个目标发完 184 之后，如果这个连接**就是被治疗的那个人**，再补一条 111，值就是刚结算出来的血量。
  这样「按 4 回血」在客户端表现上和「/set health」等价。

### 二、技能效果要按「槽位真的装了技能」判定

`ResolveGameEquipmentSkillId` 在槽位是武器或空槽时返回 0，而护卫的**战地医疗技能 id 也是 0**，所以以前按武器槽
（1/2/3）也会命中 `case 0` 顺手治一次疗。现在 `HandlePacket136GameSkillActivateAsync` 只在
`ResolveGameEquipmentSkillDefinition(room, slot) != null` 时才调用 `ApplyGameSkillActivationEffectAsync`，
并把快捷栏位一起传下去（冲击波要用）。

### 三、冲击波：给被打的人开「受击反应」能力（能力 4）

- 台服按 5 只回 `A0 00 <uid> 05 01 01`（160），**没有 162**：表现全靠客户端本地播的施法特效
  （`AvatarStar_cache/skill/shock.lua` = `skill_19_cast_effect`），击退那一下没有任何可比对的帧。
- 本地原来只发自己猜的 162 击退帧（`A2 00 03 00 20 01 <attacker> <victim> 04 00 <压缩向量>`，
  flags = ActorUid|TargetUid|Subtype|Origin），客户端大概率不认识这种字段组合，所以「按了没反应」。
- 本轮在击退帧之后，再给每个被打的人补一条**已知可用**的 162 能力帧（和战地医疗帧同一种 11 字节布局：
  `A2 00 01 00 00 0B <actor> <target> <parameter> <ability> 00`），ability 用 `4`
  （`AvatarStar_cache/buff/4.lua` = `buff:AddBuffEffect("s_shock_receive")`，就是被击退方身上该播的受击特效），
  parameter 用这次施法的快捷栏位。1.5 秒后再用 155 关掉这条能力状态（台服对箭雨的能力 3 就是这个套路），
  避免受击状态一直挂在别人身上。
- 击退的**位移**本身仍然只能靠那条猜测的 162 帧：客户端的坐标是客户端自己上报的（packet105），服务端改不动它，
  所以本轮只保证「有反应」，位移是否生效要看客户端认不认那条帧。

### 复现验证

1. 重新编译并重启服务端，两个客户端进同一个房间（A 护卫、B 突击/生化）。
2. A 先用 `/set health 800` 把血打下来，再按 4（战地医疗）：A 的血条应从 800 回上去（mode1 = 600，
   服务端日志 `Practice room skill heal ... applied=True healCount=1 broadcastCount=..`），
   A 的客户端「局内接收封包」里应同时看到 `B8 ...`(184) 和 `6F ...`(111)。
3. A 走到 B 身边（6 米内）按 5（冲击波）：B 的画面应出现受击反应，服务端日志出现
   `Channel packet162 -> ... remote ability open actorUid=.. targetUid=.. abilityId=4`，1.5 秒后出现
   `Channel packet155 -> ... shockwave reaction state closed`。
4. 若第 2 步日志是 `reason=no-wounded-ally-in-range`，说明服务端认为没人受伤（满血或队伍不符），
   先把那行日志发出来再定位；若日志 `applied=True` 而血条仍不动，那就是客户端不认 184 的加血，
   此时能靠的就是第 2 步里那条 111。

### 仍然没做

- 击退位移的帧布局（没有台服样本可比对）。
- 台服离开对局时用 155 关掉仍然开着的能力（本地还没有这一步）。
## 第 22 轮：血条不动（packet111 少 6 字节 + 永远写满血）+ 冲击波在练习房里推不到人

用户反馈「还是不能回血，护卫兵的冲击波技能也没用」。把两条链路和台服抓包逐字节重新对齐，
本轮改了三处。

### 一、packet111 少 6 个字节，而且除治疗外永远写最大血量

- 台服两次抓包的 111 都是 **35 字节**，字段是
  `6F 00 <uid> <health:int32> <state:u16> <float ×5> 00 00 00 00 00 00`：
  `6F 00 40 FC 08 00 00 | 00 00 | 00 00 A0 40 …`（health=2300，state=0，float 从偏移 9 开始）。
  本地只写 29 字节，少了 yaw 之后的 6 个 0。现在 `SendPacket111GameSpawnAsync` 和
  `SendPacket111GameTeleportAsync` 都补 `GameLocalStateTrailingBytes = 6` 个 0，长度与台服一致。
- 111 里那个 int 是客户端显示的**本机血量**。以前只有「传了 healthOverride 且带 publish 标记」
  才写真血，其余 111（出生、`/tp`、位置纠正、`/set health`）一律写**最大血量**，于是
  `/set health 800` 之后客户端又被 111 拉回满血，用户既看不到「被打下去的血」，也就看不到回血。
- 现在 `SendPacket111GameTeleportAsync` 一律写服务端当前血量（`ResolveLocalRuntimeHealth`，
  调用方传 `healthOverride` 时用它）。出生时当前==最大，与台服帧一致；`/set health 800` 显示 800，
  治疗把它抬到 1400 就显示 1400。上一轮加的 `publishHealthOverride` 参数已删除。

### 二、治疗的日志补上施法者自己的血量

`HealGamePlayersAroundAsync` 只治「受伤的人」，所以满血按治疗本来就不该有变化。为了能一眼定位，
日志现在带上施法者血量：

```text
Practice room skill heal: roomId=.. healerUid=1 amount=600 radius=8 healerHealth=800/2300 healed=1:1400 broadcastCount=1
Practice room skill heal skipped: .. healerHealth=2300/2300 reason=no-wounded-ally-in-range
```

第二行说明服务端认为你是满血（先做验证步骤 2，把血打下来再按 4）。

### 三、冲击波：练习房间里根本没有敌人可推

- `KnockbackGamePlayersInRadiusAsync` 原先只推**敌人**，而练习房的加入槽位是 1..8，
  `ResolveGameTeamId` 把 1..8 全算成红队 —— 两个客户端永远同队，`IsEnemyTeam` 恒为 false，
  所以「按 5 什么都没发生」是必然的（台服那一局也只有 `A0`，没有 162）。
- 现在改成两趟：第一趟保持台服行为只推敌人；**只有第一趟一个人都推不到时**，第二趟才推施法者
  同队、半径内、还活着的其它玩家，日志 `reason=applied-teammate-fallback teammateFallback=True`。
  真有两个敌对队伍时第一趟就命中，行为与台服一致。

### 复现验证

1. `dotnet build`（或 `dotnet run`）后重启服务端，用护卫兵进练习房。
2. `/set health 800`：血条应**掉到 800**（改之前会一直是满的）。
3. 按 4（战地医疗）：血条应回到 1400（mode1 = 600）；服务端日志
   `Practice room skill heal: ... healerHealth=800/2300 healed=1:1400` 加
   `Channel packet111 state refresh -> ... health=1400`；客户端「局内接收封包」里的
   `6F` 应是 35 字节。
4. 按 5（冲击波）：站到另一个客户端 6 米内，对方应出现受击反应；服务端日志
   `Practice room skill knockback: ... teammateFallback=True pushed=1:6.0/2.5`。

### 仍然没做

- 击退位移本身是否被客户端接受（没有台服样本，客户端的坐标由它自己上报 packet105）。
- 台服离开对局时会用 155 关掉仍然开着的能力（本地还没有这一步）。


## 第 23 轮：修复进局初始化 NullReferenceException（PlayerState 并发）

用户复现：进练习房初始化时客户端报错，栈顶为

```text
PlayerState.NormalizeHotKeySlots() 行 1482
PlayerState.GetGameLoadoutItems() 行 1927
PracticeRoomChannelProtocol.CreateGamePacketPlayer 行 6929
PracticeRoomChannelProtocol.ResolveGamePlayersForPacket 行 6910
PracticeRoomChannelProtocol.SendPacket106GameInitAsync 行 6298
PracticeRoomChannelProtocol.SendGameInitSpawnPacketsAsync 行 2927
PracticeRoomChannelProtocol.SendGameInitSpawnHandshakeFallbackAsync 行 2906
```

### 根因：PlayerState 是被多线程共享的

- 1482 行是 `pair.Value.Type`。`HotKeySlot` 是引用类型 record，只有 `pair.Value == null` 才会 NRE；
  而所有写入点（`FromSnapshot` / `EnsureDefault*` / `TrySet*`）写进去的都是非 null 值，DB 全量扫过一遍
  （4 个角色 hotKeys=6/7/0/5，`nullHotKeys=0`、`nullSkillLevels=0`），
  所以 null 不是持久化数据带进来的，而是**字典被并发读写破坏**后读到的默认值。
- 共享来源：`_playerStore.GetOrCreate(characterId)` 每个角色只有一份 `PlayerState`，却被下面这些路径同时访问
  - 大厅连接（`GameClient.Rpc` 的 skill_upgrade / skill_equip / skill_reset）
  - 局内通道（`ResolveGamePlayersForPacket` 会给房间里**每个人**取一次 loadout，所以 A 的初始化会去读 B 的 `PlayerState`）
  - 一堆 fire-and-forget 的 `SendGameInitSpawnHandshakeFallbackAsync` 与定时器任务
  崩溃点正好落在“初始化握手 + 重试”这一段（`packet105` retriesRemaining=0 之后）。

### 修法：给 PlayerState 的可变状态加锁 + 空值防御

- 新增 `private readonly object _stateLock = new();`。`PlayerState` 里所有会碰 `_hotKeySlots` / `SkillLevels` 的方法
  都在这把锁里执行（`lock` 可重入，被嵌套调用的私有方法照样加锁）：
  `GetHotKeySlots` / `GetGameLoadoutItems` / `GetGameLoadoutSource` / `TrySetSkillHotKeySlot` / `TrySetHotKeySlot` /
  `TryClearHotKeySlot` / `TrySwapHotKeySlots` / `NormalizeHotKeySlots` / `EnsureDefaultWeaponHotKeySlots` /
  `EnsureDefaultSkillHotKeySlots` / `CountWeaponHotKeys` / `RemoveHotKeyReferencesToItem` / `GetEquippedEquipmentPids` /
  `ResetSkillLevels` / `ToSnapshot`（拆出 `SnapshotHotKeySlots` / `SnapshotSkillLevels`）/ `SetSkillLevel` /
  `GetSkillLevel` / `GetSpentSkillPoints`。
  锁顺序只有一条（存档路径先拿 `PlayerStore._lock` 再拿 `_stateLock`，`PlayerState` 不会反向回调 `PlayerStore`），没有死锁环。
- 空值防御：`NormalizeHotKeySlots` 第一遍就删掉 value 为 null 的槽位，其余 `.Where/.Any/.Count` 统一补 `x is not null`；
  `FromSnapshot` 碰到 null 条目直接 `continue`。这样老档/坏档带进 null 时只丢一个槽位，不会再崩。
- `SkillLevels` 走同一把锁（大厅 `skill_upgrade` / `skill_reset` 写、局内 `CreateHotKeyLoadoutItem` 读）。

### 复验

1. `dotnet build src\AvatarStar.Server.Game\AvatarStar.Server.Game.csproj`（0 警告 0 错误）。
2. 重开服务端与客户端，进练习房：两个客户端同时进同一房间、或反复快速进房触发初始化重试，
   确认不再出现 `NormalizeHotKeySlots` 的 NRE。
3. 局内按技能应保持正常（本轮未改动技能释放逻辑）。

### 还没做

- `Storages`（背包/装备）也是同一份 `PlayerState` 上的可变字典：大厅的入库/换装与局内的
  `GetGameLoadoutItems` 之间仍存在同类并发风险，只是这次崩溃没落在它上面，暂未加锁。

## 第 24 轮：回血瞬移 / 最大血量被改写 / 装置互相顶掉——都是 packet111 推血量惹的

用户反馈三件事：护卫回血时人物会「瞬移」一下、回血后**最大血量变成和当前血量一样**、
以及「敌方放雷我这边的活力振荡器会消失，反之也这样」。三件事同一个根因：**治疗把当前血量
写进了 packet111**（第 21 轮引入、第 22 轮改成「永远写当前血量」）。

### 一、packet111 那个 int 是「满血值」，不是「当前血量」

- 台服出生帧 `6F 00 40 FC 08 00 00 ...`（=2300）就是该角色的满血，出生时当前血量恰好等于它，
  所以单看这一帧看不出区别。真正的证据是把两次改动串起来看：
  - 改之前 111 写**满血**：`/set health 800` 发的是 `184(800)` + `111(2300)`，用户看到的是
    **满条**（第 22 轮记录的「改之前会一直是满的」）——说明 111 这个字会把客户端血条**拉回 2300**，
    也就是客户端拿它当「这人多少血」来用，同时也会写进最大值。
  - 改之后 111 写**当前血量**：回血 1400 时客户端就变成 `1400/1400`——这就是用户说的
    「最大血量数变成当前血量一致」。
- 结论：**111 = 出生/传送帧，血量字必须写最大值**。当前血量的变化只走 packet184
  （`B8 00 <flags> <attacker> <victim> <health>`，和 113 同一族「远端物件增量」，int 字段是结算后的血量；
  第 2500fd8 次提交「修复不显示伤害」用的就是它，客户端认这条帧）。

### 二、瞬移是哪来的

`SendPacket111GameTeleportAsync` 除了血量还带 `x/y/z/yaw`，客户端收到就按它**立刻拉位置**。
服务端记的位置是客户端最后一条 `0x69` 上报的（可能已经过去几十毫秒），yaw 在拿不到时还会写成 `0`，
所以每发一次 111，客户端就把人往回拽一下、朝向也翻一下——这就是「回血瞬移」。
治疗根本不需要位置，所以治疗链路不再发 111。

### 三、装置互相顶掉：也是这条 111

振荡器每 2 秒一跳地治疗半径内的**所有同队玩家**（练习房里 1..8 槽全是红队，所以另一个客户端也算
「队友」），每次治疗都会给被治疗者补一条 111 → 对方客户端被「重新出生」一次，
**它刚放下的地雷就跟着一起被清掉**；反过来自己中招（被雷炸、被打掉血）后自己的振荡器给自己回血，
自己的 111 也会把自己的振荡器清掉。第 20 轮把「按键就回 155」去掉后这类现象一度消失，
第 21 轮又把治疗 111 加回来，于是它又回来了——本轮把治疗 111 去掉，两个方向的互顶都应该结束。

### 修改

- `PracticeRooms/PracticeRoomChannelProtocol.cs`
  - `SendPacket111GameTeleportAsync`：去掉 `healthOverride` 参数，血量字**永远写
    `ResolveLocalRuntimeMaxHealth`**（日志里仍打 `runtimeHealth` 方便核对）。
  - `SetLocalHealthAsync`（`/set health`）：只发 `184`，删掉那条 `SendLocalStateUiRefreshAsync`。
  - 删除 `SendLocalStateUiRefreshAsync` / `SendLocalHealthRefreshAsync` 两个方法（没有调用方了）。
- `PracticeRooms/PracticeRoomManager.cs`
  - `HealGamePlayersAroundAsync`：每个目标只发一条 `184`，删掉「被治疗者再补一条 111」的分支。

### 复现验证

1. `dotnet build`（0 警告 0 错误）后重启服务端，用护卫兵进练习房。
2. `/set health 800`：血条掉到 800，**最大值仍是 2300**（可对照 packet103/111 帧里的 2300）。
3. 按 4（战地医疗）：血量回到 1400，最大值不变，人物**不再位移/转身**；日志里只有
   `Channel packet184 -> ...: health update ... health=1400 trigger=packet136-effect`，
   不再出现 `Channel packet111 state refresh`。
4. 按 7（活力振荡器）：站在自己振荡器旁边（或让别人站过去）吃到脉冲时，双方的装置都不应消失。
5. 双开验证装置共存：A 放地雷、B 放振荡器，两个装置同时在场上；再互相走到对方治疗范围内，
   装置照旧存在。

### 如果第 4/5 步还有问题

那说明装置清掉的时机不是 111，需要一段**双客户端同局**的抓包（谁按了什么、两边各自收到哪些
`B9/9B/A2/6F/B8`），才能定死是哪条帧被客户端当成「重新出生」。
