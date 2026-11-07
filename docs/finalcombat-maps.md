# 大冲锋地图导入

从 `C:\Game\DaChongFeng\finalcombat_cache` 导入 50 个具有完整主场景模型和碰撞资源的独立场景。98 份地图脚本中的不同模式、难度共享同一场景时合并登记。客户端目标为 `C:\Game\AvatarStar\AvatarStar.pde`。

地图码接 LEVEL53，新增 LEVEL54～LEVEL98、LEVEL100～LEVEL104；保留原 LEVEL99。房间 levelId 为 400023～400072。新增图统一登记在 AvatarStar 的团队竞技模式（gameType 4）。大厅 packet30、房间显示名和进图 packet102 继续使用同一份 LobbyLevelCatalog。

## 资源转换

- 保留源场景全部主模型顶点、索引、材质和全部 PhysX 碰撞 actor；将静态 mesh v8 转为 AvatarStar 的 v10，PhysX 缓存版本转为 v6。材质标记必须转换：大冲锋的不透明 `1` 转为 AvatarStar 的 `0`，透明裁剪 `2` 转为 `1`；其余透明混合位保留。
- 材质贴图和着色器使用独立路径；按新路径重算 CRC。DX9 着色器采样寄存器与 AvatarStar 一致：ColorMap 0、LightMap 4、ShadowAOMap 15、ReflectMap 7。源 LOD0 占位着色器改用完整 LOD1，并补齐贴图与常量绑定。
- 地图入口使用 AvatarStar 支持的 API，包含小地图、主模型、碰撞、光照、相机、死亡区域；Lua 经 luac 编译后写入带校验的 .cache。大厅名称与预览追加到原 CustomMaps 字节码后，原函数完整保留。
- 依据碰撞生成导航，限制在地图范围内并排除死亡区域。红蓝队分别选择可互达的八个出生点；真人在没有 AI 的新地图中同样使用这些出生点。
- PDE 使用 `tools/unpdec/Src/PDEPack` 的完整打包实现重建，不再追加并迁移全部目录。先解出导入前的完整备份，叠加地图资源，再分配全部目录、数据块和 FAT；原有资源按逐文件内容比对。

## 范围与已知缺项

这是场景移植，玩法使用 AvatarStar 团队竞技。源游戏的推车、僵尸、BOSS、跳跃规则、机关控制、独立动态道具及粒子/音频脚本不在本次转换范围，不能当作原版大冲锋模式运行。静态材质动画保留。

源 level43 的小地图路径不存在，按场景几何生成俯视图；源 level54 没有入口脚本，按模型和碰撞补建静态入口，暂命名“大冲锋54号地图”。车辆测试只有 `level_car_test_script.lua.cache`，缓存和原 finalcombat.pde 均没有对应主场景模型，因此没有登记空地图。

已通过服务端编译与 2,739 项回归检查；资源验证脚本校验缓存 CRC、Lua 字节码、每张地图的全部模型/材质/着色器依赖，以及旧 PDE 内容不变。尚未逐图进行客户端画面和对局实测。

## 重建

在仓库根目录依次执行：

```powershell
node client-patches/import-finalcombat-maps.mjs prepare 'C:/Game/DaChongFeng/finalcombat_cache' 'C:/Game/AvatarStar/AvatarStar.pde.before-finalcombat-20261107-133344.bak'
node client-patches/build-finalcombat-navigation.mjs
node client-patches/register-finalcombat-maps.mjs
node client-patches/rebuild-finalcombat-pde.mjs 'C:/Game/AvatarStar/AvatarStar.pde.before-finalcombat-20261107-133344.bak' .tmpbuild/finalcombat-maps/import .tmpbuild/pde-rebuild-next
```

