# 听卷 图标与启动页 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把已确认的「线描展开书 + 书口声纹」图标与配套启动页落进 Android 资源层，让 API 24–36 的图标与冷启动画面正确、不白闪、可复算。

**Architecture:** 三层自适应图标全用 VectorDrawable（`mipmap-anydpi-v26/` + 两个 drawable + 一个颜色），API 24–25 回落 5 档位图；启动页分两条路径——API 31+ 用系统闪屏属性，API 24–30 用一张含 288dp 记印的 layer-list，并让 `NormalTheme` 复用同一张 layer-list 以消除「记印→纯色→首屏」跳变。资源正确性由 `tool/ci/check_brand_assets.dart` 门禁守（沿用仓库既有的 `tool/ci/*_rules.dart` + `check_*.dart` + `test/ci/*` 三件套）。

**Tech Stack:** Android 资源层（VectorDrawable / adaptive-icon / layer-list / values-* 限定符）、Dart 门禁脚本与 `flutter_test`、无头 Chrome（仅用于一次性导出 legacy 位图）。

**Spec:** `docs/tometone_brand_icon_splash.md`

## Global Constraints

- `minSdk 24`、`targetSdk 36`、`compileSdk 36`（`android/app/build.gradle.kts`）。
- **零新依赖**：`pubspec.yaml` / `pubspec.lock` diff 必须为空。
- **`AndroidManifest.xml` 零改动**（已指向 `@mipmap/ic_launcher`，自适应与位图两条路径都命中）。
- 品牌三色：墨蓝 `#FF0E2A3B`、纸白 `#FFF2F4E9`、青绿 `#FF58DCC1`；**不跟随**应用内 5 套色盘。
- 图标内**不含任何文字**；单色层**只用 alpha**、不带底色块。
- 内容外接直径 **≤ Ø56dp**（距 Ø66dp 官方安全圆余量 ≥ 5dp）。
- 冷启动 **≤ 800ms**：不设最小展示时长、不加自绘动效、不新增依赖。
- **不要碰同一工作树里其他会话正在改的文件**：`android/app/src/main/kotlin/**`、`lib/platform/saf/**`、`lib/ui/widgets/book_cover.dart`、`lib/contracts/media/**`、`lib/modules/storage_local/**`、`lib/modules/storage_saf/**`、`test/modules/**`、`test/ui/**`、`test/contracts/**`。
- 图标与启动页资源一律**手写 XML**；不引入 `flutter_launcher_icons` / `flutter_native_splash`（它们会覆盖 `anydpi-v26/` 与 `launch_background.xml`）。

## Review Focus

1. **ROM / 第三方启动器裁得比 Ø66 更狠** —— 用户期望图标内容完整、不贴边。Task 2 用 `conservativeRadius ≤ 28` 断言把它钉住。
2. **主题图标（API 33+）把线描压成剪影后细线糊掉** —— 用户期望还能认出「书 + 声纹」。Task 2 断言单色层笔宽被加粗（书 4.0dp / 声纹 4.4dp）且不含品牌色。
3. **API 24–30 的浅色启动页若无墨盘，纸白书页会落在纸白窗口底上而「消失」** —— 用户期望看到完整记印。Task 4 断言 `drawable/launch_mark.xml` 含墨盘、`drawable-night/launch_mark.xml` 不含。
4. **系统因对比不足而隐藏自适应图标的背景层时，纸白书页会落在浅色窗口底上** —— 用户期望仍看得见。Task 4 断言窗口底色与图标背景色对比度 ≥ 3:1。
5. **用户切到非默认色盘后，窗口底与首屏底色会有一帧不一致** —— 已知限制，无自动测试；Task 5 的人工核对里明确记录。

---

### Task 1: 品牌资源门禁骨架（规则 + 单元测试 + CLI）

**Files:**
- Create: `tool/ci/brand_asset_rules.dart`
- Create: `tool/ci/check_brand_assets.dart`
- Test: `test/ci/brand_asset_rules_test.dart`

