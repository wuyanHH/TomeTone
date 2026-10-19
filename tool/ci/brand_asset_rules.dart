import 'dart:io';
import 'dart:math' as math;

/// 品牌资源门禁规则（图标三层 + 启动页），《tometone_brand_icon_splash.md》的机器可读版本。
///
/// 与 `import_boundary_rules.dart` 同构：本文件只放纯函数与文件读取，
/// 命令行包装见 `check_brand_assets.dart`，测试见 `test/ci/*`。
///
/// 为什么需要它：图标与启动页是资源层，`flutter analyze` 与 `flutter test` 都看不见
/// 它们的正确性——三层资源是否齐、内容是否落在自适应图标安全圆内、旧安卓位图是否是
/// 我们自己生成的、`NormalTheme` 是否还引用着会白闪的系统色。这些错一旦上线只会
/// 在真机上表现为「图标被切」「闪白」「老机器上用默认图标」，因此全部写成可复算的断言。
///
/// **判定口径是「精确值」而不是「黑名单」**：把白底换成另一个白、把 transform 挪出
/// 安全圆、把单色层清空只留注释，都必须被抓到。对应的反向用例在
/// `test/ci/brand_asset_gate_test.dart`。

/// 108dp 画布的坐标系中心；外接判定一律相对它。
const double canvasCentre = 54;

/// 品牌资源的仓库相对根目录。
const String brandResRoot = 'android/app/src/main/res';

/// 前景层（书页 + 声纹）。
const String foregroundAsset = '$brandResRoot/drawable/ic_launcher_foreground.xml';

/// 单色层（API 33+ 主题图标，只用 alpha）。
const String monochromeAsset = '$brandResRoot/drawable/ic_launcher_monochrome.xml';

/// 昼间记印（带墨盘）。
const String dayMarkAsset = '$brandResRoot/drawable/launch_mark.xml';

/// 夜间记印（不带墨盘）。
const String nightMarkAsset = '$brandResRoot/drawable-night/launch_mark.xml';

/// 对外接上限（半径，dp）：内容必须落在 Ø56dp 内，距 Ø66dp 安全圆留 ≥5dp。
const double maxContentRadius = 28.0;

/// 启动页记印的声明尺寸。
///
/// **实测依据**：不设 `windowSplashScreenIconBackgroundColor` 时，Android 12+ 走的是
/// 「无 icon background」分支——288dp 画布 / Ø192dp 可见圆（模拟器 API 36 上量到
/// 墨盘 504px @420dpi = 192dp）。因此 layer-list 的记印也必须是 288dp，
/// 两条分支才会是同一画面而不是「大记印 → 小一号记印」。
const String splashMarkSize = '288dp';

/// 读取 PNG 的 IHDR 宽高；不是 PNG 或长度不足时返回 null。
(int width, int height)? pngSize(List<int> bytes) {
  if (!_isPng(bytes) || bytes.length < 24) {
    return null;
  }
  return (_readUint32(bytes, 16), _readUint32(bytes, 20));
}

/// 读取 PNG 的颜色类型（IHDR 偏移 25）：3 = 调色板型（Flutter 默认图就是它），
/// 2 = 真彩型（我们的截图；无 alpha），6 = 真彩 + alpha（会露出透明圆角）。
int? pngColorType(List<int> bytes) {
  if (!_isPng(bytes) || bytes.length < 26) {
    return null;
  }
  return bytes[25];
}

/// 取出 XML 里所有 `pathData` / `d` 属性值。
///
/// 用负向后行断言排除 `android:id="…"` 这类以 `d=` 结尾的属性名。
List<String> pathDataOf(String xml) {
  final matches = RegExp(r'(?<![A-Za-z0-9_])(?:pathData|d)="([^"]*)"').allMatches(xml);
  return matches.map((match) => match.group(1)!).toList();
}

/// 把 pathData 的数字两两当作 (x,y)，返回相对画布中心的最远顶点距离。
double maxVertexDistance(List<double> pathNumbers) {
  var farthest = 0.0;
  for (var index = 0; index + 1 < pathNumbers.length; index += 2) {
    final dx = pathNumbers[index] - canvasCentre;
    final dy = pathNumbers[index + 1] - canvasCentre;
    farthest = math.max(farthest, math.sqrt(dx * dx + dy * dy));
  }
  return farthest;
}

