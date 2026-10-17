/// 依赖方向门禁规则引擎（《架构需求文档》§5.2）。
///
/// 本文件只包含纯函数与常量，不触碰文件系统 —— 便于单元测试与负例自检。
///
/// 解析口径：以"行首的 `import` / `export` 关键字"识别一条指令，
/// 向后收集到 `;` 为止的**全部**字符串字面量，因此
///
/// - 多行指令（URI 与 `if (...)` 条件分支分行书写）不会被漏检；
/// - 条件导入 `import 'a.dart' if (dart.library.io) 'b.dart';` 的两个分支都受检；
/// - 行首非指令的行（注释、普通代码）不参与匹配，注释里的 `import` 不会被误判。
library;

/// 分层目录白名单：`lib/<segment>` → 层名。
///
/// 新增顶层目录必须先在此登记，否则门禁报错（防止架构悄然漂移）。
const Map<String, String> layerByDirectory = <String, String>{
  'app': 'app',
  'contracts': 'contracts',
  'domain': 'domain',
  'modules': 'modules',
  'platform': 'platform',
  'ui': 'ui',
};

/// 唯一的装配入口：允许导入任意层。
const String compositionRootFile = 'lib/main.dart';

/// 每层允许依赖的目标层（含自身）。
///
/// - `ui → app/domain/contracts`：UI 只依赖契约与领域能力，不 import 具体实现。
/// - `app → domain/contracts`：业务策略（睡眠 / 回退 / 连播 / 心跳 / 进度）落在应用层。
/// - `domain → contracts`：领域服务只面向契约。
/// - `contracts → contracts`：契约不得依赖任何内部层（也不得出现 UI 文案）。
/// - `modules → contracts/platform`：模块实现只依赖契约与平台能力，
///   禁止依赖 UI / 应用 / 领域（即禁止出现"书 / 卷 / 章"等业务概念）。
/// - `platform → contracts`：平台适配层同样只依赖契约。
const Map<String, Set<String>> allowedTargets = <String, Set<String>>{
  'app': <String>{'app', 'contracts', 'domain'},
  'contracts': <String>{'contracts'},
  'domain': <String>{'contracts', 'domain'},
  'modules': <String>{'contracts', 'modules', 'platform'},
  'platform': <String>{'contracts', 'platform'},
  'ui': <String>{'app', 'contracts', 'domain', 'ui'},
};

/// 每层禁止导入的外部包前缀。
///
/// `contracts` 是纯接口层：一旦依赖 Flutter，模块实现就无法在纯 Dart 环境
/// （CLI 工具、契约测试、未来桌面端）复用契约，分层会立刻瓦解。
const Map<String, Set<String>> forbiddenPackagePrefixes = <String, Set<String>>{
  'contracts': <String>{'package:flutter/'},
};

/// 包名：`package:tometone/...` 指向 `lib/...`。
const String packageName = 'tometone';

final RegExp _directiveLine = RegExp(r'^(?:import|export)\b');
final RegExp _quotedLiteral = RegExp('''['"]([^'"]+)['"]''');

/// 归一化 posix 风格路径（折叠 `.` 与 `..`，丢弃空段）。
String normalizePath(String path) {
  final segments = <String>[];
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.') {
      continue;
    }
    if (segment == '..') {
      if (segments.isNotEmpty) {
        segments.removeLast();
      }
      continue;
    }
    segments.add(segment);
  }
  return segments.join('/');
}

/// 返回文件所属分层；不在 `lib/` 下或分层未登记时返回 `null`。
///
/// `lib/main.dart` 这类直接位于 `lib/` 下的文件返回 `'root'`。
String? layerOfFile(String libRelativePath) {
  final segments = libRelativePath.split('/');
  if (segments.length < 2 || segments.first != 'lib') {
    return null;
  }
  if (segments.length == 2) {
    return 'root';
  }
  return layerByDirectory[segments[1]];
}

/// 把导入 URI 解析为仓库内 `lib/...` 路径。
///
/// SDK（`dart:`）、第三方包、绝对路径返回 `null`（不参与内部边界检查）。
String? resolveImportUri({required String importerFile, required String uri}) {
  const packagePrefix = 'package:$packageName/';
  if (uri.startsWith('package:')) {
    if (!uri.startsWith(packagePrefix)) {
      return null;
    }
    return normalizePath('lib/${uri.substring(packagePrefix.length)}');
  }
  if (uri.startsWith('dart:') || uri.startsWith('/')) {
    return null;
  }
  final lastSlash = importerFile.lastIndexOf('/');
  if (lastSlash < 0) {
    return null;
  }
  return normalizePath('${importerFile.substring(0, lastSlash)}/$uri');
}

/// 一条依赖方向违规。
class BoundaryViolation {
  /// 创建一条违规记录。
  const BoundaryViolation({
    required this.file,
    required this.line,
    required this.uri,
    required this.message,
  });

  /// 违规文件（`lib/...` 相对路径）。
  final String file;

