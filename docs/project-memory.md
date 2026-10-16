# AvatarStar 服务端 · 项目记忆文档

> 面向后续接手本仓库的编码代理与开发者。这里只记录**长期有效**的东西：项目结构、环境硬性约束、
> 构建与验证流程、代码地图、已完成功能索引、已知不确定项。
> 单个功能/单轮修复的完整过程请看 `docs/` 下的三篇专题文档（见第 9 节），本文不复制它们的正文。
>
> 最后更新：冒险远征 boss **不会动**（packet198 的 12 字节块其实是「相位/计时器/朝向的每秒变化率」，之前只发固定模板）与**第二局 boss 消失**（packet104 ×3 + 212 一局改下发两次）已修；服务端另有文件日志 `logs/server-YYYYMMDD.log`（工作区改动，未提交）。文中行号是当时的快照、会随提交漂移，**以符号名为准**。

## 1. 这个项目是什么

AvatarStar 的**服务端复刻**（C# / .NET 8），配合官方客户端使用：客户端被重定向到本机服务端，
`run_game.bat` 一键拉起。实现方式是「按抓包逐字节还原官方协议」，因此**绝大多数细节来自抓包日志**，
不是从官方源码推导出来的。

工作方式（重要）：用户的诉求几乎总是「这是游戏里的发包 dump / 这是日志，帮我实现 XX」。
所以最高效的路径是——先解析日志里的十六进制包，与已有实现比对，再改代码，最后编译验证。
用户是中文交流，**回复一律中文**。

## 2. 目录结构

```text
AvatarStar/
├─ run_game.bat                 # 拉起客户端：client.exe -ip 127.0.0.1 -port 9532 -token ... -local zh_cn
├─ README.md                    # 部署指南（MySQL 建库 / AS_MYSQL_CONNECTION_STRING / token）
├─ docs/                        # 文档区（本篇记忆文档 + 3 篇专题文档）
├─ images/                      # README 用的截图
├─ tools/                       # 抓包/解包辅助（frida-client、frida-launcher、unluac 等）
├─ src/
│  ├─ AvatarStar.Server/        # 共享库：Client.cs、PacketWriter/PacketReader、LuaSerializer …
│  ├─ AvatarStar.Server.Login/  # 登录服，TCP 9531
│  └─ AvatarStar.Server.Game/   # 游戏服，TCP/UDP 9532，房间 channel 默认 9533   ← 主要改这里
├─ AvatarStar_cache/            # 官方客户端解出来的 lua 与资源（**只读参考**，多为 GBK）
├─ AvatarStar_zh_cn_cache/      # 简中客户端缓存
└─ tmp/                         # 临时脚本与解析产物（已 gitignore，可随意造）
```

数据流：客户端 → 游戏服（大厅 RPC 走 9532，进房后切到房间 channel 端口）→ 落 MySQL（`AS_MYSQL_CONNECTION_STRING`）。

## 3. 环境与硬性约束（动手前先看这段）

- 沙箱 `workspace-write`，可写根 = `E:\Game-RE\AvatarStar`。**只改 `src\AvatarStar.Server.Game` 与 `docs`**，别动客户端缓存和 `tools`。
- **所有回复用中文**（用户明确要求）。
- git 命令一律带 `-c safe.directory='*'`；会伴随 `C:\Users\33735/.config/git/ignore` 权限告警，无害。
- **不要 `git commit`、不要建分支**，除非用户明确要求。
- **不要改 `src\AvatarStar.Server.Game\Properties\launchSettings.json`**（里面的 MySQL 密码是用户自己配的）。
- `apply_patch` 传多行 patch 会失败。可行替代：用 Python 做精确字符串替换，或用 PowerShell here-string 写文件。替换 `.cs` 前把 `\n` 归一成 `\r\n`。
- 编码：`.cs` 是 CRLF；`docs/*.md` 与 `README.md` 是 UTF-8 **无 BOM**；客户端 lua 多为 **GBK**（读不出来就 fallback）；游戏日志是 UTF-8。
- 命令通道的中文能正确传递（实测 UTF-8 无损）；但 `python print` 按 cp936 输出，控制台看中文会乱码，用 hexdump / 写文件核对即可。

## 4. 构建 / 运行 / 验证

编译校验（**运行中的服务端会占用 exe**，所以把输出重定向到临时目录）：

```powershell
dotnet build src/AvatarStar.Server.Game/AvatarStar.Server.Game.csproj -p:BaseOutputPath=tmp/buildchk/ -v m
```

要求 **0 警告 0 错误**。

