import 'package:flutter/material.dart';

/// 五套国风色盘的标识（《架构需求文档》§2.8）。
enum AppPaletteId {
  /// 琥珀旧卷：宣纸、琥珀与檀木。
  amberScroll,

  /// 竹海幽青：青瓷、竹青与苔痕。
  bambooMist,

  /// 星夜深蓝：靛蓝夜空与一线铜金。
  starryIndigo,

  /// 暮紫沉香：紫檀、沉香与藕荷。
  duskAloeswood,

  /// 山丹丹红：丹砂、黄土与麦金。
  shandanRed,
}

/// 根据名称解析 [AppPaletteId]，未知名称回落到 [AppPaletteId.amberScroll]。
AppPaletteId paletteIdFromName(String name) {
  return AppPaletteId.values.firstWhere(
    (id) => id.name == name,
    orElse: () => AppPaletteId.amberScroll,
  );
}

/// 一套色盘在某个明暗形态下的语义色集合。
///
/// 字段与 Material 3 [ColorScheme] 的语义角色一一对应，页面只应消费这些
/// 语义角色，不再散落 raw hex。`onXxx` 均为对应底色上的前景色，且保证
/// 达到 WCAG AA（正文 ≥ 4.5:1）。
@immutable
class AppPaletteColors {
  /// 创建语义色集合。
  const AppPaletteColors({
    required this.brightness,
    required this.oled,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
  });

  /// 该集合所属的明暗形态。
  final Brightness brightness;

  /// 是否用于暗夜 OLED（纯黑背景、压低中间色阶、强调色降饱和）。
  final bool oled;

  /// 主色：品牌与关键操作。
  final Color primary;

  /// 主色上的前景色。
  final Color onPrimary;

  /// 主色容器：选中态、封面字标底色。
  final Color primaryContainer;

  /// 主色容器上的前景色。
  final Color onPrimaryContainer;

  /// 次色：辅助强调、筛选标签。
  final Color secondary;

  /// 次色上的前景色。
  final Color onSecondary;

  /// 次色容器：NavigationBar 指示器等。
  final Color secondaryContainer;

  /// 次色容器上的前景色。
  final Color onSecondaryContainer;

  /// 第三色：数据可视化与点缀。
  final Color tertiary;

  /// 第三色上的前景色。
  final Color onTertiary;

  /// 第三色容器。
  final Color tertiaryContainer;

  /// 第三色容器上的前景色。
  final Color onTertiaryContainer;

  /// 页面底色。
  final Color surface;

  /// 页面主文字色。
  final Color onSurface;

  /// 次级文字色（说明、副标题）。
  final Color onSurfaceVariant;

  /// 最低层表面（列表卡片下方、浮层之上）。
  final Color surfaceContainerLowest;

  /// 较低层表面。
  final Color surfaceContainerLow;

  /// 标准容器表面。
  final Color surfaceContainer;

  /// 较高层表面。
  final Color surfaceContainerHigh;

  /// 最高层表面（对话框、悬浮控件）。
  final Color surfaceContainerHighest;

  /// 描边（输入框、分隔）。
  final Color outline;

  /// 弱描边（发丝线、装饰框）。
  final Color outlineVariant;

  /// 错误色。
  final Color error;

  /// 错误色上的前景色。
  final Color onError;

  /// 错误容器。
  final Color errorContainer;

  /// 错误容器上的前景色。
  final Color onErrorContainer;

  /// 组装为 Material 3 [ColorScheme]。
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      surfaceTint: primary,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      // 反色表面用于 SnackBar 等：深底浅字 / 浅底深字，随明暗自动翻转。
      inverseSurface: onSurface,
      onInverseSurface: surface,
      inversePrimary: primaryContainer,
    );
  }
}

/// 一套完整的国风色盘：浅色、深色与暗夜 OLED 三种形态。
@immutable
class AppPalette {
  /// 创建色盘。
  const AppPalette({
    required this.id,
    required this.label,
    required this.summary,
    required this.light,
    required this.dark,
    required this.darkOled,
  });

  /// 色盘标识。
  final AppPaletteId id;

  /// 中文名（设置页展示）。
  final String label;

  /// 一句话气质描述。
  final String summary;

  /// 浅色形态。
  final AppPaletteColors light;

