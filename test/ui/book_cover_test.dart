import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/app_theme.dart';
import 'package:tometone/ui/widgets/book_cover.dart';

Widget _host(Widget child, {double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.build(palette: AppColorPalettes.amberScroll),
    home: Builder(
      builder: (BuildContext context) {
        return Scaffold(
          body: Center(
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child,
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  testWidgets('无封面路径时绘制几何字标，并提供无障碍标签', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(_host(const BookCover(title: '山海经', size: 96)));

    expect(find.byType(BookCover), findsOneWidget);
    expect(find.byKey(BookCover.monogramKey), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('山'), findsOneWidget);
    expect(find.text('海'), findsOneWidget);
    expect(find.bySemanticsLabel('《山海经》封面'), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('书名号会被剥离，书名不足两字时只显示首字', (WidgetTester tester) async {
    await tester.pumpWidget(_host(const BookCover(title: '《三体》', size: 80)));

    expect(find.text('三'), findsOneWidget);
    expect(find.text('体'), findsOneWidget);
    expect(find.text('《'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(_host(const BookCover(title: '活着', size: 80)));
    expect(find.text('活'), findsOneWidget);
    expect(find.text('着'), findsOneWidget);

    await tester.pumpWidget(_host(const BookCover(title: '   ', size: 80)));
    expect(find.text('书'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('有封面路径时叠加图片层，读取失败回落字标且不抛异常', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(
        const BookCover(
          title: '长安十二时辰',
          size: 96,
          coverPath: r'Z:\definitely-missing\cover.jpg',
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(BookCover.monogramKey), findsOneWidget);
    expect(find.text('长'), findsOneWidget);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('超长中文书名在窄容器内不溢出', (WidgetTester tester) async {
    const List<String> titles = <String>[
      '第一章：山丹丹花开红艳艳的那个漫长夏天与她的故事',
      '献给阿尔吉侬的花束',
      '我在东北当保安的那些年之第一卷',
    ];

    for (final String title in titles) {
      await tester.pumpWidget(
        _host(
          SizedBox(
            width: 88,
            height: 88,
            child: BookCover(title: title, size: 88),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: '书名「$title」溢出');
    }
  });

  testWidgets('大字号缩放下仍然不溢出', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(const BookCover(title: '追忆似水年华', size: 72), textScale: 2.5),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(BookCover)), const Size(72, 72));
  });

  testWidgets('尊重自定义圆角与尺寸', (WidgetTester tester) async {
    await tester.pumpWidget(
      _host(
        const BookCover(
          title: '东坡志林',
          size: 120,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
      ),
    );

    expect(tester.getSize(find.byType(BookCover)), const Size(120, 120));
    final ClipRRect clip = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byType(BookCover),
        matching: find.byType(ClipRRect),
      ),
    );
    expect(clip.borderRadius, const BorderRadius.all(Radius.circular(4)));
    expect(tester.takeException(), isNull);
  });
}
