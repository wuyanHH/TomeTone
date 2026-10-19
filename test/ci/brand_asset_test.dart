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
}
