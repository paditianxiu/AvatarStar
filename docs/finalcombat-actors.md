# 大冲锋角色和武器移植

源目录为 `C:\Game\DaChongFeng\finalcombat_cache`。在已修复原生解压兼容性的主包基础上新增 336 张造型卡和 478 件武器。2026-11-07 16:46 根据用户允许分包的选择，改为主包 `AvatarStar.pde` 和角色武器分包 `AvatarStar_actors.pde`；语言包不参与修改。

## 商店与使用

- 造型卡 SID 为 320000–320335，覆盖七类源角色及红蓝配色、服装变体，在商店「造型卡」中分页显示。
- 武器 SID 为 220000–220477，使用 `fca_` 前缀的独立资源名，在商店对应武器分类中分页显示。
- 新增商品定价 1 金币，不限制职业。造型卡只改变外观，保留玩家现有职业与技能；购买、装备、快捷栏和存档沿用既有服务端流程。
- 武器使用移植模型、贴图、骨骼、图标及武器部件动画，战斗属性、角色持枪动作和射击效果沿用 AvatarStar 对应枪种。并非复刻源游戏的全部武器机制。6 件源武器没有击杀图标，使用对应原生枪种的击杀图标。
- 源缓存中缺少模型的 2 套服装和 8 件武器没有上架；197 项子弹、NPC、部署物或无独立动作的定义不作为商店武器。逐项原因见 `Config/finalcombat_items.json` 的 `excluded`。

## 资源适配

角色的身体与服装保留独立蒙皮骨骼表，转换为 AvatarStar v10 模型，通过完整造型卡部件加载。骨骼按名称和人体方向重定向至原生 basemodel，补全权重和包围盒，并隐藏原生基础身体，适用于五种职业及原有移动动作。

材质修正混合标志、贴图路径和采样器寄存器；武器模型按原生类别装配，并保留源骨骼和部件动画。Lua 使用 `tools/unpdec/Release/Lua/luac.exe` 回编译；中文名称追加到主包既有 `scripts/newsys/custommaps.lua`，完整嵌入原脚本以保留地图注册。

缓存压缩和 PDE 打包复用 `tools/unpdec` 工具源码，通过已有适配器排除客户端不兼容的短距离重复引用。内容包括 28,633 个文件，新增或更新 6,763 个资源，其中 6,762 个为缓存。初版 3,405,111,296 字节单包会导致启动黑屏，禁止部署；原因与当前修复见下文。

## 构建与验证

基于已完成回编译、压缩和资源验证的 `.tmpbuild/finalcombat-actors/import` 目录，用新的输出目录构建分包：

```powershell
node client-patches/build-finalcombat-split-pde.mjs .tmpbuild/finalcombat-actors/import .tmpbuild/finalcombat-actors/split-rebuild
py client-patches/verify-native-pde.py .tmpbuild/finalcombat-actors/split-rebuild/AvatarStar.pde .tmpbuild/finalcombat-actors/split-rebuild/AvatarStar_actors.pde
dotnet run --project tests/AvatarStar.Game.Tests/AvatarStar.Game.Tests.csproj -c Release -- .
```

本次构建位于 `.tmpbuild/finalcombat-actors/import`。`pack-verification.json` 记录全包回读结果，`actor-verification.json` 记录模型、贴图、着色器、缓存 CRC、客户端原生解压规则以及各枪种完整动作集的检查结果；`unpdec-verification.json` 记录独立 UnPdeC 解包和 UnCache 回读结果。

后端 6,613 项检查通过，覆盖所有新增商品可在商城分页中找到、价格与资源解析，以及五职业的购买、装备、快捷栏和存档恢复。AI 外观检查按整套部件区分造型，不再只比较上衣字段。

七类角色的基础红色造型均用 D3D9 离屏绘制静态绑定姿态及原生向前移动动作，贴图和模型能够显示，预览为 `.tmpbuild/finalcombat-actors/previews/contact.png`。实际游戏商店及战斗画面尚未验证：电脑操作接口返回 `Computer Use native pipe is unavailable`（Windows 错误 2）。

部署记录位于 `.tmpbuild/finalcombat-actors/deployment.json`，包含正式主包哈希、备份路径和验证结果。商店配置同步到现有 Debug 服务端输出目录，先写入造型卡，再更新商店文件触发已有热加载；无需重启服务端。

