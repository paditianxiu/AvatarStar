# 冒险远征（Boss）模式：房间、关卡表与 BOSS 三阶段

抓包来源：`E:\AvatarStar\远征模式.txt`（18:53:53–19:01:44，官方服务端；
玩家「易拉罐」id=1000992，房间 id=299，关卡 id=10001）。

## 这个模式是什么

- 客户端 `lobby/CreateRoom.lua` 里 `kGameTypeBoss = 9`，界面上叫「Boss」；
  大厅入口是 `lobby/expedition.lua`（冒险远征），选图 / 建房在
  `lobby/expeditionRoom.lua`、`expeditionRoomCreate.lua`。
- 建房的 `Client.RoomInfoDesc`：`game_type = "kBoss"`、`use_password = 0`、
  `spawn_time = 3`、`join_halfway = false`、`check_balance = false`、`enter_limit = 3`、
  `max_client_num = level_map_data.maxCount`、`level_id = map_id_of_key[难度][地图]`。
- 客户端能选哪些图，取决于服务端 packet30 下发的关卡表里 `game_type = 9` 的条目；
  没有这些条目，远征界面就是空的（这是本模式此前完全用不了的原因）。

## 流程（按抓包逐段）

1. 大厅
   - `player_venture_detail` → 体力：`fitnessValue = 100 / fitnessMaxValue = 100`
   - `player_venture_info {mid = 10001}` → 关卡要求：
     `level = 10 / minCount = 1 / maxCount = 4 / venturePower = 0 / fitnessConsumer = 20 /
     mapInfoKey = "id_weapon_naimo_book_effect"`
   - 这两个值客户端会拿来卡开局（`expedition.lua` 里比对玩家 level / ventureForce / fitness），
     所以 `fitnessConsumer` 必须 ≤ 体力，否则一直提示人数 / 条件不符。
2. 建房：channel `packet6`（房间名「XX的房间」、密码、`levelId=10001`、`gameType=9`、
   `maxClientNum=4`、`spawnTime=3`），服务端回 `packet2` / `packet4` / `packet18` / `packet20`。
   - 抓包里 packet6 的**地图名是空串**，官方服务端按 `levelId` 回填成
     `UI_inGame_BOSS1_MAP`，所以服务端要自己补（见 `SendPacket2RoomInfoChangedAsync` 那条路径）。
3. 开局（18:54:12–13）包序：
   `packet100 → packet102 → packet103 → packet112 → packet105 → packet104 ×3 → packet212 →`
   `（客户端发 packet103 请求）→ packet106`
   - `packet102`：`"LEVEL10001"` + `gameType = 09`
   - `packet104`：**BOSS 三阶段实体**（本次实现）
   - `packet106`：局内初始化

## 关卡表（packet30）

官方下发的 69 条 `LevelInfo`：`[int64 id][string name][byte game_type][string show_name]
[string description][int32 difficulty][int32 group]`。

其中 `game_type = 9`（kBoss）的 8 条就是远征可选地图：

| id | 关卡码 | 难度 | 组 | 地图显示名 |
|---|---|---|---|---|
| 10001 | LEVEL10001 | 0 | 1 | UI_inGame_BOSS1_MAP |
| 10002 | LEVEL10002 | 0 | 2 | UI_common_hell_hollow |
| 10003 | LEVEL10003 | 0 | 3 | UI_inGame_BOSS3_MAP |
| 10009 | LEVEL10009 | 0 | 9 | UI_lobby_siwangzhijing |
| 20001 | LEVEL10001 | 1 | 1 | UI_inGame_BOSS1_MAP |
| 20002 | LEVEL10002 | 1 | 2 | UI_common_hell_hollow |
| 20003 | LEVEL10003 | 1 | 3 | UI_inGame_BOSS3_MAP |
| 20009 | LEVEL10009 | 1 | 9 | UI_lobby_siwangzhijing |

注意 **同一个关卡码会出现在两个 id 上**（10001 难度 0 / 20001 难度 1），所以
「关卡 id → 关卡码」必须查表，不能写成 `LEVEL{id}`。
## packet104：BOSS 的三个阶段

