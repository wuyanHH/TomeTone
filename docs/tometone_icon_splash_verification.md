# 听卷 图标与启动页 · 验收记录

> 计划：`docs/superpowers/plans/2026-10-19-tometone-icon-splash.md`（Task 5）
> 设计：`docs/tometone_brand_icon_splash.md`
> 本文件只记录**实测**到的结果；没做到的一律标出来，不留空话。

## 1 结论摘要

| 项 | 结果 |
| :-- | :-- |
| 四道自动门禁 | 全绿（analyze 0 问题 / 463 个测试全过 / 依赖方向通过 / 品牌资源通过） |
| 零依赖、manifest 零改动 | 达成（`pubspec.yaml`、`pubspec.lock`、`AndroidManifest.xml` diff 为空） |
| 自适应图标（API 26+） | 模拟器实测正确：圆形遮罩下墨蓝底 + 纸白书 + 青绿声纹，内容不被裁、不贴边 |
| 旧安卓位图（API 24–25） | 5 档位图已生成并受门禁守（尺寸 + 非调色板型） |
| 启动页（API 31+ / 24–30） | 资源与主题已就位，模拟器上形态见 §2；**白闪判据需真机，模拟器不作为通过依据** |
| 真机项（B1–B7） | **未执行**，清单与命令见 §3 |

## 2 模拟器实测（Android 16 / API 36 · emulator-5554 · 1080×2400）

| # | 查什么 | 实测 | 判定 |
| :-- | :-- | :-- | :-- |
| E1 | 桌面上屏形态 | 圆形遮罩：墨蓝墨盘满幅、纸白展开书、青绿声纹自书口升起；标记居中、未被遮罩啃到 | 通过 |
| E2 | 小尺寸可辨识（同一枚图标的启动器缩放） | 桌面图标里「书」先成立，声纹仍可辨 | 通过 |
| E3 | 系统闪屏形态（浅色） | 宣纸底 + 墨盘 + 记印；实测**墨盘 Ø192dp**（504px @420dpi） | 通过（尺寸对齐见 E6） |
| E4 | 系统闪屏形态（深色） | 墨底 + 纸白书 + 青绿声纹，**墨盘被系统隐去**，无多余色块 | 通过 |
| E5 | 冷启动耗时 | 中位数 **7120ms**（10 次：5799 / 5864 / 5940 / 6130 / 6689 / 7551 / 7640 / 7692 / 7726 / 9271，取中间两数均值） | **不可用作判据**，见下 |
| E6 | 两条分支的记印尺寸一致 | 系统闪屏实测 192dp；`launch_mark` 已按 288dp 画布书写（r=36/108×288 = Ø192dp） | 尺寸一致；**位置对齐仍需 B6** |

E3/E4 的意义：同一份图标资源，昼与夜得到两种正确形态，我们没有写任何条件代码——`windowSplashScreenIconBackgroundColor` 故意不设，由系统按「窗口底 vs 图标背景层」的对比度决定显隐（昼 13.37:1 → 显示；夜 1:1 → 隐去）。

E6 是一次**已修正的缺陷**：首版按文档里的「带 icon background = 240dp / Ø160dp」写了 `launch_mark`，但因为没有设 `windowSplashScreenIconBackgroundColor`，系统实际走的是「不带 icon background」分支——288dp / Ø192dp。从 E3 的截图量出墨盘 504px、除以 420dpi 得 192dp，证实了这一点。于是系统闪屏比 `NormalTheme` 的记印大 20%，冷启动会出现「大记印 → 小一号记印」。修正方式是把 `launch_mark` 与 layer-list 的记印都改成 288dp（viewport 仍是 108，墨盘 r 仍是 36），两条分支的**尺寸**由此对齐；**位置**是否也逐像素对齐，仍需 B6 在真机上量。

E5 为什么不算数：这是 **debug 构建 + 模拟器**，且 10 次运行极差 5799–9271ms（±1.7s 抖动），比 800ms 门槛大一个数量级，比 20ms 的退化阈值大两个数量级。要判断"启动页是否拖慢了启动"，只能在**真机 + profile/release 构建**上比 before/after，见 §3 的 B3。**不要**拿这里的 7120ms 当基线。

截图（已随仓库提交）：
- `docs/design-preview/icon-v3/verified/launcher-api36.png`
- `docs/design-preview/icon-v3/verified/splash-api36-light.png`
- `docs/design-preview/icon-v3/verified/splash-api36-dark.png`

### 2.1 采集方式（可复现）

```bash
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s emulator-5554 shell input keyevent 3            # 回桌面看图标
adb -s emulator-5554 exec-out screencap -p > home.png

# 闪屏：把动画时长放大 10 倍，把闪屏窗口拉长到能截到
adb -s emulator-5554 shell settings put global animator_duration_scale 10
adb -s emulator-5554 shell am force-stop com.tometone.app
adb -s emulator-5554 shell am start -n com.tometone.app/.MainActivity
sleep 1.5 && adb -s emulator-5554 exec-out screencap -p > splash-light.png
adb -s emulator-5554 shell cmd uimode night yes        # 深色再来一次
# 收尾：settings put global animator_duration_scale 1 ; cmd uimode night no
```

