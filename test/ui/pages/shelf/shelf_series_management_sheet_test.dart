import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/ui/pages/shelf/shelf_series_management_sheet.dart';

void main() {
  Widget buildTestWidget({
    required AppPreferences initialPreferences,
    required List<String> allAvailableSeries,
    void Function(ProviderContainer container)? onContainerCreated,
    bool openViaShow = false,
  }) {
    final store = InMemoryAppPreferencesStore(initialPreferences);
    final container = ProviderContainer(
      overrides: [
        preferencesStoreProvider.overrideWithValue(store),
        initialPreferencesProvider.overrideWithValue(initialPreferences),
      ],
    );
    if (onContainerCreated != null) {
      onContainerCreated(container);
    }

    if (openViaShow) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      ShelfSeriesManagementSheet.show(
                        context,
                        allAvailableSeries: allAvailableSeries,
                      );
                    },
                    child: const Text('打开系列管理'),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: ShelfSeriesManagementSheet(
            allAvailableSeries: allAvailableSeries,
          ),
        ),
      ),
    );
  }

  group('ShelfSeriesManagementSheet', () {
    testWidgets('1. 模式切换：通过 SegmentedButton 切换 Tab 栏与下拉选择框模式，并通知更新 AppPreferences', (WidgetTester tester) async {
      ProviderContainer? testContainer;
      const initialPrefs = AppPreferences(
        shelfSeriesNavMode: ShelfSeriesNavMode.tabs,
      );

      await tester.pumpWidget(
        buildTestWidget(
          initialPreferences: initialPrefs,
          allAvailableSeries: const ['凡人修仙', '遮天'],
          onContainerCreated: (c) => testContainer = c,
        ),
      );
      await tester.pumpAndSettle();

      // 验证初始状态为 tabs
      expect(find.byType(SegmentedButton<ShelfSeriesNavMode>), findsOneWidget);
      expect(testContainer!.read(preferencesProvider).shelfSeriesNavMode, ShelfSeriesNavMode.tabs);

      // 切换到下拉选择框
      await tester.tap(find.text('下拉选择框'));
      await tester.pumpAndSettle();

      expect(testContainer!.read(preferencesProvider).shelfSeriesNavMode, ShelfSeriesNavMode.dropdown);

      // 切换回 Tab 栏
      await tester.tap(find.text('Tab 栏'));
      await tester.pumpAndSettle();

      expect(testContainer!.read(preferencesProvider).shelfSeriesNavMode, ShelfSeriesNavMode.tabs);
    });

    testWidgets('2. 基础开关：切换「显示全部」与「显示未分类」', (WidgetTester tester) async {
      ProviderContainer? testContainer;
      const initialPrefs = AppPreferences(
        shelfShowAllSeriesTab: true,
        shelfShowUncategorizedSeriesTab: true,
      );

      await tester.pumpWidget(
        buildTestWidget(
          initialPreferences: initialPrefs,
          allAvailableSeries: const ['凡人修仙', '遮天'],
          onContainerCreated: (c) => testContainer = c,
        ),
      );
      await tester.pumpAndSettle();

      // 验证找到两个 SwitchListTile
      final showAllSwitch = find.byKey(ShelfSeriesManagementKeys.showAllSwitch);
      final showUncategorizedSwitch = find.byKey(ShelfSeriesManagementKeys.showUncategorizedSwitch);
      expect(showAllSwitch, findsOneWidget);
      expect(showUncategorizedSwitch, findsOneWidget);

      // 切换「显示未分类」为关闭
      await tester.tap(showUncategorizedSwitch);
      await tester.pumpAndSettle();
      expect(testContainer!.read(preferencesProvider).shelfShowUncategorizedSeriesTab, isFalse);

      // 再次切换「显示未分类」为开启
      await tester.tap(showUncategorizedSwitch);
      await tester.pumpAndSettle();
      expect(testContainer!.read(preferencesProvider).shelfShowUncategorizedSeriesTab, isTrue);

      // 切换「显示全部」为关闭
      await tester.tap(showAllSwitch);
      await tester.pumpAndSettle();
      expect(testContainer!.read(preferencesProvider).shelfShowAllSeriesTab, isFalse);
    });

    testWidgets('3. 列表拖拽与显隐：在 ReorderableListView 中调整顺序与点击眼睛切换显隐', (WidgetTester tester) async {
      ProviderContainer? testContainer;
      const initialPrefs = AppPreferences(
        shelfSeriesOrder: ['凡人修仙', '遮天', '完美世界'],
        shelfHiddenSeries: [],
      );

      await tester.pumpWidget(
        buildTestWidget(
          initialPreferences: initialPrefs,
          allAvailableSeries: const ['凡人修仙', '遮天', '完美世界'],
          onContainerCreated: (c) => testContainer = c,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReorderableListView), findsOneWidget);
      expect(find.text('凡人修仙'), findsOneWidget);
      expect(find.text('遮天'), findsOneWidget);
      expect(find.text('完美世界'), findsOneWidget);

      // 1) 点击「遮天」的眼睛图标进行隐藏
      final eyeZhetian = find.byKey(ShelfSeriesManagementKeys.seriesVisibilityToggle('遮天'));
      expect(eyeZhetian, findsOneWidget);
      await tester.tap(eyeZhetian);
      await tester.pumpAndSettle();

      expect(testContainer!.read(preferencesProvider).shelfHiddenSeries, contains('遮天'));

      // 2) 再次点击「遮天」的眼睛图标解除隐藏
      await tester.tap(eyeZhetian);
      await tester.pumpAndSettle();

      expect(testContainer!.read(preferencesProvider).shelfHiddenSeries, isNot(contains('遮天')));

      // 3) 拖拽调整顺序：将「凡人修仙」拖到下方
      final dragHandle = find.byKey(ShelfSeriesManagementKeys.seriesDragHandle('凡人修仙'));
      expect(dragHandle, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(dragHandle));
      await tester.pump();
      // 向下拖动 150 像素（跨过「遮天」和「完美世界」）
      await gesture.moveBy(const Offset(0, 150));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // 验证顺序变更已持久化到 AppPreferences
      final newOrder = testContainer!.read(preferencesProvider).shelfSeriesOrder;
      expect(newOrder.first, isNot(equals('凡人修仙')));
    });

    testWidgets('4. 防空限制：当仅剩最后一个可见项时，禁用隐藏操作并给出提示', (WidgetTester tester) async {
      ProviderContainer? testContainer;
      // 仅剩「全部」可见：showAll = true, showUncategorized = false, 唯一系列「凡人修仙」被隐藏
      const initialPrefs = AppPreferences(
        shelfShowAllSeriesTab: true,
        shelfShowUncategorizedSeriesTab: false,
        shelfHiddenSeries: ['凡人修仙'],
      );

      await tester.pumpWidget(
        buildTestWidget(
          initialPreferences: initialPrefs,
          allAvailableSeries: const ['凡人修仙'],
          onContainerCreated: (c) => testContainer = c,
        ),
      );
      await tester.pumpAndSettle();

      // 尝试关闭最后一个可见项「全部」
      final showAllSwitch = find.byKey(ShelfSeriesManagementKeys.showAllSwitch);
      await tester.tap(showAllSwitch);
      await tester.pumpAndSettle();

      // 验证操作被拦截，配置未被修改，仍然为 true
      expect(testContainer!.read(preferencesProvider).shelfShowAllSeriesTab, isTrue);
      // 验证弹出提示
      expect(find.text('至少保留一个可见系列'), findsOneWidget);

      // 现在测试系列眼睛图标的防空限制：
      // showAll = false, showUncategorized = false, 仅剩「凡人修仙」是可见的
      testContainer!.read(preferencesProvider.notifier).replace(
        const AppPreferences(
          shelfShowAllSeriesTab: false,
          shelfShowUncategorizedSeriesTab: false,
          shelfHiddenSeries: [],
        ),
      );
      await tester.pumpAndSettle();

      // 尝试点击「凡人修仙」眼睛图标隐藏它
      final eyeFanren = find.byKey(ShelfSeriesManagementKeys.seriesVisibilityToggle('凡人修仙'));
      await tester.tap(eyeFanren);
      await tester.pumpAndSettle();

      // 验证操作被拦截，凡人修仙未被隐藏
      expect(testContainer!.read(preferencesProvider).shelfHiddenSeries, isEmpty);
      expect(find.text('至少保留一个可见系列'), findsOneWidget);
    });

    testWidgets('5. 静态 show 方法能正常呼出 BottomSheet', (WidgetTester tester) async {
      const initialPrefs = AppPreferences.defaults;

      await tester.pumpWidget(
        buildTestWidget(
          initialPreferences: initialPrefs,
          allAvailableSeries: const ['凡人修仙'],
          openViaShow: true,
        ),
      );
      await tester.pumpAndSettle();

      // 点击按钮呼出抽屉
      await tester.tap(find.text('打开系列管理'));
      await tester.pumpAndSettle();

      // 抽屉展示
      expect(find.text('管理系列'), findsOneWidget);
      expect(find.text('凡人修仙'), findsOneWidget);

      // 点击关闭按钮关闭抽屉
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('管理系列'), findsNothing);
    });

    testWidgets('6. 当无自定义系列时（allAvailableSeries 为空），展示暂无自定义系列空态提示，且基础开关防空依然生效', (WidgetTester tester) async {
      ProviderContainer? testContainer;
      const initialPrefs = AppPreferences(
        shelfShowAllSeriesTab: true,
        shelfShowUncategorizedSeriesTab: false,
      );

      await tester.pumpWidget(
        buildTestWidget(
          initialPreferences: initialPrefs,
          allAvailableSeries: const [],
          onContainerCreated: (c) => testContainer = c,
        ),
      );
      await tester.pumpAndSettle();

      // 展示空态
      expect(find.text('暂无自定义系列'), findsOneWidget);
      expect(find.byType(ReorderableListView), findsNothing);

      // 仅剩「全部」可见，尝试关闭
      final showAllSwitch = find.byKey(ShelfSeriesManagementKeys.showAllSwitch);
      await tester.tap(showAllSwitch);
      await tester.pumpAndSettle();

      // 防空拦截
      expect(testContainer!.read(preferencesProvider).shelfShowAllSeriesTab, isTrue);
      expect(find.text('至少保留一个可见系列'), findsOneWidget);

      // 开启「未分类」
      final showUncategorizedSwitch = find.byKey(ShelfSeriesManagementKeys.showUncategorizedSwitch);
      await tester.tap(showUncategorizedSwitch);
      await tester.pumpAndSettle();
      expect(testContainer!.read(preferencesProvider).shelfShowUncategorizedSeriesTab, isTrue);

      // 此时有两个可见项，关闭「全部」成功
      await tester.tap(showAllSwitch);
      await tester.pumpAndSettle();
      expect(testContainer!.read(preferencesProvider).shelfShowAllSeriesTab, isFalse);
    });

    testWidgets('7. 历史排序包含已不存在的系列时，能够正确过滤并追加新系列', (WidgetTester tester) async {
      const initialPrefs = AppPreferences(
        shelfSeriesOrder: ['已删除系列', '遮天'],
      );

      await tester.pumpWidget(
        buildTestWidget(
          initialPreferences: initialPrefs,
          allAvailableSeries: const ['凡人修仙', '遮天'],
        ),
      );
      await tester.pumpAndSettle();

      // '已删除系列' 不应该展示
      expect(find.text('已删除系列'), findsNothing);
      expect(find.text('遮天'), findsOneWidget);
      expect(find.text('凡人修仙'), findsOneWidget);
    });
  });
}