服务端开局连发三条（阶段 1/2/3），客户端拿它们建 boss 模型并按阶段切换。
三包结构相同，差异只在阶段相关字段（下表 offset 从 0 起，字节序为小端）：

| offset | 含义 | 一阶 | 二阶 | 三阶 |
|---|---|---|---|---|
| 0..1 | 包号 `68 00` = 104 | 同 | 同 | 同 |
| 2 | 固定 `00` | 同 | 同 | 同 |
| 3 | 阶段索引 | `00` | `01` | `02` |
| 4..5 | 固定 `01 00` | 同 | 同 | 同 |
| 6 | 阶段号 | `01` | `02` | `03` |
| 7..9 | `00 00 00` | 同 | 同 | 同 |
| 10..13 | 阶段号（int32） | 1 | 2 | 3 |
| 14..17 | `00 00 00 00` | 同 | 同 | 同 |
| 18..21 | 显示名长度（int32 = 34） | 同 | 同 | 同 |
| 22..55 | 显示名 `UI_inGame_explore_boss_chaonaimo0X` | …01 | …02 | …03 |
| 56..59 | 资源名长度（int32 = 10） | 同 | 同 | 同 |
| 60..69 | 模型 `boss_01_0X` | …01 | …02 | …03 |
| 70..73 | `00 00 00 00` | 同 | 同 | 同 |
| 74..77 | **血量（int32）** | 560000 | 880000 | 1200000 |
| 78.. | 一串 float 参数（8.0 / 5.0 / 10.0 / 15.0 / 20.0 / -90 / -180 / 0.2 / 0.7854…） | 一阶第 4 个 float 是 8.0，三阶是 2.0 | | |
| 尾部 | 部件表 + 技能表 | 2 个部件 | 4 个部件 | 5 个部件 |

- 部件名形如 `Ba01ArmLt_001` / `Ba01ArmRt_001` / `Ba01ArmHLt_003` …，
  紧跟一段中文部位名（`BOSS一阶火弩炮`、`BOSS三阶肩膀炎-左` 等，UTF-8）。
- 技能表每条是 `<1><序号><1><技能id><4字节 "cure">[string 显示名 / 或中文名]<float 1.0><int 0><byte 1>`，
  一阶 4 条（`UI_abilities_BOSS_skill_01..04`），二阶 5 条，三阶 10 条
  （中间一条是中文技能名 `磁能爆裂-普通`）。
- 包尾还有一组部位→骨骼映射（`LArm03` / `RArm03` / `Hlt` / `Hmt` / `Hrt`）。

因为三包只差阶段相关字段、没有玩家 uid，服务端**原样回放**抓包字节即可，
不需要按房间改写。数据存在 `Resources/boss_stages.json`（`hex` 字段就是整包）。

## 房内「开始游戏」链路（第 2 轮补的 `get_room_player_info`）

远征房间建好之后，房主按「开始游戏」走的是**纯客户端判定 + 一条大厅 RPC**：

1. `lobby/expeditionRoomCreate.lua:258` 房主按钮 → `LobbyPlayGame.CheckEquipment()` →
   `Expedition.SetLimitText(true)`。
2. `lobby/expedition.lua:194 SetLimitText`：
   - 先看房内人数：`count < d.minCount or count > d.maxCount` → `bad_count`
     （`d` = `ExpeditionRoom.level_map_data`，来自 `player_venture_info`，即 `minCount=1/maxCount=4`）。
   - 再 `rpc.safecall("get_room_player_info", {playerIds = "id1,id2,"}, cb)`，
     用回包里的 **`playerList`**（`level` / `ventureForce`）与 **`playerExtraList`**（`fitness`）
     逐个玩家和 `d`（`level=10` / `venturePower=0` / `fitnessConsumer=20`）比对。
   - 全部通过才 `state:StartGame()` → **channel `packet10`** → 服务端 `TryStartGame` →
     开局的 `packet100 → 102 → 103 → 112 → 105 → 104×3 → 212×3 → 106`。
