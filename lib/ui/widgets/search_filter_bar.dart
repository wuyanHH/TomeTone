import 'package:flutter/material.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 独立通用搜索筛选一体化组件。
///
/// 包含单行胶囊搜索框、清空按钮、筛选触发按钮（带激活数量角标），
/// 以及点击平滑展开的折叠卡片容器（基于 [AnimatedSize]）。
class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = '搜索...',
    this.onQueryChanged,
    this.activeFilterCount = 0,
    this.filterPanelBuilder,
    this.initiallyExpanded = false,
    this.onExpandChanged,
    this.margin,
    this.padding,
  });

  /// 搜索输入控制器。
  final TextEditingController controller;

  /// 输入框焦点节点。
  final FocusNode? focusNode;

  /// 输入框占位提示文案。
  final String hintText;

  /// 搜索词变动回调。
  final ValueChanged<String>? onQueryChanged;

  /// 当前激活的筛选条件数量。大于 0 时在筛选按钮上高亮显示徽标。
  final int activeFilterCount;

  /// 展开卡片内容构建器。
  final WidgetBuilder? filterPanelBuilder;

  /// 初始状态下筛选面板是否展开。
  final bool initiallyExpanded;

  /// 展开/收起状态变动回调。
  final ValueChanged<bool>? onExpandChanged;

  /// 外边距。
  final EdgeInsetsGeometry? margin;

  /// 输入条内部边距。
  final EdgeInsetsGeometry? padding;

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant SearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
    widget.onExpandChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool hasQuery = widget.controller.text.isNotEmpty;
    final bool isFilterActive = widget.activeFilterCount > 0;

    final Color filterBtnColor = (_expanded || isFilterActive)
        ? scheme.primaryContainer.withValues(alpha: 0.6)
        : Colors.transparent;
    final Color filterTextColor = (_expanded || isFilterActive)
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // 主输入行：胶囊圆角，左搜索，中输入与清除，右弱分割线与筛选按钮
          Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: AppRadii.pill,
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: <Widget>[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    onChanged: widget.onQueryChanged,
                    textInputAction: TextInputAction.search,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: widget.hintText,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                if (hasQuery)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: '清除搜索',
                    splashRadius: 18,
                    onPressed: () {
                      widget.controller.clear();
                      widget.onQueryChanged?.call('');
                    },
                  ),
                Container(
                  width: 1,
                  height: 18,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  color: scheme.outlineVariant.withValues(alpha: 0.5),
                ),
                Material(
                  color: filterBtnColor,
                  borderRadius: AppRadii.pill,
                  child: InkWell(
                    borderRadius: AppRadii.pill,
                    onTap: _toggleExpanded,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs + 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.filter_alt_outlined,
                            size: 18,
                            color: filterTextColor,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            '筛选',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: filterTextColor,
                              fontWeight: (_expanded || isFilterActive)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          if (isFilterActive) ...<Widget>[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary,
                                borderRadius: AppRadii.pill,
                              ),
                              child: Text(
                                '${widget.activeFilterCount}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
          ),

          // 折叠卡片面板
          AnimatedSize(
            duration: AppMotion.resolve(context, AppDurations.standard),
            curve: AppDurations.standardCurve,
            alignment: Alignment.topCenter,
            child: (_expanded && widget.filterPanelBuilder != null)
                ? Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLow,
                      borderRadius: AppRadii.lg,
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    ),
                    child: widget.filterPanelBuilder!(context),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// 结构化筛选分组容器，提供标题、可选操作及子项排布。
class SearchFilterGroup extends StatelessWidget {
  const SearchFilterGroup({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
  });

  /// 便捷构造：自动将 [children] 以 [Wrap] 排布。
  SearchFilterGroup.wrap({
    super.key,
    required this.title,
    this.trailing,
    required List<Widget> children,
    double spacing = AppSpacing.sm,
    double runSpacing = AppSpacing.xs,
    this.padding = const EdgeInsets.only(bottom: AppSpacing.sm),
  })  : child = Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children,
        );

  /// 分组标题。
  final String title;

  /// 标题右侧扩展组件（如“重置”、“管理”）。
  final Widget? trailing;

  /// 分组内容组件。
  final Widget child;

  /// 分组外边距。
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (trailing != null) ...<Widget>[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

/// 样式统一的胶囊筛选按钮，符合宣纸/夜色主题的选中高亮胶囊。
class SearchFilterChip extends StatelessWidget {
  const SearchFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onSelected,
    this.onTap,
    this.icon,
    this.count,
    this.tooltip,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.xs,
    ),
  });

  /// 标签文案。
  final String label;

  /// 是否选中。
  final bool selected;

  /// 选中变动回调。
  final ValueChanged<bool>? onSelected;

  /// 点击回调。
  final VoidCallback? onTap;

  /// 可选前缀图标。
  final IconData? icon;

  /// 可选命中计数。
  final int? count;

  /// 无障碍与长按提示文案。
  final String? tooltip;

  /// 内部边距。
  final EdgeInsetsGeometry padding;

  void _handleTap() {
    onSelected?.call(!selected);
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    final Color backgroundColor = selected
        ? scheme.secondaryContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.35);

    final Color contentColor = selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;

    final Color countBgColor = selected
        ? scheme.onSecondaryContainer.withValues(alpha: 0.15)
        : scheme.surfaceContainerHighest;

    final Border border = Border.all(
      color: selected
          ? scheme.primary.withValues(alpha: 0.25)
          : scheme.outlineVariant.withValues(alpha: 0.35),
    );

    Widget chipContent = Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.pill,
        side: border.top,
      ),
      child: InkWell(
        borderRadius: AppRadii.pill,
        onTap: _handleTap,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 15, color: contentColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: contentColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (count != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: countBgColor,
                    borderRadius: AppRadii.pill,
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: contentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      chipContent = Tooltip(
        message: tooltip,
        child: chipContent,
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: tooltip ?? label,
      child: chipContent,
    );
  }
}