源脚本、转换清单保存在 `.tmpbuild/finalcombat-maps/import`。重建输出目录必须是新的目录，产物为该目录中的 `AvatarStar.rebuilt.pde`。原始导入部署记录见 `.tmpbuild/finalcombat-maps/deployment.json`；首次客户端重建记录见 `.tmpbuild/pde-rebuild/deployment.json`，最新原生压缩兼容修复记录见 `.tmpbuild/pde-native-compression/deployment.json`。替换客户端 PDE 前必须退出客户端；服务器地图配置已经部署，此次只重建客户端包。

## 黑屏后的资源包重建

使用用户指定的 `tools/unpdec/Release/Lua/luac.exe` 回编译 50 份地图入口和 CustomMaps 补丁，写入游戏内虚拟路径，并嵌入原 CustomMaps 完整字节码。该编译器与原 `tools/Lua/luac.exe` 相同，因此不能把故障简单归因于编译器版本。

`build-unpdec-adapter.mjs` 从 PDEPack 源码提取无界面的完整打包方法；PDE 格式实现不作修改。该轮先修正 ReCache 压缩器的控制字跨界及末尾 10 字节必须为字面量的规则，修正代码为 `unpdec-compressor-body.cs`。原版在本次 149 项缓存中有 48 项无法完整解压，修正后第三方解包工具全部回读一致；后续又发现客户端原生解码器对短距离引用的限制，见下文。这属于重压缩发现的问题，最初黑屏包使用的是未压缩缓存。

重建移除了追加产生的旧目录和资源空洞，并压缩新增资源，包大小从 2,202,202,112 降至 2,093,289,472 字节，低于保守的 2 GiB 兼容上限。导入只复制清单列出的资源，避免中间目录遗留的试验文件（包括 LEVEL99）进入包中。验证包括地图依赖、缓存 CRC、Lua 结构、旧文件内容，以及用独立 `FastXOR`、`UnPdeC` 和 `UnCache` 工具解包回读。文件大小和目录迁移是兼容性排查项，尚不能单独认定为黑屏根因；客户端画面验证仍需游戏实测。

2026-11-07 此次重建包通过 67,958 项结构和内容检查，UnPdeC 回读 21,871 个文件全部一致，UnCache 回读 149 项重压缩缓存全部一致。该版包 SHA-256 为 `9C5A17A83FF3A23064BF91336C3958C594F1AEAAA7CFB90C7A17982A587CB6B3`；替换前故障包保存在 `C:\Game\AvatarStar\AvatarStar.pde.before-unpdec-rebuild-20261107-140545.bak`。后续渲染修复包见下节。

## 导入场景渲染修复

用户报告全部导入地图只显示少量方片、地形和建筑大面积缺失。原转换器保留了大冲锋的混合标记，但 AvatarStar 原生场景中的不透明表面标记是 `0`，植被裁剪标记通常是 `1`；源游戏对应值为 `1`、`2`。客户端 `Primitive::Draw`（分析映像地址 `0x95B300`）对标记 `1` 跳过普通 Early-Z 预绘制，并按裁剪材质处理。直接复制源值会把地形和建筑错误分类。

`avatarStarBlendMode` 对这两个值作明确转换，`import-finalcombat-maps.mjs prepare` 会自动应用。`fix-finalcombat-render.mjs` 可以针对上一版完整重建目录修正现有资源并重新打包；它先比对全部顶点和索引，确保模型转换只改变材质标记。该脚本现已同时重压缩清单内全部转换资源，避免复用旧着色器和脚本中的不兼容压缩引用；正常重建优先使用上节的完整重建命令。基于原生 11,937 个场景 primitive 的检查，以及 D3DDisassemble 的字节码对照，主顶点布局和 `default_static_vs` 相同；导入着色器的采样器映射未发现槽位冲突。

```powershell
node client-patches/fix-finalcombat-render.mjs .tmpbuild/pde-rebuild .tmpbuild/pde-render/fixed
```

修复记录与逐地图标记数量见 `.tmpbuild/pde-render/fixed/render-fix.json`，部署记录见同目录 `deployment.json`。用户随后确认这版仍缺失或只显示方片，旧地图正常；材质标记修正没有解决全部问题。