**Interfaces:**
- Consumes: 无。
- Produces:
  - `double maxVertexDistance(List<double> pathNumbers)` —— 把 pathData 里按顺序出现的数字两两当作 (x,y)，返回相对画布中心 `(54,54)` 的**最大顶点距离**。
  - `double maxStrokeWidth(String xml)` —— 文件里最大的 `strokeWidth` 值；没有则返回 `0`。**含描边的实际外接 = `maxVertexDistance(...) + maxStrokeWidth(...) / 2`**（圆头/圆角连接下，顶点外扩最多为半个笔宽，这是外接的保守上界）。
  - `double contrastRatio(String argbA, String argbB)` —— WCAG 2.1 相对亮度对比度；入参接受 `#AARRGGBB` 或 `#RRGGBB`。
  - `(int width, int height)? pngSize(List<int> bytes)` —— 读 PNG 的 IHDR 宽高（大端）；不是 PNG 或长度 < 24 时返回 `null`。
  - `int? pngColorType(List<int> bytes)` —— 读 IHDR 的颜色类型字节（偏移 25）。**用于区分我们的位图与 Flutter 默认图**：默认图是调色板型 `3`，Chrome 截图是真彩型 `2`/`6`。
  - `List<String> pathDataOf(String xml)` —— 取出 XML 里所有 `android:pathData="…"` / `d="…"` 的内容。
  - `List<String> brandViolations({String root = '.'})` —— 返回违规说明；空 = 通过。
  - CLI：`dart run tool/ci/check_brand_assets.dart`，退出码 0 = 通过、1 = 违规、2 = 环境错误（不在仓库根目录）。

- [ ] **Step 1: 写失败的单元测试**

```dart
// test/ci/brand_asset_rules_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../tool/ci/brand_asset_rules.dart';

void main() {
  test('pngSize 读 IHDR 宽高', () {
    // 8 字节签名 + IHDR 长度/类型 + 宽 48 高 72（大端）
    final bytes = <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52,
      0, 0, 0, 48,
      0, 0, 0, 72,
    ];
    expect(pngSize(bytes), (48, 72));
    expect(pngSize(<int>[1, 2, 3]), isNull);
  });

  test('pngColorType 读颜色类型', () {
    final bytes = <int>[
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
      0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52,
      0, 0, 0, 48,
      0, 0, 0, 72,
      8, 6, 0, 0, 0,
    ];
    expect(pngColorType(bytes), 6);
  });

  test('maxVertexDistance 取最远顶点', () {
    // (54,54) 中心；(66,66) 距离 = sqrt(144+144) ≈ 16.97
    expect(maxVertexDistance(<double>[54, 54, 66, 66]), closeTo(16.97, 0.01));
  });

  test('maxStrokeWidth 取最大笔宽，缺失为 0', () {
    expect(maxStrokeWidth('<path android:strokeWidth="3"/><path android:strokeWidth="3.4"/>'), 3.4);
    expect(maxStrokeWidth('<path android:fillColor="#000"/>'), 0);
  });

  test('contrastRatio 符合 WCAG 2.1', () {
    // 纸白 #F2F4E9 vs 墨蓝 #0E2A3B ≈ 13.4:1（文档 §2 实测 13.37）
    expect(contrastRatio('#FFF2F4E9', '#FF0E2A3B'), closeTo(13.37, 0.01));
    // 同色为 1:1
    expect(contrastRatio('#FF0E2A3B', '#FF0E2A3B'), closeTo(1.0, 0.001));
  });

  test('pathDataOf 取出所有 pathData', () {
    const xml = '<path android:pathData="M1,2 L3,4"/><path android:pathData="M5,6"/>';
    expect(pathDataOf(xml), <String>['M1,2 L3,4', 'M5,6']);
  });
}
```

- [ ] **Step 2: 运行，确认失败**

Run: `flutter test test/ci/brand_asset_rules_test.dart`
Expected: FAIL —— `Error: Couldn't resolve the package ... brand_asset_rules.dart` / 找不到符号。

- [ ] **Step 3: 实现 `tool/ci/brand_asset_rules.dart`**

要点：`pngSize` 用大端读第 16–19 与 20–23 字节；`conservativeRadius` 用 `sqrt(dx*dx + dy*dy)` 取最大值（`dart:math`）；`pathDataOf` 用 `RegExp(r'pathData="([^"]*)"|d="([^"]*)"')`；`brandViolations` 本任务只实现文件存在性检查（下面列出的 4 个矢量源），其余检查由 Task 2/3/4 追加。文件头写清用途与退出码约定，风格对齐 `tool/ci/check_import_boundaries.dart`。

