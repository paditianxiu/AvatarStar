# Samurai 创建入口

客户端第五职业对应 `jobId = 5`，服务端保存的职业编号从 0 开始，因此对应 `occupation = 4`。

当前客户端 `scripts/newsys/class/samurai.lua` 会检查 `get_occupation_properties` 返回的 `characterList[5]`。缺少这一项时，`SamuraiClass.serverReady` 为 `false`，职业选择界面的“开始创建”按钮被禁用。

服务端现已返回第五项职业资料，并为 `sysavatar_list(sysCharacterId = 5)` 提供 `Config/SysAvatarPayloads/5_samurai.lua`。`player_create(id = 5)` 保存为 `occupation = 4`，不会再被截断为生化专家的 `occupation = 3`。

第五职业现在使用客户端已有的男女翡翠武士资源（`jadesamurai` / `jadesamuraiw`），包含服装、头发和上下身饰品。服务端预设编号为 `100201` / `100202`，可选部件仍使用创建界面原来的 Lua 数据格式。

技能列表、加点、洗点、快捷栏和局内技能均支持职业 4。居合斩、风步、风切、刀刃格挡和武士道的实现与验证范围见 [武士技能说明](samurai-implementation.md)。

旧武士角色首次读取背包或技能列表时获得新的武士造型卡，保留原卡。只有仍穿原临时突击兵服装、没有换用其他头饰/饰品的角色会自动装备新卡，并保留脸部和肤色；自定义服装继续保持装备。误分配的其他职业技能点会退回，旧快捷栏中的其他职业技能会清理。

客户端当前只有 `katana_01` / `wakizashi_01` / `yumi_01` 图标，没有同名武器 Lua 或模型，不能把图标名当作可装备武器下发。目前初始武器使用已有的 `knives_01`、`bow_01`、`pistol_01`。

已通过服务端编译、Lua 语法、资源存在性、存档及战斗协议离线检查。尚未完成实际客户端画面验证。

重新编译并重启游戏服后，客户端重新进入职业选择界面即可重新获取职业列表。此修复不需要修改客户端资源包。
