import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/ui/app.dart';

/// TomeTone（听卷）装配入口 —— 全仓库唯一的 composition root。
///
/// 依赖方向铁律（《架构需求文档》§5.2）：UI / 应用 / 领域层只依赖契约层
/// （`lib/contracts/`），具体模块实现（`lib/modules/`）只能在这里注入。
/// 本文件由 `tool/ci/check_import_boundaries.dart` 显式豁免。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: TomeToneApp()));
}
