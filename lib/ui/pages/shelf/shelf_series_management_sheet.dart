import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书架系列管理弹层的测试稳定键。
abstract final class ShelfSeriesManagementKeys {
  static const Key sheet = Key('shelf-series-management-sheet');
  static const Key navModeSegmentedButton =
      Key('shelf-series-nav-mode-segmented-button');
  static const Key showAllSwitch = Key('shelf-series-show-all-switch');
  static const Key showUncategorizedSwitch =
      Key('shelf-series-show-uncategorized-switch');
  static const Key seriesList = Key('shelf-series-reorderable-list');

  static Key seriesItem(String series) =>
      ValueKey<String>('shelf-series-item-$series');
  static Key seriesVisibilityToggle(String series) =>
      ValueKey<String>('shelf-series-visibility-$series');
  static Key seriesDragHandle(String series) =>
      ValueKey<String>('shelf-series-drag-$series');
}

/// 书架系列管理抽屉组件。
///
/// 允许用户配置：
/// 1. 系列导航模式（Tab 栏 / 下拉选择框）；
/// 2. 基础标签（全部 / 未分类）的显隐；
/// 3. 自定义系列的自定义顺序（拖拽排序）与显隐状态；
/// 4. 防空限制：保证至少保留一个可见系列标签。
class ShelfSeriesManagementSheet extends ConsumerWidget {
  const ShelfSeriesManagementSheet({
    super.key,
    required this.allAvailableSeries,
  });

  /// 当前书架中所有可用的系列名称列表。
  final List<String> allAvailableSeries;

  /// 提示文案常量。
  static const String minVisibleWarning = '至少保留一个可见系列';