  /// 深色形态。
  final AppPaletteColors dark;

  /// 暗夜 OLED 形态（纯黑背景）。
  final AppPaletteColors darkOled;

  /// 按明暗与 OLED 开关取色；OLED 仅影响深色形态。
  AppPaletteColors colorsFor(Brightness brightness, {bool oled = false}) {
    if (brightness == Brightness.light) {
      return light;
    }
    return oled ? darkOled : dark;
  }
}

/// 五套国风色盘的常量集合。
///
/// 命名取自材质与意象，而非 Material 默认色板：
/// - 琥珀旧卷：宣纸底 + 琥珀墨 + 檀木灰，长读不刺眼。
/// - 竹海幽青：青瓷白 + 竹青 + 苔痕灰，安静克制。
/// - 星夜深蓝：月白底 + 靛蓝 + 一线铜金，夜间听书友好。
/// - 暮紫沉香：藕荷底 + 紫檀 + 沉香木，偏沉静的睡前后场。
/// - 山丹丹红：米纸底 + 丹砂 + 黄土赭，最热烈的一套。
abstract final class AppColorPalettes {
  /// 默认色盘。
  static const AppPalette fallback = amberScroll;

  /// 全部色盘（设置页按此顺序展示）。
  static const List<AppPalette> all = <AppPalette>[
    amberScroll,
    bambooMist,
    starryIndigo,
    duskAloeswood,
    shandanRed,
  ];

  /// 按标识取色盘。
  static AppPalette byId(AppPaletteId id) {
    return all.firstWhere(
      (AppPalette palette) => palette.id == id,
      orElse: () => fallback,
    );
  }

