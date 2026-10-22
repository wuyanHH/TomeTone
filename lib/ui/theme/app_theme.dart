import 'package:flutter/material.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 应用主题工厂（Material 3）。
///
/// 组合维度：`palette`（五套国风色盘）× `brightness`（明/暗）× `oled`
/// （暗夜 OLED：纯黑背景、压低中间色阶、强调色降饱和）。
///
/// 排版取向：中文长时间阅读/听书场景 —— 标题用衬线（宋体一族）提气质，
/// 正文用无衬线并以 1.7–1.75 行高保证中文的呼吸感。
abstract final class AppTheme {
  /// 构建主题。
  static ThemeData build({
    AppPalette palette = AppColorPalettes.fallback,
    Brightness brightness = Brightness.light,
    bool oled = false,
  }) {
    final AppPaletteColors paletteColors = palette.colorsFor(
      brightness,
      oled: oled,
    );
    final ColorScheme scheme = paletteColors.toColorScheme();
    final TextTheme textTheme = _buildTextTheme(scheme);
    final bool isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: AppSizes.navigationBarHeight,
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected
                ? scheme.onSecondaryContainer
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        indicatorShape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        selectedIconTheme: IconThemeData(
          color: scheme.onSecondaryContainer,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 24,
        ),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lg,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.xl),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: scheme.surfaceContainer,
        modalBarrierColor: scheme.scrim.withValues(alpha: 0.5),
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sm),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: AppSpacing.sm,
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
          ),
          iconSize: const WidgetStatePropertyAll<double>(22),
          foregroundColor: WidgetStatePropertyAll<Color>(
            scheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(72, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(72, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          side: BorderSide(color: scheme.outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minTouchTarget,
            AppSizes.minTouchTarget,
          ),
          textStyle: textTheme.labelLarge,
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.md,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: isLight ? 0.20 : 0.30),
        selectionHandleColor: scheme.primary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: AppRadii.xs,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onInverseSurface,
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[MiniPlayerTheme.fromScheme(scheme)],
    );
  }

  static TextTheme _buildTextTheme(ColorScheme scheme) {
    // 标题：衬线 + 略紧的行高，中文标题更有"书卷气"。
    TextStyle serif(TextStyle style) {
      return style.copyWith(
        fontFamily: AppTypefaces.serifFamily,
        fontFamilyFallback: AppTypefaces.serifFallback,
        color: scheme.onSurface,
      );
    }

    // 正文：无衬线 + 宽松行高（1.7–1.75），适配长篇中文连续阅读。
    TextStyle sans(TextStyle style) {
      return style.copyWith(color: scheme.onSurface);
    }

    return TextTheme(
      displayLarge: serif(
        const TextStyle(
          fontSize: 40,
          height: 1.2,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      displayMedium: serif(
        const TextStyle(
          fontSize: 34,
          height: 1.22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
      displaySmall: serif(
        const TextStyle(
          fontSize: 30,
          height: 1.26,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      headlineLarge: serif(
        const TextStyle(
          fontSize: 27,
          height: 1.3,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      headlineMedium: serif(
        const TextStyle(
          fontSize: 24,
          height: 1.32,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      headlineSmall: serif(
        const TextStyle(
          fontSize: 21,
          height: 1.36,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      titleLarge: serif(
        const TextStyle(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      titleMedium: sans(
        const TextStyle(
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      titleSmall: sans(
        const TextStyle(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      bodyLarge: sans(
        const TextStyle(
          fontSize: 16,
          height: 1.75,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
      ),
      bodyMedium: sans(
        const TextStyle(
          fontSize: 14,
          height: 1.7,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
      ),
      bodySmall: sans(
        const TextStyle(
          fontSize: 12,
          height: 1.6,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
      ),
      labelLarge: sans(
        const TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      labelMedium: sans(
        const TextStyle(
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
      labelSmall: sans(
        const TextStyle(
          fontSize: 11,
          height: 1.4,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// MiniPlayer 组件主题。
///
/// 外壳只负责"槽位"，具体播放器实现从这里取底色、描边、进度条配色，
/// 以保证五套色盘 × 明暗 × OLED 下观感一致。
@immutable
class MiniPlayerTheme extends ThemeExtension<MiniPlayerTheme> {
  /// 创建 MiniPlayer 主题。
  const MiniPlayerTheme({
    required this.background,
    required this.border,
    required this.titleColor,
    required this.subtitleColor,
    required this.progressTrack,
    required this.progressFill,
    this.height = AppSizes.miniPlayerHeight,
    this.borderRadius = AppRadii.miniPlayer,
  });

  /// 从配色方案推导。
  factory MiniPlayerTheme.fromScheme(ColorScheme scheme) {
    return MiniPlayerTheme(
      background: scheme.surfaceContainerHigh,
      border: scheme.outlineVariant,
      titleColor: scheme.onSurface,
      subtitleColor: scheme.onSurfaceVariant,
      progressTrack: scheme.surfaceContainerHighest,
      progressFill: scheme.primary,
    );
  }

  /// 槽位底色。
  final Color background;

  /// 描边色。
  final Color border;

  /// 书名颜色。
  final Color titleColor;

  /// 章节 / 演播者颜色。
  final Color subtitleColor;

  /// 进度条轨道。
  final Color progressTrack;

  /// 进度条已播部分。
  final Color progressFill;

  /// 参考高度（真实播放器可覆盖）。
  final double height;

  /// 圆角。
  final BorderRadius borderRadius;

  /// 从 [Theme] 读取；主题未注册时回退到当前配色方案。
  static MiniPlayerTheme of(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return theme.extension<MiniPlayerTheme>() ??
        MiniPlayerTheme.fromScheme(theme.colorScheme);
  }

  @override
  MiniPlayerTheme copyWith({
    Color? background,
    Color? border,
    Color? titleColor,
    Color? subtitleColor,
    Color? progressTrack,
    Color? progressFill,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return MiniPlayerTheme(
      background: background ?? this.background,
      border: border ?? this.border,
      titleColor: titleColor ?? this.titleColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      progressTrack: progressTrack ?? this.progressTrack,
      progressFill: progressFill ?? this.progressFill,
      height: height ?? this.height,
      borderRadius: borderRadius ?? this.borderRadius,
    );
  }

  @override
  MiniPlayerTheme lerp(ThemeExtension<MiniPlayerTheme>? other, double t) {
    if (other is! MiniPlayerTheme) {
      return this;
    }
    return MiniPlayerTheme(
      background: Color.lerp(background, other.background, t) ?? background,
      border: Color.lerp(border, other.border, t) ?? border,
      titleColor: Color.lerp(titleColor, other.titleColor, t) ?? titleColor,
      subtitleColor:
          Color.lerp(subtitleColor, other.subtitleColor, t) ?? subtitleColor,
      progressTrack:
          Color.lerp(progressTrack, other.progressTrack, t) ?? progressTrack,
      progressFill:
          Color.lerp(progressFill, other.progressFill, t) ?? progressFill,
      height: height + (other.height - height) * t,
      borderRadius:
          BorderRadius.lerp(borderRadius, other.borderRadius, t) ??
          borderRadius,
    );
  }
}