  /// 呼出系列管理底部抽屉。
  static Future<void> show(
    BuildContext context, {
    required List<String> allAvailableSeries,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadii.sheet,
      ),
      builder: (BuildContext sheetContext) {
        return ShelfSeriesManagementSheet(
          allAvailableSeries: allAvailableSeries,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppPreferences prefs = ref.watch(preferencesProvider);

    final List<String> orderedSeries = _computeOrderedSeries(
      allAvailableSeries,
      prefs.shelfSeriesOrder,
    );

    final int visibleCount = _calculateVisibleCount(
      showAll: prefs.shelfShowAllSeriesTab,
      showUncategorized: prefs.shelfShowUncategorizedSeriesTab,
      allAvailableSeries: allAvailableSeries,
      hiddenSeries: prefs.shelfHiddenSeries,
    );

    final bool isShowAllLastVisible =
        prefs.shelfShowAllSeriesTab && visibleCount <= 1;
    final bool isShowUncategorizedLastVisible =
        prefs.shelfShowUncategorizedSeriesTab && visibleCount <= 1;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Column(
          key: ShelfSeriesManagementKeys.sheet,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // 顶部拖拽把手
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: AppRadii.pill,
                ),
              ),
            ),

            // 标题栏
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '管理系列',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 模式切换
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '导航模式',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ShelfSeriesNavMode>(
                      key: ShelfSeriesManagementKeys.navModeSegmentedButton,
                      segments: const <ButtonSegment<ShelfSeriesNavMode>>[
                        ButtonSegment<ShelfSeriesNavMode>(
                          value: ShelfSeriesNavMode.tabs,
                          label: Text('Tab 栏'),
                          icon: Icon(Icons.tab_rounded),
                        ),
                        ButtonSegment<ShelfSeriesNavMode>(
                          value: ShelfSeriesNavMode.dropdown,
                          label: Text('下拉选择框'),
                          icon: Icon(Icons.arrow_drop_down_circle_outlined),
                        ),
                      ],
                      selected: <ShelfSeriesNavMode>{prefs.shelfSeriesNavMode},
                      onSelectionChanged: (Set<ShelfSeriesNavMode> selected) {
                        if (selected.isNotEmpty) {
                          ref.read(preferencesProvider.notifier).replace(
                                prefs.copyWith(
                                  shelfSeriesNavMode: selected.first,
                                ),
                              );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // 基础分类开关
            SwitchListTile(
              key: ShelfSeriesManagementKeys.showAllSwitch,
              title: const Text('显示全部'),
              subtitle: const Text('在导航栏首位展示全量藏书'),
              value: prefs.shelfShowAllSeriesTab,
              onChanged: (bool value) {
                if (!value && isShowAllLastVisible) {
                  _showMinVisibleWarning(context);
                  return;
                }
                ref.read(preferencesProvider.notifier).replace(
                      prefs.copyWith(shelfShowAllSeriesTab: value),
                    );
              },
            ),
            SwitchListTile(
              key: ShelfSeriesManagementKeys.showUncategorizedSwitch,
              title: const Text('显示未分类'),
              subtitle: const Text('展示未归入任何系列的书籍'),
              value: prefs.shelfShowUncategorizedSeriesTab,
              onChanged: (bool value) {
                if (!value && isShowUncategorizedLastVisible) {
                  _showMinVisibleWarning(context);
                  return;
                }
                ref.read(preferencesProvider.notifier).replace(
                      prefs.copyWith(shelfShowUncategorizedSeriesTab: value),
                    );
              },
            ),

            const Divider(height: 1),

            // 系列列表标题
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '系列排序与显隐',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '拖拽排序 · 点击眼睛切换显隐',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // 系列排序列表或空态提示
            if (orderedSeries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text(
                    '暂无自定义系列',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ReorderableListView.builder(
                  key: ShelfSeriesManagementKeys.seriesList,
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: orderedSeries.length,
                  onReorderItem: (int oldIndex, int newIndex) {
                    _onReorder(
                      ref: ref,
                      prefs: prefs,
                      currentOrdered: orderedSeries,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    );
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final String series = orderedSeries[index];
                    final bool isHidden =
                        prefs.shelfHiddenSeries.contains(series);
                    final bool isLastVisible = !isHidden && visibleCount <= 1;

                    return ListTile(
                      key: ShelfSeriesManagementKeys.seriesItem(series),
                      leading: Icon(
                        Icons.collections_bookmark_outlined,
                        color: isHidden ? scheme.outline : scheme.primary,
                      ),
                      title: Text(
                        series,
                        style: TextStyle(
                          color: isHidden ? scheme.outline : scheme.onSurface,
                          decoration:
                              isHidden ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            key: ShelfSeriesManagementKeys.seriesVisibilityToggle(
                              series,
                            ),
                            icon: Icon(
                              isHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: isHidden
                                  ? scheme.outline
                                  : scheme.onSurfaceVariant,
                            ),
                            tooltip: isHidden ? '显示系列' : '隐藏系列',
                            onPressed: () {
                              _onToggleVisibility(
                                context: context,
                                ref: ref,
                                prefs: prefs,
                                series: series,
                                isCurrentlyHidden: isHidden,
                                isLastVisible: isLastVisible,
                              );
                            },
                          ),
                          ReorderableDragStartListener(
                            key: ShelfSeriesManagementKeys.seriesDragHandle(
                              series,
                            ),
                            index: index,
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.xs),
                              child: Icon(
                                Icons.drag_handle,
                                color: scheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMinVisibleWarning(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(minVisibleWarning),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onToggleVisibility({
    required BuildContext context,
    required WidgetRef ref,
    required AppPreferences prefs,
    required String series,
    required bool isCurrentlyHidden,
    required bool isLastVisible,
  }) {
    if (!isCurrentlyHidden && isLastVisible) {
      _showMinVisibleWarning(context);
      return;
    }

    final List<String> updatedHidden = List<String>.from(
      prefs.shelfHiddenSeries,
    );
    if (isCurrentlyHidden) {
      updatedHidden.remove(series);
    } else {
      updatedHidden.add(series);
    }

    ref.read(preferencesProvider.notifier).replace(
          prefs.copyWith(shelfHiddenSeries: updatedHidden),
        );
  }

  void _onReorder({
    required WidgetRef ref,
    required AppPreferences prefs,
    required List<String> currentOrdered,
    required int oldIndex,
    required int newIndex,
  }) {
    final List<String> updated = List<String>.from(currentOrdered);
    final String item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    ref.read(preferencesProvider.notifier).replace(
          prefs.copyWith(shelfSeriesOrder: updated),
        );
  }

  List<String> _computeOrderedSeries(
    List<String> allAvailable,
    List<String> savedOrder,
  ) {
    final List<String> result = <String>[];
    final Set<String> availableSet = allAvailable.toSet();

    for (final String s in savedOrder) {
      if (availableSet.contains(s) && !result.contains(s)) {
        result.add(s);
      }
    }
    for (final String s in allAvailable) {
      if (!result.contains(s)) {
        result.add(s);
      }
    }
    return result;
  }

  int _calculateVisibleCount({
    required bool showAll,
    required bool showUncategorized,
    required List<String> allAvailableSeries,
    required List<String> hiddenSeries,
  }) {
    int count = 0;
    if (showAll) {
      count++;
    }
    if (showUncategorized) {
      count++;
    }
    final Set<String> hiddenSet = hiddenSeries.toSet();
    for (final String series in allAvailableSeries) {
      if (!hiddenSet.contains(series)) {
        count++;
      }
    }
    return count;
  }
}