3. 另外 `lobby/playgame.lua:983` 在 `GameType == "kBoss"` 时要求
   `left_num == ready_num[1]`（房主算 ready）才把 `boss_game_can_begin` 置真，
   否则弹 `UI_lobby_explore_no_ready`。

**关键坑**：`rpc.lua:248 ErrorHandler` 把回调包在 `pcall` 里，回调报错只 print 到控制台；
所以服务端一旦不返回 `playerList`/`playerExtraList`，客户端 `data.playerList[i]` 直接索引 nil，
表现为「开始游戏按了没反应」，没有任何提示。

回包格式（照官方抓包 `远征模式.txt` #31/#35）：

```text
ok = 1
playerList = {{id=100190001,playerId=100190001,name="易拉罐",level=30,ventureForce=3842}}
playerExtraList = {{id=100190001,fitness=100}}
```

服务端实现：`Clients/GameClient.Rpc.cs` 的 `case "get_room_player_info"` →
`BuildRoomPlayerInfoPayload`（`playerIds` 逗号拆分 + `_playerStore` 取名字 / 等级 +
每人的 `fitness` 与 `player_venture_detail` 用同一个常量 `ExpeditionFitnessValue = 100`）；
`ventureForce` 由 `PlayerStore.PlayerState.GetVentureForce()` 按
「已装备物品（`EquippedItemsByType` + 快捷栏里的装备）tip 里的 `ventureForce` 求和」算出来。

## 服务端实现位置

| 内容 | 位置 |
|---|---|
| 关卡表数据（69 条，官方 packet30） | `src/AvatarStar.Server.Game/Config/lobby_levels.json` |
| 关卡表加载 / 查询 | `src/AvatarStar.Server.Game/Config/LobbyLevelCatalog.cs` |
| 大厅关卡列表（packet30）改为优先用官方表 | `Clients/GameClient.cs`：`GetConfiguredLobbyLevelsOrDefault` |
| 远征 RPC 回包 | `Clients/GameClient.Rpc.cs`：`case "player_venture_detail"` / `case "player_venture_info"` |
| 关卡码查表（10001 / 20001 → LEVEL10001）与地图名回填 | `PracticeRooms/PracticeRoomChannelProtocol.cs`：`ResolveBattleLevelCode`、`HandlePacket6RoomChangeOptionAsync` |
| boss 阶段包数据 | `src/AvatarStar.Server.Game/Resources/boss_stages.json` |
| boss 阶段包加载 | `src/AvatarStar.Server.Game/Resources/BossStageCatalog.cs` |
| boss 三阶段下发 | `PracticeRooms/PracticeRoomChannelProtocol.cs`：`SendBossStageEntitiesAsync`（在 `SendGameInitSpawnPacketsAsync` 里、packet106 之前，仅 `gameType == 9`；一局只发一次） |

日志里可以直接确认：

```text
Channel packet104 -> <remote>: boss stage=1 display=UI_inGame_explore_boss_chaonaimo01 health=560000 payloadBytes=769 trigger=...
```

## 验证步骤

1. 大厅进「冒险远征」：界面应能列出 8 张图（4 张图 × 2 难度），不再空白。
2. 选 LEVEL10001 建房 → 房间列表 / 房间信息里地图名是 `UI_inGame_BOSS1_MAP`。
3. 开始游戏，局内日志应出现 3 条 `boss stage=1/2/3`，客户端应出现 boss 模型。
4. 单测（临时工程，用完删）：校验关卡数 69、boss 关 8、`ResolveLevelCode(20001) == "LEVEL10001"`、
   boss 阶段数 3 且 payload 长度 769/1212/1512、血量 560000/880000/1200000。

## 进局内：官方 boss 战斗帧与「出生延后 10 秒」（第 36 轮实现）

抓包（`远征模式.txt` 18:54:12–19:01:10，LEVEL10001）里 boss 图的进局时序和练习房**完全不同**：