2026-11-07 14:25 已部署至 `C:\Game\AvatarStar\AvatarStar.pde`。50 张地图共核对 1,144 个 primitive，其中 945 个不透明标记由 `1` 改为 `0`、119 个裁剪标记由 `2` 改为 `1`。修复包通过 69,102 项结构与内容检查，独立 UnPdeC 回读 21,871 个文件、UnCache 回读 149 项缓存全部一致。新包为 2,093,285,376 字节，SHA-256 为 `8A80D9D6ED0BEF4274497ED062E85CFE4469B1967A7AC11955741B8E2FD2E42F`；替换前包保存在 `C:\Game\AvatarStar\AvatarStar.pde.before-render-fix-20261107-142517.bak`。

现有 `.tmpbuild/finalcombat-maps/import` 中的 50 份模型也已同步修正，逐份解码后与已验证包一致；同步前的模型和清单保存在 `.tmpbuild/pde-render/fixed/import-stage-before-render-fix`，同步记录为同目录 `import-stage-sync.json`。后续完整重建会继续使用正确的材质标记。

## 客户端原生解压兼容修复

进一步检查发现，AvatarStar 1.4.0.65795 的原生解压函数（分析地址 `0x4F9980`）每次复制 4 字节并前进 3 字节，因此重复引用的距离必须至少为 3。ReCache 的匹配搜索允许距离 1、2，导致客户端读到尚未写入的输出字节。UnCache 及原 JS 解码器逐字节复制，能正确还原这些引用，不能发现这种客户端兼容性问题。

按原生规则审计上一版 684 项新增缓存，发现 112 项解压结果错误、205 个距离小于 3 的引用，包含地图共用的 `fc_default_static_vs`、`fc_s_lambert_lod_1` 等着色器。123 项原生着色器对照全部一致。随后用 Unicorn 执行客户端实际解压机器码，在旧包 42 项导入着色器中复现 39 项错误；该结果与 JS 原生规则模拟器一致。审计记录分别为 `.tmpbuild/pde-render/native-decode-audit.json` 和 `.tmpbuild/pde-render/fixed/native-machine-verification.json`。

`build-unpdec-adapter.mjs` 现已在 ReCache 的粗搜、精搜中排除距离 1、2，`unpdec-compressor-body.cs` 同时增加输出保护。用户提供的原始工具源码保持不变。`cache-native.mjs` 按客户端的 DWORD 复制和尾部规则解压，并用非零初始缓冲区检查未初始化内存依赖。完整重建及修复脚本均校验压缩结果，`verify-finalcombat-maps.mjs` 对包内全部新增缓存再次执行该验证。

本次使用 `tools/unpdec` 回编译 Lua、完整打包，候选包位于 `.tmpbuild/pde-native-compression/AvatarStar.rebuilt.pde`，通过 69,786 项结构与内容检查，覆盖 50 张地图、685 项资源，其中 684 项缓存均通过原生解压规则比对。UnPdeC 独立解包的 21,871 个文件全部一致，UnCache 回读的 149 项重压缩缓存全部一致；执行客户端实际机器码后，这 149 项缓存也全部还原正确，记录见同目录 `native-machine-verification.json`。

2026-11-07 15:16 已原子替换至 `C:\Game\AvatarStar\AvatarStar.pde`，大小为 2,093,285,376 字节，SHA-256 为 `0FCB16A3339F439BAE6FB9D7CA7034484EE4122F703059787F468D94C0D7A6DE`。替换前包保存为 `C:\Game\AvatarStar\AvatarStar.pde.before-native-compression-20261107-151639.bak`。部署前确认客户端已退出，部署后再次核对正式文件哈希；记录为 `.tmpbuild/pde-native-compression/deployment.json`。

