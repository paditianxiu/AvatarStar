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
   `packet100 → packet102 → packet103 → packet112 → packet105 → packet104 ×3 → packet212 ×3 → packet106`
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

## 还没做的部分

以下都是「boss 战斗中」的包，抓包里量很大，本次没有实现（客户端能看到 boss，但打不死 / 不换阶段）：

- `0xC6`(198) 81 字节 ×37750、`0xC7`(199) 6 字节 ×36233：频率最高的两条同步流，
  应该是 boss/玩家的战斗状态同步（198 里带 uid 与一组 float 坐标）。
- `0x70`(112) 180 字节 ×1525、`0x71`(113) ×1567、`0x74`(116) ×1520、`0xBB`(187) ×1520、
  `0xC8`(200) ×864：开局后持续下发的实体/状态帧。
- `0xA1`(161) 34 字节 ×1537（客户端→服务端）、`0x78`(120) ×205：客户端上行，可能是开火/输入。
- boss 掉血 → 阶段切换的触发条件、boss 技能（`UI_abilities_BOSS_skill_*`）的释放包。

要继续做的话，需要按上面这些包号逐个把抓包切片、和现有练习房的伤害 / 射击 / 移动实现对齐。