# 主题偏好与检查更新 · 设计

- 日期：2026-10-19
- 对应需求：《架构需求文档》§2.7（版本、发布与检查更新）、§2.8（系统偏好）、§4 验收 13
- 状态：待评审

## 1. 背景与意图

设置页目前有两处“看得见但按不动”的地方：

- **外观**：五套色盘 × 明暗 × OLED 的渲染已经完成，但设置页是一段只读说明；`AppInfo` 之外的任何地方都没有主题偏好，`themeMode` 写死 `ThemeMode.system`，色盘与 OLED 永远取默认值。
- **更新**：`检查更新` 行没有 `onTap`，没有更新源配置，没有网络层，没有自动检查，应用内也看不到更新历史。

本轮把这两块做成真的：外观选择立刻生效、重启保持；更新能自动查、手动查、给出提示、能跳过某个版本、能在应用内翻更新历史。

同时，仓库已经从“只在本地”变成公开的 GitHub 仓库：<https://github.com/wuyanHH/TomeTone>，`v0.2.0-beta.1` 已打 tag 并建 Release（prerelease）。更新源从此有真实数据可测。

## 2. 目标

1. 外观可改且被记住：色盘、明暗模式、暗夜 OLED。
2. 启动时自动检查更新（默认开启、可关闭；关闭后零网络请求）。
3. 关于页“检查更新”可手动触发，并且明确区分“检查中 / 已是最新 / 有新版本 / 已跳过 / 失败”。
4. 发现新版本时用户能“撞见”：设置 tab 出现小红点，并在启动后弹出一次轻量提示。
5. 更新详情页展示版本号、发布日期、完整更新说明（Markdown）、各 ABI 安装包与大小、校验值入口、Release 页入口。
6. “跳过此版本”：跳过后该版本不再主动打扰，但仍可手动查看并取消跳过。
7. 应用内“更新历史”：离线可读的完整更新记录，当前版本高亮。
8. 全程只发 GET，无账号、无标识、无遥测。

## 3. 非目标

- **不做应用内下载 APK、SHA256 本地校验、调起系统安装器**。本轮下载按钮直接把对应 APK 的 GitHub 资产地址交给系统浏览器；校验值以文本展示并链接到 `SHA256SUMS.txt`。真正的下载/校验/安装属于 M3“更新完善”。
- 不做 `update.json` 静态清单回退；接口形状留好，本轮只实现 GitHub Releases 源。
- 不做 stable/beta 通道切换 UI；通道仍来自 `AppInfo.channel`。
- 不做增量更新、静默安装、自动下载。
- 不做 iOS / 桌面端更新。
- 不改动播放、书库、纪年等既有功能。

反目标：为了“看起来完整”而塞进按下去不生效的开关，或让自动检查变成每次启动都打一次网络。

## 4. 已定决策

用户已确认：

- 更新源走 GitHub 仓库（公开）。
- 自动检查、手动检查、新版本提示三者都要。
- 需要“跳过此版本”。
- 主题三项默认值：色盘 5 选 1、明暗三选一（跟随系统 / 浅色 / 深色）、OLED 开关（仅深色生效）。

由实现方决定（用户授权“你觉得怎么好怎么做”）：

- **更新历史用打包进应用的 `CHANGELOG.md` 快照**，而不是每次现拉：与“本地优先、离线可用”一致，打开即读，不受网络与限流影响。检查更新成功后，新版本的说明在更新详情页单独展示。
- 下载走系统浏览器，不做应用内安装器（见非目标）。
- 跳过状态只记一个版本号；出现更新的版本时照常提示。

## 5. 偏好持久化

新增依赖 `shared_preferences`。

模型（`lib/app/preferences/app_preferences.dart`）：

| 字段 | 类型 | 默认 | 说明 |
| --- | --- | --- | --- |
| `paletteId` | `AppPaletteId` | `amberScroll` | 五套色盘 |
| `brightness` | `BrightnessPreference` | `system` | `system` / `light` / `dark` |
| `oledDark` | `bool` | `false` | 仅深色形态生效 |
| `autoCheckUpdates` | `bool` | `true` | 关闭后零网络请求 |
| `skippedVersion` | `String?` | `null` | 已跳过的版本号 |
| `promptedVersion` | `String?` | `null` | 已弹过启动提示的版本号（避免重复打扰） |
| `acknowledgedVersion` | `String?` | `null` | 用户已打开过更新页的版本号（清红点） |
| `lastCheckAt` | `DateTime?` | `null` | 上次**成功**检查时间 |
| `lastAttemptAt` | `DateTime?` | `null` | 上次**尝试**自动检查时间（含失败） |
| `cachedRelease` | `CachedRelease?` | `null` | 裁剪后的最新 Release 快照 + ETag |