| 时刻 | 方向 | 包 |
|---|---|---|
| +0s | S→C | 9 / 100 / 102 / 103(1998B 玩家与装备) / **112 ×1（180B）** / 105 / **104 ×3** / **212 ×1（一阶）** |
| +1s | C→S | 103（客户端请求局内初始化） |
| +1s | S→C | **106（30 字节，空玩家列表）** → **151（float = 10.0）** |
| +1s 起 | S→C | **198（81B）+ 199（6B），每 200ms 一条** |
| +10s | S→C | **151（0.0）** → 146 → 231 → 111（35B 出生帧） |

### 根因：boss 图的出生必须延后

官方在 106 之后**没有**立刻发 111；它先用 `151(float = 10.0)` 起一个 10 秒的「进入倒计时」，
到点才 `151(0.0)` + 111 出生。本地服务端以前在 106 之后马上发 146/231/165/111，
客户端在 boss 大场景（`mesh/scene/level10001`）还没加载完时收到出生帧，
表现就是**进房 1 秒后「网络异常」掉线**。

### 现在的实现（`PracticeRooms/PracticeRoomChannelProtocol.cs`）

| 成员 | 作用 |
|---|---|
| `IsBossGameRoom(room)` | `gameType == 9` 判定 |
| `TrySendBossGameInitSpawnPacketsAsync` | 客户端 packet103 请求之后的初始化：**packet104 ×3 + packet212**（`SendBossStagePreludeAsync`，幂等只发一次）→ 106（30B）→ 151(10.0) → 起状态流 → 排出生；返回 true 后练习房那段直接 return |
| `SendBossGameInitPlayerStatePreludeAsync`（105 之前）+ `TrySendBossGameInitSpawnPacketsAsync`（客户端请求之后） | 开局前奏：`SendBossGameInitPlayerStatePreludeAsync` 在 packet105 **之前**只发 1 条 packet112（180B，uid 字节改成本地 uid）；packet104 ×3 + packet212 由 `TrySendBossGameInitSpawnPacketsAsync`（**客户端自己的 packet103 请求**触发）在 packet106 之前下发 |
| `SendBossGameInitPacket106Async` | 写官方 30 字节 106（**不带**玩家列表/装备块），uid 改成本地 uid |
| `StartBossStateLoop` / `RunBossStateLoopAsync` / `SendBossStateFramesAsync` | 每 200ms 一条 198 + 一条 199 |
| `ScheduleBossLocalSpawn` / `RunBossLocalSpawnAsync` | 等 10 秒倒计时（再等客户端「加载完成」`packet157`，最多多等 15 秒）后：151(0.0) → 146 → 231 → 165 → 111 → 107 → 143 |
| `SendPacket151PlayerEnteringCompleteAsync` | 倒计时期间直接吞掉（不清进入遮罩） |
| `SendActiveClientGameInitRefreshOnceAsync` | 倒计时期间不重发初始化 |
| `SendBossOverlayInfoAsync` | boss 房间回客户端的 156（信息遮罩请求）：157（`9d00 00000000`）+ 一条 112，之后才 194 |

数据在 `Resources/boss_combat.json`，加载在 `Resources/BossCombatCatalog.cs`
（整包 hex + 三阶段 198/199 模板 + 出生点 + 倒计时/间隔参数）。

### packet198：boss 状态帧（81 字节）

| offset | 含义 | 一阶 | 二阶 | 三阶 |
|---|---|---|---|---|
| 0..1 | 包号 `c6 00` = 198 | | | |
| 3 | **阶段索引** | 0 | 1 | 2 |
| 7..8 | `fe 07` = 2046，boss 实体 id | | | |
| 11..14 | float **相位计数器**（动作播放进度） | 0 | 13.12 | 0.727 |
| 15..18 | float **动作计时器**（一阶开场 8.0 → 0 播转身） | 8.0 | 0 | 0 |
| 19..22 | **boss 朝向（度）** | -90 | -40 | -0.3634 |
| 23..34 | **12 字节动作块**：6 个 i16（小端）÷256 = 相位/计时器/朝向的每秒变化率（第 38 轮） | 全 0 | 全 0 | 全 0 |
| 37..40 | **当前血量 float** | 560000 | 880000 | 1200000 |

