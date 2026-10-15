# AvatarStar 服务端 · 项目记忆文档

> 面向后续接手本仓库的编码代理与开发者。这里只记录**长期有效**的东西：项目结构、环境硬性约束、
> 构建与验证流程、代码地图、已完成功能索引、已知不确定项。
> 单个功能/单轮修复的完整过程请看 `docs/` 下的三篇专题文档（见第 9 节），本文不复制它们的正文。
>
> 最后更新：提交 `aeedd41`（「新增两个造型卡」）。文中行号是当时的快照、会随提交漂移，**以符号名为准**。

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
| `Clients/GameClient.Rpc.cs`（≈168KB） | 大厅 RPC 总入口。`HandleRpcCall`(1697) 读包 → `var rpcName`(1700) → `switch (rpcName)`(1721) 分发；未命中走白名单 `KnownRpcNames`(93) 兜底 `GenericOkPayload`(1564)，再不行返回 `error=nil`。**加新 RPC 就改这里**。 |
| `Clients/GameClient.Inventory.cs`（≈17KB） | 背包/仓库：`GetStorageItems`(14)、`BuildStorageListPayload`(206)、`ParseIntSetArg`(216)、`ParseGradeFilterArg`(240)、`BuildAvatarCardTipPayload`(276)。 |
| `Clients/GameClient.Refit.cs`（≈23KB） | 武器强化（refit）、`ResolveBaseRank`。 |
| `Clients/GameClient.cs`（≈38KB） | 连接生命周期、`GetIntArg`、`GetActivePlayerStateOrDefault`、私有 `_playerStore`。 |
| `Persistence/PlayerStore.cs`（≈126KB） | 玩家存档主体：嵌套 `PlayerState`、`Storages`、`AddItem`、`EnsureStarterInventory`(873)、`NormalizeHotKeySlots`(1542)、`GetGameLoadoutItems`(2271)、`NeatenStorage`(2981)、`ResolveStorageTypeByItemType`(3026)。 |
| `Persistence/GameDataRepository.cs`（≈12KB） | MySQL 落盘。 |
| `PracticeRooms/PracticeRoomChannelProtocol.cs`（**≈356KB，最大**） | 局内 channel 协议：技能释放（packet136/155/160/162/185）、对局初始化（packet103/106）、血量同步（packet111）。**技能类需求基本都改这个文件**。 |
| `PracticeRooms/PracticeRoomManager.cs`（≈123KB） | 房间生命周期、玩家快照 `GamePlayerSnapshot`(3286)、房间广播。 |
| `Models/InventoryItem.cs` | 物品记录（Pid/Slot/Sid/Subtype/Grade/Quantity/UnitType/RefitLevel/PlusLevel/IsEquip…）。 |
| `Models/CharacterInfo.cs` | 角色信息（Id/Name/Level/Occupation/BattleForce/EquipAvatar/MaxHealth）。 |
| `Resources/ShopItemDatabase.cs`（≈53KB） | 商城/造型卡基础数据与价格；`CurrencyType{Gold=1,Diamond=2,Ticket=4}`；造型卡载入(≈692/711/835)。 |
| `Resources/ShopItemProvider.cs`（≈15KB） | 商城取数/分页/购买校验：`SelectShopItems`(71)、`GetAvatarCardListWithPaging`(122)、`ConvertAvatarCardToRpcFormat`、`CanPurchaseItem`(245)、`TryGetPriceById`(254)。 |
| `Config/game_text_id_to_text.json`（≈425KB） | 7xxx 条文本 id → 文本。 |
| `Lua/LuaSerializer.cs` | lua 表字面量序列化（客户端大量字段是 lua table 字符串）。 |

## 6. 数据资源与常量

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

按轮次索引（第 1~11 轮见 `ingame-skill-release.md` 前半）：

- 第 12~24 轮：局内技能/血量/进局初始化的一连串根因修复。
- 第 25 轮：重装兵「护盾 / 飞毛腿」——补上缺失的 packet162 帧。
- 第 26 轮：生化专家「生命抽取 / 生命传导」——一次按键发两条 packet162。
- 第 27 轮：把「有等级的武器」带进局内 + 强化面板分页。
- 第 28/29 轮：武器射速（`fire_time`）整体调慢；再调慢 + 手枪单独调快。
- 第 30 轮：造型卡（拥有列表 / 切换页 / 商城列表 / 卡片数据）。
- 第 31 轮：强化面板物品分页真的能翻页（根因：`GetStorageItems` 在 `storage_item_filter` 路径漏了跳过 `pageOffset`）+ 大厅背包「整理」`storage_neaten`。
- 第 32 轮：造型卡商城补两张卡（狼王斯沃夫 / 龙鳞战甲）。

## 10. 待办 / 已知不确定项

- `storage_neaten`（背包整理）的**官方排序规则无法从抓包推断**（抓包账号的仓库本来就排好序）。
  当前是自定义策略：已装备最前 → Grade 降序 → 子类型升序 → Sid 升序 → 原槽位升序。
- 第 32 轮新增的两张造型卡，**价格是照同档卡套的**（钻石 99 / 券 99），不是官方定价。
- `storage_*` 系列回包比官方多一个 `ok = 1` 字段（客户端不读，无影响，但对比抓包时会看到差异）。
- 商城 `shop_config.json` 的 `type = 5` 分类为空，造型卡数据只来自 `avatar_cards.json`。

## 11. 日志与临时脚本

- 游戏日志：`E:\AvatarStar\log-YYYY-MM-DD.txt`（UTF-8，按天一份）。用户会指定「最新的那份」。
  里面有 `局外接收封包 server to client` / `局外发送封包 client to server` 的 hex dump，实现依据都从这里来。
- `tmp/` 下可复用的解析脚本：
  - `tmp/rd.py <file> <lo> <hi>`：按行读（UTF-8，`\r\n` → `\n`）。
  - `tmp/rdl.py <file> <lo> <hi>`：UTF-8 → GBK fallback（读 lua 用）。
  - 各轮还有 `tmp/n*.py`、`tmp/a*.py` 等专用解析器，改路径即可复用。
- 解 hex dump 的常用手法：dump 复制进 txt → Python `bytes.fromhex` → 按长度前缀逐段切 → 与实现里的写包顺序对齐。
  字符串字段是「4 字节小端长度 + 字节」，数字多为小端定长，`t=…` 这类 kv 块是「字符串 + 值」交替。