2026-11-07 16:28 部署完成，正式主包 SHA-256 为 `91D4C62C1502A793601E1BCE4CA806EC374739565D469EF511328C9DD1D0C99B`。旧包备份为 `C:\Game\AvatarStar\AvatarStar.pde.before-finalcombat-actors-20261107-162755.bak`。独立 UnPdeC 回读 28,633 个文件、UnCache 回读 1,747 项重压缩缓存全部一致；正式主包复制后再次核对哈希，所有语言包哈希保持一致。服务端日志于 16:28:16.644 确认 `Reloaded shop config successfully (rev=4)`。

## 启动黑屏与 2 GiB 限制

上述 16:28 单包部署随后被用户确认启动即黑屏。客户端 `sub_C36D60` 以 `SetFilePointer(handle, signedOffset, NULL, FILE_BEGIN)` 定位 PDE；新包将 `scripts` 目录放在 3,271,143,424 字节处，`custommaps.lua` 位于 3,274,534,912 字节处。32 位有符号偏移超过 2 GiB 后成为负数。Win32 只读复现实验中，2,147,483,647 可读，而 2,147,483,648 和 3,274,534,912 均返回错误 131（ERROR_NEGATIVE_SEEK）。先前 64 位工具能独立解包，不代表客户端能访问这些位置。

同版本 Lua 5.2-alpha 解释器已执行新旧 `custommaps.lua`：新增 814 个商品文本与 102 个地图预览注册均正常，排除了启动脚本语法或字节码结构问题。诊断证据保存在 `.tmpbuild/finalcombat-actors/black-screen`。

用户明确允许新增资源分包后，保留全部模型、贴图和清晰度，将新增角色武器资源放入 `AvatarStar_actors.pde`。主包的 `custommaps.lua` 先通过现有 `Path.MountVFS` 挂载分包，再执行完整原脚本；使用标记资源检查挂载结果，重复执行不重复挂载，分包缺失时记录错误并继续原启动流程。运行诊断写入 `C:\Game\AvatarStar\actors-pack-status.log`。

16:46 的文件为：

| 文件 | 大小（字节） | SHA-256 |
| --- | ---: | --- |
| AvatarStar.pde | 2,101,473,280 | 20111BD0C0F276973553D432863AA139E159C2A5A701B18624FFCEE5ED161DFC |
| AvatarStar_actors.pde | 1,311,817,728 | 62216304BC9D1BCD8B694DFF962F23CF49114298D6B7E7596656C022ADAEAA0D |

两个包合并后的 28,633 个原文件均逐字节回读一致（启动挂载钩子除外，另有 1 个挂载标记文件）。`verify-native-pde.py` 使用与客户端相同的 Win32 定位参数，遍历全部目录、文件链并读取每个文件末块，共 32,624 次原生读取通过；全包内容对比覆盖其余数据。Lua 挂载钩子的正常、已挂载、文件缺失和标记缺失四种分支均执行验证，并检查商品文本和地图预览仍然注册。

打包适配器、单包构建和资源追加操作现在都拒绝超过 2 GiB 的输出；边界回归验证确认拒绝发生在修改原有输出文件之前。当前部署记录为 `.tmpbuild/finalcombat-actors/split/deployment.json`；被替换的故障单包备份为 `AvatarStar.pde.before-split-20261107-164555.bak`。

用户重启后已确认可以进入大厅。客户端挂载日志为 `Actor resource archive mounted successfully`，服务端随后收到造型卡商城第 44–46 页等分页请求，确认分包实际挂载成功且商城通信恢复。此记录验证启动和分包接入；全部造型与武器的逐件游戏画面并未实测。

## 新增武器模型路径修复（2026-11-07）

新增武器的 Lua 调用 `weapon:SetMesh("rv", "fca_airgun/rv1_n_lod0.mesh")`。AvatarStar 将该相对路径拼接到 `/mesh/weapon/`，导入器却沿用了源游戏的 `/mesh/prop/weapon/`，因此全部 478 件新增武器都找不到模型。原生武器的实际资源目录及客户端 `/mesh/weapon/` 常量均确认了这个差异。

导入器现在把武器模型写入 `mesh/weapon/fca_*/`。现有构建中的 506 个部件缓存已迁移并按新虚拟路径重算 CRC，模型、骨骼和原始清晰度贴图保持原有内容。正确的 Lua 相对引用和已回编译字节码无需更改。修复同时更新生成目录和清单，后续重新构建会保留正确路径。