/// 文件里最大的 `strokeWidth`；没有则返回 0。
double maxStrokeWidth(String xml) {
  final matches = RegExp(r'strokeWidth="([0-9.]+)"').allMatches(xml);
  var widest = 0.0;
  for (final match in matches) {
    widest = math.max(widest, double.parse(match.group(1)!));
  }
  return widest;
}

/// 含描边的保守外接半径 = 最远顶点距离 + 半个笔宽。
///
/// 圆头 / 圆角连接下，描边在顶点处最多外扩半个笔宽，因此这是外接的上界。
/// 前提：pathData 只用绝对坐标、且数字成对出现（本仓库的三层资源满足；门禁会校验）。
double contentRadius(String xml) =>
    maxVertexDistance(_numbersOf(pathDataOf(xml).join(' '))) + maxStrokeWidth(xml) / 2;

/// WCAG 2.1 对比度；入参接受 `#AARRGGBB` 或 `#RRGGBB`。
double contrastRatio(String argbA, String argbB) {
  final a = _relativeLuminance(argbA);
  final b = _relativeLuminance(argbB);
  return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
}

/// 校验品牌资源，返回违规说明；空列表 = 通过。
List<String> brandViolations({String root = '.'}) {
  final violations = <String>[];

  final foreground = _readFile(root, foregroundAsset);
  final monochrome = _readFile(root, monochromeAsset);

  _checkIconLayer(
    violations,
    asset: foregroundAsset,
    xml: foreground,
    expectedStrokes: const <double>[3.0, 3.4],
    requiredColors: const <String>['#FFF2F4E9', '#FF58DCC1'],
    forbiddenColors: const <String>['0E2A3B'],
  );

  _checkIconLayer(
    violations,
    asset: monochromeAsset,
    xml: monochrome,
    expectedStrokes: const <double>[4.0, 4.4],
    requiredColors: const <String>['#FF000000'],
    // 单色层只允许 alpha：任何品牌色都会在系统 tint 下变成"脏色块"。
    forbiddenColors: const <String>['58DCC1', 'F2F4E9', '0E2A3B'],
  );

  _checkColors(violations, root);
  _checkAdaptiveIcon(violations, root);
  _checkLegacyBitmaps(violations, root);
  _checkLaunchArtwork(violations, root, foreground);
  _checkLaunchThemes(violations, root);

  return violations;
}

/// 单层图标：禁 transform、笔宽精确、外接在安全圆内、颜色符合该层的职责。
void _checkIconLayer(
  List<String> violations, {
  required String asset,
  required String? xml,
  required List<double> expectedStrokes,
  required List<String> requiredColors,
  required List<String> forbiddenColors,
}) {
  if (xml == null) {
    violations.add('缺少 $asset');
    return;
  }

  final body = _stripComments(xml);

  // transform 会让门禁"看到的坐标"与"屏幕上的坐标"不一致，直接禁用。
  if (body.contains('<group')) {
    violations.add('$asset 不允许使用 <group>（门禁按 pathData 复算外接，transform 会成为盲区）');
  }
  for (final attribute in <String>['translateX', 'translateY', 'scaleX', 'scaleY', 'rotate']) {
    if (body.contains(attribute)) {
      violations.add('$asset 不允许使用 $attribute（同上：transform 会破坏外接复算）');
    }
  }

  final paths = RegExp(r'<path\b').allMatches(body).length;
  if (paths == 0) {
    violations.add('$asset 没有任何 <path>（空层会让主题图标整片空白）');
  }

  final strokes = RegExp(r'strokeWidth="([0-9.]+)"')
      .allMatches(body)
      .map((match) => double.parse(match.group(1)!))
      .toSet();
  final expected = expectedStrokes.toSet();
  if (strokes.length != expected.length || !strokes.containsAll(expected)) {
    violations.add('$asset 的笔宽应为 $expected，实际 $strokes');
  }

  for (final color in requiredColors) {
    if (!body.contains('strokeColor="$color"')) {
      violations.add('$asset 缺少 strokeColor="$color"');
    }
  }
  for (final color in forbiddenColors) {
    if (body.toUpperCase().contains(color)) {
      violations.add('$asset 不得出现 $color');
    }
  }

  final radius = contentRadius(body);
  if (radius > maxContentRadius) {
    violations.add(
      '$asset 外接 Ø${(radius * 2).toStringAsFixed(1)}dp 超出上限 '
      'Ø${(maxContentRadius * 2).toStringAsFixed(0)}dp（距 Ø66 安全圆不足 5dp）',
    );
  }
}

