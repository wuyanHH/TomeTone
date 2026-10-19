import 'dart:io';
import 'dart:math' as math;

/// 品牌资源门禁规则（图标三层 + 启动页），《tometone_brand_icon_splash.md》的机器可读版本。
///
/// 与 `import_boundary_rules.dart` 同构：本文件只放纯函数与文件读取，
/// 命令行包装见 `check_brand_assets.dart`，测试见 `test/ci/brand_asset_rules_test.dart`。
///
/// 为什么需要它：图标与启动页是资源层，`flutter analyze` 与 `flutter test` 都看不见
/// 它们的正确性——三层资源是否齐、内容是否落在自适应图标安全圆内、旧安卓位图是否是
/// 我们自己生成的、`NormalTheme` 是否还引用着会白闪的系统色。这些错一旦上线只会
/// 在真机上表现为「图标被切」「闪白」「老机器上用默认图标」，因此全部写成可复算的断言。

/// 108dp 画布的坐标系中心；外接判定一律相对它。
const double canvasCentre = 54;

/// 品牌资源的仓库相对根目录。
const String brandResRoot = 'android/app/src/main/res';

/// 前景层（书页 + 声纹）。
const String foregroundAsset = '$brandResRoot/drawable/ic_launcher_foreground.xml';

/// 单色层（API 33+ 主题图标，只用 alpha）。
const String monochromeAsset = '$brandResRoot/drawable/ic_launcher_monochrome.xml';

/// 对外接上限（半径，dp）：内容必须落在 Ø56dp 内，距 Ø66dp 安全圆留 ≥5dp。
const double maxContentRadius = 28.0;

/// 读取 PNG 的 IHDR 宽高；不是 PNG 或长度不足时返回 null。
(int width, int height)? pngSize(List<int> bytes) {
  if (!_isPng(bytes) || bytes.length < 24) {
    return null;
  }
  final width = _readUint32(bytes, 16);
  final height = _readUint32(bytes, 20);
  return (width, height);
}

/// 读取 PNG 的颜色类型（IHDR 偏移 25）：3 = 调色板型（Flutter 默认图就是它），
/// 2 / 6 = 真彩型（Chrome 截图的产物）。用来区分「我们的位图」与「默认位图」。
int? pngColorType(List<int> bytes) {
  if (!_isPng(bytes) || bytes.length < 26) {
    return null;
  }
  return bytes[25];
}

/// 取出 XML 里所有 `pathData` / `d` 属性值。
List<String> pathDataOf(String xml) {
  final matches = RegExp(r'(?:pathData|d)="([^"]*)"').allMatches(xml);
  return matches.map((match) => match.group(1)!).toList();
}

/// 把 pathData 的数字两两当作 (x,y)，返回相对画布中心的最远顶点距离。
///
/// 只取顶点，不含描边外扩；含描边的外接见 [contentRadius]。
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
double contentRadius(String xml) =>
    maxVertexDistance(_numbersOf(pathDataOf(xml).join(' '))) + maxStrokeWidth(xml) / 2;

/// WCAG 2.1 对比度；入参接受 `#AARRGGBB` 或 `#RRGGBB`。
double contrastRatio(String argbA, String argbB) {
  final a = _relativeLuminance(argbA);
  final b = _relativeLuminance(argbB);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

/// 校验品牌资源，返回违规说明；空列表 = 通过。
///
/// [root] 为仓库根目录（测试与 CLI 都从仓库根执行）。
List<String> brandViolations({String root = '.'}) {
  final violations = <String>[];

  final foreground = _readFile(root, foregroundAsset);
  final monochrome = _readFile(root, monochromeAsset);

  if (foreground == null) {
    violations.add('缺少前景层 drawable/ic_launcher_foreground.xml');
  } else {
    // 前景层不得自带底色：一旦带上底色，自适应图标的 background 层就白设了，
    // 系统在深色/主题图标下也无法按对比度自动显隐。
    if (foreground.toUpperCase().contains('0E2A3B')) {
      violations.add('前景层不得自带底色（出现 0E2A3B）');
    }
    for (final stroke in <String>['#FFF2F4E9', '#FF58DCC1']) {
      if (!foreground.contains('strokeColor="$stroke"')) {
        violations.add('前景层缺少 strokeColor="$stroke"');
      }
    }
  }

  if (monochrome == null) {
    violations.add('缺少单色层 drawable/ic_launcher_monochrome.xml');
  } else {
    // 单色层只允许 alpha：带任何品牌色都会在系统 tint 下变成"脏色块"。
    for (final banned in <String>['58DCC1', 'F2F4E9', '0E2A3B']) {
      if (monochrome.toUpperCase().contains(banned)) {
        violations.add('单色层只能用 alpha，不得出现品牌色 $banned');
      }
    }
    // 3dp 细线在剪影 + 系统 tint 下会糊；单色层必须加粗（结构不变、笔宽变）。
    for (final width in <String>['4', '4.4']) {
      if (!monochrome.contains('strokeWidth="$width"')) {
        violations.add('单色层缺少加粗笔宽 strokeWidth="$width"');
      }
    }
  }

  for (final asset in <String, String?>{foregroundAsset: foreground, monochromeAsset: monochrome}.entries) {
    final xml = asset.value;
    if (xml == null) {
      continue;
    }
    final radius = contentRadius(xml);
    if (radius > maxContentRadius) {
      violations.add(
        '${asset.key} 外接 Ø${(radius * 2).toStringAsFixed(1)}dp 超出上限 '
        'Ø${(maxContentRadius * 2).toStringAsFixed(0)}dp（距 Ø66 安全圆不足 5dp）',
      );
    }
  }

  final colors = _readFile(root, '$brandResRoot/values/colors.xml');
  if (colors == null) {
    violations.add('缺少 values/colors.xml');
  } else {
    final background = RegExp(r'<color name="ic_launcher_background">\s*([^<\s]+)')
        .firstMatch(colors)
        ?.group(1);
    if (background == null) {
      violations.add('values/colors.xml 缺少 ic_launcher_background');
    } else if (background.toUpperCase() != '#FF0E2A3B') {
      violations.add('ic_launcher_background 应为 #FF0E2A3B，实际 $background');
    }
  }

  final adaptive = _readFile(root, '$brandResRoot/mipmap-anydpi-v26/ic_launcher.xml');
  if (adaptive == null) {
    violations.add('缺少 mipmap-anydpi-v26/ic_launcher.xml');
  } else {
    for (final reference in <String>[
      '@color/ic_launcher_background',
      '@drawable/ic_launcher_foreground',
      '@drawable/ic_launcher_monochrome',
    ]) {
      if (!adaptive.contains(reference)) {
        violations.add('mipmap-anydpi-v26/ic_launcher.xml 缺少 $reference');
      }
    }
  }

  return violations;
}

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

/// 抽出字符串里全部数字（含负号与小数），用于几何复算。
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