**构建后必须清理**这两个目录（否则会污染工作区）：

```powershell
$targets = @('src\AvatarStar.Server.Game\tmp', 'src\AvatarStar.Server\tmp') |
    ForEach-Object { Join-Path 'E:\Game-RE\AvatarStar' $_ } |
    ForEach-Object { if (Test-Path -LiteralPath $_) { (Resolve-Path -LiteralPath $_).Path } }
# 逐个确认前缀仍是 E:\Game-RE\AvatarStar\ 后再删
$targets | ForEach-Object { Remove-Item -LiteralPath $_ -Recurse -Force }
```

临时测试工程：`tmp/avtest/`。要点：

- 同目录要放 `nuget.config`，内容 `<packageSources><clear /></packageSources>`（否则 restore 会联网，报 NU1301）。
- `ProjectReference` 指向 `..\..\src\AvatarStar.Server.Game\AvatarStar.Server.Game.csproj`。
- 服务端内部类型没有 `InternalsVisibleTo`，用 `Assembly.Load("AvatarStar.Server.Game")` + 反射访问。
- 建工程只需「建 / 用 / 删」三步，用完删除。

运行：客户端侧用 `run_game.bat`；服务端通常由用户自己起，代理一般只需保证编译通过。

## 5. 服务端代码地图（`src/AvatarStar.Server.Game`）

| 文件 | 说明 |
|---|---|
| `Clients/GameClient.Rpc.cs`（≈168KB） | 大厅 RPC 总入口。远征相关：`case "player_venture_detail"` / `"player_venture_info"` / `"get_room_player_info"`（`BuildRoomPlayerInfoPayload`）。`HandleRpcCall`(1697) 读包 → `var rpcName`(1700) → `switch (rpcName)`(1721) 分发；未命中走白名单 `KnownRpcNames`(93) 兜底 `GenericOkPayload`(1564)，再不行返回 `error=nil`。**加新 RPC 就改这里**。 |
| `Clients/GameClient.Inventory.cs`（≈17KB） | 背包/仓库：`GetStorageItems`(14)、`BuildStorageListPayload`(206)、`ParseIntSetArg`(216)、`ParseGradeFilterArg`(240)、`BuildAvatarCardTipPayload`(276)。 |
| `Clients/GameClient.Refit.cs`（≈23KB） | 武器强化（refit）、`ResolveBaseRank`。 |
| `Clients/GameClient.cs`（≈38KB） | 连接生命周期、`GetIntArg`、`GetActivePlayerStateOrDefault`、私有 `_playerStore`。 |
| `Persistence/PlayerStore.cs`（≈126KB） | 玩家存档主体：嵌套 `PlayerState`、`Storages`、`AddItem`、`EnsureStarterInventory`(873)、`NormalizeHotKeySlots`(1542)、`GetGameLoadoutItems`(2271)、`NeatenStorage`(2981)、`ResolveStorageTypeByItemType`(3026)。 |
| `Persistence/GameDataRepository.cs`（≈12KB） | MySQL 落盘。 |
| `PracticeRooms/PracticeRoomChannelProtocol.cs`（**≈365KB，最大**） | 局内 channel 协议：技能释放（packet136/155/160/162/185）、对局初始化（packet103/106）、血量同步（packet111）、**冒险远征 boss 战斗帧**（`TrySendBossGameInitSpawnPacketsAsync` / `StartBossStateLoop` / `ScheduleBossLocalSpawn`）。**技能与局内类需求基本都改这个文件**。 |
| `PracticeRooms/PracticeRoomManager.cs`（≈123KB） | 房间生命周期、玩家快照 `GamePlayerSnapshot`(3286)、房间广播。 |
| `Models/InventoryItem.cs` | 物品记录（Pid/Slot/Sid/Subtype/Grade/Quantity/UnitType/RefitLevel/PlusLevel/IsEquip…）。 |
| `Models/CharacterInfo.cs` | 角色信息（Id/Name/Level/Occupation/BattleForce/EquipAvatar/MaxHealth）；`DefaultLevel = 30` 是唯一的等级来源，`Create` 与 `PlayerStore.PlayerState.FromSnapshot` 都强制 30（旧存档载入即提升）。 |
| `Resources/ShopItemDatabase.cs`（≈53KB） | 商城/造型卡基础数据与价格；`CurrencyType{Gold=1,Diamond=2,Ticket=4}`；造型卡载入(≈692/711/835)。 |
| `Resources/ShopItemProvider.cs`（≈15KB） | 商城取数/分页/购买校验：`SelectShopItems`(71)、`GetAvatarCardListWithPaging`(122)、`ConvertAvatarCardToRpcFormat`、`CanPurchaseItem`(245)、`TryGetPriceById`(254)。 |
| `Config/game_text_id_to_text.json`（≈425KB） | 7xxx 条文本 id → 文本。 |
| `Lua/LuaSerializer.cs` | lua 表字面量序列化（客户端大量字段是 lua table 字符串）。 |