void _checkColors(List<String> violations, String root) {
  final colors = _readFile(root, '$brandResRoot/values/colors.xml');
  if (colors == null) {
    violations.add('缺少 values/colors.xml');
    return;
  }
  final background = _colorValue(colors, 'ic_launcher_background');
  if (background?.toUpperCase() != '#FF0E2A3B') {
    violations.add('ic_launcher_background 应为 #FF0E2A3B，实际 ${background ?? '缺失'}');
  }

  final nightColors = _readFile(root, '$brandResRoot/values-night/colors.xml');
  if (nightColors == null) {
    violations.add('缺少 values-night/colors.xml');
  }

  final daySplash = _colorValue(colors, 'splash_window_background');
  final nightSplash = nightColors == null ? null : _colorValue(nightColors, 'splash_window_background');
  if (daySplash?.toUpperCase() != '#FFF2F4E9') {
    violations.add('splash_window_background（昼）应为 #FFF2F4E9，实际 ${daySplash ?? '缺失'}');
  }
  if (nightSplash?.toUpperCase() != '#FF0E2A3B') {
    violations.add('splash_window_background（夜）应为 #FF0E2A3B，实际 ${nightSplash ?? '缺失'}');
  }

  // 系统会按「窗口底 vs 图标背景层」的对比度决定是否显示图标的背景层。
  // 昼底（纸白）必须与图标背景（墨蓝）足量对比，否则墨盘被隐去、
  // 纸白书页会落在纸白窗口底上而看不见。
  if (daySplash != null) {
    final ratio = contrastRatio(daySplash, '#FF0E2A3B');
    if (ratio < 3.0) {
      violations.add('启动页昼底与图标背景对比度 ${ratio.toStringAsFixed(2)}:1 低于 3:1');
    }
  }
}

void _checkAdaptiveIcon(List<String> violations, String root) {
  final adaptive = _readFile(root, '$brandResRoot/mipmap-anydpi-v26/ic_launcher.xml');
  if (adaptive == null) {
    violations.add('缺少 mipmap-anydpi-v26/ic_launcher.xml');
    return;
  }
  for (final reference in <String>[
    '@color/ic_launcher_background',
    '@drawable/ic_launcher_foreground',
    '@drawable/ic_launcher_monochrome',
  ]) {
    if (!_stripComments(adaptive).contains(reference)) {
      violations.add('mipmap-anydpi-v26/ic_launcher.xml 缺少 $reference');
    }
  }
}

void _checkLegacyBitmaps(List<String> violations, String root) {
  // API 24–25 没有自适应图标，回落位图。尺寸错会让启动器缩放模糊；
  // 调色板型（3）说明它还是 Flutter 默认图；带 alpha 会露出透明圆角。
  const densities = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  densities.forEach((density, expected) {
    final path = '$brandResRoot/$density/ic_launcher.png';
    final file = File('$root/$path');
    if (!file.existsSync()) {
      violations.add('缺少 $path');
      return;
    }
    final bytes = file.readAsBytesSync();
    final size = pngSize(bytes);
    if (size == null) {
      violations.add('$path 不是可解析的 PNG');
    } else if (size.$1 != expected || size.$2 != expected) {
      violations.add('$path 尺寸应为 $expected×$expected，实际 ${size.$1}×${size.$2}');
    }
    if (pngColorType(bytes) != 2) {
      violations.add(
        '$path 应为真彩无 alpha 的 PNG（colorType=2）：3 说明仍是 Flutter 默认图，'
        '6 说明带了透明圆角；请运行 tool/brand/generate_legacy_icons.ps1',
      );
    }
  });
}

