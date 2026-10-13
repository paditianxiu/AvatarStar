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
| 护卫 | 6 Achilles Heel（被动） | 5 |
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