offset 37 的血量与 `boss_stages.json` 里 packet104 的三阶段血量完全一致。
官方一局里 offset 3 在 18:56:59 / 18:58:49 发生变化（玩家把 boss 打下阶段），
即**阶段切换由服务端的状态帧驱动**。本次只做「基础 boss」：停在第一阶段、按阶段满血发布；
后续接伤害时把 `health` 换成实际血量、offset 3 换成新阶段即可。

### packet199：本阶段剩余时间（6 字节）

`c7 00` + float：一阶 300.0 / 二阶 420.0 / 三阶 600.0，每秒减 1.0
（18:54:13 的 300.0 → 18:56:59 重置成 420.0 → 18:58:49 重置成 600.0）。客户端据此画 boss 战倒计时。

### packet112：玩家局内状态（180 字节）

`70 00 <uid> 00 00 00` + 一堆 0 + offset 7..9 的三字节计数器（官方一局从 0 涨到 264 万，
约 7~8 千/秒，疑似累计输出/伤害）。官方在 105 之前只发 1 条、对局中每秒约 3.5 条（156 的回包里也会带一条）。
本次只在开局（105 之前）回放 1 条。

## 还没做的部分

- **boss 掉血 / 阶段切换**：198 的 offset 3 与血量字段已经能写，但还没接「玩家打中 boss」的伤害计算；
  目前 boss 永远停在一阶段满血。
- **对局中的周期性 packet112**（约 3.5 条/秒），以及 `0x71`(113) ×1567、`0x74`(116) ×1520、
  `0xBB`(187) ×1520、`0xC8`(200) ×864 这些实体/状态帧（多半是练习房已有的移动/开火回显）。
- `0xA1`(161) 34 字节 ×1537（客户端→服务端）、`0x78`(120) ×205：客户端上行输入。
- boss 技能（`UI_abilities_BOSS_skill_*`）的释放包、boss 死亡 / 通关结算。

### 验证步骤（boss 进局）

1. 大厅「冒险远征」选 LEVEL10001 建房 → 开始游戏。
2. 服务端日志应依次出现：
   `packet112 ... boss player-state prelude copies=1` → `packet105`
   →（`packet103 <- ... client requested game init/spawn handshake`）
   → `packet104 ... boss stage=1/2/3` → `packet212 ... boss battle prelude`
   → `packet106 ... boss minimal init ... bytes=30`
   → `packet151 ... value=10` → `boss state loop started ... intervalMs=200 stage=1 stageSeconds=300`
   → `packet198 ... boss state stage=1 health=560000` →（10 秒后）`packet151 ... value=0`
   → `packet111 ... spawnPosition=(-0.734375, 1.0390625, 3.1875)` → `boss local spawn ... loadingWaitMs=...`。
   注意 **104 ×3 必须排在 `packet103 <-`（客户端请求）之后、`packet106` 之前**（见文末「第 37 轮」）。
3. 客户端应能进 boss 图（不再「网络异常」），能看到 boss 模型与倒计时，玩家 10 秒后出生。
   启动日志里还有一行 `Server log file: ...`：服务端现在会把**同一份日志**同时写进
   `src/AvatarStar.Server.Game/bin/Debug/net8.0/logs/server-YYYYMMDD.log`，出问题时直接看这个文件就行。
3. 客户端应能进 boss 图（不再「网络异常」），能看到 boss 模型与倒计时，玩家 10 秒后出生。

### 单测（临时工程 `tmp/avtest`）

`boss combat HasData` / `stages == 3` / 血量 560000/880000/1200000 / 时限 300/420/600 /
198 长度 81 / 199 长度 6 / 106 == 30 字节且 gameType=9 / 112 == 180 字节 / 212 == 16 字节 /
`BossStatePacket` 阶段与血量字段 / `BossStageTimerPacket` float / 出生点与倒计时常量。