void _checkLaunchArtwork(List<String> violations, String root, String? foreground) {
  final dayMark = _readFile(root, dayMarkAsset);
  final nightMark = _readFile(root, nightMarkAsset);

  if (dayMark == null) {
    violations.add('缺少 drawable/launch_mark.xml');
  } else {
    final body = _stripComments(dayMark);
    // 昼：宣纸底上必须自带墨盘，否则纸白书页会"消失"。
    if (!body.contains('fillColor="#FF0E2A3B"') || !body.contains('A36,36')) {
      violations.add('drawable/launch_mark.xml 缺少 r=36 的墨盘（昼底上纸白书页会看不见）');
    }
    if (!body.contains('android:width="$splashMarkSize"')) {
      violations.add('drawable/launch_mark.xml 的声明宽度应为 $splashMarkSize（与 12+ 系统闪屏的可见圆对齐）');
    }
  }

  if (nightMark == null) {
    violations.add('缺少 drawable-night/launch_mark.xml');
  } else {
    final body = _stripComments(nightMark);
    if (body.toUpperCase().contains('0E2A3B')) {
      violations.add('drawable-night/launch_mark.xml 不应带墨盘（夜：纸纹直接浮在墨底上）');
    }
    if (!body.contains('android:width="$splashMarkSize"')) {
      violations.add('drawable-night/launch_mark.xml 的声明宽度应为 $splashMarkSize');
    }
  }

  // 三份矢量（前景 / 昼记印 / 夜记印）必须逐值同构：改了图标却忘了启动页，
  // 会悄悄留下两个形状，而所有门禁仍然绿。
  if (foreground != null && dayMark != null && nightMark != null) {
    final reference = _normalizedPaths(foreground).toSet();
    final dayPaths = _normalizedPaths(dayMark);
    final nightPaths = _normalizedPaths(nightMark);
    // 昼间只允许比前景层多一条墨盘 path（r=36），其余必须逐值相同；
    // 夜间不允许有任何额外 path。改了图标却忘了启动页，会在这里被抓住。
    if (!dayPaths.toSet().containsAll(reference) || dayPaths.length != reference.length + 1) {
      violations.add('$dayMarkAsset 的书页/声纹 pathData 与 $foregroundAsset 不一致（昼间只应多一条墨盘 path）');
    }
    if (!nightPaths.toSet().containsAll(reference) || nightPaths.length != reference.length) {
      violations.add('$nightMarkAsset 的书页/声纹 pathData 与 $foregroundAsset 不一致（夜间不应有额外 path）');
    }
  }

  final background = _readFile(root, '$brandResRoot/drawable/launch_background.xml');
  if (background == null) {
    violations.add('缺少 drawable/launch_background.xml');
    return;
  }
  final body = _stripComments(background);
  // 底色必须是那个颜色资源：换成 @android:color/white 之类会让夜间整屏白闪。
  final firstLayer = RegExp(r'<item\s+android:drawable="([^"]+)"').firstMatch(body)?.group(1);
  if (firstLayer != '@color/splash_window_background') {
    violations.add('drawable/launch_background.xml 的第一层应为 @color/splash_window_background，实际 ${firstLayer ?? '缺失'}');
  }
  if (!body.contains('android:width="$splashMarkSize"') ||
      !body.contains('android:height="$splashMarkSize"')) {
    violations.add('drawable/launch_background.xml 的记印应为 $splashMarkSize 见方');
  }
  if (!body.contains('@drawable/launch_mark')) {
    violations.add('drawable/launch_background.xml 未引用 @drawable/launch_mark');
  }
}

