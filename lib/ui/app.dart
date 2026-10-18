import 'package:flutter/material.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/ui/app_shell.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/app_theme.dart';

/// 应用根 widget（UI 层）：只装配 `MaterialApp`、主题与外壳，不含业务策略。
///
/// 主题走「五套国风色盘 × 明/暗 × OLED」三维组合（§2.8）：
/// 当前默认跟随系统明暗，色盘与 OLED 由后续的设置页控制（届时换成
/// `ref.watch(preferencesProvider)` 即可，本类签名已经是这个形状）。
class TomeToneApp extends StatelessWidget {
  /// 创建应用根 widget。
  const TomeToneApp({
    super.key,
    this.palette = AppColorPalettes.fallback,
    this.oledDark = false,
  });

  /// 当前国风色盘。
  final AppPalette palette;

  /// 暗色形态是否使用 OLED 纯黑底。
  final bool oledDark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(palette: palette),
      darkTheme: AppTheme.build(
        palette: palette,
        brightness: Brightness.dark,
        oled: oledDark,
      ),
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