## 6. 数据资源与常量

- `Config/lobby_levels.json`：官方 packet30 的 69 条关卡表（含 8 条 `gameType = 9` 的远征 boss 关），
  加载在 `Config/LobbyLevelCatalog.cs`；大厅关卡列表、房间地图名、局内关卡码都走它。
- 角色等级：全服固定 **30 级**（`CharacterInfo.DefaultLevel`，官方上限）。没有经验/升级系统；
  改等级只动这一个常量——新建角色与读档都会用它，不需要改客户端。
- `Resources/boss_stages.json`：冒险远征的 BOSS 一/二/三阶段实体包（packet104 整包 hex，血量 56 万 / 88 万 / 120 万），
  加载在 `Resources/BossStageCatalog.cs`。
- `Resources/boss_combat.json`：冒险远征**局内战斗帧**（`gameInitPacket106Hex` 30 字节最小 106、
  `gameInitPlayerStatePacket112Hex` 180 字节 112、`gameInitPreludePacket212Hex` 212、三阶段的
  `packet198Hex`/`packet199Hex` 模板、`spawnTransform`、倒计时/间隔参数），加载在 `Resources/BossCombatCatalog.cs`。
- `Resources/avatar_cards.json`：造型卡数据（当前 **27 张**）。顶层键 `version / source / slotTemplate / cards`；
  每张卡 `sid / subtype / display / grade / avatarLevel / designer / level / prices[] / avatar{}`，
  `avatar{}` 里是各部位 `{名称,索引,颜色,模型,RGB…}` 的 lua 字面量。
  仅 `subtype = 1` 的卡会出现在造型卡商城的 `st="1"` 页签（现有 27 张全部是 1）。
  `source` 字段记录了数据的抓包出处（如 `log-2026-10-15.txt`）。**追加新卡是纯数据改动，不用改代码。**
- `Resources/shop_config.json`（≈3.5MB）：结构 `shop.categories`；注意 `type = 5`（造型卡）分类为空，造型卡走 `avatar_cards.json` 这条线。
- 页签常量：大厅仓库 `depotS = {24,24,24,10}`；强化面板 `reinfS = {5,12,36,12,12,20}`；仓库固定 5 页。
- 物品类型：`t=2` 装备/武器，`t=3` 道具，`t=4` 手势，`t=5` 造型卡背包，`t=6` 造型卡房间。
- `Config/game_text_id_to_text.json` 可直接查显示名，例如 `UI_lobby_avatar_langwang` → 狼王 斯沃夫、
  `id_avatar_name_dayuanshuai` → 龙鳞战甲、`tips_buff_langwangshichou` → 狼王复仇。

## 7. 客户端 Lua 关键入口（`AvatarStar_cache/scripts/`，多为 GBK）

- `sys/rpc.lua`：`ErrorHandler`(248)、`safecall`(302)。
  **关键**：客户端 RPC 是**串行队列**——收到上一条回包才会发下一条。所以凡是「必须先改服务端状态再回包」的 RPC
  （例如背包整理 `storage_neaten`），一定在回包前把数据排好序。
- `sys/comFuc.lua`：`depotS` / `reinfS` 常量（86-87 行附近）。
- `lobby/personalInfo.lua`：背包/强化各列表解析；`rpc_storage_item_filter`(4867)、`rpc_storage_neaten`(4911)、
  `rpc_storage_storage_list`(4929)；整理按钮 `ui.btn_depot_reorder.EventClick`(7724)；页签切换 `ui.pb_depot.EventIndexChanged`(7871)。
- `lobby/shop/shop.lua`：`buy_t`(30)、`buy_st`(69)、`RequestBuyList`(645)；造型卡商城用 `interface = "shop_avatar_list"`（t=5）。

## 8. 局内 channel 协议要点（逐帧细节见第 9 节的专题文档）

日志里的 `packetNNN` 是 channel 层包号，技能相关核心：

- 客户端按键发 `packet136`（槽位触发），服务端要回一整套：
  - `packet160`：槽位触发回执
  - `packet162`：**技能效果帧**（能力参数；真正「开技能」的是它）
  - `packet155`：能力状态（开 / 关）
  - `packet152` / `packet185`：落点类技能（地雷、活力振荡器）的实体帧
