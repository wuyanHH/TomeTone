import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/pages/settings/settings_page.dart';
import 'package:tometone/ui/pages/settings/update_history_page.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';

import 'ui_test_harness.dart';

void main() {
  /// 把设置页塞进最小应用；页面不再读写书库数据，容器仅注入偏好配置。
  Future<ProviderContainer> pumpSettings(WidgetTester tester) async {
    usePhoneViewport(tester);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(
          InMemoryAppPreferencesStore(),
        ),
        initialPreferencesProvider.overrideWithValue(AppPreferences.defaults),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      testApp(container, const Scaffold(body: SettingsPage())),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('分组结构：外观明暗/色盘/OLED开关正常渲染，书库根已拆到「书库」页', (WidgetTester tester) async {
    await pumpSettings(tester);

    expect(find.text('系统偏好'), findsOneWidget);
    expect(find.text('偏好 · PREFERENCES'), findsNothing);
    expect(find.text('外观与关于，都收在这一页；书库根在「书库」里管理。'), findsNothing);
    expect(find.text('外观'), findsOneWidget);
    expect(find.byType(SegmentedButton<BrightnessPreference>), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('浅色'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);

    expect(find.text('国风色盘'), findsOneWidget);
    for (final palette in AppColorPalettes.all) {
      expect(
        find.byKey(SettingsPage.appearancePaletteKey(palette.id)),
        findsOneWidget,
      );
      expect(find.text(palette.label), findsOneWidget);
    }

    expect(find.byKey(SettingsPage.oledSwitchKey), findsOneWidget);
    expect(find.text('暗夜 OLED 纯黑'), findsOneWidget);
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

    // 版本号来自 AppInfo（唯一来源），不在这里写死具体值：
    // 否则每次发版都要改测试，而这条用例的意图是"页面读的是 AppInfo"。
    expect(find.text(AppInfo.version), findsOneWidget);
    expect(find.text('发布通道 · ${AppInfo.channel.label}'), findsOneWidget);

    expect(find.byKey(SettingsPage.autoCheckSwitchKey), findsOneWidget);
    expect(find.text('自动检查更新'), findsOneWidget);
    expect(find.byKey(SettingsPage.checkUpdateKey), findsOneWidget);
    expect(find.text('检查更新'), findsOneWidget);
    expect(find.text('点击检查新版本'), findsOneWidget);
    expect(find.text('检查'), findsOneWidget);
    expect(find.text('开源许可'), findsOneWidget);

    // 更新历史入口
    expect(find.byKey(SettingsPage.updateHistoryKey), findsOneWidget);
    expect(find.text('更新历史'), findsOneWidget);
    expect(find.text('逐版本查看更新内容'), findsOneWidget);

    await tester.ensureVisible(find.byKey(SettingsPage.updateHistoryKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsPage.updateHistoryKey));
    await tester.pumpAndSettle();
    expect(find.byType(UpdateHistoryPage), findsOneWidget);

    // 返回设置页继续测试开源许可
    Navigator.of(tester.element(find.byType(UpdateHistoryPage))).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(SettingsPage.licensesKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsPage.licensesKey));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
