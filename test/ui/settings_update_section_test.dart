import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/update_providers.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/contracts/update/update_state.dart';
import 'package:tometone/ui/pages/settings/settings_page.dart';
import 'package:tometone/ui/pages/settings/update_page.dart';

import 'ui_test_harness.dart';

void main() {
  final sampleRelease = ReleaseInfo(
    tag: 'v0.3.0',
    name: 'TomeTone 0.3.0',
    body: '## 更新日志\n- 支持多架构下载',
    publishedAt: DateTime.utc(2026, 10, 20),
    htmlUrl: 'https://github.com/example/releases/v0.3.0',
    prerelease: false,
    draft: false,
    assets: const <ReleaseAsset>[
      ReleaseAsset(
        name: 'tometone-arm64-v8a.apk',
        sizeBytes: 25 * 1024 * 1024,
        downloadUrl: 'https://example.com/arm64.apk',
      ),
    ],
  );

  Widget createSettingsApp({
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: SettingsPage()),
      ),
    );
  }

  testWidgets('设置页：自动检查开关持久化', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore(
      AppPreferences.defaults.copyWith(autoCheckUpdates: true),
    );
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(
          const FakeDeviceArchitecture(),
        ),
        updateSourceProvider.overrideWithValue(FakeUpdateSource()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createSettingsApp(container: container));
    await tester.pumpAndSettle();

    final switchFinder = find.byKey(SettingsPage.autoCheckSwitchKey);
    await tester.ensureVisible(switchFinder);
    await tester.pumpAndSettle();
    expect(switchFinder, findsOneWidget);
    expect(container.read(preferencesProvider).autoCheckUpdates, isTrue);

    // 点击关闭开关
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(container.read(preferencesProvider).autoCheckUpdates, isFalse);
    expect(store.current.autoCheckUpdates, isFalse);

    // 再次点击开启开关
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(container.read(preferencesProvider).autoCheckUpdates, isTrue);
    expect(store.current.autoCheckUpdates, isTrue);
  });

  testWidgets('设置页：各个 UpdateStatus 下副标题与 Tag 变化', (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource();
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(
          const FakeDeviceArchitecture(),
        ),
        updateSourceProvider.overrideWithValue(fakeSource),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createSettingsApp(container: container));
    await tester.pumpAndSettle();

    // 1. idle 初始态
    expect(find.text('点击检查新版本'), findsOneWidget);
    expect(find.text('检查'), findsOneWidget);

    // 2. checking 态
    container.read(updateControllerProvider.notifier).state = const UpdateState(
      status: UpdateStatus.checking,
    );
    await tester.pump();
    expect(find.text('正在检查新版本…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // 3. available 态
    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.available,
      release: sampleRelease,
    );
    await tester.pump();
    expect(find.text('发现新版本 v0.3.0'), findsOneWidget);
    expect(find.text('可更新'), findsOneWidget);

    // 4. upToDate 态
    container.read(updateControllerProvider.notifier).state = const UpdateState(
      status: UpdateStatus.upToDate,
    );
    await tester.pump();
    expect(find.text('当前已是最新版本'), findsOneWidget);
    expect(find.text('最新'), findsOneWidget);

    // 5. skipped 态
    container.read(updateControllerProvider.notifier).state = UpdateState(
      status: UpdateStatus.skipped,
      release: sampleRelease,
    );
    await tester.pump();
    expect(find.text('已跳过版本 v0.3.0'), findsOneWidget);
    expect(find.text('已跳过'), findsOneWidget);

    // 6. noRelease 态
    container.read(updateControllerProvider.notifier).state = const UpdateState(
      status: UpdateStatus.noRelease,
    );
    await tester.pump();
    expect(find.text('暂无可用版本'), findsOneWidget);
    expect(find.text('暂无'), findsOneWidget);

    // 7. failure 态
    container.read(updateControllerProvider.notifier).state = const UpdateState(
      status: UpdateStatus.failure,
      failure: UpdateFailureKind.network,
    );
    await tester.pump();
    expect(find.text('检查失败，点击重试或查看'), findsOneWidget);
    expect(find.text('失败'), findsOneWidget);
  });

  testWidgets('设置页：点击检查更新行 push 到 UpdatePage 并触发 check',
      (WidgetTester tester) async {
    usePhoneViewport(tester);
    final store = InMemoryAppPreferencesStore();
    final fakeSource = FakeUpdateSource(
      result: UpdateFetchResult(releases: [sampleRelease]),
    );
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(store.current),
        deviceArchitectureProvider.overrideWithValue(
          const FakeDeviceArchitecture(),
        ),
        updateSourceProvider.overrideWithValue(fakeSource),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createSettingsApp(container: container));
    await tester.pumpAndSettle();

    final checkUpdateRow = find.byKey(SettingsPage.checkUpdateKey);
    await tester.ensureVisible(checkUpdateRow);
    await tester.pumpAndSettle();

    await tester.tap(checkUpdateRow);
    await tester.pumpAndSettle();

    expect(find.byType(UpdatePage), findsOneWidget);
    expect(fakeSource.calls, greaterThanOrEqualTo(1));
  });
}