- `packet162` 帧里的**两个身份字节都要改成本地玩家 uid**，否则表现为「有动作没效果」。
- 技能 → 局内能力（buff）编号表、各技能的帧 hex 模板都在 `PracticeRoomChannelProtocol.cs`
  （帧表 `CapturedSkillEffectFrames` ≈5658）与 `docs/ingame-skill-release.md`。
- 血量同步走 `packet111`：其中那个 int 是**满血值**，不是当前血量（第 24 轮踩过坑）。
- 调试开关：环境变量 `AS_SKILL_ABILITY_MODE`（`cancel|cast|instant|off`，默认 `cancel`，定义在 `PracticeRoomChannelProtocol.cs:121-148`）。

## 9. 已完成功能索引（**不要重复实现**）

| 文档 | 覆盖内容 |
|---|---|
| `docs/ingame-skill-release.md`（88KB） | 局内技能释放全流程，第 12~26 轮：对局初始化与移动回显、隐身/冲刺、packet155 的真实语义、护卫兵技能、箭雨按等级、技能同步给房间内他人、治疗/振荡器回血、冲击波、进局 NullReferenceException、packet111 血量包、重装兵护盾/飞毛腿、生化专家生命抽取/生命传导。 |
| `docs/weapon-refit.md` | 武器强化协议与实现；「强化等级带进局内」补充。 |
| `docs/practice-room-multiplayer.md` | 练习房间广播与多人加入。 |
| `docs/ingame-boss-expedition.md` | 冒险远征（kBoss = 9）：官方关卡表（packet30）、远征 RPC（`player_venture_detail` / `player_venture_info` / `get_room_player_info`）、BOSS 三阶段实体包（packet104）、**进局内的 boss 战斗帧（106/112/212/151/198/199）与「出生延后 10 秒」根因**。 |

按轮次索引（第 1~11 轮见 `ingame-skill-release.md` 前半）：

- 第 12~24 轮：局内技能/血量/进局初始化的一连串根因修复。
- 第 25 轮：重装兵「护盾 / 飞毛腿」——补上缺失的 packet162 帧。
- 第 26 轮：生化专家「生命抽取 / 生命传导」——一次按键发两条 packet162。
- 第 27 轮：把「有等级的武器」带进局内 + 强化面板分页。
- 第 28/29 轮：武器射速（`fire_time`）整体调慢；再调慢 + 手枪单独调快。
- 第 30 轮：造型卡（拥有列表 / 切换页 / 商城列表 / 卡片数据）。
- 第 31 轮：强化面板物品分页真的能翻页（根因：`GetStorageItems` 在 `storage_item_filter` 路径漏了跳过 `pageOffset`）+ 大厅背包「整理」`storage_neaten`。
- 第 32 轮：造型卡商城补两张卡（狼王斯沃夫 / 龙鳞战甲）。
- 第 33~35 轮：冒险远征（Boss）模式 —— 官方关卡表 + 远征 RPC + BOSS 三阶段实体包（packet104）；
  房内「开始游戏」补 `get_room_player_info` 的 `playerList` / `playerExtraList`；角色等级固定 30。
- 第 36 轮：冒险远征**进局内**（地图 + 基础 BOSS）—— 开局 106 用官方 30 字节最小包、
  105 之前补 1 条 packet112，106 之后发 151(10.0) 倒计时 + 每 200ms 的 198/199 状态流，
  **10 秒后才 111 出生**；根因是 boss 大场景没加载完就收到出生帧 → 进房 1 秒「网络异常」掉线。
- 第 37 轮：**BOSS 不出现**——开局初始化有两个触发者（客户端自己的 packet103 请求 / 0.5 秒的
  `game-enter-fallback` 兜底），两者时刻几乎相同、谁先到是随机的；兜底抢跑时 packet104 落在客户端
  「还在加载」的窗口里，本机客户端（1.4.0.65795）不会据此建 boss 模型（官方 1.4.0.65828 两种都会建）。
  现改成：packet112 在 105 之前；packet104 ×3 + 212 只由客户端 packet103 请求触发（在 packet106 之前）；
  boss 图的兜底推迟到 `BossGameInitFallbackDelayMilliseconds = 8000`。
