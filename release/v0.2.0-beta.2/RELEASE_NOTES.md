# 听卷 TomeTone v0.2.0-beta.2

对外测试版本：包含在线听书 M1-D、平滑换源与目录防丢刷新、智能静默预载与沙盒缓存、书架双布局与元数据编辑、5 套东方雅致色盘外观与应用内 GitHub Releases 自动检查更新。

## 亮点

**1. 主题偏好与暗夜 OLED**
- 5 套精选色盘：竹海幽青、暮山紫烟、琥珀温润、玄墨沉金、霁蓝静心，点击即刻换肤；
- 亮色 / 深色 / 跟随系统模式，深色模式支持 OLED 像素级全黑省电。

**2. 应用内检查更新**
- 基于 GitHub Releases 官方渠道无感知检测；
- 设备 CPU 架构自动识别与推荐（arm64-v8a / armeabi-v7a / x86_64）；
- 支持直接调用系统浏览器下载、红点提示、跳过版本与离线更新日志查看。

**3. 在线听书 M1-D 与平滑换源**
- 单本书目与目录刷新（弱网中断或分页不全保护，绝对不丢章）；
- 平滑换源：基于编辑距离与序号多策略匹配，未对齐时锁死原进度；
- 换源抽屉与独立试听播放器（10 秒片头独立试听，不污染主播放器）；
- 智能静默预载与沙盒音频 LRU 缓存池，Wi-Fi 下按进度自动缓冲后续章节；
- 分级安全删除弹窗（移出书架 / 彻底删除 / 物理文件删除防护门禁）。

**4. 书架双布局与元数据编辑**
- 网格大卡片与紧凑列表双布局；
- 展开式全维度即时搜索与复合筛选；
- 书籍详情页按章起播、完听标记、元数据手动编辑与书根 sidecar 双写。

## 下载哪个包

按手机 CPU 架构选择（都是同一版本，装错会提示「应用未安装」）：

| 文件 | 适用 |
| :-- | :-- |
| `TomeTone-v0.2.0-beta.2-arm64-v8a.apk` | 绝大多数现代手机（推荐） |
| `TomeTone-v0.2.0-beta.2-armeabi-v7a.apk` | 较老的 32 位设备 |
| `TomeTone-v0.2.0-beta.2-x86_64.apk` | 模拟器 / x86 设备 |

校验值见同目录 `SHA256SUMS.txt`（PowerShell：`Get-FileHash <文件> -Algorithm SHA256`）。

## 版本信息

- versionName：`0.2.0-beta.2`
- versionCode：arm64 = 22002 / armeabi-v7a = 21002 / x86_64 = 24002
  （Flutter 对 `--split-per-abi` 会按 ABI 追加偏移，单调递增）
- minSdk 24（Android 7.0）/ targetSdk 36（Android 16）

## 已知问题

- **本包使用 debug 签名**，可以安装试用，但**不能作为正式渠道分发**：将来换成正式 keystore 签名的版本无法覆盖安装。
- 本版本已上传 GitHub Release：<https://github.com/wuyanHH/TomeTone/releases/tag/v0.2.0-beta.2>。
- SAF 书库根本轮只读：元数据只写入 SQLite，不生成 `tometone.meta.json`。
- iOS / 桌面端不在本版本范围内。
