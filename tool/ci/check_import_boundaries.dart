import 'dart:io';

import 'import_boundary_rules.dart';
import 'lib_sources.dart';

/// 依赖方向门禁（《架构需求文档》§5.2 / §12）。
///
/// 用法：在仓库根目录执行
/// `dart run tool/ci/check_import_boundaries.dart`
///
/// 退出码：0 = 通过；1 = 存在违规；2 = 环境错误（不在仓库根目录）。
void main() {
  if (!Directory('lib').existsSync()) {
    stdout.writeln('× 未找到 lib/ 目录，请在仓库根目录执行本脚本。');
    exitCode = 2;
    return;
  }

  final sources = readLibSources();

  // 空集合一律判定为环境错误：绝不能在"什么都没检查"的情况下静默通过。
  if (sources.isEmpty) {
    stdout.writeln('× 未扫描到任何 lib/**/*.dart 源码，判定为环境错误。');
    exitCode = 2;
    return;
  }

  final violations = analyzeSources(sources);

  if (violations.isEmpty) {
    stdout.writeln('√ 依赖方向检查通过（扫描 ${sources.length} 个文件）。');
    return;
  }

  stdout.writeln('× 依赖方向检查失败，共 ${violations.length} 处违规：');
  for (final violation in violations) {
    stdout.writeln('  - $violation');
  }
  exitCode = 1;
}
