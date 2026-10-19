import 'package:flutter/widgets.dart';

/// 间距 token：4dp 基准的八点栅格，页面只从这里取间距。
abstract final class AppSpacing {
  /// 2dp：发丝级微调。
  static const double xxs = 2;

  /// 4dp。
  static const double xs = 4;

  /// 8dp。
  static const double sm = 8;

  /// 12dp。
  static const double md = 12;

  /// 16dp：默认页面边距。
  static const double lg = 16;

  /// 24dp：区块之间。
  static const double xl = 24;

  /// 32dp：大区块之间。
  static const double xxl = 32;

  /// 48dp：空态/占位页留白。
  static const double xxxl = 48;

  /// 页面左右边距（手机）。
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg);

  /// 列表项内边距。
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
}

/// 圆角 token。
abstract final class AppRadii {
  /// 6dp：标签、小徽标。
  static const double xsValue = 6;

  /// 10dp。
  static const double smValue = 10;

  /// 14dp：输入框、列表卡片。
  static const double mdValue = 14;

  /// 20dp：卡片、封面。
  static const double lgValue = 20;

  /// 28dp：底部抽屉、大面板。
  static const double xlValue = 28;

  /// 胶囊。
  static const double pillValue = 999;

  /// 6dp 圆角。
  static const BorderRadius xs = BorderRadius.all(Radius.circular(xsValue));

  /// 10dp 圆角。
  static const BorderRadius sm = BorderRadius.all(Radius.circular(smValue));

  /// 14dp 圆角。
  static const BorderRadius md = BorderRadius.all(Radius.circular(mdValue));

  /// 20dp 圆角。
  static const BorderRadius lg = BorderRadius.all(Radius.circular(lgValue));

  /// 28dp 圆角。
  static const BorderRadius xl = BorderRadius.all(Radius.circular(xlValue));

  /// 胶囊圆角。
  static const BorderRadius pill = BorderRadius.all(Radius.circular(pillValue));

  /// 书籍封面默认圆角（比卡片略小，多封面并排时更整齐）。
  static const BorderRadius cover = BorderRadius.all(Radius.circular(14));

  /// 底部抽屉只圆上沿。
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xlValue),
  );

  /// MiniPlayer 圆角。
  static const BorderRadius miniPlayer = BorderRadius.all(
    Radius.circular(mdValue),
  );
}

/// 尺寸 token。
abstract final class AppSizes {
  /// 关键触控目标下限（《架构需求文档》§3.4，48dp）。
  static const double minTouchTarget = 48;

  /// 底部导航栏（NavigationBar）高度。
  static const double navigationBarHeight = 72;

  /// 平板 / 桌面 NavigationRail 宽度。
  static const double navigationRailWidth = 88;

  /// MiniPlayer 槽位参考高度（真实播放器接入后以其自身高度为准）。
  static const double miniPlayerHeight = 64;

  /// 手机 / 平板的断点（§3.1）。
  static const double wideBreakpoint = 600;

  /// 正文可读宽度上限：超过后不再拉长行宽。
  static const double readingMaxWidth = 560;

  /// 占位页文案宽度上限。
  static const double placeholderMaxWidth = 380;

  /// 小封面（列表行内）。
  static const double coverSmall = 48;

  /// 中封面（MiniPlayer）。
  static const double coverMedium = 56;

  /// 大封面（网格）。
  static const double coverLarge = 132;
}

/// 字体族 token。
///
/// 不引入字体资源（离线优先、包体克制），只声明系统衬线族与中文回退链：
/// 标题走宋体一族，正文走系统无衬线。
abstract final class AppTypefaces {
  /// 衬线字体族。
  static const String serifFamily = 'serif';

  /// 中文衬线回退链（Android / iOS / 桌面常见字体名）。
  static const List<String> serifFallback = <String>[
    'Noto Serif CJK SC',
    'Source Han Serif SC',
    'Noto Serif SC',
    'Songti SC',
    'SimSun',
  ];
}

/// 动效时长 token（§3.2：克制，只保留必要过渡）。
abstract final class AppDurations {
  /// 150ms：颜色、状态切换。
  static const Duration fast = Duration(milliseconds: 150);

  /// 200ms：页面内过渡的默认值。
  static const Duration standard = Duration(milliseconds: 200);

  /// 250ms：强调性过渡（MiniPlayer → 播放台）。
  static const Duration emphasized = Duration(milliseconds: 250);

  /// 300ms：Material 3 Container Transform 展开播放台。
  static const Duration containerTransform = Duration(milliseconds: 300);

  /// 标准缓动。
  static const Curve standardCurve = Curves.easeOutCubic;

  /// 离场缓动（比入场略快，避免拖沓）。
  static const Curve exitCurve = Curves.easeInCubic;

  /// 强调缓动。
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;
}

/// 动效偏好：跟随系统"减弱动效"（§3.4）。
abstract final class AppMotion {
  /// 系统是否要求减弱动效。
  static bool reduced(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// 按系统偏好解析时长：减弱动效时返回 [Duration.zero]。
  static Duration resolve(BuildContext context, Duration duration) {
    return reduced(context) ? Duration.zero : duration;
  }
}