存储方式：单个 JSON blob（键 `tometone.preferences.v1`），带 `schemaVersion`；读取失败或版本不认识时回落默认值，不崩溃、不覆盖用户数据的“半截状态”。

装配：`main()` 改为 `Future<void> main() async`，`ensureInitialized` 后 `await AppPreferencesStore.load()`，再 `ProviderScope(overrides: [preferencesStoreProvider.overrideWithValue(store)])`。UI 通过 `preferencesProvider` 同步读取，修改走 notifier 并立即落盘。

契约：`AppPreferencesStore` 定义在应用层，底层实现用 `shared_preferences`；测试用内存实现（`InMemoryAppPreferencesStore`）注入，避免插件依赖。

## 6. 主题

`TomeToneApp` 改为 `ConsumerWidget`：

- `theme: AppTheme.build(palette: palette)`；
- `darkTheme: AppTheme.build(palette: palette, brightness: dark, oled: oledDark)`；
- `themeMode` 由 `brightness` 映射：`system` → `ThemeMode.system`，`light` → `light`，`dark` → `dark`。

外观区改为三个真控件：

1. **明暗**：`SegmentedButton` 三选一（跟随系统 / 浅色 / 深色）。
2. **色盘**：五个色块（琥珀旧卷 / 竹海幽青 / 星夜深蓝 / 暮紫沉香 / 山丹丹红），标签 + 选中描边；点击立即生效。
3. **暗夜 OLED**：`SwitchListTile`；明暗为“浅色”时禁用并说明“仅深色下生效”。

无障碍：色块有 `Semantics(label: ..., selected: ...)`；触控目标 ≥48dp；沿用现有 `theme_contrast_test.dart` 的对比度约束。

删除只读文案与 `settings_page_test.dart` 中对应的“只读”断言，改为持久化行为测试。

## 7. 更新

### 7.1 更新源

`AppInfo` 填入：

```dart
static const String githubOwner = 'wuyanHH';
static const String githubRepo = 'TomeTone';
```

`hasUpdateSource` 因此为 true。回退清单地址继续留空。

请求：`GET https://api.github.com/repos/wuyanHH/TomeTone/releases?per_page=30`

- 头：`Accept: application/vnd.github+json`、`X-GitHub-Api-Version: 2022-11-28`、`User-Agent: TomeTone/<version>`。
- 不带 token、不带任何设备或用户标识。
- 只读 GET；不跟随登录、不上传。
- 已实测（2026-10-19）：匿名请求返回 200，`v0.2.0-beta.1` 为 prerelease，4 个资产，且每个资产自带 `digest: sha256:...`。因此更新详情页可直接展示 `asset.digest`，无需解析 `SHA256SUMS.txt`；后者仍作为人工核对入口。

### 7.2 版本比较

新增纯 Dart `SemVer` 解析与比较（含预发布段规则：数字段按数值、字母段按字典序、数字段低于字母段、无预发布段高于有预发布段）。

- 通道过滤：`beta` 接受 prerelease，`stable` 忽略 prerelease。
- 丢弃 `draft`、无法解析 tag、没有任何 `.apk` 资产的 Release。
- 在剩余项中取版本最大者。
- 与 `AppInfo.version` 比较：更大 → 有新版本；相等 → 已是最新；更小（用户装了更新版本）→ 已是最新，不提示降级。

### 7.3 缓存、退避与失败

- 成功结果裁剪后写入 `cachedRelease`（tag、name、body、publishedAt、htmlUrl、assets[{name,size,url,digest}]）+ `fetchedAt` + `etag`。
- **自动检查的节流看 `lastAttemptAt`，不是成功时间**：距上次尝试 <24h 一律不请求（含失败）。这样断网用户不会每次启动都打一次网络，开关文案“每天最多一次”才成立。
- 手动检查：不受节流限制，但仍带 `If-None-Match`。
- 304 视为成功：刷新 `fetchedAt` 与 `lastCheckAt`，缓存内容不动。
- 手动检查成功同样更新 `lastCheckAt` / `lastAttemptAt`，自动检查的 24h 窗口随之重新计时。
- 失败处理：
  - 自动检查失败：静默，不弹任何提示；只更新 `lastAttemptAt`，保留旧缓存。
  - 手动检查失败且有缓存：展示缓存结果并标注“检查失败，显示上次结果”。
  - 手动检查失败且无缓存：明确失败原因（网络不可达 / GitHub 限流 / 响应异常）+“打开 Release 页”。
