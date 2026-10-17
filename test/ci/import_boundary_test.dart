import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/import_boundary_rules.dart';
import '../../tool/ci/lib_sources.dart';

/// 对一个只放 `lib/` 文件的合成源码集做边界分析。
List<BoundaryViolation> _analyze(Map<String, String> files) =>
    analyzeSources(files);

void main() {
  group('resolveImportUri', () {
    test('解析 package 导入到 lib 路径', () {
      expect(
        resolveImportUri(
          importerFile: 'lib/ui/app.dart',
          uri: 'package:tometone/app/app_info.dart',
        ),
        'lib/app/app_info.dart',
      );
    });

    test('解析相对导入并折叠 ..', () {
      expect(
        resolveImportUri(
          importerFile: 'lib/ui/pages/shelf.dart',
          uri: '../../domain/library/book.dart',
        ),
        'lib/domain/library/book.dart',
      );
    });

    test('SDK / 第三方包 / 绝对路径不参与内部边界检查', () {
      expect(
        resolveImportUri(importerFile: 'lib/ui/a.dart', uri: 'dart:async'),
        isNull,
      );
      expect(
        resolveImportUri(
          importerFile: 'lib/ui/a.dart',
          uri: 'package:flutter/material.dart',
        ),
        isNull,
      );
      expect(
        resolveImportUri(
          importerFile: 'lib/ui/a.dart',
          uri: 'package:path/path.dart',
        ),
        isNull,
      );
      expect(
        resolveImportUri(importerFile: 'lib/ui/a.dart', uri: '/abs/x.dart'),
        isNull,
      );
    });
  });

  group('layerOfFile', () {
    test('识别各分层', () {
      expect(layerOfFile('lib/ui/app.dart'), 'ui');
      expect(layerOfFile('lib/app/app_info.dart'), 'app');
      expect(layerOfFile('lib/domain/library/book.dart'), 'domain');
      expect(layerOfFile('lib/contracts/x.dart'), 'contracts');
      expect(layerOfFile('lib/modules/x.dart'), 'modules');
      expect(layerOfFile('lib/platform/x.dart'), 'platform');
    });

    test('lib/ 根文件视为装配入口，lib/ 之外不适用', () {
      expect(layerOfFile('lib/main.dart'), 'root');
      expect(layerOfFile('test/foo_test.dart'), isNull);
      expect(layerOfFile('tool/ci/x.dart'), isNull);
    });

    test('未登记目录返回 null', () {
      expect(layerOfFile('lib/utils/ext.dart'), isNull);
    });
  });

  group('合法依赖方向不产生违规（正例）', () {
    test('逐层放行', () {
      final violations = _analyze(<String, String>{
        'lib/main.dart': "import 'package:tometone/modules/engine.dart';\n",
        'lib/modules/engine.dart':
            "import 'package:tometone/contracts/api.dart';\n"
            "import 'package:tometone/platform/android.dart';\n",
        'lib/platform/android.dart': "import '../contracts/api.dart';\n",
        'lib/contracts/api.dart': "import 'dart:async';\n",
        'lib/domain/library.dart':
            "import '../contracts/api.dart';\n"
            "import 'shelf.dart';\n",
        'lib/domain/shelf.dart': '// 同层\n',
        'lib/app/policy.dart':
            "import 'package:tometone/domain/library.dart';\n",
        'lib/ui/app.dart':
            "import '../app/policy.dart';\n"
            "import 'package:tometone/contracts/api.dart';\n",
      });
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('违规依赖被拦截（负例自检）', () {
    test('ui 不允许依赖 modules', () {
      final violations = _analyze(<String, String>{
        'lib/ui/app.dart': "import 'package:tometone/modules/engine.dart';\n",
        'lib/modules/engine.dart': '// ok\n',
      });
      expect(violations, hasLength(1));
      expect(violations.single.file, 'lib/ui/app.dart');
      expect(violations.single.line, 1);
      expect(violations.single.message, contains('ui 层禁止依赖 modules 层'));
    });

    test('app 不允许依赖 modules（契约层注入是唯一的解）', () {
      final violations = _analyze(<String, String>{
        'lib/app/policy.dart':
            "import 'package:tometone/modules/engine.dart';\n",
        'lib/modules/engine.dart': '// ok\n',
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('app 层禁止依赖 modules 层'));
    });

    test('domain 不允许依赖 modules', () {
      final violations = _analyze(<String, String>{
        'lib/domain/library.dart': "import '../modules/engine.dart';\n",
        'lib/modules/engine.dart': '// ok\n',
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('domain 层禁止依赖 modules 层'));
    });

    test('modules 不允许依赖 domain（禁止业务概念泄漏进模块）', () {
      final violations = _analyze(<String, String>{
        'lib/modules/engine.dart':
            "import 'package:tometone/domain/book.dart';\n",
        'lib/domain/book.dart': '// ok\n',
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('modules 层禁止依赖 domain 层'));
    });

    test('contracts 不允许依赖任何内部层', () {
      final violations = _analyze(<String, String>{
        'lib/contracts/api.dart': "import '../ui/app.dart';\n",
        'lib/ui/app.dart': '// ok\n',
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('contracts 层禁止依赖 ui 层'));
    });

    test('platform 不允许依赖 modules', () {
      final violations = _analyze(<String, String>{
        'lib/platform/android.dart': "import '../modules/engine.dart';\n",
        'lib/modules/engine.dart': '// ok\n',
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('platform 层禁止依赖 modules 层'));
    });

    test('未登记的顶层目录被拦截', () {
      final violations = _analyze(<String, String>{
        'lib/utils/ext.dart': "import 'dart:math';\n",
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('未登记的顶层目录'));
    });

    test('lib/ 根目录只允许 main.dart', () {
      final violations = _analyze(<String, String>{
        'lib/bootstrap.dart': "import 'dart:math';\n",
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('只允许 lib/main.dart'));
    });

    test('导入未登记目录的目标文件被拦截', () {
      final violations = _analyze(<String, String>{
        'lib/ui/app.dart': "import '../utils/ext.dart';\n",
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('依赖了未登记的顶层目录'));
    });

    test('规范/导出语句同样受检', () {
      final violations = _analyze(<String, String>{
        'lib/ui/barrel.dart':
            "export 'package:tometone/modules/engine.dart';\n",
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('ui 层禁止依赖 modules 层'));
    });

    test('注释中的 import 不被误判', () {
      final violations = _analyze(<String, String>{
        'lib/ui/app.dart':
            "// import 'package:tometone/modules/engine.dart';\n",
      });
      expect(violations, isEmpty);
    });

    test('行尾注释中的 import 不被误判', () {
      final violations = _analyze(<String, String>{
        'lib/ui/app.dart':
            "import 'package:tometone/contracts/api.dart';"
            " // import 'package:tometone/modules/engine.dart';\n",
      });
      expect(violations, isEmpty);
    });

    test('contracts 层依赖 Flutter 被拦截（契约必须是纯 Dart）', () {
      final violations = _analyze(<String, String>{
        'lib/contracts/api.dart': "import 'package:flutter/material.dart';\n",
      });
      expect(violations, hasLength(1));
      expect(violations.single.line, 1);
      expect(violations.single.message, contains('必须保持纯 Dart'));
    });

    test('modules 层依赖 Flutter 属于正常（实现层需要平台绑定）', () {
      final violations = _analyze(<String, String>{
        'lib/modules/engine.dart':
            "import 'package:flutter/services.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart';\n",
      });
      expect(violations, isEmpty);
    });

    test('多行条件导入的两个分支都受检，行号指向指令起始行', () {
      final violations = _analyze(<String, String>{
        'lib/ui/app.dart':
            "import 'package:tometone/contracts/api.dart'\n"
            "    if (dart.library.io) 'package:tometone/modules/engine.dart'\n"
            '    as remote;\n',
      });
      expect(violations, hasLength(1));
      expect(violations.single.line, 1);
      expect(violations.single.uri, 'package:tometone/modules/engine.dart');
      expect(violations.single.message, contains('ui 层禁止依赖 modules 层'));
    });

    test('单行条件导入同样受检', () {
      final violations = _analyze(<String, String>{
        'lib/domain/library.dart':
            "import 'a.dart' if (dart.library.io) '../modules/engine.dart';\n",
      });
      expect(violations, hasLength(1));
      expect(violations.single.message, contains('domain 层禁止依赖 modules 层'));
    });
  });

  group('extractDirectiveUris', () {
    test('多行指令合并到起始行', () {
      final uris = extractDirectiveUris(
        "import 'a.dart'\n    show A;\n"
        "import 'b.dart';\n",
      );
      expect(uris, hasLength(2));
      expect(uris[0].uri, 'a.dart');
      expect(uris[0].line, 1);
      expect(uris[1].uri, 'b.dart');
      expect(uris[1].line, 3);
    });

    test('普通代码与注释不产生引用', () {
      expect(
        extractDirectiveUris("final a = 'x';\n// import 'b.dart';\n"),
        isEmpty,
      );
      expect(
        extractDirectiveUris("String s = \"import 'c.dart'\";\n"),
        isEmpty,
      );
    });

    test('export 指令被识别', () {
      final uris = extractDirectiveUris("export 'd.dart';\n");
      expect(uris, hasLength(1));
      expect(uris.single.uri, 'd.dart');
    });
  });

  group('真实仓库门禁', () {
    test('lib/ 现状无依赖方向违规', () {
      final sources = readLibSources();
      expect(sources, isNotEmpty, reason: '未读到 lib/ 源码，检查工作目录');
      final violations = analyzeSources(sources);
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}
