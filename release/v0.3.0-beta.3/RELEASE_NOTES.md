# 听卷 TomeTone v0.3.0-beta.3

对外测试版本：书架系列手势导航与一体化复合搜索筛选，书库页彻底重塑为纯粹来源与资产管理中心，全项目 UI 设计系统变量规范化。

## 亮点

**1. 书架系列导航与 PageView 手势切页**
- 支持 Tab 栏横向滑动和下拉选择框两种模式，自由选择系列切换形式；
- 原生 PageView 左右滑动手势快速在不同系列间切换浏览，Tab 自动居中定位与下划线平滑滚动；
- 弹出式系列管理抽屉（`ShelfSeriesManagementSheet`）：自由勾选显隐系列、拖拽排序与「全部」系列开关，无系列防空兜底保护。

**2. 一体化搜索与动画复合筛选栏**
- 全新通用可折叠搜索筛选栏（`SearchFilterBar`），集成搜索输入框、一键清空按钮、展开筛选按钮与选中项计数角标徽章；
- 筛选面板支持平滑尺寸展开/收起动画（SizeTransition）；
- 支持多选在听状态（全部 / 在听 / 未听 / 已完）与来源过滤（全部 / 仅本机音频 / 仅在线书源）。

**3. 书库页重构为纯粹来源与资产中心**
- 彻底移除原书库页中的重复书籍卡片列表，化身为专注管理「本地扫描目录」与「在线书源」的纯粹资产中心；
- 集中提供本机目录扫描、在线书源增删改查与实时健康度监控，彻底杜绝与书架的书目职责混淆。

**4. 设计规范统一与音频预加载装配**
- 全面清理冗余卡片与孤立组件，全项目统一规范 Spacing 与 Radii 设计系统变量；
- 发现页搜索框增加一键清除按钮与填色样式；
- 装配 `audioPreloadManagerProvider`，增强音频后台预加载调度机制。

## 下载哪个包

按手机 CPU 架构选择（都是同一版本，装错会提示「应用未安装」）：

| 文件 | 适用 |
| :-- | :-- |
| `TomeTone-v0.3.0-beta.3-arm64-v8a.apk` | 绝大多数现代手机（推荐） |
| `TomeTone-v0.3.0-beta.3-armeabi-v7a.apk` | 较老的 32 位设备 |
| `TomeTone-v0.3.0-beta.3-x86_64.apk` | 模拟器 / x86 设备 |

校验值见同目录 `SHA256SUMS.txt`（PowerShell：`Get-FileHash <文件> -Algorithm SHA256`）。

## 版本信息

- versionName：`0.3.0-beta.3`
- versionCode：arm64 = 32003 / armeabi-v7a = 31003 / x86_64 = 34003
  （Flutter 对 `--split-per-abi` 会按 ABI 追加偏移，单调递增）
- minSdk 24（Android 7.0）/ targetSdk 36（Android 16）

## 已知问题

- **本包使用 debug 签名**，可以安装试用，但**不能作为正式渠道分发**：将来换成正式 keystore 签名的版本无法覆盖安装。
- 本版本已上传 GitHub Release：<https://github.com/wuyanHH/TomeTone/releases/tag/v0.3.0-beta.3>。
- SAF 书库根本轮只读：元数据只写入 SQLite，不生成 `tometone.meta.json`。
- iOS / 桌面端不在本版本范围内。
