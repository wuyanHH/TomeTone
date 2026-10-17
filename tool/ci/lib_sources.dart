import 'dart:io';

import 'import_boundary_rules.dart';

/// 从磁盘读取 `lib/` 下的全部 Dart 源码（跳过生成代码）。
///
/// 键为仓库相对路径（`lib/...`）。目录不存在时返回空 Map。
Map<String, String> readLibSources({String libPath = 'lib'}) {
  final directory = Directory(libPath);
  if (!directory.existsSync()) {
    return <String, String>{};
  }

  final sources = <String, String>{};
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final path = normalizePath(entity.path.replaceAll('\\', '/'));
    if (!path.startsWith('lib/') || !path.endsWith('.dart')) {
      continue;
    }
    if (path.endsWith('.g.dart') || path.endsWith('.freezed.dart')) {
      continue;
    }
    sources[path] = entity.readAsStringSync();
  }
  return sources;
}