## 第 37 轮：BOSS 不出现 —— 开局初始化被「0.5 秒兜底」抢跑

**现象**：boss 图能正常进、HUD 正常（技能格 4/5/6 有技能、`HP 2300`、右上角 boss 头像 + 倒计时、
场景中央的传送门里**没有 boss 模型**）。同一台客户端同一个服务端版本，**有时出现、有时不出现**
（`ScreenShot\20261016124558.bmp` 里 boss 是出现的，`20261016125141.bmp` 里没有）。

**根因**：boss 图的局内初始化（`TrySendBossGameInitSpawnPacketsAsync`，里面才有 packet104 ×3 + 212）
有**两个**触发者：

| 触发者 | 时刻（相对 packet105） | 说明 |
|---|---|---|
| 客户端自己的 `packet103` 请求 | 约 +1.0s（官方 18:54:12→13 也是约 1 秒） | 客户端**已经进局内**，104 会被建出 boss 实体 |
| `ScheduleGameInitSpawnHandshakeFallback`（`GameInitSpawnFallbackDelayMilliseconds = 500` + `WaitForGameClientRpcQuietAsync` 的 500ms 静默等待） | 约 +1.0s | 客户端**还在加载场景**，104 被丢掉 → boss 不建 |

两者时刻几乎相同，谁先到是随机的 —— 这就是「有时有 boss 有时没有」。抢跑的那一局日志里，
104 的 `trigger=game-enter-fallback`；另一局是 `trigger=packet103`。

抓包对照（`远征模式.txt` 18:54:12–13，官方客户端 1.4.0.65828）是
`112 → 105 → 104 ×3 → 212 →`（客户端发 103）`→ 106 → 151`，即官方 104 落在**客户端请求之前**；
但本机客户端是 **1.4.0.65795**，在这一版里「还在加载」时收到的 104 不会变成 boss 实体，
必须等客户端自己发过 `packet103`。**以实测为准：104 只能跟在客户端请求之后**。

**修复**（`PracticeRooms/PracticeRoomChannelProtocol.cs`）：

- `BeginGameEnterSequenceAsync`：boss 图只在 packet105 **之前**发 packet112
  （`SendBossGameInitPlayerStatePreludeAsync`）；删掉了「105 之后立刻发 104 ×3 + 212」那段
  （第 37 轮前半段的改法反而把 104 固定在「还在加载」的窗口里，等于每局都不出现）。
- `TrySendBossGameInitSpawnPacketsAsync` 恢复成唯一的 104/212 出口：`104 ×3 + 212 → 106(30B)
  → 151(10.0) → 198/199 状态流 →（10 秒后）出生`。
- `ScheduleGameInitSpawnHandshakeFallback`：boss 图的兜底推迟到
  `BossGameInitFallbackDelayMilliseconds = 8000`（练习房仍是 500ms），
  这样正常情况一定是客户端请求先到（兜底随后因握手已开始而直接 return），
  只有客户端压根没来请求时兜底才会兜住。

日志上应看到（顺序即上面这张表的后半段）：

```text
Channel packet112 -> <remote>: boss player-state prelude copies=1 bytes=180 uid=...
Channel packet105 -> <remote>: game-loading substate advance
Channel packet103 <- <remote>: client requested game init/spawn handshake   ← 必须是客户端请求在前
Channel packet104 -> <remote>: boss stage=1 display=UI_inGame_explore_boss_chaonaimo01 health=560000 payloadBytes=769
Channel packet104 -> <remote>: boss stage=2 ...
Channel packet104 -> <remote>: boss stage=3 ...
Channel packet212 -> <remote>: boss battle prelude bytes=16
Channel packet106 -> <remote>: boss minimal init ... bytes=30
Channel packet151 -> <remote>: value=10
Channel boss state loop started -> ... intervalMs=200 stage=1 stageSeconds=300
```

**已核对过的字节（不是本次现象的原因）**

