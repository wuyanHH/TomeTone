import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/brand_asset_rules.dart';

void main() {
  // 资源层的门禁：图标三层是否齐、内容是否落在自适应图标安全圆内、
  // 旧安卓位图是否真的是我们生成的、启动页主题是否还引用着会白闪的系统色。
  // 这些错 flutter analyze / 单元测试都看不见，只能在真机上表现为
  // 「图标被切」「闪白」「老机器上仍是默认图标」。
  test('品牌资源门禁：当前仓库无违规', () {
    expect(brandViolations(), isEmpty);
  });

  test('legacy 位图存在、尺寸精确、且不是 Flutter 默认图', () {
    const expected = <String, int>{
      'mipmap-mdpi': 48,
      'mipmap-hdpi': 72,
      'mipmap-xhdpi': 96,
      'mipmap-xxhdpi': 144,
      'mipmap-xxxhdpi': 192,
    };
    expected.forEach((density, size) {
      final file = File('android/app/src/main/res/$density/ic_launcher.png');
      expect(file.existsSync(), isTrue, reason: '缺少 $density/ic_launcher.png');
      final bytes = file.readAsBytesSync();
      expect(pngSize(bytes), (size, size), reason: '$density 尺寸不对');
      // Flutter 默认图标是调色板型（3）；我们的 Chrome 截图是真彩型（2/6）。
      expect(pngColorType(bytes), isNot(3), reason: '$density 仍是 Flutter 默认位图');
    });
  });
}