- 403/429 且 `x-ratelimit-remaining: 0` 视为限流，文案指向稍后再试。
- **空结果**：请求成功但过滤后没有任何可用 Release（当前 live 状态就是如此之前；stable 通道下只有 prerelease 也会这样）→ 状态为 `noRelease`，文案“暂无可用版本”，不改动缓存、不点红点、不视为失败。

### 7.4 跳过此版本

- `skippedVersion` 只存一个版本号。
- 自动检查发现的新版本等于 `skippedVersion` 时不弹提示、不点红点；设置页仍显示“已跳过 vX”并可取消。
- 发现比 `skippedVersion` 更新的版本时正常提示（不自动清除跳过记录）。
- 取消跳过会清空字段并立即恢复提示。

### 7.5 状态与触发

`updateControllerProvider` 暴露：`idle / checking / upToDate / noRelease / available / skipped / failure`。

- 启动自动检查：`AppShell` 首帧后触发，条件是 `autoCheckUpdates == true` 且距 `lastAttemptAt` 已满 24h（从未尝试过则立即）。关闭时绝不调用服务层（用假客户端断言请求数为 0），也不显示红点。
- 自动检查发现可用更新：展示一次 `SnackBar`（“发现新版本 vX · 查看”，约 7 秒），并在设置 tab 上显示红点。
- **“提示过”与“看过”分开记**：
  - SnackBar：自动检查发现可用更新后弹一次，写 `promptedVersion = 最新版本号`；同一版本不再弹，跨重启保持，更新的版本重新弹。SnackBar 超时/滑走都不影响红点。
  - 红点：写 `acknowledgedVersion = 最新版本号` 的场景只有两个——用户打开更新详情页，或跳过该版本。此后红点消失；出现更新的版本时重新出现。
  - 红点不因“升级完成”而特殊处理——安装的新版本号 ≥ 最新版本时状态自然变为 `upToDate`。
- 设置页“检查更新”行状态：`检查中…` / `已是最新` / `暂无可用版本` / `有新版本 vX` / `已跳过 vX` / `检查失败`，尾部 tag 跟随变化；点击进入更新详情页并触发手动检查。
- “自动检查更新”开关放在关于区卡片顶部，说明“每天最多一次，只读取版本信息”。

### 7.6 更新详情页

路由：`Navigator.push(MaterialPageRoute(builder: (_) => const UpdatePage()))`。

内容自上而下：

1. 当前版本 → 最新版本，发布日期；
2. 完整更新说明，Markdown 渲染（支持标题、列表、粗体、代码、链接、表格——现有 Release 正文含表格）；
3. 安装包列表：文件名、大小、ABI 推荐标记；
4. 操作：`下载`（打开对应 APK 资产 URL）、`打开 Release 页`、`跳过此版本` / `取消跳过`、失败时 `重试`；
5. 校验值：直接展示每个资产的 `digest`（`sha256:...`，可复制）；`digest` 缺失时才给 `SHA256SUMS.txt` 链接，不额外发起第二次 GET；
6. 说明文字：安装需在系统里允许“安装未知应用”；当前包为 debug 签名，换正式签名后无法覆盖安装。

ABI 推荐：通过一个极小的平台通道读取 `Build.SUPPORTED_ABIS`（`android/app/src/main/kotlin/com/tometone/app/MainActivity.kt`），Dart 侧抽象为 `DeviceArchitecture` 接口，纯函数把 ABI 列表映射到资产名中的 `arm64-v8a` / `armeabi-v7a` / `x86_64`。通道失败时不做推荐，列出全部包，不影响使用。

### 7.7 更新历史

- 把仓库根 `CHANGELOG.md` 作为资产打包（`assets/changelog/CHANGELOG.md`），在 `pubspec.yaml` 注册。
- 用测试守住“资产与根目录 CHANGELOG 完全一致”，避免两处漂移。
- 解析 `## [版本] - 日期` 段落，按版本倒序列表；当前版本标“当前”。
- 条目展开后复用同一个 Markdown 渲染器。
- 入口：关于区新增“更新历史”一行；更新详情页底部也提供入口。

## 8. 分层与文件落点

遵循现有依赖方向铁律（UI / app / domain 只依赖 `contracts`，模块实现只在 `main.dart` 注入）：