离屏 D3D9 对照中，正确解压后的导入模型、贴图、着色器能完整绘制 LEVEL54；46 项着色器（含原生对照）均能成功创建。这些是独立资源验证，不能替代游戏进图实测。未把对照用原生材质替换进正式地图，画面恢复情况仍待用户重新进图确认。

## 编号映射

| 地图码 | 房间 levelId | 中文名 | 源场景 |
| --- | --- | --- | --- |
| LEVEL54 | 400023 | 风车小镇 | level1 |
| LEVEL55 | 400024 | 金色农场 | level2 |
| LEVEL56 | 400025 | 乡间伐木场 | level3 |
| LEVEL57 | 400026 | 神庙遗迹 | level4_test |
| LEVEL58 | 400027 | 法老神殿 | level5_test |
| LEVEL59 | 400028 | 阴霾教堂 | level6_test |
| LEVEL60 | 400029 | 盛夏农场 | level7 |
| LEVEL61 | 400030 | 夜晚小镇 | level8_test |
| LEVEL62 | 400031 | 神殿广场 | level10 |
| LEVEL63 | 400032 | 阿拉伯古城 | level11 |
| LEVEL64 | 400033 | 夜晚农场 | level13 |
| LEVEL65 | 400034 | 战神竞技场 | level14 |
| LEVEL66 | 400035 | 埃及古墓 | level15 |
| LEVEL67 | 400036 | 红岩谷 | level16 |
| LEVEL68 | 400037 | 宫廷回廊 | level19 |
| LEVEL69 | 400038 | 失落废墟 | level20 |
| LEVEL70 | 400039 | 沙之吊桥 | level21 |
| LEVEL71 | 400040 | 风暴都城 | level23 |
| LEVEL72 | 400041 | 激战麦田 | level25 |
| LEVEL73 | 400042 | 灵石谷 | level26 |
| LEVEL74 | 400043 | 神秘山丘 | level27 |
| LEVEL75 | 400044 | 毁灭之都 | level28 |
| LEVEL76 | 400045 | 极地双塔 | level29 |
| LEVEL77 | 400046 | 夕阳矿山 | level30 |
| LEVEL78 | 400047 | 量子星球 | level31 |
| LEVEL79 | 400048 | 青源别墅 | level33 |
| LEVEL80 | 400049 | 起源之城 | level34 |
| LEVEL81 | 400050 | 玛雅祭坛 | level35 |
| LEVEL82 | 400051 | 末日街区 | level36 |
| LEVEL83 | 400052 | 英魂墓地 | level37 |
| LEVEL84 | 400053 | 蓝海空间站 | level38 |
| LEVEL85 | 400054 | 北斗导航站 | level39 |
| LEVEL86 | 400055 | 地心遗迹 | level40 |
| LEVEL87 | 400056 | 火线运输 | level41 |
| LEVEL88 | 400057 | 辛贝尔神庙 | level42 |
| LEVEL89 | 400058 | 极地兵团 | level43 |
| LEVEL90 | 400059 | 祭祀圣坛 | level44 |
| LEVEL91 | 400060 | 琳娜女王号 | level45 |
| LEVEL92 | 400061 | 沙漠堡垒 | level48 |
| LEVEL93 | 400062 | 孤岛神殿 | level49 |
| LEVEL94 | 400063 | 金属风暴 | level50 |
| LEVEL95 | 400064 | 沙漠围城 | level51 |
| LEVEL96 | 400065 | 主题乐园（一） | level52 |
| LEVEL97 | 400066 | 主题乐园（二） | level53 |
| LEVEL98 | 400067 | 大冲锋54号地图 | level54 |
| LEVEL100 | 400068 | 糖果星球(新年版) | level55 |
| LEVEL101 | 400069 | 亚特兰遗迹 | level56 |
| LEVEL102 | 400070 | 黑石小镇 | level57 |
| LEVEL103 | 400071 | 丛林补给站 | level58 |
| LEVEL104 | 400072 | 新手关训练 | level_train |