> 注意：`am start` 之后立刻截图会截到桌面（此刻闪屏还没画出来），必须留 ~1.5s。第一次采集就踩了这个坑。

## 3 真机项（需要设备，未执行）

| # | 查什么 | 命令 / 方法 | 通过标准 |
| :-- | :-- | :-- | :-- |
| B1 | 12+ 浅色：系统显示墨盘 | `adb shell am force-stop com.tometone.app` 后冷启截图 | 纸白底 + 墨盘记印 |
| B2 | 12+ 深色：系统隐去墨盘 | 系统切深色后同 B1 | 墨底 + 纸白书 + 青绿声纹，无墨盘色块 |
| B3 | 冷启动不回归 800ms | `adb shell am force-stop com.tometone.app`；`adb shell am start -W com.tometone.app/.MainActivity`；取 `TotalTime` 连测 10 次取中位数 | 中位数 ≤ 800ms，且比改动前基线退化 ≤ 20ms |
| B4 | 无白闪、底色不跳 | `adb shell screenrecord /sdcard/s.mp4` 冷启 5s，逐帧看**首屏内容出现之前**的帧 | ① 无平均亮度 ≥ 0.95 的帧；② 相邻帧底色最大通道差 ≤ 8/255；③ 无纯白像素占比 > 1% 的帧 |
| B5 | 无最小展示时长 | `grep -rn "KeepOnScreen\|postDelayed\|Thread.sleep" android/app/src/main` | 无匹配 |
| B6 | 两条分支画面一致 | API 30 与 API 31 各截一张 | 记印大小与位置一致（240dp / Ø160dp 对齐） |
| B7 | 24–30 分支 | API 30 模拟器（模拟器不算通过）或真机 | 纸白底 + 墨盘记印，无裸白屏 |

B3 的基线取法：在本次改动之前（`4d5c131`）构建一版，用同一条命令、同一台设备、同样冷启 10 次取中位数，两者相减。

## 4 已知限制与踩过的坑

1. **首帧一定有一次底色切换**：启动页用的是**品牌色**（昼 纸白 `#F2F4E9` / 夜 墨蓝 `#0E2A3B`），而应用首屏用的是**色盘 surface**（默认 `amberScroll`：昼 `#FBF6EC` / 夜 `#191510`）。两对颜色并不相同（夜间的蓝→暖黑尤其明显），所以**所有色盘、两种明暗形态**都会在首帧发生一次底色变化；切换色盘只是让差异换一种颜色，不是新增差异。这是设计上「启动页是品牌、首屏是内容」的取舍，不是遗漏。如果判定不可接受，正确做法是让 Flutter 首帧的背景与启动页取同一个值（而不是把启动页改成色盘色）。
2. **模拟器不作为白闪判据**：模拟器的启动链路与真机不同，B4 必须在真机跑。
3. **新增 drawable 后的 Gradle 陈旧合并**：本次新增 `drawable/launch_background.xml` 后，`flutter build apk` 报 `resource drawable/launch_background not found`，但文件存在、`aapt2 compile --dir android/app/src/main/res` 整树 exit 0。判定为 Gradle 增量资源合并的陈旧状态，执行 `cd android; .\gradlew :app:mergeDebugResources --rerun-tasks` 后构建通过。**下次新增资源文件若遇到同样的报错，先跑这条命令，不要去改 XML。**
4. **legacy 位图需要一次性生成**：`android/app/src/main/res/mipmap-*/ic_launcher.png` 由 `tool/brand/generate_legacy_icons.ps1` 生成（依赖本机 Chrome，脚本要求 PowerShell 7+）。它们已提交进仓库，CI 不需要跑该脚本；若要重新生成，跑脚本后必须确认 `dart run tool/ci/check_brand_assets.dart` 仍然通过。
5. **门禁能抓什么、抓不到什么**：`tool/ci/brand_asset_rules.dart` 用**精确值**判定（白底、transform、空层、笔宽、尺寸、真彩无 alpha、三份 pathData 同构），反向用例在 `test/ci/brand_asset_gate_test.dart`。它**抓不到**的是「形状本身好不好看」「换了一套同样合规但不同的图形」——那属于评审，不属于门禁。

## 5 复现命令

```bash
flutter analyze
flutter test
dart run tool/ci/check_import_boundaries.dart
dart run tool/ci/check_brand_assets.dart
git diff --stat pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml   # 期望为空
pwsh -File tool/brand/generate_legacy_icons.ps1                                        # 仅在需要重导位图时
```