- packet104 三段与官方**逐字节相同**（`tmp/fb8.py`：769 / 1212 / 1512）。
- packet198 一阶段模板与官方 81 字节逐字节相同；`198` 就是 boss 实体的状态流
  （官方一局 37750 条，`fe 07` = 2046 只出现在 198 里），客户端据此画 boss 血条/头像/倒计时，
  **所以「HUD 有、模型没有」并不矛盾**。
- packet212 官方整局只有 3 条：18:54:12 `d400 0000000000000041 0000b4c2 02 01`（开局一阶）、
  18:56:59 `02 02`（二阶）、18:58:49 `02 03`（三阶）；开局只发第 1 条。
- boss 资源齐全：`AvatarStar_cache\mesh\character\thirdperson\boss\boss_01_01\mesh.mesh`、
  `skeleton\boss_01_01.skel`、`animation\character\thirdperson\male\boss_01_01\stdborn.anim` 都在。
- boss 出生粒子在 `(0, 3.4, -88)`，玩家出生点 `(-0.735, 1.039, 3.188)`，相距约 91 单位，
  关卡雾从 30 起、开到 800 —— 进场后要朝 -Z 走一段才贴近 boss。

### 仍待实测确认

- 客户端 F5 的局内封包打印里，三条 `68 00`（769/1212/1512）应**晚于自己发的 `67 00`**。
- 若还是不出现：看 `src/AvatarStar.Server.Game/bin/Debug/net8.0/logs/server-YYYYMMDD.log`，
  确认 104 那一行的 `trigger=` 是不是 `packet103`（而不是 `game-enter-fallback`）。

## 第 38 轮：BOSS 不会动 + 第二局 BOSS 消失

**现象**：①第一局进场有 boss，但它**站着不动**（只转过一次身，之后永远定格）；
②同一个客户端**第二次**开房进图，boss **直接不出现**。

### 根因 1：198 的 12 字节块不是「动作编号」，是「速率」

把 `远征模式.txt` 一局里 37750 条 packet198（18:54:13–19:01:10）按时序展开，
offset 23..34 每一个常量段都满足 **端点差值 = 速率 × 段时长**：

```text
12 字节块 = 6 个 i16（小端）÷ 256
  i16[0] = 相位（offset 11）每秒变化率
  i16[1] = 动作计时器（offset 15）每秒变化率
  i16[2] = 朝向（offset 19）每秒变化率
  i16[3..5] = 0
例：0006 0000 0000 0000 0000 0000 → 相位 +6/秒
    fa 00 00 00 f6 00 …            → 相位 -6/秒、朝向 -10/秒（i16 = -1536、-2560）
    00 00 00 00 80 0c …            → 朝向 +12.5/秒
```

之前的实现只发 `boss_stages.json` 里「倒计时阶段」的固定 198 模板（相位 0 / 计时器 8 / 朝向 -90 /
动作块全 0），**三帧之间没有任何变化**，所以客户端画出来的 boss 永远定格。
官方在倒计时阶段也确实发这一帧（整段 20 秒不变），转身是从「动作块开始有速率」那一刻起的。

三阶段实测轨道（`tmp` 里按秒内均匀插值展开后分段；`速率 × 时长` 与端点完全对得上）：

| 阶段 | 入场段（一局只播一次） | 之后循环 | 循环时长 |
|---|---|---|---|
| 一阶 | `000000fe800c000000000000` 4.0s（计时器 8→0、朝向 -90→-40，即「转身面向玩家」） | `0006…` 5s 相位 0→30 → `00fa…f6…` 5s 相位 30→0、朝向 -40→-90 → `0000…800c` 4s 朝向 -90→-40 | **14s** |
| 二阶 | `60f900000006…` 4.95s（相位 13.12→-19.95、朝向 -40→-10，接上一阶段结束姿态） | `0004…02` 相位 -20→0、朝向 -10→0 → `0004…fe` 相位 0→20、朝向 0→-10 → `00fc…fa` 相位 20→0、朝向 -10→-40 → `00fc…06` 相位 0→-20、朝向 -40→-10 | **20s** |
| 三阶 | `dbfb000013fe…` 4.99s（相位 0.727→-20、朝向 -0.363→-10） | `0008…` 相位 -20→20、朝向 -10 → `abfc…f6…` 相位 20→0、朝向 -10→-70 → `0000…05` 相位 0、朝向 -70→-40 → `00fc…06` 相位 0→-20、朝向 -40→-10 | **22s** |

