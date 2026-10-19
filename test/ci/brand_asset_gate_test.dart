import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/brand_asset_rules.dart';

/// 门禁的**反向测试**：把真实资源复制到临时目录，逐项改坏，
/// 断言门禁必须报错。
///
/// 为什么需要这一层：`brandViolations()` 全绿只证明"当前仓库没违规"，
/// 不证明"违规会被抓住"。没有这些用例，门禁很容易退化成只查文件是否存在，
/// 而白底启动窗、被 transform 挪出安全圆的图标、空掉的单色层都会静默通过。
void main() {
  late Directory sandbox;

  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('tometone-brand-gate-');
    _copyTree(
      Directory('android/app/src/main/res'),
      Directory('${sandbox.path}/android/app/src/main/res'),
    );
  });

  tearDown(() {
    if (sandbox.existsSync()) {
      sandbox.deleteSync(recursive: true);
    }
  });

  List<String> violations() => brandViolations(root: sandbox.path);

  test('基线：真实资源无违规', () {
    expect(violations(), isEmpty);
  });

  test('启动窗口底被换回纯白 → 必须报错', () {
    _replace(
      '${sandbox.path}/android/app/src/main/res/drawable/launch_background.xml',
      '@color/splash_window_background',
      '@android:color/white',
    );
    expect(violations(), isNotEmpty);
  });

  test('LaunchTheme 的窗口底被换掉 → 必须报错', () {
    _replace(
      '${sandbox.path}/android/app/src/main/res/values/styles.xml',
      '<item name="android:windowBackground">@drawable/launch_background</item>',
      '<item name="android:windowBackground">@android:color/background_light</item>',
    );
    expect(violations(), isNotEmpty);
  });

  test('v31 的系统闪屏底被换成纯白 → 必须报错', () {
    _replace(
      '${sandbox.path}/android/app/src/main/res/values-v31/styles.xml',
      '@color/splash_window_background',
      '@android:color/white',
    );
    expect(violations(), isNotEmpty);
  });

  test('前景层被 group 平移出安全圆 → 必须报错', () {
    final path = '${sandbox.path}/android/app/src/main/res/drawable/ic_launcher_foreground.xml';
    final xml = File(path).readAsStringSync();
    final wrapped = xml.replaceFirst(
      '<path',
      '<group android:translateY="20"><path',
    ).replaceFirst('</vector>', '</group></vector>');
    File(path).writeAsStringSync(wrapped);
    expect(violations(), isNotEmpty);
  });

  test('单色层被清空、只在注释里留笔宽 → 必须报错', () {
    File('${sandbox.path}/android/app/src/main/res/drawable/ic_launcher_monochrome.xml')
        .writeAsStringSync(
      '<?xml version="1.0" encoding="utf-8"?>\n'
      '<!-- strokeWidth="4" strokeWidth="4.4" -->\n'
      '<vector xmlns:android="http://schemas.android.com/apk/res/android"'
      ' android:width="108dp" android:height="108dp"'
      ' android:viewportWidth="108" android:viewportHeight="108" />\n',
    );
    expect(violations(), isNotEmpty);
  });

  test('legacy 位图高度被改错 → 必须报错', () {
    final path = '${sandbox.path}/android/app/src/main/res/mipmap-mdpi/ic_launcher.png';
    final bytes = File(path).readAsBytesSync();
    // IHDR 高度在偏移 20，改成 96（mdpi 应为 48）。
    bytes[23] = 96;
    File(path).writeAsBytesSync(bytes);
    expect(violations(), isNotEmpty);
  });

  test('启动页记印的几何与前景层不一致 → 必须报错', () {
    _replace(
      '${sandbox.path}/android/app/src/main/res/drawable/launch_mark.xml',
      'M41,44.5 L41,40.5',
      'M41,44.5 L41,40.0',
    );
    expect(violations(), isNotEmpty);
  });
}

void _copyTree(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entity in from.listSync(recursive: true)) {
    if (entity is! File) {
      continue;
    }
    final relative = entity.path.substring(from.path.length + 1);
    final target = File('${to.path}/$relative');
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(entity.readAsBytesSync());
  }
}

void _replace(String path, String from, String to) {
  final file = File(path);
  final content = file.readAsStringSync();
  if (!content.contains(from)) {
    throw StateError('沙箱里找不到待替换的片段：$from');
  }
  file.writeAsStringSync(content.replaceFirst(from, to));
}