本任务 `brandViolations` 检查：`android/app/src/main/res/drawable/ic_launcher_foreground.xml` 存在；否则返回 `['缺少前景层 drawable/ic_launcher_foreground.xml']`。

- [ ] **Step 4: 实现 `tool/ci/check_brand_assets.dart`**

结构照抄 `check_import_boundaries.dart`：`Directory('android/app/src/main/res')` 不存在 → 退出码 2；`brandViolations()` 为空 → 打印 `√ 品牌资源检查通过`；否则逐条打印 `×` 并 `exitCode = 1`。

- [ ] **Step 5: 运行，确认单元测试通过、CLI 按预期报红**

Run: `flutter test test/ci/brand_asset_rules_test.dart`
Expected: PASS（3 个用例）

Run: `dart run tool/ci/check_brand_assets.dart`
Expected: 退出码 1，打印 `× 缺少前景层 drawable/ic_launcher_foreground.xml`（**这是本任务预期的红色状态**，Task 2 转绿）

- [ ] **Step 6: Commit**

```bash
git add tool/ci/brand_asset_rules.dart tool/ci/check_brand_assets.dart test/ci/brand_asset_rules_test.dart
git commit -m "test(ci): 品牌资源门禁骨架（规则 + CLI + 单元测试）"
```

---

### Task 2: 自适应图标三层（VectorDrawable + anydpi-v26）

**Files:**
- Create: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- Create: `android/app/src/main/res/drawable/ic_launcher_monochrome.xml`
- Create: `android/app/src/main/res/values/colors.xml`
- Create: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- Modify: `tool/ci/brand_asset_rules.dart`（追加图标检查）
- Test: `test/ci/brand_asset_test.dart`

**Interfaces:**
- Consumes: `brandViolations`、`conservativeRadius`、`pathDataOf`（Task 1）。
- Produces: 三个可被 Task 4 复用的 drawable 名（`@drawable/ic_launcher_foreground`、`@drawable/ic_launcher_monochrome`、`@color/ic_launcher_background`）；`values/colors.xml` 的 `brand_ink` / `brand_paper` / `brand_echo` 供 Task 4 引用。

**几何（108×108 画布，中心 54,54；改任何数字都要重跑门禁）**

| 元素 | 值 |
| :-- | :-- |
| 书页路径（一条闭合路径，描边不填充） | `M54,57.5 C48.5,52 42,51 34,52.5 L34,69.5 C42,68 48.5,69 54,75.5 C59.5,69 66,68 74,69.5 L74,52.5 C66,51 59.5,52 54,57.5 Z`（= 方向稿坐标整体下移 7.5dp 后烘焙进 pathData） |
| 声纹（一条路径，5 段竖线） | `M41,44.5 L41,40.5 M47.5,44.5 L47.5,33.5 M54,44.5 L54,29.5 M60.5,44.5 L60.5,35.5 M67,44.5 L67,39.5` |
| 描边宽度 | 前景：书 3dp / 声纹 3.4dp；**单色层加粗**：书 4.0dp / 声纹 4.4dp |
| 端头 | `strokeLineCap="round"`、`strokeLineJoin="round"`；书页 `fillColor="#00000000"` |
| 保守外接半径（顶点距离 + 半个笔宽） | 前景 27.0dp（Ø54.0）、单色 27.5dp（Ø55.0）→ 距 Ø66 余量 6.0 / 5.5dp |

- [ ] **Step 1: 写失败的集成测试**

```dart
// test/ci/brand_asset_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../tool/ci/brand_asset_rules.dart';

void main() {
  test('品牌资源门禁：当前仓库无违规', () {
    expect(brandViolations(), isEmpty);
  });
}
```

- [ ] **Step 2: 运行，确认失败**

Run: `flutter test test/ci/brand_asset_test.dart`
Expected: FAIL，`["缺少前景层 drawable/ic_launcher_foreground.xml"]`

- [ ] **Step 3: 追加图标检查到 `brandViolations`**