`repair-finalcombat-weapon-paths.mjs` 在旧分包的候选副本中追加修正资源，保留其他文件块。候选分包为 1,396,318,208 字节，仍小于客户端的 2 GiB 定位限制；主包及服务端商品 ID 无需变化。

验证结果：

- 修复前，同版 Lua 解释器执行真实分包武器字节码时，明确报告缺失 `/mesh/weapon/fca_airgun/rv1_n_lod0.mesh`。
- 修复后，`verify-finalcombat-weapon-loading.mjs` 执行全部 478 件武器字节码，从分包目录独立解析全部 506 个模型路径，均成功。该检查同时要求移植纹理存在；原生模板中的可选 HUD 图标允许为空。
- 现有模型验证器检查全部 6,762 个资源缓存的原生解压、CRC、顶点、骨骼、材质依赖和动作集，全部通过，并新增目标武器目录断言。
- Win32 原生读取验证通过 9,693 次读取。追加操作逐项回读修正缓存，并确认其他文件块未变化。
- 九类代表武器（霰弹枪、步枪、近战、火箭筒、手枪、机枪、喷射器、狙击枪、手雷）已用原生武器顶点着色器及移植材质完成 D3D9 离屏渲染，模型及贴图可见。预览为 `.tmpbuild/finalcombat-actors/weapon-path-fix/previews/contact.png`。离屏工具为武器的 `WeaponRot` 提供单位矩阵。

修复产物及部署记录位于 `.tmpbuild/finalcombat-actors/weapon-path-fix/`。正式替换前备份旧角色武器分包，复制后核对 SHA-256，并核对主包哈希保持不变。游戏内商店及装备画面仍需客户端重启后确认。

## 商店图片与武器材质兼容修复（2026-11-07）

商店 `shop.lua` 使用 `Tip.GetIcon(item.resource)`；该函数固定读取 `ui/skinF/lobby/<resource>.tga`，不会使用武器脚本中的 `weapon.icon`。导入器此前只复制了源游戏图标并设置 `weapon.icon`，没有提供这个 UI 路径。现在为全部 478 件武器添加对应图片缓存，保持原图片像素、分辨率与透明通道，并按新路径重算 CRC。导入器也会直接生成这些资源，清单新增 `shopIcon` 字段。

模型兼容处理包括两项：

- 505 个模型中的 1,695 个顶点着色器引用从 `default_weapon_vs` 改为原生武器实际使用的 `default_skined_vs`。前者需要额外的 `WeaponRot` 矩阵，后者沿用客户端标准蒙皮参数。同步将零权重槽位中的无效骨骼索引 255 改成有效索引，避免四骨骼蒙皮访问越界。网格位置、权重、UV 和贴图像素不变。
- 39 个材质着色器的 61 个采样器绑定在 D3DX `CTAB` 反射表中仍是源游戏槽位，而着色指令及缓存反射表已转换。现在三者保持一致，例如 `ColorMap` 的反射记录与实际指令都使用 `s0`。`shader-samplers.mjs` 在后续导入时也会同步更新 CTAB。

上一轮离屏工具人为设置了 `WeaponRot` 单位矩阵，未覆盖客户端标准武器渲染参数缺少该矩阵的情况。本次 18 件代表武器使用修正模型，在不设置 `WeaponRot` 的条件下渲染，模型颜色、纹理均可见；涵盖九个武器类别及多种材质，预览位于 `.tmpbuild/finalcombat-actors/shop-icons/previews/contact.png`。环境反射与游戏光照仍以实际客户端为准。

验证使用正式候选分包内容：原版编译后的 `IconsF.GetLobbySlotIcon` 经同版 Lua VM 成功读取 478 个商品图标，所有图标都经图片解码器检查且透明通道有可见像素。修复前相同检查在 `ui/skinf/lobby/fca_airgun.tga.cache` 处失败。全部 478 个武器脚本、506 个模型部件路径及 7,240 个导入资源缓存通过加载、CRC、原生解压与材质依赖检查；Direct3D 反汇编确认修正后的采样器反射槽位。Win32 原生读取验证通过 10,215 次读取。

候选分包大小为 1,594,617,856 字节，小于 2 GiB。部署产物、旧包备份位置及哈希记录见 `.tmpbuild/finalcombat-actors/shop-icons/deployment.json`。此次仅更新角色武器分包；客户端重启后的实际商店画面仍待用户确认。
