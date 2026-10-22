import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/ui/app_shell.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/app_theme.dart';

/// 应用根 widget（UI 层）：只装配 `MaterialApp`、主题与外壳，不含业务策略。
///
/// 主题走「五套国风色盘 × 明/暗 × OLED」三维组合（§2.8）：
/// 色盘、明暗偏好与 OLED 纯黑由全局偏好驱动。
class TomeToneApp extends ConsumerWidget {
  /// 创建应用根 widget。
  const TomeToneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final palette = AppColorPalettes.byId(paletteIdFromName(prefs.paletteId));

    final themeMode = switch (prefs.brightness) {
      BrightnessPreference.system => ThemeMode.system,
      BrightnessPreference.light => ThemeMode.light,
      BrightnessPreference.dark => ThemeMode.dark,
    };

    return MaterialApp(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(palette: palette),
      darkTheme: AppTheme.build(
        palette: palette,
        brightness: Brightness.dark,
        oled: prefs.oledDark,
      ),
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