void _checkLaunchThemes(List<String> violations, String root) {
  // API 24–30：LaunchTheme 与 NormalTheme 的窗口底都必须精确等于那张记印。
  // FlutterActivity 在 onCreate 第一句就切到 NormalTheme，所以 NormalTheme 一旦
  // 退回纯色（尤其亮色主题下解析为纯白），就会在首帧前闪一下白。
  for (final file in <String>['$brandResRoot/values/styles.xml', '$brandResRoot/values-night/styles.xml']) {
    final xml = _readFile(root, file);
    if (xml == null) {
      violations.add('缺少 $file');
      continue;
    }
    for (final style in <String>['LaunchTheme', 'NormalTheme']) {
      final body = _styleBody(xml, style);
      if (body == null) {
        violations.add('$file 缺少 style $style');
        continue;
      }
      final windowBackground = _itemValue(body, 'android:windowBackground');
      if (windowBackground != '@drawable/launch_background') {
        violations.add('$file 的 $style.windowBackground 应为 @drawable/launch_background，实际 ${windowBackground ?? '缺失'}');
      }
    }
  }

  // API 31+：系统闪屏只接受底色 / 图标 / 图标底色。这里精确校验前两项；
  // 图标底色故意不设，让系统按对比度决定墨盘显隐。
  for (final file in <String>['$brandResRoot/values-v31/styles.xml', '$brandResRoot/values-night-v31/styles.xml']) {
    final xml = _readFile(root, file);
    if (xml == null) {
      violations.add('缺少 $file');
      continue;
    }
    final body = _styleBody(xml, 'LaunchTheme');
    if (body == null) {
      violations.add('$file 缺少 style LaunchTheme');
      continue;
    }
    final splashBackground = _itemValue(body, 'android:windowSplashScreenBackground');
    if (splashBackground != '@color/splash_window_background') {
      violations.add('$file 的 windowSplashScreenBackground 应为 @color/splash_window_background，实际 ${splashBackground ?? '缺失'}');
    }
    final splashIcon = _itemValue(body, 'android:windowSplashScreenAnimatedIcon');
    if (splashIcon != '@mipmap/ic_launcher') {
      violations.add('$file 的 windowSplashScreenAnimatedIcon 应为 @mipmap/ic_launcher，实际 ${splashIcon ?? '缺失'}');
    }
    final windowBackground = _itemValue(body, 'android:windowBackground');
    if (windowBackground != '@drawable/launch_background') {
      violations.add('$file 的 LaunchTheme.windowBackground 应为 @drawable/launch_background，实际 ${windowBackground ?? '缺失'}');
    }
  }
}

/// 去掉 XML 注释后再做字符串判定：注释里提到某个色值或笔宽不能算数。
String _stripComments(String xml) => xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

List<String> _normalizedPaths(String xml) =>
    pathDataOf(_stripComments(xml)).map((path) => path.replaceAll(RegExp(r'\s+'), ' ').trim()).toList()..sort();

String? _styleBody(String xml, String name) =>
    RegExp('<style name="$name"[^>]*>(.*?)</style>', dotAll: true).firstMatch(xml)?.group(1);

String? _itemValue(String styleBody, String itemName) =>
    RegExp('<item name="$itemName">\\s*([^<]+?)\\s*</item>').firstMatch(styleBody)?.group(1);

String? _colorValue(String colorsXml, String name) =>
    RegExp('<color name="$name">\\s*([^<\\s]+)').firstMatch(colorsXml)?.group(1);

String? _readFile(String root, String relativePath) {
  final file = File('$root/$relativePath');
  return file.existsSync() ? file.readAsStringSync() : null;
}

bool _isPng(List<int> bytes) {
  const signature = <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (bytes.length < signature.length) {
    return false;
  }
  for (var index = 0; index < signature.length; index++) {
    if (bytes[index] != signature[index]) {
      return false;
    }
  }
  return true;
}

int _readUint32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) | (bytes[offset + 1] << 16) | (bytes[offset + 2] << 8) | bytes[offset + 3];

List<double> _numbersOf(String text) {
  final matches = RegExp(r'-?[0-9]*\.?[0-9]+').allMatches(text);
  return matches.map((match) => double.parse(match.group(0)!)).toList();
}

double _relativeLuminance(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 8) {
    value = value.substring(2);
  }
  final channels = <double>[
    int.parse(value.substring(0, 2), radix: 16) / 255,
    int.parse(value.substring(2, 4), radix: 16) / 255,
    int.parse(value.substring(4, 6), radix: 16) / 255,
  ].map((channel) {
    return channel <= 0.03928
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }).toList();
  return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2];
}