逐条实现（每条都返回一句可读的违规说明，含实际值与期望值）：
1. `values/colors.xml` 存在，且 `ic_launcher_background` 的值恰为 `#FF0E2A3B`。
2. `mipmap-anydpi-v26/ic_launcher.xml` 同时含 `@color/ic_launcher_background`、`@drawable/ic_launcher_foreground`、`@drawable/ic_launcher_monochrome`。
3. 前景层与单色层：`maxVertexDistance(pathDataOf(...)) + maxStrokeWidth(...) / 2` ≤ `28.0`（实测前景 27.0、单色 27.5）。
4. 单色层：不含 `58DCC1` 与 `F2F4E9`；且 `strokeWidth="4"`（书）与 `strokeWidth="4.4"`（声纹）都在。
5. 前景层：不含 `0E2A3B`（不得自带底色），且含 `strokeColor="#FFF2F4E9"` 与 `strokeColor="#FF58DCC1"`。

- [ ] **Step 4: 创建 `values/colors.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- 品牌三色（docs/tometone_brand_icon_splash.md §2）：图标与启动页共用，不跟随应用内色盘。 -->
    <color name="brand_ink">#FF0E2A3B</color>
    <color name="brand_paper">#FFF2F4E9</color>
    <color name="brand_echo">#FF58DCC1</color>
    <!-- 自适应图标背景层：满幅不透明，不得有透明边。 -->
    <color name="ic_launcher_background">#FF0E2A3B</color>
</resources>
```

- [ ] **Step 5: 创建 `drawable/ic_launcher_foreground.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- 前景层：线描展开书 + 书口上升的五根声纹。
     108dp 画布；内容保守外接 Ø54.2dp（距 Ø66 安全圆 5.9dp）。
     改几何或笔宽后必须重跑 dart run tool/ci/check_brand_assets.dart。 -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:pathData="M54,55 C50,51.5 44.5,50.6 39,52 L39,74 C44.5,72.6 50,73.4 54,77.5 C58,73.4 63.5,72.6 69,74 L69,52 C63.5,50.6 58,51.5 54,55 Z"
        android:fillColor="#00000000"
        android:strokeColor="#FFF2F4E9"
        android:strokeWidth="3"
        android:strokeLineCap="round"
        android:strokeLineJoin="round" />
    <path
        android:pathData="M43,54.5 L43,41.5 M48.5,54.5 L48.5,37.5 M54,54.5 L54,34.2 M59.5,54.5 L59.5,37.5 M65,54.5 L65,41.5"
        android:fillColor="#00000000"
        android:strokeColor="#FF58DCC1"
        android:strokeWidth="3.4"
        android:strokeLineCap="round" />
</vector>
```

- [ ] **Step 6: 创建 `drawable/ic_launcher_monochrome.xml`**

同 Step 5 的两条 `pathData` 逐值一致，只改：`strokeColor="#FF000000"`、书 `strokeWidth="4"`、声纹 `strokeWidth="4.4"`；**不得**出现墨盘或任何品牌色。

- [ ] **Step 7: 创建 `mipmap-anydpi-v26/ic_launcher.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- API 26+ 自适应图标。monochrome 是 API 33 属性，放在 -v26 里对 26–32 无害。 -->
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
```

- [ ] **Step 8: 运行门禁与测试**

Run: `dart run tool/ci/check_brand_assets.dart && flutter test test/ci`
Expected: 门禁退出码 0；`test/ci` 全绿

- [ ] **Step 9: 目视自检**

Run: `flutter build apk --debug`
Expected: 构建成功（资源可编译）。随后把 `android/app/src/main/res/drawable/ic_launcher_foreground.xml` 的三条图层叠加后与 `docs/design-preview/icon-v3/preview/sheet.png` 第 01 段对照，形状一致。

- [ ] **Step 10: Commit**

```bash
git add android/app/src/main/res/drawable/ic_launcher_foreground.xml \
        android/app/src/main/res/drawable/ic_launcher_monochrome.xml \
        android/app/src/main/res/values/colors.xml \
        android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml \
        tool/ci/brand_asset_rules.dart test/ci/brand_asset_test.dart
git commit -m "feat(icon): 自适应图标三层（前景/背景/单色）+ 资源门禁"
```

---

### Task 3: legacy 五档位图（API 24–25）

**Files:**
- Create: `tool/brand/generate_legacy_icons.ps1`
- Modify: `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`（覆盖 Flutter 默认图）
- Modify: `tool/ci/brand_asset_rules.dart`（追加位图检查）
- Modify: `test/ci/brand_asset_test.dart`（追加位图断言）

**Interfaces:**
- Consumes: Task 2 的两条 `pathData` 与三个色值。
- Produces: 5 个精确尺寸的 PNG（48/72/96/144/192），供 API 24–25 与 `values` 之外的回落路径使用。

