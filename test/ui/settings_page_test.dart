import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/pages/settings/settings_page.dart';

import 'ui_test_harness.dart';

void main() {
  /// 把设置页塞进最小应用；页面不再读写书库数据，容器无需业务 override。
  Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
    usePhoneViewport(tester);
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      testApp(container, const Scaffold(body: SettingsPage())),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('分组结构：只保留外观与关于，书库根已拆到「书库」页', (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text('系统偏好'), findsOneWidget);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('跟随系统明暗'), findsOneWidget);
    expect(find.text('只读'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);

    // 书库根整块搬走：设置页不再出现它的列表与入口。
    expect(find.text('书库根'), findsNothing);
    expect(find.text('还没有书库根'), findsNothing);
    expect(find.byKey(LibraryRootsKeys.rootsListKey), findsNothing);
    expect(find.byKey(LibraryRootsKeys.rootsEmptyKey), findsNothing);
    expect(find.byKey(LibraryRootsKeys.safPickKey), findsNothing);
    expect(find.byKey(LibraryRootsKeys.addRootKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('关于：版本与通道来自 AppInfo，更新源未配置时如实说明', (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text('0.1.0-beta.1'), findsOneWidget);
    expect(find.text('发布通道 · beta'), findsOneWidget);

    if (!AppInfo.hasUpdateSource) {
      expect(find.text('更新源未配置，暂时无法检查更新'), findsOneWidget);
      expect(find.text('未配置'), findsOneWidget);
    }
    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('开源许可'), findsOneWidget);

    await tester.ensureVisible(find.byKey(SettingsPage.licensesKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsPage.licensesKey));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