  // ---------------------------------------------------------------------------
  // 琥珀旧卷 · Amber Scroll
  // ---------------------------------------------------------------------------
  /// 琥珀旧卷。
  static const AppPalette amberScroll = AppPalette(
    id: AppPaletteId.amberScroll,
    label: '琥珀旧卷',
    summary: '宣纸与琥珀，像翻旧了一册线装书',
    light: AppPaletteColors(
      brightness: Brightness.light,
      oled: false,
      primary: Color(0xFF8A5A20),
      onPrimary: Color(0xFFFFF8EE),
      primaryContainer: Color(0xFFF6DFB8),
      onPrimaryContainer: Color(0xFF3A2405),
      secondary: Color(0xFF6B5741),
      onSecondary: Color(0xFFFFF8F0),
      secondaryContainer: Color(0xFFEDE0CB),
      onSecondaryContainer: Color(0xFF2A2013),
      tertiary: Color(0xFF7C4A38),
      onTertiary: Color(0xFFFFF7F3),
      tertiaryContainer: Color(0xFFF4D9CB),
      onTertiaryContainer: Color(0xFF34140B),
      surface: Color(0xFFFBF6EC),
      onSurface: Color(0xFF221A11),
      onSurfaceVariant: Color(0xFF5C4B38),
      surfaceContainerLowest: Color(0xFFFFFDF8),
      surfaceContainerLow: Color(0xFFF7EFE0),
      surfaceContainer: Color(0xFFF2E8D6),
      surfaceContainerHigh: Color(0xFFECE0CC),
      surfaceContainerHighest: Color(0xFFE5D8C0),
      outline: Color(0xFF8B7860),
      outlineVariant: Color(0xFFDCCCB0),
      error: Color(0xFFA5332A),
      onError: Color(0xFFFFF8F6),
      errorContainer: Color(0xFFFBDAD3),
      onErrorContainer: Color(0xFF3D0906),
    ),
    dark: AppPaletteColors(
      brightness: Brightness.dark,
      oled: false,
      primary: Color(0xFFE5B77A),
      onPrimary: Color(0xFF3A2405),
      primaryContainer: Color(0xFF5B411F),
      onPrimaryContainer: Color(0xFFF6DEB7),
      secondary: Color(0xFFD2BFA4),
      onSecondary: Color(0xFF33291B),
      secondaryContainer: Color(0xFF453B2B),
      onSecondaryContainer: Color(0xFFEEE0CA),
      tertiary: Color(0xFFE3B7A2),
      onTertiary: Color(0xFF3E1E13),
      tertiaryContainer: Color(0xFF5B3B2C),
      onTertiaryContainer: Color(0xFFF7DBD0),
      surface: Color(0xFF191510),
      onSurface: Color(0xFFEDE4D5),
      onSurfaceVariant: Color(0xFFC9B79D),
      surfaceContainerLowest: Color(0xFF100D09),
      surfaceContainerLow: Color(0xFF1E1913),
      surfaceContainer: Color(0xFF241E17),
      surfaceContainerHigh: Color(0xFF2B241C),
      surfaceContainerHighest: Color(0xFF332B21),
      outline: Color(0xFF978672),
      outlineVariant: Color(0xFF4B4135),
      error: Color(0xFFFFB4A8),
      onError: Color(0xFF561E16),
      errorContainer: Color(0xFF742B21),
      onErrorContainer: Color(0xFFFFDAD4),
    ),
    darkOled: AppPaletteColors(
      brightness: Brightness.dark,
      oled: true,
      primary: Color(0xFFD6AE7C),
      onPrimary: Color(0xFF2E1D04),
      primaryContainer: Color(0xFF3D2C15),
      onPrimaryContainer: Color(0xFFEBD2AC),
      secondary: Color(0xFFC3B199),
      onSecondary: Color(0xFF2B2217),
      secondaryContainer: Color(0xFF332B20),
      onSecondaryContainer: Color(0xFFE7DAC5),
      tertiary: Color(0xFFD3AC9A),
      onTertiary: Color(0xFF34180F),
      tertiaryContainer: Color(0xFF3F2A1F),
      onTertiaryContainer: Color(0xFFEED4C9),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFE3DACA),
      onSurfaceVariant: Color(0xFFBFAF97),
      surfaceContainerLowest: Color(0xFF000000),
      surfaceContainerLow: Color(0xFF0C0A07),
      surfaceContainer: Color(0xFF13100B),
      surfaceContainerHigh: Color(0xFF191510),
      surfaceContainerHighest: Color(0xFF211B14),
      outline: Color(0xFF7E6F5E),
      outlineVariant: Color(0xFF3A3228),
      error: Color(0xFFE8A79C),
      onError: Color(0xFF3F110B),
      errorContainer: Color(0xFF52201A),
      onErrorContainer: Color(0xFFF5D3CD),
    ),
  );

  // ---------------------------------------------------------------------------
  // 竹海幽青 · Bamboo Mist
  // ---------------------------------------------------------------------------
  /// 竹海幽青。
  static const AppPalette bambooMist = AppPalette(
    id: AppPaletteId.bambooMist,
    label: '竹海幽青',
    summary: '青瓷与竹影，风过处只剩安静',
    light: AppPaletteColors(
      brightness: Brightness.light,
      oled: false,
      primary: Color(0xFF1F5C46),
      onPrimary: Color(0xFFF3FBF5),
      primaryContainer: Color(0xFFC3E5D2),
      onPrimaryContainer: Color(0xFF05291C),
      secondary: Color(0xFF50695B),
      onSecondary: Color(0xFFF5FBF6),
      secondaryContainer: Color(0xFFD8E7DC),
      onSecondaryContainer: Color(0xFF11251B),
      tertiary: Color(0xFF356A67),
      onTertiary: Color(0xFFF1FBF9),
      tertiaryContainer: Color(0xFFCBE6E3),
      onTertiaryContainer: Color(0xFF072C2A),
      surface: Color(0xFFF3F7F1),
      onSurface: Color(0xFF15211A),
      onSurfaceVariant: Color(0xFF45564B),
      surfaceContainerLowest: Color(0xFFFBFDF9),
      surfaceContainerLow: Color(0xFFEDF3EB),
      surfaceContainer: Color(0xFFE7EFE5),
      surfaceContainerHigh: Color(0xFFE1EADF),
      surfaceContainerHighest: Color(0xFFDAE4D8),
      outline: Color(0xFF6E7F73),
      outlineVariant: Color(0xFFC5D3C7),
      error: Color(0xFFA03B2E),
      onError: Color(0xFFFFF8F6),
      errorContainer: Color(0xFFFADAD3),
      onErrorContainer: Color(0xFF3C0A05),
    ),
    dark: AppPaletteColors(
      brightness: Brightness.dark,
      oled: false,
      primary: Color(0xFF8CD3B2),
      onPrimary: Color(0xFF042A1B),
      primaryContainer: Color(0xFF204A3A),
      onPrimaryContainer: Color(0xFFB7E9D2),
      secondary: Color(0xFFB7CCBF),
      onSecondary: Color(0xFF23352A),
      secondaryContainer: Color(0xFF354B3F),
      onSecondaryContainer: Color(0xFFD3E8DA),
      tertiary: Color(0xFF9CCFCA),
      onTertiary: Color(0xFF00302E),
      tertiaryContainer: Color(0xFF23504D),
      onTertiaryContainer: Color(0xFFB8ECE6),
      surface: Color(0xFF0F1914),
      onSurface: Color(0xFFDDE9DF),
      onSurfaceVariant: Color(0xFFB4C5B8),
      surfaceContainerLowest: Color(0xFF0A120E),
      surfaceContainerLow: Color(0xFF141E18),
      surfaceContainer: Color(0xFF18231D),
      surfaceContainerHigh: Color(0xFF1E2A23),
      surfaceContainerHighest: Color(0xFF25332B),
      outline: Color(0xFF7E9084),
      outlineVariant: Color(0xFF3B4C41),
      error: Color(0xFFFFB4A4),
      onError: Color(0xFF561E14),
      errorContainer: Color(0xFF732B21),
      onErrorContainer: Color(0xFFFFDAD3),
    ),
    darkOled: AppPaletteColors(
      brightness: Brightness.dark,
      oled: true,
      primary: Color(0xFF7FBD9F),
      onPrimary: Color(0xFF032015),
      primaryContainer: Color(0xFF16362A),
      onPrimaryContainer: Color(0xFFAEDDC7),
      secondary: Color(0xFFAFC3B6),
      onSecondary: Color(0xFF1D2C23),
      secondaryContainer: Color(0xFF283A2F),
      onSecondaryContainer: Color(0xFFC9DCCF),
      tertiary: Color(0xFF92C4BF),
      onTertiary: Color(0xFF002321),
      tertiaryContainer: Color(0xFF1A3B39),
      onTertiaryContainer: Color(0xFFADDCD7),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFD3E2D6),
      onSurfaceVariant: Color(0xFFA9BCAC),
      surfaceContainerLowest: Color(0xFF000000),
      surfaceContainerLow: Color(0xFF08120C),
      surfaceContainer: Color(0xFF0E1913),
      surfaceContainerHigh: Color(0xFF14211A),
      surfaceContainerHighest: Color(0xFF1B2A21),
      outline: Color(0xFF6E8074),
      outlineVariant: Color(0xFF2F3F35),
      error: Color(0xFFE5A69A),
      onError: Color(0xFF3E0F08),
      errorContainer: Color(0xFF4F1C15),
      onErrorContainer: Color(0xFFF3D0C9),
    ),
  );

  // ---------------------------------------------------------------------------
  // 星夜深蓝 · Starry Indigo
  // ---------------------------------------------------------------------------
  /// 星夜深蓝。
  static const AppPalette starryIndigo = AppPalette(
    id: AppPaletteId.starryIndigo,
    label: '星夜深蓝',
    summary: '靛蓝夜空配一线铜金，适合熄灯后听',
    light: AppPaletteColors(
      brightness: Brightness.light,
      oled: false,
      primary: Color(0xFF2C3A72),
      onPrimary: Color(0xFFF6F7FF),
      primaryContainer: Color(0xFFD9DEF8),
      onPrimaryContainer: Color(0xFF111B45),
      secondary: Color(0xFF5A627C),
      onSecondary: Color(0xFFF7F8FE),
      secondaryContainer: Color(0xFFDFE2EF),
      onSecondaryContainer: Color(0xFF171C2B),
      tertiary: Color(0xFF8A6A2F),
      onTertiary: Color(0xFFFFF8EC),
      tertiaryContainer: Color(0xFFF3E2BE),
      onTertiaryContainer: Color(0xFF2C1F02),
      surface: Color(0xFFF4F5FB),
      onSurface: Color(0xFF181A26),
      onSurfaceVariant: Color(0xFF474B60),
      surfaceContainerLowest: Color(0xFFFCFCFF),
      surfaceContainerLow: Color(0xFFEFF0F7),
      surfaceContainer: Color(0xFFE9EAF2),
      surfaceContainerHigh: Color(0xFFE2E4ED),
      surfaceContainerHighest: Color(0xFFDCDEE8),
      outline: Color(0xFF71758A),
      outlineVariant: Color(0xFFC6C9D6),
      error: Color(0xFFA43530),
      onError: Color(0xFFFFF7F6),
      errorContainer: Color(0xFFFAD9D5),
      onErrorContainer: Color(0xFF3D0705),
    ),
    dark: AppPaletteColors(
      brightness: Brightness.dark,
      oled: false,
      primary: Color(0xFFBAC4F6),
      onPrimary: Color(0xFF1F2B5A),
      primaryContainer: Color(0xFF35406D),
      onPrimaryContainer: Color(0xFFDCE0FB),
      secondary: Color(0xFFC2C6D9),
      onSecondary: Color(0xFF2B3042),
      secondaryContainer: Color(0xFF414659),
      onSecondaryContainer: Color(0xFFDEE2F0),
      tertiary: Color(0xFFE3C48C),
      onTertiary: Color(0xFF412F05),
      tertiaryContainer: Color(0xFF594413),
      onTertiaryContainer: Color(0xFFF5E2BA),
      surface: Color(0xFF0F1220),
      onSurface: Color(0xFFE2E3F1),
      onSurfaceVariant: Color(0xFFBBC0D4),
      surfaceContainerLowest: Color(0xFF090C17),
      surfaceContainerLow: Color(0xFF141726),
      surfaceContainer: Color(0xFF191C2C),
      surfaceContainerHigh: Color(0xFF1F2233),
      surfaceContainerHighest: Color(0xFF272A3C),
      outline: Color(0xFF84899E),
      outlineVariant: Color(0xFF40455A),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF5A1A16),
      errorContainer: Color(0xFF78201B),
      onErrorContainer: Color(0xFFFFDAD6),
    ),
    darkOled: AppPaletteColors(
      brightness: Brightness.dark,
      oled: true,
      primary: Color(0xFFB0BAE8),
      onPrimary: Color(0xFF151E44),
      primaryContainer: Color(0xFF242E52),
      onPrimaryContainer: Color(0xFFCED6F6),
      secondary: Color(0xFFB5BACD),
      onSecondary: Color(0xFF232838),
      secondaryContainer: Color(0xFF2E3346),
      onSecondaryContainer: Color(0xFFD2D7E6),
      tertiary: Color(0xFFD3B77F),
      onTertiary: Color(0xFF332400),
      tertiaryContainer: Color(0xFF43330C),
      onTertiaryContainer: Color(0xFFEBD9B1),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFD8DAEA),
      onSurfaceVariant: Color(0xFFB1B7CC),
      surfaceContainerLowest: Color(0xFF000000),
      surfaceContainerLow: Color(0xFF0A0D18),
      surfaceContainer: Color(0xFF111422),
      surfaceContainerHigh: Color(0xFF171B2A),
      surfaceContainerHighest: Color(0xFF1F2333),
      outline: Color(0xFF727A90),
      outlineVariant: Color(0xFF343A4D),
      error: Color(0xFFDFA49B),
      onError: Color(0xFF3C100C),
      errorContainer: Color(0xFF4E1714),
      onErrorContainer: Color(0xFFF0CFCA),
    ),
  );

  // ---------------------------------------------------------------------------
  // 暮紫沉香 · Dusk Aloeswood
  // ---------------------------------------------------------------------------
  /// 暮紫沉香。
  static const AppPalette duskAloeswood = AppPalette(
    id: AppPaletteId.duskAloeswood,
    label: '暮紫沉香',
    summary: '紫檀与沉香木，黄昏书房的气味',
    light: AppPaletteColors(
      brightness: Brightness.light,
      oled: false,
      primary: Color(0xFF6B3560),
      onPrimary: Color(0xFFFFF7FC),
      primaryContainer: Color(0xFFF2D9EB),
      onPrimaryContainer: Color(0xFF33102C),
      secondary: Color(0xFF7A5A4A),
      onSecondary: Color(0xFFFFF8F4),
      secondaryContainer: Color(0xFFEFE0D5),
      onSecondaryContainer: Color(0xFF2B1E14),
      tertiary: Color(0xFF7C5A16),
      onTertiary: Color(0xFFFFF9EC),
      tertiaryContainer: Color(0xFFF2E3BC),
      onTertiaryContainer: Color(0xFF2A1D00),
      surface: Color(0xFFF8F3F7),
      onSurface: Color(0xFF221A21),
      onSurfaceVariant: Color(0xFF574751),
      surfaceContainerLowest: Color(0xFFFDFAFF),
      surfaceContainerLow: Color(0xFFF3ECF1),
      surfaceContainer: Color(0xFFEDE5EB),
      surfaceContainerHigh: Color(0xFFE6DEE5),
      surfaceContainerHighest: Color(0xFFE0D7DE),
      outline: Color(0xFF86717E),
      outlineVariant: Color(0xFFD8C6D2),
      error: Color(0xFFA3312D),
      onError: Color(0xFFFFF7F6),
      errorContainer: Color(0xFFFAD9D5),
      onErrorContainer: Color(0xFF3D0705),
    ),
    dark: AppPaletteColors(
      brightness: Brightness.dark,
      oled: false,
      primary: Color(0xFFE3AAD4),
      onPrimary: Color(0xFF421A38),
      primaryContainer: Color(0xFF5B2F52),
      onPrimaryContainer: Color(0xFFF3D7EC),
      secondary: Color(0xFFDCC2B1),
      onSecondary: Color(0xFF3B2A1E),
      secondaryContainer: Color(0xFF4E3A2C),
      onSecondaryContainer: Color(0xFFF2DFD1),
      tertiary: Color(0xFFE2C68C),
      onTertiary: Color(0xFF3F2E04),
      tertiaryContainer: Color(0xFF594313),
      onTertiaryContainer: Color(0xFFF5E3B9),
      surface: Color(0xFF1A141A),
      onSurface: Color(0xFFEEE0E8),
      onSurfaceVariant: Color(0xFFCDB9C5),
      surfaceContainerLowest: Color(0xFF110C11),
      surfaceContainerLow: Color(0xFF1F181E),
      surfaceContainer: Color(0xFF251E24),
      surfaceContainerHigh: Color(0xFF2C242A),
      surfaceContainerHighest: Color(0xFF342B31),
      outline: Color(0xFF988491),
      outlineVariant: Color(0xFF4D4048),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF5A1A16),
      errorContainer: Color(0xFF78201B),
      onErrorContainer: Color(0xFFFFDAD6),
    ),
    darkOled: AppPaletteColors(
      brightness: Brightness.dark,
      oled: true,
      primary: Color(0xFFD3A1C6),
      onPrimary: Color(0xFF36132C),
      primaryContainer: Color(0xFF3F2139),
      onPrimaryContainer: Color(0xFFE9CFE2),
      secondary: Color(0xFFCBB4A5),
      onSecondary: Color(0xFF302117),
      secondaryContainer: Color(0xFF3B2B20),
      onSecondaryContainer: Color(0xFFE5D3C6),
      tertiary: Color(0xFFD2B57E),
      onTertiary: Color(0xFF322400),
      tertiaryContainer: Color(0xFF3F3109),
      onTertiaryContainer: Color(0xFFEDDCB3),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFE5D8DF),
      onSurfaceVariant: Color(0xFFC0B0BA),
      surfaceContainerLowest: Color(0xFF000000),
      surfaceContainerLow: Color(0xFF0D090C),
      surfaceContainer: Color(0xFF141014),
      surfaceContainerHigh: Color(0xFF1A151A),
      surfaceContainerHighest: Color(0xFF221C21),
      outline: Color(0xFF7F6D78),
      outlineVariant: Color(0xFF3A3036),
      error: Color(0xFFE0A59C),
      onError: Color(0xFF3E110D),
      errorContainer: Color(0xFF4F1A16),
      onErrorContainer: Color(0xFFF1D0CB),
    ),
  );

  // ---------------------------------------------------------------------------
  // 山丹丹红 · Shandan Red
  // ---------------------------------------------------------------------------
  /// 山丹丹红。
  static const AppPalette shandanRed = AppPalette(
    id: AppPaletteId.shandanRed,
    label: '山丹丹红',
    summary: '丹砂与黄土，最热烈的一抹陕北',
    light: AppPaletteColors(
      brightness: Brightness.light,
      oled: false,
      primary: Color(0xFFA8401F),
      onPrimary: Color(0xFFFFF8F5),
      primaryContainer: Color(0xFFF8D9C9),
      onPrimaryContainer: Color(0xFF3B1002),
      secondary: Color(0xFF8A5A32),
      onSecondary: Color(0xFFFFF8F2),
      secondaryContainer: Color(0xFFF1DFC9),
      onSecondaryContainer: Color(0xFF2D1D0A),
      tertiary: Color(0xFF7A5A20),
      onTertiary: Color(0xFFFFF8EC),
      tertiaryContainer: Color(0xFFF3E1B8),
      onTertiaryContainer: Color(0xFF281D00),
      surface: Color(0xFFFDF5F0),
      onSurface: Color(0xFF241512),
      onSurfaceVariant: Color(0xFF5D453D),
      surfaceContainerLowest: Color(0xFFFFFCFA),
      surfaceContainerLow: Color(0xFFF9EEE8),
      surfaceContainer: Color(0xFFF4E9E2),
      surfaceContainerHigh: Color(0xFFEFE2DA),
      surfaceContainerHighest: Color(0xFFE9DBD2),
      outline: Color(0xFF8C7067),
      outlineVariant: Color(0xFFDFC9C0),
      error: Color(0xFFA02435),
      onError: Color(0xFFFFF7F7),
      errorContainer: Color(0xFFFAD9DC),
      onErrorContainer: Color(0xFF3D060C),
    ),
    dark: AppPaletteColors(
      brightness: Brightness.dark,
      oled: false,
      primary: Color(0xFFFFB59B),
      onPrimary: Color(0xFF5A1D08),
      primaryContainer: Color(0xFF7B3219),
      onPrimaryContainer: Color(0xFFFFDBCC),
      secondary: Color(0xFFE0BE9C),
      onSecondary: Color(0xFF402D18),
      secondaryContainer: Color(0xFF574028),
      onSecondaryContainer: Color(0xFFF5DFC7),
      tertiary: Color(0xFFE5C77F),
      onTertiary: Color(0xFF422F00),
      tertiaryContainer: Color(0xFF5C460F),
      onTertiaryContainer: Color(0xFFF8E3B5),
      surface: Color(0xFF1C1210),
      onSurface: Color(0xFFF2DED8),
      onSurfaceVariant: Color(0xFFD0B9B1),
      surfaceContainerLowest: Color(0xFF120C0A),
      surfaceContainerLow: Color(0xFF211613),
      surfaceContainer: Color(0xFF271B18),
      surfaceContainerHigh: Color(0xFF2E211D),
      surfaceContainerHighest: Color(0xFF362823),
      outline: Color(0xFF9D847B),
      outlineVariant: Color(0xFF4F423C),
      error: Color(0xFFFFB3B8),
      onError: Color(0xFF5E1120),
      errorContainer: Color(0xFF7C2433),
      onErrorContainer: Color(0xFFFFD9DD),
    ),
    darkOled: AppPaletteColors(
      brightness: Brightness.dark,
      oled: true,
      primary: Color(0xFFE8A992),
      onPrimary: Color(0xFF441505),
      primaryContainer: Color(0xFF52210F),
      onPrimaryContainer: Color(0xFFF3D2C2),
      secondary: Color(0xFFCFAF8E),
      onSecondary: Color(0xFF33230F),
      secondaryContainer: Color(0xFF3F2E18),
      onSecondaryContainer: Color(0xFFE9D4BC),
      tertiary: Color(0xFFD4B872),
      onTertiary: Color(0xFF352500),
      tertiaryContainer: Color(0xFF453407),
      onTertiaryContainer: Color(0xFFEEDCAC),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFE8D5CF),
      onSurfaceVariant: Color(0xFFC4ADA5),
      surfaceContainerLowest: Color(0xFF000000),
      surfaceContainerLow: Color(0xFF0E0908),
      surfaceContainer: Color(0xFF150F0D),
      surfaceContainerHigh: Color(0xFF1B1411),
      surfaceContainerHighest: Color(0xFF231A16),
      outline: Color(0xFF81685F),
      outlineVariant: Color(0xFF3B302B),
      error: Color(0xFFE7A5AB),
      onError: Color(0xFF420D17),
      errorContainer: Color(0xFF531B24),
      onErrorContainer: Color(0xFFF3D0D4),
    ),
  );
}