**关键**：位图内容取自画布**中央 72dp 区域**（`viewBox="18 18 72 72"`），不是整个 108dp 画布——否则老安卓上的 mark 会比自适应小一圈。

- [ ] **Step 1: 追加失败的位图测试**

在 `test/ci/brand_asset_test.dart` 增加：

```dart
test('legacy 位图存在、尺寸精确、且不是 Flutter 默认图', () {
  const expected = <String, int>{
    'mipmap-mdpi': 48, 'mipmap-hdpi': 72, 'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192,
  };
  expected.forEach((dir, size) {
    final file = File('android/app/src/main/res/$dir/ic_launcher.png');
    expect(file.existsSync(), isTrue, reason: '缺少 $dir/ic_launcher.png');
    final bytes = file.readAsBytesSync();
    expect(pngSize(bytes), (size, size), reason: '$dir 尺寸不对');
    // Flutter 默认图标是调色板型（3）；我们的 Chrome 截图是真彩型（2/6）。
    expect(pngColorType(bytes), isNot(3), reason: '$dir 仍是 Flutter 默认位图');
  });
});
```

- [ ] **Step 2: 运行，确认失败**

Run: `flutter test test/ci/brand_asset_test.dart`
Expected: FAIL —— 5 个密度的**尺寸本来就是对**的（默认图同样是 48/72/96/144/192），失败来自最后一条断言：`mipmap-mdpi 仍是 Flutter 默认位图`（实测 `pngColorType` = 3）。这条断言就是「位图确实被我们替换过」的守门人。

- [ ] **Step 3: 写生成脚本 `tool/brand/generate_legacy_icons.ps1`**

脚本对 `mdpi 48 / hdpi 72 / xhdpi 96 / xxhdpi 144 / xxxhdpi 192` 各生成一张 SVG 到临时目录再截图：

```powershell
# 每个尺寸一份 SVG：width/height = 目标像素，viewBox = 中央 72dp 区域
#   <svg width="N" height="N" viewBox="18 18 72 72">
#     <rect x="18" y="18" width="72" height="72" fill="#0E2A3B"/>
#     <g fill="none" stroke-linecap="round" stroke-linejoin="round">
#       <path d="<书页 pathData>" stroke="#F2F4E9" stroke-width="3"/>
#       <path d="<声纹 pathData>" stroke="#58DCC1" stroke-width="3.4"/>
#     </g>
#   </svg>
# 截图：--window-size=N,N --force-device-scale-factor=1 --hide-scrollbars --no-first-run
#       --user-data-dir=<每张独立临时目录>   <-- 复用 profile 会互相抢锁
# 落盘：android/app/src/main/res/mipmap-<density>/ic_launcher.png
# 截图返回后 Chrome 仍在异步写盘：必须轮询确认文件存在且大小 > 0 再继续
```

- [ ] **Step 4: 追加位图检查到 `brandViolations`**

对 5 个路径断言：文件存在；`pngSize` 的宽高恰为 48/72/96/144/192；`pngColorType` **不是** `3`（不是 Flutter 默认图）。PNG 用位图检查而非几何检查（几何已由矢量层守）。

- [ ] **Step 5: 生成并验证**

Run: `pwsh -File tool/brand/generate_legacy_icons.ps1`
Expected: 5 个文件被覆盖，无 `Err_FILE_NOT_FOUND`

Run: `dart run tool/ci/check_brand_assets.dart && flutter test test/ci`
Expected: 全绿

- [ ] **Step 6: 目视自检**

把 `mipmap-xxxhdpi/ic_launcher.png`（192px）缩小到 48px 查看：书页轮廓与中间三根声纹可分；四角不透明（不得出现透明圆角）。

- [ ] **Step 7: Commit**

```bash
git add tool/brand/generate_legacy_icons.ps1 tool/ci/brand_asset_rules.dart test/ci/brand_asset_test.dart \
        android/app/src/main/res/mipmap-mdpi/ic_launcher.png \
        android/app/src/main/res/mipmap-hdpi/ic_launcher.png \
        android/app/src/main/res/mipmap-xhdpi/ic_launcher.png \
        android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png \
        android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
git commit -m "feat(icon): legacy 五档位图（中央 72dp 裁切）+ 生成脚本"
```

---

### Task 4: 启动页资源与主题（API 24–36）

