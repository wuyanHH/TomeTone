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
| E3 | 系统闪屏形态（浅色） | 宣纸底 + 墨盘 + 记印：**系统按对比度自动显示了图标的背景层** | 通过 |
| E4 | 系统闪屏形态（深色） | 墨底 + 纸白书 + 青绿声纹，**墨盘被系统自动隐去**，无多余色块 | 通过 |
| E5 | 冷启动耗时 | 中位数 **7551ms**（10 次：9271 / 5864 / 5940 / 5799 / 6689 / 6130 / 7551 / 7726 / 7692 / 7640） | **不可用作判据**，见下 |

E3/E4 的意义：同一份图标资源，昼与夜得到两种正确形态，我们没有写任何条件代码——`windowSplashScreenIconBackgroundColor` 故意不设，由系统按「窗口底 vs 图标背景层」的对比度决定显隐（昼 13.37:1 → 显示；夜 1:1 → 隐去）。

E5 为什么不算数：这是 **debug 构建 + 模拟器**，且 10 次运行极差 5799–9271ms（±1.7s 抖动），比 800ms 门槛大一个数量级，比 20ms 的退化阈值大两个数量级。要判断"启动页是否拖慢了启动"，只能在**真机 + profile/release 构建**上比 before/after，见 §3 的 B3。**不要**拿这里的 7551ms 当基线。

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

1. **非默认色盘下的窗口底**：`NormalTheme` 用的是默认色盘（`amberScroll`）的 surface 值，用户切到别的色盘时，首帧可能出现**一帧**底色不一致。这是为了不在冷启动路径上同步读 SharedPreferences 而接受的代价。
2. **模拟器不作为白闪判据**：模拟器的启动链路与真机不同，B4 必须在真机跑。
3. **新增 drawable 后的 Gradle 陈旧合并**：本次新增 `drawable/launch_background.xml` 后，`flutter build apk` 报 `resource drawable/launch_background not found`，但文件存在、`aapt2 compile --dir android/app/src/main/res` 整树 exit 0。判定为 Gradle 增量资源合并的陈旧状态，执行 `cd android; .\gradlew :app:mergeDebugResources --rerun-tasks` 后构建通过。**下次新增资源文件若遇到同样的报错，先跑这条命令，不要去改 XML。**
4. **legacy 位图需要一次性生成**：`android/app/src/main/res/mipmap-*/ic_launcher.png` 由 `tool/brand/generate_legacy_icons.ps1` 生成（依赖本机 Chrome）。它们已提交进仓库，CI 不需要跑该脚本；若要重新生成，跑脚本后必须确认 `dart run tool/ci/check_brand_assets.dart` 仍然通过。

## 5 复现命令

```bash
flutter analyze
flutter test
dart run tool/ci/check_import_boundaries.dart
dart run tool/ci/check_brand_assets.dart
git diff --stat pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml   # 期望为空
pwsh -File tool/brand/generate_legacy_icons.ps1                                        # 仅在需要重导位图时
```
