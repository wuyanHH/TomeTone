import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/ui/app.dart';
import 'package:tometone/ui/pages/settings/settings_page.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';

import 'ui_test_harness.dart';

void main() {
  testWidgets(
    '点击色盘色块（例如竹海幽青）后，MaterialApp.theme 立即改变为对应色盘的主色，且 store.current.paletteId 变为 bambooMist',
    (WidgetTester tester) async {
      usePhoneViewport(tester);
      final store = InMemoryAppPreferencesStore();
      final engine = FakePlaybackEngine();
      final controller = testController(engine);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            controller: controller,
            preferencesStore: store,
          ),
          child: const TomeToneApp(),
        ),
      );
      await tester.pumpAndSettle();

      MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        app.theme?.colorScheme.primary,
        AppColorPalettes.amberScroll.light.primary,
      );
      expect(store.current.paletteId, 'amberScroll');

      // 切换到设置页
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 点击竹海幽青色盘
      final bambooKey = SettingsPage.appearancePaletteKey(
        AppPaletteId.bambooMist,
      );
      await tester.ensureVisible(find.byKey(bambooKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(bambooKey));
      await tester.pumpAndSettle();

      // 验证 MaterialApp.theme 立即同步，且偏好持久化为 bambooMist
      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        app.theme?.colorScheme.primary,
        AppColorPalettes.bambooMist.light.primary,
      );
      expect(store.current.paletteId, 'bambooMist');
    },
  );

  testWidgets(
    '切换明暗（浅色/深色/跟随系统），MaterialApp.themeMode 立即同步变化',
    (WidgetTester tester) async {
      usePhoneViewport(tester);
      final store = InMemoryAppPreferencesStore();
      final engine = FakePlaybackEngine();
      final controller = testController(engine);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            controller: controller,
            preferencesStore: store,
          ),
          child: const TomeToneApp(),
        ),
      );
      await tester.pumpAndSettle();

      MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      expect(store.current.brightness, BrightnessPreference.system);

      // 切换到设置页
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 切换为浅色
      final lightKey = SettingsPage.brightnessKey(BrightnessPreference.light);
      await tester.ensureVisible(find.byKey(lightKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(lightKey));
      await tester.pumpAndSettle();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.light);
      expect(store.current.brightness, BrightnessPreference.light);

      // 切换为深色
      final darkKey = SettingsPage.brightnessKey(BrightnessPreference.dark);
      await tester.ensureVisible(find.byKey(darkKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(darkKey));
      await tester.pumpAndSettle();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(store.current.brightness, BrightnessPreference.dark);

      // 切换回跟随系统
      final systemKey = SettingsPage.brightnessKey(
        BrightnessPreference.system,
      );
      await tester.ensureVisible(find.byKey(systemKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(systemKey));
      await tester.pumpAndSettle();

      app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.system);
      expect(store.current.brightness, BrightnessPreference.system);
    },
  );

  testWidgets(
    '浅色模式下暗夜 OLED 开关为 disabled；深色或跟随系统下可切换更新 oledDark',
    (WidgetTester tester) async {
      usePhoneViewport(tester);
      final store = InMemoryAppPreferencesStore();
      final engine = FakePlaybackEngine();
      final controller = testController(engine);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            controller: controller,
            preferencesStore: store,
          ),
          child: const TomeToneApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 切换到设置页
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 1. 默认状态：跟随系统，OLED 开关为启用状态（onChanged != null），默认值为 false
      SwitchListTile oledTile = tester.widget<SwitchListTile>(
        find.byKey(SettingsPage.oledSwitchKey),
      );
      expect(oledTile.onChanged, isNotNull);
      expect(oledTile.value, isFalse);

      // 切换 OLED 开关
      await tester.ensureVisible(find.byKey(SettingsPage.oledSwitchKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(SettingsPage.oledSwitchKey));
      await tester.pumpAndSettle();

      oledTile = tester.widget<SwitchListTile>(
        find.byKey(SettingsPage.oledSwitchKey),
      );
      expect(oledTile.value, isTrue);
      expect(store.current.oledDark, isTrue);

      // 2. 切换到浅色模式
      final lightKey = SettingsPage.brightnessKey(BrightnessPreference.light);
      await tester.ensureVisible(find.byKey(lightKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(lightKey));
      await tester.pumpAndSettle();

      // 浅色模式下，暗夜 OLED 开关应为 disabled (onChanged == null)
      oledTile = tester.widget<SwitchListTile>(
        find.byKey(SettingsPage.oledSwitchKey),
      );
      expect(oledTile.onChanged, isNull);

      // 3. 切换到深色模式
      final darkKey = SettingsPage.brightnessKey(BrightnessPreference.dark);
      await tester.ensureVisible(find.byKey(darkKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(darkKey));
      await tester.pumpAndSettle();

      // 深色模式下，OLED 开关再次启用
      oledTile = tester.widget<SwitchListTile>(
        find.byKey(SettingsPage.oledSwitchKey),
      );
      expect(oledTile.onChanged, isNotNull);

      // 再次点击切换为 false
      await tester.tap(find.byKey(SettingsPage.oledSwitchKey));
      await tester.pumpAndSettle();

      oledTile = tester.widget<SwitchListTile>(
        find.byKey(SettingsPage.oledSwitchKey),
      );
      expect(oledTile.value, isFalse);
      expect(store.current.oledDark, isFalse);
    },
  );
}