**Files:**
- Create: `android/app/src/main/res/drawable/launch_mark.xml`
- Create: `android/app/src/main/res/drawable-night/launch_mark.xml`
- Create: `android/app/src/main/res/values-night/colors.xml`
- Create: `android/app/src/main/res/values-v31/styles.xml`
- Create: `android/app/src/main/res/values-night-v31/styles.xml`
- Modify: `android/app/src/main/res/values/colors.xml`（加 `splash_window_background`）
- Modify: `android/app/src/main/res/drawable/launch_background.xml`
- Delete: `android/app/src/main/res/drawable-v21/launch_background.xml`
- Modify: `android/app/src/main/res/values/styles.xml`
- Modify: `android/app/src/main/res/values-night/styles.xml`
- Modify: `tool/ci/brand_asset_rules.dart`（追加启动页检查）

**Interfaces:**
- Consumes: `@drawable/ic_launcher_foreground` 的两条 `pathData`、`brand_ink` / `brand_paper` / `brand_echo`。
- Produces: `@drawable/launch_background`（同时被 `LaunchTheme` 与 `NormalTheme` 引用，这是防白闪的关键）、`@drawable/launch_mark`（288dp）、`@color/splash_window_background`。

**几何对齐**：`launch_mark.xml` 声明 **288dp**、viewport 108，墨盘 `r=36` → 渲染 Ø192dp。实测依据：不设 `windowSplashScreenIconBackgroundColor` 时，12+ 走「不带 icon background」分支（288dp 画布 / Ø192dp 可见圆），API 36 模拟器上量到墨盘 504px @420dpi = 192dp。mark 外接 27.0dp → 渲染 Ø144dp。若按文档里的 240dp/Ø160dp 写，系统闪屏会比应用窗口底大 20%。

- [ ] **Step 1: 追加失败的启动页断言**

在 `brandViolations` 追加（先写断言，再改资源）：
1. `drawable/launch_mark.xml` 含 `fillColor="#FF0E2A3B"` 的圆盘路径；`drawable-night/launch_mark.xml` **不含**该色。
2. `drawable/launch_background.xml` 的第一层精确等于 `@color/splash_window_background`，且含 `android:width="288dp"` 与 `@drawable/launch_mark`。
3. `values/styles.xml` 与 `values-night/styles.xml` **必须各自定义 `LaunchTheme` 与 `NormalTheme`**，两者的 `windowBackground` 都精确等于 `@drawable/launch_background`（v31 文件只定义 `LaunchTheme`，按资源名解析会正确回落到这两份 `NormalTheme`）。v31 两个文件里 `windowSplashScreenBackground` 精确等于 `@color/splash_window_background`、`windowSplashScreenAnimatedIcon` 精确等于 `@mipmap/ic_launcher`。
4. `values/colors.xml` 的 `splash_window_background` = `#FFF2F4E9`；`values-night/colors.xml` 的 = `#FF0E2A3B`。
5. 对比度：`splash_window_background`（昼）与 `ic_launcher_background` 的 WCAG 比值 ≥ 3.0（用 Task 1 已实现的 `contrastRatio`；实测 13.37:1）。

- [ ] **Step 2: 运行，确认失败**

Run: `flutter test test/ci/brand_asset_test.dart`
Expected: FAIL，列出启动页相关违规

- [ ] **Step 3: 改 `values/colors.xml`、新建 `values-night/colors.xml`**

`values/colors.xml` 追加：

```xml
    <!-- 启动窗口底/记印底：昼=纸白；夜在 values-night 覆盖为墨蓝。 -->
    <color name="splash_window_background">#FFF2F4E9</color>
```

`values-night/colors.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- 夜间窗口底：深色首屏之前不再闪白。 -->
    <color name="splash_window_background">#FF0E2A3B</color>
</resources>
```

