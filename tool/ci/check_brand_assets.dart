import 'dart:io';

import 'brand_asset_rules.dart';

/// 品牌资源门禁（图标三层 / 旧安卓位图 / 启动页主题）。
///
/// 用法：在仓库根目录执行
/// `dart run tool/ci/check_brand_assets.dart`
///
/// 退出码：0 = 通过；1 = 存在违规；2 = 环境错误（不在仓库根目录）。
void main() {
  if (!Directory(brandResRoot).existsSync()) {
    stdout.writeln('× 未找到 $brandResRoot，请在仓库根目录执行本脚本。');
    exitCode = 2;
    return;
  }

  final violations = brandViolations();

  if (violations.isEmpty) {
    stdout.writeln('√ 品牌资源检查通过。');
    return;
  }

  stdout.writeln('× 品牌资源检查失败，共 ${violations.length} 处违规：');
  for (final violation in violations) {
    stdout.writeln('  - $violation');
  }
  exitCode = 1;
}
