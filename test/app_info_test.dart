import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/app_info.dart';

/// 发布纪律门禁（《架构需求文档》2.7）：
/// 版本号在 `pubspec.yaml`、`AppInfo`、`CHANGELOG.md` 三处必须一致。
void main() {
  test('AppInfo.version 与 pubspec.yaml 的 version 一致', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:[ \t]*(\S+)$',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml 必须声明 version');
    final pubspecVersion = match!.group(1)!.split('+').first;
    expect(AppInfo.version, pubspecVersion);
  });

  test('AppInfo.version 与 CHANGELOG.md 保持一致', () {
    final changelog = File('CHANGELOG.md').readAsStringSync();
    expect(
      changelog,
      contains(AppInfo.version),
      reason: 'CHANGELOG.md 是发布记录唯一来源，必须包含当前版本号',
    );
  });

  test('应用标识与 Android 工程配置一致', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "${AppInfo.applicationId}"'));
    expect(gradle, contains('namespace = "${AppInfo.organization}.app"'));
  });

  test('未配置更新源时不发起任何检查', () {
    // M1 阶段 GitHub owner/repo 尚未确定，必须保持"未启用"而非静默请求空地址。
    expect(AppInfo.hasUpdateSource, isFalse);
  });
}