- [ ] **Step 4: 新建 `drawable/launch_mark.xml`（昼：带墨盘）**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- 昼：宣纸窗口上的墨盘记印。声明 288dp = 12+ 系统闪屏「不带 icon background」分支的画布尺寸。
     墨盘 r=36 ／ 108 × 288 → Ø192dp；mark 外接 27.0dp → Ø144dp。 -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="288dp"
    android:height="288dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:pathData="M18,54 A36,36 0 1,0 90,54 A36,36 0 1,0 18,54 Z"
        android:fillColor="#FF0E2A3B" />
    <!-- 以下两条与 drawable/ic_launcher_foreground.xml 逐值一致 -->
    <path
        android:pathData="M54,55 C50,51.5 44.5,50.6 39,52 L39,74 C44.5,72.6 50,73.4 54,77.5 C58,73.4 63.5,72.6 69,74 L69,52 C63.5,50.6 58,51.5 54,55 Z"
        android:fillColor="#00000000"
        android:strokeColor="#FFF2F4E9"
        android:strokeWidth="3"
        android:strokeLineCap="round"
        android:strokeLineJoin="round" />
    <path
        android:pathData="M43,54.5 L43,41.5 M48.5,54.5 L48.5,37.5 M54,54.5 L54,34.2 M59.5,54.5 L59.5,37.5 M65,54.5 L65,41.5"
        android:fillColor="#00000000"
        android:strokeColor="#FF58DCC1"
        android:strokeWidth="3.4"
        android:strokeLineCap="round" />
</vector>
```

- [ ] **Step 5: 新建 `drawable-night/launch_mark.xml`**

内容同 Step 4，**只删掉墨盘那条 `path`**（夜：金/纸纹直接浮在墨色窗口底上）。

- [ ] **Step 6: 重写 `drawable/launch_background.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- 启动窗口底：一层纯色 + 居中 288dp 记印。API 24–30 的启动画面就是这张；
     API 31+ 由系统闪屏接管，NormalTheme 复用同一张以消除「记印→纯色→首屏」跳变。 -->
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_window_background" />
    <item
        android:width="288dp"
        android:height="288dp"
        android:gravity="center"
        android:drawable="@drawable/launch_mark" />
</layer-list>
```

- [ ] **Step 7: 删除 `drawable-v21/launch_background.xml`**

Run: `git rm android/app/src/main/res/drawable-v21/launch_background.xml`
理由：minSdk 已是 24，v21 变体没有存在意义，留着会让将来调 minSdk 时行为不可预测。

- [ ] **Step 8: 改 `values/styles.xml` 与 `values-night/styles.xml`**

两个文件里 `NormalTheme` 的 `windowBackground` 从 `?android:colorBackground` 改为 `@drawable/launch_background`（`LaunchTheme` 不动）。`parent` 保持原样（昼 `Theme.Light.NoTitleBar` / 夜 `Theme.Black.NoTitleBar`）。

- [ ] **Step 9: 新建 `values-v31/styles.xml` 与 `values-night-v31/styles.xml`**

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- API 31+：系统闪屏。只定义 LaunchTheme；NormalTheme 沿用 values/styles.xml。
     windowSplashScreenBehavior 是 API 33 属性，在 31–32 上被忽略（compileSdk 36 可编译）。
     不设 windowSplashScreenIconBackgroundColor：让系统按窗口底与图标背景层的对比度
     自动决定显示或隐藏墨盘（浅色显示 / 深色隐藏），两种形态由同一份图标资源得出。 -->
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/splash_window_background</item>
        <item name="android:windowSplashScreenAnimatedIcon">@mipmap/ic_launcher</item>
        <item name="android:windowSplashScreenBehavior">icon_preferred</item>
    </style>
</resources>
```

`values-night-v31/styles.xml` 与之逐行相同，只把 `parent` 换成 `@android:style/Theme.Black.NoTitleBar`。

- [ ] **Step 10: 运行门禁与构建**

Run: `dart run tool/ci/check_brand_assets.dart && flutter test test/ci`
Expected: 全绿

Run: `flutter build apk --debug`
Expected: 构建成功

- [ ] **Step 11: Commit**

```bash
git add android/app/src/main/res/values/colors.xml \
        android/app/src/main/res/values-night/colors.xml \
        android/app/src/main/res/drawable/launch_mark.xml \
        android/app/src/main/res/drawable-night/launch_mark.xml \
        android/app/src/main/res/drawable/launch_background.xml \
        android/app/src/main/res/values/styles.xml \
        android/app/src/main/res/values-night/styles.xml \
        android/app/src/main/res/values-v31/styles.xml \
        android/app/src/main/res/values-night-v31/styles.xml \
        tool/ci/brand_asset_rules.dart test/ci/brand_asset_test.dart
git commit -m "feat(splash): 启动页记印与双路径主题（含防白闪）"
```

---