顺带量到的官方节奏：198 约 **50~90 条/秒**、199（本阶段剩余时间，300/420/600 递减）与之同频。

**改法**

- `Resources/boss_combat.json` → `stateTracks`：按上表写「入场段 + 循环段」，每段带
  `actionHex / durationMilliseconds / phaseStart / phaseEnd / timerStart / timerEnd / yawStart / yawEnd`
  和 `entrySegmentCount`（前面几段只播一次，默认 1）。
- `Resources/BossCombatCatalog.cs`：`BossStateSegment` 增加动作计时器起止；`BossStateTrack` 增加
  `EntryMilliseconds`；`BossStatePacket(stage, health, elapsedMs)` 现在按
  「入场段走完 → 剩余时间对循环长度取模」推进，并写 offset 11 / **15** / 19 / 23..34
  （新增常量 `BossTimerFieldOffset = 15`）。传 `null` 时仍只写血量 = 倒计时阶段的定格模板。
- `stateIntervalMilliseconds` 200 → **50**（对齐官方节奏；跟随 `BossStateTrack` 推的相位/朝向也就更平滑）。
- `BossStateVerboseLogIntervalFrames` 25 → 100（50ms 间隔下 25 帧太密）。

### 根因 2：第二局 boss 消失 —— 104 只在「场景刚切进来」的窗口里生效

本机客户端（1.4.0.65795）只在**刚切进 boss 图**的那个窗口里用 packet104 建 boss 实体。
第二次开房进图时客户端已经在图内（不重新加载场景），此时收到的 104 被丢掉 → 没有 boss。
所以 `packet104 ×3 + packet212` 一局要下发**两次**：

1. 客户端自己的 packet103 请求之后（`SendBossStagePreludeAsync`，第 37 轮的位置，兜底路径也算一次，
   共允许 2 次）；
2. 客户端报「地图加载完成」（packet157）之后、出生帧（packet111）之前
   ——`SendBossSpawnPreludeAsync`（`_bossSpawnPreludeSent` 一局一次，不占第 1 项的额度），
   放在 `RunBossLocalSpawnAsync` 里。

### 验证

```text
Boss combat state tracks loaded: stages=3 segments=14 entryMs=4000,4950,4990 cyclesMs=14000,20000,22000
Channel packet104 -> <remote>: boss stage=1 … trigger=packet103
Channel packet212 -> <remote>: boss battle prelude bytes=16
Channel boss state loop started -> … intervalMs=50 stage=1 stageSeconds=300
Channel packet104 -> <remote>: boss stage=1 … trigger=<trigger>-boss-spawn   ← 出生前补发那一次
Channel boss local spawn -> <remote>: delayMs=10000 loadingWaitMs=… trigger=<trigger>
```

单测（`tmp/avtest`，用完即删）新增：轨道数 3 / 循环 14000·20000·22000 / 入场 4000·4950·4990 /
一阶段入场段末 yaw=-40、计时器=0 / 循环 2.5s 时相位 15 且动作块 = `0006…` /
入场段 + 一整个循环后回到同一帧 / 二阶段循环起点相位 -10、朝向 -5 / 三阶段巡场段朝向 -70。

### 仍待实测确认

- 第二局 boss 是否出现（看日志里出生前那条 104 的 `trigger=` 是不是 `*-boss-spawn`）。
- boss 是否转身 + 巡场（一阶段应每 14 秒重复一次「相位 0→30 / 朝向 -40→-90→-40」）。
- 若仍不动：官方还有 `0x74`(116) ×1520、`0xBB`(187) ×1520、`0x71`(113) ×1567 三条未实现的实体流
  （116 的 offset 35 也带 `fe 07`），可能另有骨骼/位移通道。
