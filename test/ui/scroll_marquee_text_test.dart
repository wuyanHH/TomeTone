import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/ui/widgets/scroll_marquee_text.dart';

Widget _host({
  required double width,
  required String text,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: ScrollMarqueeText(
              text: text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('放得下时静止展示：不建滚动动画', (WidgetTester tester) async {
    const String text = '内部存储/Audiobooks';
    await tester.pumpWidget(_host(width: 300, text: text));
    await tester.pump();

    expect(find.text(text), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ScrollMarqueeText),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('放不下时进入滚动循环，位移随时间变化', (WidgetTester tester) async {
    const String text = '内部存储/有声书/武侠/长篇合集/第二季/第三卷';
    await tester.pumpWidget(_host(width: 120, text: text));
    await tester.pump();

    final Finder transform = find.descendant(
      of: find.byType(ScrollMarqueeText),
      matching: find.byType(Transform),
    );
    expect(transform, findsOneWidget);

    // 先停留 2.2 秒，再开始滚动。
    await tester.pump(const Duration(seconds: 3));
    final Transform widget = tester.widget<Transform>(transform);
    expect(widget.transform.getTranslation().x, lessThan(0));

    // 无限循环动画不会自己停；换掉整棵树以释放 ticker。
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('减少动态效果时退化为省略号静态文本', (WidgetTester tester) async {
    const String text = '内部存储/有声书/武侠/长篇合集/第二季/第三卷';
    await tester.pumpWidget(_host(width: 120, text: text, reduceMotion: true));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(ScrollMarqueeText),
        matching: find.byType(AnimatedBuilder),
      ),
      findsNothing,
    );
    final Text rendered = tester.widget<Text>(find.text(text));
    expect(rendered.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('语义标签始终是完整文本', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    const String text = '内部存储/有声书/武侠/长篇合集/第二季/第三卷';

    await tester.pumpWidget(_host(width: 120, text: text));
    await tester.pump();

    expect(find.bySemanticsLabel(text), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });
}
