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

  final foreground = File('$root/$foregroundAsset');
  if (!foreground.existsSync()) {
    violations.add('缺少前景层 drawable/ic_launcher_foreground.xml');
  }

  return violations;
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
