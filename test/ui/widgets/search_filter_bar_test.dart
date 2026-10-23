import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/ui/widgets/search_filter_bar.dart';

void main() {
  group('SearchFilterBar', () {
    testWidgets('搜索框文字输入与清空按钮点击回调', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      String query = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterBar(
              controller: controller,
              hintText: '搜索书名或作者',
              onQueryChanged: (String val) => query = val,
            ),
          ),
        ),
      );

      expect(find.text('搜索书名或作者'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);

      // 输入文字
      await tester.enterText(find.byType(TextField), '凡人修仙');
      await tester.pump();

      expect(query, '凡人修仙');
      expect(controller.text, '凡人修仙');
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // 点击清空按钮
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(query, '');
      expect(controller.text, '');
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('筛选按钮根据 activeFilterCount 是否展示徽标角标及数字', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      int activeCount = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: <Widget>[
                    SearchFilterBar(
                      controller: controller,
                      activeFilterCount: activeCount,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => activeCount = 2),
                      child: const Text('设置角标为2'),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => activeCount = 0),
                      child: const Text('清除角标'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // activeFilterCount == 0 时，不显示角标数字
      expect(find.text('0'), findsNothing);
      expect(find.text('2'), findsNothing);

      // 更新 activeFilterCount 为 2
      await tester.tap(find.text('设置角标为2'));
      await tester.pump();

      expect(find.text('2'), findsOneWidget);

      // 清除角标
      await tester.tap(find.text('清除角标'));
      await tester.pump();

      expect(find.text('2'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('点击筛选按钮时平滑展开与收起折叠面板', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      bool? lastExpanded;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterBar(
              controller: controller,
              onExpandChanged: (bool val) => lastExpanded = val,
              filterPanelBuilder: (BuildContext context) {
                return const Text('折叠面板内容区');
              },
            ),
          ),
        ),
      );

      // 默认折叠，面板内容未渲染或高度为 0
      expect(find.text('折叠面板内容区'), findsNothing);

      // 点击筛选按钮展开
      await tester.tap(find.text('筛选'));
      await tester.pumpAndSettle();

      expect(lastExpanded, isTrue);
      expect(find.text('折叠面板内容区'), findsOneWidget);

      // 再次点击收起
      await tester.tap(find.text('筛选'));
      await tester.pumpAndSettle();

      expect(lastExpanded, isFalse);
      expect(find.text('折叠面板内容区'), findsNothing);
    });

    testWidgets('initiallyExpanded 为 true 时初始直接展开面板', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterBar(
              controller: controller,
              initiallyExpanded: true,
              filterPanelBuilder: (BuildContext context) {
                return const Text('预先展开的面板');
              },
            ),
          ),
        ),
      );

      expect(find.text('预先展开的面板'), findsOneWidget);
    });
  });

  group('SearchFilterGroup & SearchFilterChip', () {
    testWidgets('SearchFilterGroup 渲染标题、尾部组件及子内容', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SearchFilterGroup(
              title: '阅读状态',
              trailing: Text('重置'),
              child: Text('分组子项'),
            ),
          ),
        ),
      );

      expect(find.text('阅读状态'), findsOneWidget);
      expect(find.text('重置'), findsOneWidget);
      expect(find.text('分组子项'), findsOneWidget);
    });

    testWidgets('SearchFilterGroup.wrap 自动以 Wrap 排布子组件', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchFilterGroup.wrap(
              title: '来源渠道',
              children: const <Widget>[
                Text('本地音频'),
                Text('在线网络源'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('来源渠道'), findsOneWidget);
      expect(find.text('本地音频'), findsOneWidget);
      expect(find.text('在线网络源'), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('SearchFilterChip 交互、选中样式与回调触发', (WidgetTester tester) async {
      bool selected = false;
      bool callbackInvoked = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MaterialApp(
              home: Scaffold(
                body: SearchFilterChip(
                  label: '在听',
                  selected: selected,
                  count: 5,
                  onSelected: (bool val) {
                    callbackInvoked = true;
                    setState(() => selected = val);
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('在听'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // 点击 Chip
      await tester.tap(find.text('在听'));
      await tester.pump();

      expect(callbackInvoked, isTrue);
      expect(selected, isTrue);
    });
  });
}