  /// 违规所在行号（1 起）。
  final int line;

  /// 违规的导入 URI；结构性违规（如未登记目录）为空串。
  final String uri;

  /// 人类可读的违规说明。
  final String message;

  @override
  String toString() {
    final location = uri.isEmpty ? '' : "  import '$uri'";
    return '$file:$line$location  →  $message';
  }
}

/// 一条导入指令中出现的引用。
class DirectiveUri {
  /// 创建一条引用记录。
  const DirectiveUri({required this.uri, required this.line});

  /// 目标 URI（原样，未解析）。
  final String uri;

  /// 该导入指令的起始行号（1 起）。
  final int line;

  @override
  String toString() => '$line: $uri';
}

/// 截断行尾注释：`import 'a.dart'; // import 'b.dart'` 只保留前者。
String _stripLineComment(String line) {
  var inSingle = false;
  var inDouble = false;
  for (var index = 0; index < line.length; index++) {
    final char = line[index];
    if (char == "'" && !inDouble) {
      inSingle = !inSingle;
    } else if (char == '"' && !inSingle) {
      inDouble = !inDouble;
    } else if (char == '/' &&
        !inSingle &&
        !inDouble &&
        index + 1 < line.length &&
        line[index + 1] == '/') {
      return line.substring(0, index);
    }
  }
  return line;
}

/// 提取源码中的全部导入 / 导出引用（含条件导入的两个分支）。
List<DirectiveUri> extractDirectiveUris(String content) {
  final results = <DirectiveUri>[];
  final lines = content.split('\n');
  var index = 0;

  while (index < lines.length) {
    final head = _stripLineComment(lines[index]).trimLeft();
    if (!_directiveLine.hasMatch(head)) {
      index++;
      continue;
    }

    final startLine = index + 1;
    final directive = StringBuffer(head);
    while (!directive.toString().contains(';') && index + 1 < lines.length) {
      index++;
      directive.write(' ');
      directive.write(_stripLineComment(lines[index]).trim());
    }

    for (final match in _quotedLiteral.allMatches(directive.toString())) {
      results.add(DirectiveUri(uri: match.group(1)!, line: startLine));
    }
    index++;
  }

  return results;
}

/// 扫描源码集合，返回全部依赖方向违规（按文件路径、行号排序）。
///
/// [fileContents] 的键为仓库相对路径（例如 `lib/ui/app.dart`）。
List<BoundaryViolation> analyzeSources(Map<String, String> fileContents) {
  final violations = <BoundaryViolation>[];
  final files = fileContents.keys.toList()..sort();

  for (final file in files) {
    if (!file.startsWith('lib/') || !file.endsWith('.dart')) {
      continue;
    }
    if (file == compositionRootFile) {
      continue;
    }

    final sourceLayer = layerOfFile(file);
    if (sourceLayer == null) {
      violations.add(
        BoundaryViolation(
          file: file,
          line: 1,
          uri: '',
          message:
              '未登记的顶层目录；新增分层必须先在 '
              'tool/ci/import_boundary_rules.dart 中登记',
        ),
      );
      continue;
    }
    if (sourceLayer == 'root') {
      violations.add(
        BoundaryViolation(
          file: file,
          line: 1,
          uri: '',
          message: 'lib/ 根目录只允许 $compositionRootFile（装配入口）',
        ),
      );
      continue;
    }

    final allowed = allowedTargets[sourceLayer];
    if (allowed == null) {
      continue;
    }

    final forbidden = forbiddenPackagePrefixes[sourceLayer] ?? const <String>{};

    for (final directive in extractDirectiveUris(fileContents[file]!)) {
      var blocked = false;
      for (final prefix in forbidden) {
        if (directive.uri.startsWith(prefix)) {
          violations.add(
            BoundaryViolation(
              file: file,
              line: directive.line,
              uri: directive.uri,
              message: '$sourceLayer 层必须保持纯 Dart，禁止依赖 $prefix',
            ),
          );
          blocked = true;
          break;
        }
      }
      if (blocked) {
        continue;
      }

      final target = resolveImportUri(importerFile: file, uri: directive.uri);
      if (target == null) {
        continue;
      }
      final targetLayer = layerOfFile(target);
      if (targetLayer == null) {
        violations.add(
          BoundaryViolation(
            file: file,
            line: directive.line,
            uri: directive.uri,
            message: '依赖了未登记的顶层目录（$target）',
          ),
        );
        continue;
      }
      if (!allowed.contains(targetLayer)) {
        violations.add(
          BoundaryViolation(
            file: file,
            line: directive.line,
            uri: directive.uri,
            message: '$sourceLayer 层禁止依赖 $targetLayer 层（$target）',
          ),
        );
      }
    }
  }

  violations.sort((a, b) {
    final byFile = a.file.compareTo(b.file);
    return byFile != 0 ? byFile : a.line.compareTo(b.line);
  });
  return violations;
}