```
lib/contracts/update/update_source.dart        更新源接口 + 领域模型
lib/contracts/update/device_architecture.dart  ABI 接口
lib/modules/update_github/github_releases_source.dart   GitHub 实现（注入 http.Client）
lib/platform/device/abi_bridge.dart            MethodChannel 实现
lib/app/update/semver.dart                     版本解析与比较
lib/app/update/release_selection.dart          过滤、取最大、比较当前版本
lib/app/update/update_service.dart             编排：缓存 / TTL / 跳过 / 状态
lib/app/preferences/app_preferences.dart       偏好模型
lib/app/preferences/app_preferences_store.dart 存储接口 + SharedPreferences 实现 + 内存实现
lib/app/providers/preferences_providers.dart   偏好 provider / notifier
lib/app/providers/update_providers.dart        更新状态 provider
lib/ui/app.dart                                主题接线
lib/ui/app_shell.dart                          红点 + 启动自动检查 + SnackBar
lib/ui/pages/settings/settings_page.dart       外观区重写 + 关于区扩展
lib/ui/pages/settings/update_page.dart         更新详情
lib/ui/pages/settings/update_history_page.dart 更新历史
lib/ui/widgets/markdown_body.dart              Markdown 渲染封装
assets/changelog/CHANGELOG.md
```

`main.dart` 增加装配：`AppPreferencesStore`、`GitHubReleasesSource(http.Client())`、`UpdateService`、`AbiBridge`。

## 9. 依赖

新增：

- `shared_preferences`（偏好）
- `http`（GET + 测试注入）
- `url_launcher`（打开 APK / Release 页）
- 一个仍在维护的 Markdown 渲染包（候选：`flutter_markdown_plus`、`markdown_widget`）；实现时验证与当前 Flutter/Dart 版本兼容，若都不行则退化为覆盖本项目文案子集的自研渲染。

不引入：下载管理器、安装器、设备信息大包（ABI 用 10 行平台通道解决）。

## 10. 测试与验收

单元测试：

- `SemVer`：数字/字母预发布段、`beta.2 < beta.10`、预发布 < 正式、build metadata 忽略。
- Release 选择：过滤 draft / 无 APK / 不可解析 tag；beta 含 prerelease、stable 不含；取最大。
- 跳过：等于跳过版本不提示；更高的版本提示；取消跳过生效。
- 缓存：24h TTL、304 只刷新时间、失败保留旧缓存。
- 关闭自动检查时请求数为 0。

Widget 测试：

- 改色盘 / 明暗 / OLED 后 `MaterialApp.theme` 与 `themeMode` 立即变化，且写入存储；重建后保持。
- 设置页五种更新状态文案与 tag。
- 更新详情页渲染 Markdown 表格与下载入口。
- 更新历史按版本倒序、当前版本标记。
- 红点出现/消失、SnackBar 只弹一次。

门禁：

- `flutter analyze` 0 错误 0 警告。
- `flutter test` 全绿（含既有测试的适配）。
- 依赖方向检查通过。
- 真机/模拟器手动跑一遍：关闭自动检查 → 无网络请求；打开 → 命中 `v0.2.0-beta.1` 显示“已是最新”；把 `AppInfo.version` 临时降到 `0.2.0-beta.0` → 能提示并进入详情页。

## 11. 风险与取舍

- **GitHub 在部分网络环境不可达**：自动检查静默失败，用户仍可手动检查（看到失败原因与 Release 页链接）。后续可用 `update.json` 镜像解决。
- **匿名 API 限流 60 次/小时/IP**：24h TTL + ETag 把常态请求压到每天一次。
- **公开仓库**：CHANGELOG、Release 正文对所有人生效，文案按“给用户看”的标准写。
- **Markdown 包生态变动**：选型留了自研退路。
- **签名**：当前 Release 用 debug 签名，跨签名无法覆盖安装；本轮不解决，但更新详情页必须提示这一点，避免用户以为是更新失败。

## 12. 留给实现者的决定

- Markdown 渲染包的最终选型与降级阈值。
- 色块的具体视觉（尺寸、描边、选中动效），只要不破坏现有对比度约束。
- SnackBar / 红点的动效细节（遵循系统“减弱动效”）。
- 更新说明过长时的折叠阈值与“展开全部”交互。

## 13. 发布流程（实现完成后）

1. 递增 `AppInfo.version` 与 `pubspec.yaml`（`+build` 同步）。
2. 更新 `CHANGELOG.md`（同时同步 `assets/changelog/CHANGELOG.md`）。
3. 构建三份 ABI APK 与 `SHA256SUMS.txt`，放入 `release/vX.Y.Z/`。
4. `git tag vX.Y.Z` → push → `gh release create` 上传资产并把 CHANGELOG 对应段落作为正文。
