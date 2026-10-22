# 听卷 TomeTone v0.3.0-beta.2

对外测试版本：支持应用内一键下载与自动安装更新包，发现页轻量防白屏与秒级状态恢复缓存，播放台与二级设置页样式与交互细节打磨。

## 亮点

**1. 应用内一键下载与自动安装**
- 流式分块 APK 下载器，实时精准反馈下载进度与百分比，支持下载途中随时取消；
- 集成 Android 原生 `FileProvider` 与 `REQUEST_INSTALL_PACKAGES` 机制，下载完成后直接一键拉起系统安装包解析安装，告别手动寻找 APK 文件的繁琐步骤；
- 更新详情页（`UpdatePage`）底部常驻操作栏，支持智能切换「下载并安装 / 取消下载 / 立即安装 / 外部浏览器下载」多种操作状态与优雅降级。

**2. 发现页秒级状态恢复与防白屏缓存**
- 引入发现页轻量级内存与生命周期缓存，在书籍详情、换源或设置页间来回切换时即时恢复分类列表与搜索结果，杜绝重复网络刷新与白屏闪烁。

**3. 播放器与设置页面体验打磨**
- 优化专业听书播放台工具条布局与热区，增强底栏操作流畅度；
- 完善设置各二级子页面结构样式，提升阅读与偏好管理一致性。

## 下载哪个包

按手机 CPU 架构选择（都是同一版本，装错会提示「应用未安装」）：

| 文件 | 适用 |
| :-- | :-- |
| `TomeTone-v0.3.0-beta.2-arm64-v8a.apk` | 绝大多数现代手机（推荐） |
| `TomeTone-v0.3.0-beta.2-armeabi-v7a.apk` | 较老的 32 位设备 |
| `TomeTone-v0.3.0-beta.2-x86_64.apk` | 模拟器 / x86 设备 |

校验值见同目录 `SHA256SUMS.txt`（PowerShell：`Get-FileHash <文件> -Algorithm SHA256`）。

## 版本信息

- versionName：`0.3.0-beta.2`
- versionCode：arm64 = 32002 / armeabi-v7a = 31002 / x86_64 = 34002
  （Flutter 对 `--split-per-abi` 会按 ABI 追加偏移，单调递增）
- minSdk 24（Android 7.0）/ targetSdk 36（Android 16）

## 已知问题

- **本包使用 debug 签名**，可以安装试用，但**不能作为正式渠道分发**：将来换成正式 keystore 签名的版本无法覆盖安装。
- 本版本已上传 GitHub Release：<https://github.com/wuyanHH/TomeTone/releases/tag/v0.3.0-beta.2>。
- SAF 书库根本轮只读：元数据只写入 SQLite，不生成 `tometone.meta.json`。
- iOS / 桌面端不在本版本范围内。
