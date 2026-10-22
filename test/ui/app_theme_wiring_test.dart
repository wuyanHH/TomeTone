import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/ui/app.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/app_theme.dart';
import 'package:tometone/ui/widgets/book_cover.dart';

import 'ui_test_harness.dart';

void main() {
  testWidgets('应用装配新主题：默认琥珀旧卷，明暗跟随系统', (WidgetTester tester) async {
    final FakePlaybackEngine engine = FakePlaybackEngine();
    final controller = testController(engine);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(controller: controller),
        child: const TomeToneApp(),
      ),
    );

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );

    expect(app.themeMode, ThemeMode.system);

    final AppPaletteColors light = AppColorPalettes.fallback.colorsFor(
      Brightness.light,
    );
    final AppPaletteColors dark = AppColorPalettes.fallback.colorsFor(
      Brightness.dark,
    );

    expect(app.theme?.colorScheme.primary, light.primary);
    expect(app.theme?.colorScheme.surface, light.surface);
    expect(app.darkTheme?.colorScheme.surface, dark.surface);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OLED 开关只影响暗色形态', (WidgetTester tester) async {
    final FakePlaybackEngine engine = FakePlaybackEngine();
    final controller = testController(engine);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: testOverrides(
          controller: controller,
          preferences: const AppPreferences(oledDark: true),
        ),
        child: const TomeToneApp(),
      ),
    );

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    final AppPaletteColors oledDark = AppColorPalettes.fallback.colorsFor(
      Brightness.dark,
      oled: true,
    );
    final AppPaletteColors light = AppColorPalettes.fallback.colorsFor(
      Brightness.light,
    );

    expect(app.darkTheme?.colorScheme.surface, oledDark.surface);
    expect(app.theme?.colorScheme.surface, light.surface);
  });

  group('BookCover 拒绝相对路径（会静默不显示）', () {
    testWidgets('绝对路径不触发断言', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(palette: AppColorPalettes.fallback),
          home: const Scaffold(
            body: BookCover(
              title: '三体',
              size: 96,
              coverPath: '/storage/emulated/0/Books/三体/cover.jpg',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('相对路径在 debug 下立即失败', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(palette: AppColorPalettes.fallback),
          home: const Scaffold(
            body: BookCover(title: '三体', size: 96, coverPath: '三体/cover.jpg'),
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });
  });
}
