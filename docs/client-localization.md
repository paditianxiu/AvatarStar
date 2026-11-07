# 客户端泰文汉化

当前启动参数使用 `-local zh_cn`。主资源包里仍有部分新增功能脚本直接使用泰文，简中语言包无法覆盖这些字符串。

`tools/localization/thai-to-zh-cn.json` 收录 562 条泰文到简体中文的翻译，覆盖 16 个 Lua 脚本中的 573 处引用，包括武士介绍与技能说明、战斗通行证、情侣和婚礼、公园、战绩、批量分解与丢弃、装备方案、语音、兑换码等。

`tools/localization/client-localization.mjs` 读取 PDE 目录和文件块，解析游戏使用的 Lua 5.2-alpha 字节码及压缩缓存。汉化时只替换字符串常量，校验所有指令、其他常量及调试信息不变，并检查格式参数、换行和语音配置的参数行。

## 使用

扫描主资源包及当前语言包：

```powershell
node tools/localization/client-localization.mjs scan C:/Game/AvatarStar/AvatarStar.pde .tmpbuild/localization/base
node tools/localization/client-localization.mjs scan C:/Game/AvatarStar/AvatarStar_zh_cn.pde .tmpbuild/localization/zh_cn
```

生成补丁及原始脚本备份：

```powershell
node tools/localization/client-localization.mjs prepare C:/Game/AvatarStar/AvatarStar.pde tools/localization/thai-to-zh-cn.json .tmpbuild/localization/patch
```

退出客户端后应用补丁：

```powershell
node tools/localization/client-localization.mjs apply .tmpbuild/localization/patch/manifest.json C:/Game/AvatarStar/AvatarStar.pde
```

恢复原始脚本：

```powershell
node tools/localization/client-localization.mjs restore .tmpbuild/localization/patch/manifest.json C:/Game/AvatarStar/AvatarStar.pde
```

保留 `.tmpbuild/localization/patch/` 即可保留本次原始脚本和回滚信息。应用和恢复前均核对资源位置及 SHA-256；资源包版本或脚本发生变化时会停止，避免覆盖其他改动。补丁不会分配新文件块，译文导致资源增长时也会停止并要求重新评估。

再次生成补丁时需使用新的输出目录，工具会拒绝覆盖已有的回滚清单。本机 `C:\Game\AvatarStar\AvatarStar.pde` 已应用本次汉化。

## 验证范围

已扫描主资源包的 1,084 个脚本/文本资源（包含 902 个压缩缓存）及简中语言包的脚本。生成的主资源包再次扫描后，泰文文本和解析错误均为 0。16 个修改后的脚本均通过客户端 `luac.exe -p` 校验，格式参数、换行和原有语音配置值保持一致。

已在完整资源包副本上验证恢复操作，回滚后的整包 SHA-256 与原文件一致。

本次范围是当前简体中文客户端加载的文本资源；其他可选语言包、图片内嵌文字和配音不在文本扫描范围内。桌面自动化通道不可用，尚未完成游戏内界面实测。
