import 'package:flutter/material.dart';
import 'package:tometone/ui/pages/shelf/shelf_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/mini_player.dart';

/// 应用外壳：底部 3 栏（书架 / 纪年 / 设置）+ 底部 MiniPlayer。
///
/// 形态规则（《架构需求文档》§3.1）：
/// - `< 600dp` 手机纵屏：单列内容 + 底部 [NavigationBar]；
/// - `>= 600dp` 平板 / 桌面：单列内容 + [NavigationRail]（双列网格留给后续步骤）。
///
/// MiniPlayer 默认就是真实的 [MiniPlayer]（没有当前章节时它自己渲染为
/// `SizedBox.shrink`，不占高度）；测试或特殊端形态可以注入一个替身。
/// 外壳本身仍不读取播放数据、不含播放策略 —— 展开播放台由 MiniPlayer 自己完成。
///
/// 书架已是真实页面；纪年 / 设置仍是占位内容，后续替换 [_tabs] 即可。
class AppShell extends StatefulWidget {
  /// 创建应用外壳。
  const AppShell({super.key, this.miniPlayer = const MiniPlayer()});

  /// 底部 MiniPlayer 槽位的内容。
  final Widget miniPlayer;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int index) {
    if (index == _index) {
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final bool wide =
        MediaQuery.sizeOf(context).width >= AppSizes.wideBreakpoint;
    final Duration swapDuration = AppMotion.resolve(
      context,
      AppDurations.standard,
    );
    final Widget content = _TabSwitcher(index: _index, duration: swapDuration);
    final Widget miniPlayer = widget.miniPlayer;

    if (wide) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: <Widget>[
              _ShellRail(selectedIndex: _index, onSelected: _select),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Expanded(child: content),
                    _MiniPlayerSlot(child: miniPlayer),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(bottom: false, child: content),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _MiniPlayerSlot(child: miniPlayer),
          _ShellBar(selectedIndex: _index, onSelected: _select),
        ],
      ),
    );
  }
}

/// tab 内容切换：仅一次 200ms 淡入淡出；系统"减弱动效"时立即切换。
class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.index, required this.duration});

  final int index;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppDurations.standardCurve,
      switchOutCurve: AppDurations.exitCurve,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[...previousChildren, ?currentChild],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(key: ValueKey<int>(index), child: _tabs[index]),
    );
  }
}

/// 三个 tab 的内容。真实页面替换这里即可（届时建议改用 IndexedStack 保留滚动位置）。
const List<Widget> _tabs = <Widget>[
  ShelfPage(),
  ChronicleTabPlaceholder(),
  SettingsTabPlaceholder(),
];

/// 外壳目的地定义。
class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.hint,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String hint;
}

const List<_ShellDestination> _destinations = <_ShellDestination>[
  _ShellDestination(
    label: '书架',
    icon: Icons.auto_stories_outlined,
    selectedIcon: Icons.auto_stories,
    hint: '书架：你的藏书',
  ),
  _ShellDestination(
    label: '纪年',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights,
    hint: '聆听纪年：收听统计与足迹',
  ),
  _ShellDestination(
    label: '设置',
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune,
    hint: '设置：外观、数据与关于',
  ),
];

/// 手机纵屏：底部 3 栏。
class _ShellBar extends StatelessWidget {
  const _ShellBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: <NavigationDestination>[
        for (final _ShellDestination destination in _destinations)
          NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
            tooltip: destination.hint,
          ),
      ],
    );
  }
}

/// 平板 / 桌面：左侧 NavigationRail。
class _ShellRail extends StatelessWidget {
  const _ShellRail({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelType: NavigationRailLabelType.all,
      minWidth: AppSizes.navigationRailWidth,
      destinations: <NavigationRailDestination>[
        for (final _ShellDestination destination in _destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: Text(destination.label),
          ),
      ],
    );
  }
}

/// MiniPlayer 槽位：只负责无障碍容器；留白由 MiniPlayer 自己控制，
/// 这样"没有当前章节"时槽位高度可以真正归零。
class _MiniPlayerSlot extends StatelessWidget {
  const _MiniPlayerSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(container: true, explicitChildNodes: true, child: child);
  }
}

/// 纪年 tab 占位（真实页面：今日/累计、365 天热力图、足迹时间流）。
class ChronicleTabPlaceholder extends StatelessWidget {
  /// 创建纪年占位。
  const ChronicleTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TabPlaceholder(
      eyebrow: '纪年 · CHRONICLE',
      title: '聆听纪年',
      description: '只计真实播放的 30 秒心跳：今天听了多久、这一年听过什么，都留在这里。',
      note: '占位 · 统计图表待接入',
      icon: Icons.insights_outlined,
    );
  }
}

/// 设置 tab 占位（真实页面：五套色盘、OLED、睡眠守夜、备份与关于）。
class SettingsTabPlaceholder extends StatelessWidget {
  /// 创建设置占位。
  const SettingsTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TabPlaceholder(
      eyebrow: '偏好 · PREFERENCES',
      title: '系统偏好',
      description: '五套国风色盘、暗夜 OLED、拔耳机防护与备份恢复，都收在这一页。',
      note: '占位 · 设置项待接入',
      icon: Icons.tune_outlined,
    );
  }
}

/// 占位页的统一版式：徽记 + 装饰线 + 眉题 + 标题 + 说明 + 状态胶囊。
class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.note,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String note;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.placeholderMaxWidth,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: AppRadii.xl,
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.6),
                          ),
                        ),
                        child: SizedBox.square(
                          dimension: 72,
                          child: Icon(
                            icon,
                            size: 32,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _Ornament(color: scheme.outlineVariant),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        eyebrow,
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: scheme.primary,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: text.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: AppRadii.pill,
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          child: Text(
                            note,
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 一条短装饰线：两端细线 + 中央菱形。
class _Ornament extends StatelessWidget {
  const _Ornament({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(width: 28, height: 1, color: color),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Transform.rotate(
            angle: 0.7853981634,
            child: Container(width: 5, height: 5, color: color),
          ),
        ),
        Container(width: 28, height: 1, color: color),
      ],
    );
  }
}
