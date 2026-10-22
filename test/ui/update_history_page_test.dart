import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/ui/pages/settings/update_history_page.dart';
import 'package:tometone/ui/widgets/markdown_body.dart';

import 'ui_test_harness.dart';

void main() {
  const sampleMarkdown = '''
# 更新日志

## [未发布]

- 计划中的新特性

## [${AppInfo.version}] - 2026-10-22

### 新增功能
- 离线更新历史查看

## [0.1.0] - 2026-10-01

### 初始发布
- 基础有声书播放能力
''';

  setUp(() {
    UpdateHistoryPage.loader = () async => sampleMarkdown;
  });

  tearDown(() {
    UpdateHistoryPage.loader =
        () => rootBundle.loadString('assets/changelog/CHANGELOG.md');
  });

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    usePhoneViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(testApp(container, const UpdateHistoryPage()));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('页面正常渲染标题、各版本卡片与当前版本高亮徽章', (WidgetTester tester) async {
    await pumpPage(tester);

    // 页面 AppBar 标题
    expect(find.text('更新历史'), findsOneWidget);

    // 渲染各版本条目
    expect(
      find.byKey(UpdateHistoryPage.entryKey(AppInfo.version)),
      findsOneWidget,
    );
    expect(
      find.byKey(UpdateHistoryPage.entryKey('0.1.0')),
      findsOneWidget,
    );
    expect(
      find.byKey(UpdateHistoryPage.entryKey('未发布')),
      findsOneWidget,
    );

    // 版本标题与日期展示
    expect(find.text('v${AppInfo.version}'), findsOneWidget);
    expect(find.text('2026-10-22'), findsOneWidget);
    expect(find.text('v0.1.0'), findsOneWidget);
    expect(find.text('2026-10-01'), findsOneWidget);
    expect(find.text('未发布'), findsOneWidget);

    // 当前版本徽标存在
    expect(find.byKey(UpdateHistoryPage.currentVersionKey), findsOneWidget);
    expect(find.text('当前'), findsOneWidget);
  });

  testWidgets('点击折叠版本条目可展开正文并渲染 Markdown 内容', (WidgetTester tester) async {
    await pumpPage(tester);

    // 当前版本 (0.2.0-beta.1) 默认展开，包含其正文
    expect(find.text('离线更新历史查看'), findsOneWidget);

    // 0.1.0 尚未展开
    expect(find.text('基础有声书播放能力'), findsNothing);

    // 点击 0.1.0 条目展开
    await tester.tap(find.byKey(UpdateHistoryPage.entryKey('0.1.0')));
    await tester.pumpAndSettle();

    // 展开后正文内容可见
    expect(find.text('基础有声书播放能力'), findsOneWidget);
    expect(find.byType(MarkdownBodyView), findsWidgets);
  });

  testWidgets('加载失败显示错误提示与重试按钮，重试可恢复正常加载', (WidgetTester tester) async {
    var failOnce = true;
    UpdateHistoryPage.loader = () async {
      if (failOnce) {
        throw Exception('网络或资产异常');
      }
      return sampleMarkdown;
    };

    usePhoneViewport(tester);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(testApp(container, const UpdateHistoryPage()));
    await tester.pumpAndSettle();

    // 显示失败状态
    expect(find.text('更新历史读取失败'), findsOneWidget);
    expect(find.byKey(UpdateHistoryPage.retryButtonKey), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);

    // 修复数据源并点击重试
    failOnce = false;
    await tester.tap(find.byKey(UpdateHistoryPage.retryButtonKey));
    await tester.pumpAndSettle();

    // 恢复正常列表
    expect(find.text('更新历史读取失败'), findsNothing);
    expect(
      find.byKey(UpdateHistoryPage.entryKey(AppInfo.version)),
      findsOneWidget,
    );
  });

  testWidgets('空更新日志显示暂无更新记录', (WidgetTester tester) async {
    UpdateHistoryPage.loader = () async => '# 仅有标题\n\n没有版本段落';

    await pumpPage(tester);

    expect(find.text('暂无更新记录'), findsOneWidget);
  });
}
