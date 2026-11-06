# Samurai 创建入口

客户端第五职业对应 `jobId = 5`，服务端保存的职业编号从 0 开始，因此对应 `occupation = 4`。

当前客户端 `scripts/newsys/class/samurai.lua` 会检查 `get_occupation_properties` 返回的 `characterList[5]`。缺少这一项时，`SamuraiClass.serverReady` 为 `false`，职业选择界面的“开始创建”按钮被禁用。

服务端现已返回第五项职业资料，并为 `sysavatar_list(sysCharacterId = 5)` 提供 `Config/SysAvatarPayloads/5_samurai.lua`。`player_create(id = 5)` 保存为 `occupation = 4`，不会再被截断为生化专家的 `occupation = 3`。

仓库尚无独立的 Samurai 初始造型配置，第五职业暂时复用突击兵的男女造型、部件及初始武器，文件内已注明来源。此修改开放创建流程及职业身份保存，不包含 Samurai 专属技能实现；现有技能处理仍以原有四职业为基础。

验证已通过：服务端编译（0 警告、0 错误）、Lua 模板语法检查、五职业配置加载、男女预设及三件初始武器读取、内存创建及 JSON 存档重新加载后保持 `occupation = 4`。未在客户端实际创建角色。

重新编译并重启游戏服后，客户端重新进入职业选择界面即可重新获取职业列表。此修复不需要修改客户端资源包。
