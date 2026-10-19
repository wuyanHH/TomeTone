# 听卷 TomeTone v0.2.0-beta.1

首个对外测试版本：包含 0.1.x 开发期的全部能力，以及本轮的品牌图标与启动页。

## 亮点

**新的品牌标识**
- 图标：线描展开的书 + 从书口升起的五根声纹；墨蓝 `#0E2A3B` / 纸白 `#F2F4E9` / 青绿 `#58DCC1`。
- 自适应图标三层（前景 / 背景 / 单色）全为矢量：任何遮罩下不被裁、不贴边（内容外接 Ø54.0dp，距 Ø66dp 安全圆 6.0dp）；
  Android 13+ 开启主题图标后仍能认出「书 + 声纹」。
- Android 12+ 系统闪屏：宣纸底 + 墨盘记印；深色下墨盘由系统按对比度自动隐去，纸纹直接浮在墨底上。
- Android 7–11：288dp 记印的 layer-list，与 12+ 同几何。
- **修掉一处白闪**：`NormalTheme` 原先引用系统色（亮色下解析为纯白），现在与 `LaunchTheme` 共用同一张记印。

## 下载哪个包

按手机 CPU 架构选择（都是同一版本，装错会提示「应用未安装」）：

| 文件 | 适用 |
| :-- | :-- |
| `TomeTone-v0.2.0-beta.1-arm64-v8a.apk` | 绝大多数现代手机（推荐） |
| `TomeTone-v0.2.0-beta.1-armeabi-v7a.apk` | 较老的 32 位设备 |
| `TomeTone-v0.2.0-beta.1-x86_64.apk` | 模拟器 / x86 设备 |

校验值见同目录 `SHA256SUMS.txt`（PowerShell：`Get-FileHash <文件> -Algorithm SHA256`）。

## 版本信息

- versionName：`0.2.0-beta.1`
- versionCode：arm64 = 22000 / armeabi-v7a = 21000 / x86_64 = 24000
  （Flutter 对 `--split-per-abi` 会按 ABI 追加偏移，因此每个包不同、且都单调递增）
- minSdk 24（Android 7.0）/ targetSdk 36（Android 16）

## 已知问题

- **本包使用 debug 签名**，可以安装试用，但**不能作为正式版分发**：将来换成正式 keystore 签名的版本无法覆盖安装。
- 仓库尚未配置 git remote，本版本只在本地留存归档与 tag，未上传 GitHub Release。
- 启动页首帧会切换一次底色（品牌纸白/墨蓝 → 应用色盘 surface），属设计取舍。
- iOS / 桌面端不在本版本范围内。
