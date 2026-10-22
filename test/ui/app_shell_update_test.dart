import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/ui/app_shell.dart';
import 'package:tometone/ui/pages/settings/update_page.dart';

import 'ui_test_harness.dart';

void main() {
  final sampleRelease = ReleaseInfo(
    tag: 'v0.3.0',
    name: 'TomeTone 0.3.0',
    body: '### 更新内容\n- 模块 E 启动自动检查\n- 体验修复',
    publishedAt: DateTime.utc(2026, 10, 20),
    htmlUrl: 'https://github.com/wuyanHH/TomeTone/releases/tag/v0.3.0',
    prerelease: false,
    draft: false,
    assets: const <ReleaseAsset>[
      ReleaseAsset(
        name: 'tometone-v0.3.0-arm64-v8a.apk',
        sizeBytes: 25 * 1024 * 1024,
        downloadUrl: 'https://example.com/arm64.apk',
      ),
    ],
  );

  testWidgets(
    '测试 1：自动检查开启且有新版本可用时，首帧触发自动检查，设置 Tab 出现红点，弹出 SnackBar 提示新版本，偏好中 promptedVersion 被记录',
    (WidgetTester tester) async {
      usePhoneViewport(tester);
      final fakeEngine = FakePlaybackEngine();
      final controller = testController(fakeEngine);
      addTearDown(controller.dispose);

      final store = InMemoryAppPreferencesStore(
        AppPreferences.defaults.copyWith(autoCheckUpdates: true),
      );
      final fakeSource = FakeUpdateSource(
        result: UpdateFetchResult(releases: [sampleRelease]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            controller: controller,
            preferencesStore: store,
            preferences: store.current,
            updateSource: fakeSource,
          ),
          child: const MaterialApp(home: AppShell()),
        ),
      );

      await tester.pumpAndSettle();

      // 1. 首帧触发自动检查：网络请求已发起
      expect(fakeSource.calls, greaterThanOrEqualTo(1));

      // 2. 设置 Tab 出现红点
      final badge = tester.widget<Badge>(find.byKey(AppShell.settingsBadgeKey));
      expect(badge.isLabelVisible, isTrue);

      // 3. 弹出 SnackBar 提示新版本
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('发现新版本 v0.3.0'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, '查看'), findsOneWidget);

      // 4. 偏好中 promptedVersion 被记录
      expect(store.current.promptedVersion, '0.3.0');
    },
  );

  testWidgets(
    '测试 2：同版本第二次启动时，由于 promptedVersion 已记录，不再重复弹出 SnackBar，但红点仍然保留',
    (WidgetTester tester) async {
      usePhoneViewport(tester);
      final fakeEngine = FakePlaybackEngine();
      final controller = testController(fakeEngine);
      addTearDown(controller.dispose);

      // 模拟第一次启动后已记录 promptedVersion，但用户尚未确认（acknowledgedVersion 为空）
      final store = InMemoryAppPreferencesStore(
        AppPreferences.defaults.copyWith(
          autoCheckUpdates: true,
          promptedVersion: '0.3.0',
        ),
      );
      final fakeSource = FakeUpdateSource(
        result: UpdateFetchResult(releases: [sampleRelease]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            controller: controller,
            preferencesStore: store,
            preferences: store.current,
            updateSource: fakeSource,
          ),
          child: const MaterialApp(home: AppShell()),
        ),
      );

      await tester.pumpAndSettle();

      // 不再重复弹出 SnackBar
      expect(find.byType(SnackBar), findsNothing);

      // 但红点仍然保留
      final badge = tester.widget<Badge>(find.byKey(AppShell.settingsBadgeKey));
      expect(badge.isLabelVisible, isTrue);
    },
  );

  testWidgets(
    '测试 3：自动检查关闭时（autoCheckUpdates == false），启动时不发起任何更新源网络请求，不显示红点，不弹 SnackBar',
    (WidgetTester tester) async {
      usePhoneViewport(tester);
      final fakeEngine = FakePlaybackEngine();
      final controller = testController(fakeEngine);
      addTearDown(controller.dispose);

      final store = InMemoryAppPreferencesStore(
        AppPreferences.defaults.copyWith(autoCheckUpdates: false),
      );
      final fakeSource = FakeUpdateSource(
        result: UpdateFetchResult(releases: [sampleRelease]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            controller: controller,
            preferencesStore: store,
            preferences: store.current,
            updateSource: fakeSource,
          ),
          child: const MaterialApp(home: AppShell()),
        ),
      );

      await tester.pumpAndSettle();

      // 启动时不发起任何更新源网络请求
      expect(fakeSource.calls, 0);

      // 不显示红点
      final badge = tester.widget<Badge>(find.byKey(AppShell.settingsBadgeKey));
      expect(badge.isLabelVisible, isFalse);

      // 不弹 SnackBar
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    '测试 4：打开 UpdatePage（acknowledgedVersion 写入后），设置 Tab 的红点消失',
    (WidgetTester tester) async {
      usePhoneViewport(tester);
      final fakeEngine = FakePlaybackEngine();
      final controller = testController(fakeEngine);
      addTearDown(controller.dispose);

      final store = InMemoryAppPreferencesStore(
        AppPreferences.defaults.copyWith(autoCheckUpdates: true),
      );
      final fakeSource = FakeUpdateSource(
        result: UpdateFetchResult(releases: [sampleRelease]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            controller: controller,
            preferencesStore: store,
            preferences: store.current,
            updateSource: fakeSource,
          ),
          child: const MaterialApp(home: AppShell()),
        ),
      );

      await tester.pumpAndSettle();

      // 启动后有红点与 SnackBar
      var badge = tester.widget<Badge>(find.byKey(AppShell.settingsBadgeKey));
      expect(badge.isLabelVisible, isTrue);
      expect(find.byType(SnackBar), findsOneWidget);

      // 点击 SnackBar 中的“查看”动作跳转到 UpdatePage
      await tester.tap(find.widgetWithText(SnackBarAction, '查看'));
      await tester.pumpAndSettle();

      // 页面已转入 UpdatePage
      expect(find.byType(UpdatePage), findsOneWidget);
      // acknowledgedVersion 已被写入
      expect(store.current.acknowledgedVersion, '0.3.0');

      // 返回外壳页面
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      // 设置 Tab 的红点消失
      badge = tester.widget<Badge>(find.byKey(AppShell.settingsBadgeKey));
      expect(badge.isLabelVisible, isFalse);
    },
  );

  testWidgets(
    '宽屏（≥600dp）：NavigationRail 上的设置 Tab 红点同样正常显示与响应',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeEngine = FakePlaybackEngine();
      final controller = testController(fakeEngine);
      addTearDown(controller.dispose);

      final store = InMemoryAppPreferencesStore(
        AppPreferences.defaults.copyWith(autoCheckUpdates: true),
      );
      final fakeSource = FakeUpdateSource(
        result: UpdateFetchResult(releases: [sampleRelease]),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            controller: controller,
            preferencesStore: store,
            preferences: store.current,
            updateSource: fakeSource,
          ),
          child: const MaterialApp(home: AppShell()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      final badge = tester.widget<Badge>(find.byKey(AppShell.settingsBadgeKey));
      expect(badge.isLabelVisible, isTrue);
    },
  );
}
