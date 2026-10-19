import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 底部导航目的地（书架 / 书库 / 纪年 / 设置）。
///
/// 枚举顺序即索引顺序，[AppShell] 的 NavigationBar / NavigationRail 与
/// 各页面的跳转请求共用这一份定义。
enum AppTab {
  /// 书架：看与听。
  shelf,

  /// 书库：内容来源与扫描。
  library,

  /// 纪年：收听统计与足迹（占位）。
  chronicle,

  /// 设置：外观与关于。
  settings,
}

/// 外壳当前选中的目的地。
///
/// 放在 shell 级 provider 里而不是外壳私有 State：书架空态等页面可以
/// 直接请求切换 tab（例如「去书库添加目录」），外壳只负责渲染。
class AppTabController extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.shelf;

  /// 切到指定目的地。
  void select(AppTab tab) {
    state = tab;
  }
}

/// 外壳选中态。
final NotifierProvider<AppTabController, AppTab> appTabProvider =
    NotifierProvider<AppTabController, AppTab>(AppTabController.new);