### Task 5: 端到端验证与真机清单

**Files:**
- Create: `docs/tometone_icon_splash_verification.md`

**Interfaces:**
- Consumes: Task 1–4 的全部产物。
- Produces: 一份可被他人照着复跑的验收记录（含实测数值与未通过项）。

- [ ] **Step 1: 跑三道自动门禁并记录输出**

```bash
flutter analyze                                   # 期望：0 错误 0 警告
flutter test                                      # 期望：全绿
dart run tool/ci/check_import_boundaries.dart     # 期望：√ 依赖方向检查通过
dart run tool/ci/check_brand_assets.dart          # 期望：√ 品牌资源检查通过
```

- [ ] **Step 2: 确认仓库卫生**

```bash
git diff --stat pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml
```
Expected: 空输出（零依赖、manifest 零改动）

```bash
git status --short
```
Expected: 只有本计划涉及的文件；其他会话的文件（`lib/platform/saf/**`、`lib/ui/widgets/book_cover.dart`、`android/app/src/main/kotlin/**` 等）保持原状

- [ ] **Step 3: 模拟器上核对 API 33+ 形态（能自证的部分）**

Run: `flutter run -d Medium_Phone_API_36.1`
核对：图标出现为「墨蓝底 + 纸白书 + 青绿声纹」；长按图标不出错；系统设置里开启「主题图标」后剪影仍能读出书与声纹。

- [ ] **Step 4: 真机项（需要设备，逐条记录实测值）**

| # | 查什么 | 命令 / 方法 | 通过 |
| :-- | :-- | :-- | :-- |
| B1 | 12+ 浅色：墨盘由系统显示 | `adb shell am force-stop com.tometone.app` 后冷启截图 | 纸白底 + 墨盘记印 |
| B2 | 12+ 深色：墨盘隐去 | 系统切深色后同 B1 | 墨底 + 纸白书 + 青绿声纹，无墨盘块 |
| B3 | 冷启动不回归 800ms | `adb shell am start -W com.tometone.app/.MainActivity` 连测 10 次取 `TotalTime` 中位数 | 中位数 ≤ 800ms，且比改前基线退化 ≤ 20ms |
| B4 | 无白闪、底色不跳 | `adb shell screenrecord` 冷启 5s，逐帧看首屏内容出现**之前**的帧 | ① 无平均亮度 ≥ 0.95 的帧；② 相邻帧底色最大通道差 ≤ 8/255；③ 无纯白像素占比 > 1% 的帧 |
| B5 | 无最小展示时长 | `grep -rn "KeepOnScreen\|postDelayed\|Thread.sleep" android/app/src/main` | 无匹配 |
| B6 | 两条分支画面一致 | API 30 与 API 31 各截一张 | 记印大小与位置一致（288dp 画布 / Ø192dp 可见圆对齐）；**位置**必须实测，layer-list 在窗口内居中、系统闪屏在全屏居中，可能差半个状态栏 |
| B7 | 24–30 分支 | API 30 模拟器（模拟器不算通过，仅作形似核对）+ 可用时真机 | 纸白底 + 墨盘记印，无裸白屏 |

- [ ] **Step 5: 记录已知限制（必须写进验收文档）**

用户切到非默认色盘时，`NormalTheme` 的窗口底仍是默认色盘的 surface 值，首帧可能出现**一帧**底色不一致；这是为了不在冷启动路径上同步读 SharedPreferences 而接受的代价。

- [ ] **Step 6: Commit**

```bash
git add docs/tometone_icon_splash_verification.md
git commit -m "docs(icon): 图标与启动页验收记录"
```

---

## 计划外的待决项（不要在本计划里实现）

**标语「听见故事，看见文字。」/「Listen to the story. Follow every word.」的落点未定。** `lib/main.dart` 在 `runApp` 前只做同步装配、没有任何可等待的初始化，因此**没有**可让「品牌页」等待的时机：加一个 Flutter 品牌页只会人为增加启动耗时，与 ≤800ms 预算冲突。落点需要用户在以下两者中选一个，再单独计划：

- **A**：标语只出现在应用内（设置/关于区、书架空态）；启动体验完全交给原生闪屏（推荐，零额外启动耗时）。
- **B**：确实要一个启动时的品牌页，则必须接受一个**最小展示时长**（如 400ms），并单独评估它对 800ms 预算的影响。