- 第 38 轮：冒险远征 boss **不会动**——packet198 的 offset 23..34 是 6 个 i16÷256 的**速率**（相位 offset 11 /
  动作计时器 offset 15 / 朝向 offset 19 的每秒变化率），之前只反复发同一帧固定模板；现按官方实测轨道推进
  （一阶入场 4s 转身 + 14s 循环、二阶入场 4.95s + 20s 循环、三阶入场 4.99s + 22s 循环），
  `stateIntervalMilliseconds` 200 → 50。同时修「第二局 boss 消失」：`packet104 ×3 + packet212`
  除客户端 packet103 请求后那次外，还在 packet157「地图加载完成」之后、出生帧之前补发一次
  （`SendBossSpawnPreludeAsync`）。
- 第 33 轮：冒险远征（Boss）模式——官方关卡表（远征界面能列出 8 张图）、远征 RPC、BOSS 三阶段实体包（`docs/ingame-boss-expedition.md`）。
- 第 34 轮：角色等级固定 30（`CharacterInfo.DefaultLevel`；旧存档 `FromSnapshot` 时提升）。
- 第 35 轮：远征房间「开始游戏」没反应——根因是大厅 `get_room_player_info` 只回了泛用 `ok = 1`，
  缺 `playerList` / `playerExtraList` 让客户端 lua 回调静默报错；现已按官方格式回包（`ventureForce` 用
  `PlayerState.GetVentureForce()` 算，`fitness` 与 `player_venture_detail` 共用常量 100）。

## 10. 待办 / 已知不确定项

- `storage_neaten`（背包整理）的**官方排序规则无法从抓包推断**（抓包账号的仓库本来就排好序）。
  当前是自定义策略：已装备最前 → Grade 降序 → 子类型升序 → Sid 升序 → 原槽位升序。
- 第 32 轮新增的两张造型卡，**价格是照同档卡套的**（钻石 99 / 券 99），不是官方定价。
- `storage_*` 系列回包比官方多一个 `ok = 1` 字段（客户端不读，无影响，但对比抓包时会看到差异）。
- 商城 `shop_config.json` 的 `type = 5` 分类为空，造型卡数据只来自 `avatar_cards.json`。
- 冒险远征（boss）模式：开局 112（105 之前）→ 105 →（客户端 packet103 请求）→ 104 ×3 + 212
  → 106（官方 30 字节）→ 151(10.0) 倒计时 + 每 50ms 的 198/199 状态流，**10 秒后才发 111 出生**
  （boss 场景没加载完就出生会「网络异常」掉线；104 ×3 必须落在客户端自己的请求之后，否则 boss 不出现）。
  104 ×3 + 212 一局要发两次（客户端请求之后 + 出生帧之前），因为本机客户端只在「刚切进图」的窗口里才建 boss 实体。
- boss 的**掉血 / 阶段切换还没做**：198 的 offset 3（阶段索引）与血量字段已经能写，但还没有「玩家打中 boss」的
  伤害来源，目前 boss 永远停在一阶段满血。真要做阶段切换时，官方在每个阶段开始还会补发
  212（`d400` + 相位/计时器/朝向 float + `02` + 阶段号）与 210（`d200 02 <阶段号>`）。
- 官方 boss 图里未实现的实体流：`0x74`(116) ×1520、`0xBB`(187) ×1520、`0x71`(113) ×1567、`0xC8`(200) ×864
  （116 的 offset 35 也带 `fe 07` = boss 实体 id，疑似 boss 的另一条骨骼/位移通道）。

## 11. 日志与临时脚本

- 服务端日志：除控制台外还会同时写 `src/AvatarStar.Server.Game/bin/Debug/net8.0/logs/server-YYYYMMDD.log`
  （`Logging/FileLogSink.cs`，启动时会打一行 `Server log file: ...`）。排查封包时序看这个文件即可，不用再人工复制控制台。

- 游戏日志：`E:\AvatarStar\log-YYYY-MM-DD.txt`（UTF-8，按天一份）。用户会指定「最新的那份」。
  里面有 `局外接收封包 server to client` / `局外发送封包 client to server` 的 hex dump，实现依据都从这里来。
- `tmp/` 下可复用的解析脚本：
  - `tmp/rd.py <file> <lo> <hi>`：按行读（UTF-8，`\r\n` → `\n`）。
  - `tmp/rdl.py <file> <lo> <hi>`：UTF-8 → GBK fallback（读 lua 用）。
  - 各轮还有 `tmp/n*.py`、`tmp/a*.py` 等专用解析器，改路径即可复用。
- 解 hex dump 的常用手法：dump 复制进 txt → Python `bytes.fromhex` → 按长度前缀逐段切 → 与实现里的写包顺序对齐。
  字符串字段是「4 字节小端长度 + 字节」，数字多为小端定长，`t=…` 这类 kv 块是「字符串 + 值」交替。
