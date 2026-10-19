import 'dart:convert';
import 'dart:typed_data';

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

/// 一张 1x1 的合法 PNG，用来构造 [MemoryImage]。
final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// 必定失败的 [ImageProvider]：取键成功，但解码必然报错。
///
/// 用来验证 [BookCover.coverImage] 加载失败时能静默回落到字标，
/// 而不是抛异常或留下空白。
class _FailingImageProvider extends ImageProvider<_FailingImageProvider> {
  /// 是否真的走到了图片加载路径（防止测试在管线未触发时空过）。
  bool requested = false;

  @override
  Future<_FailingImageProvider> obtainKey(ImageConfiguration configuration) {
    return Future<_FailingImageProvider>.value(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _FailingImageProvider key,
    ImageDecoderCallback decode,
  ) {
    requested = true;
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('模拟封面解码失败')),
    );
  }
}

/// 收集字标子树里所有自绘描边（[BoxDecoration.border]）。
///
/// 只看 [BookCover.monogramKey] 内部：最外层封面自身的发丝描边是正常的，
/// 不该被算进来。
List<BoxBorder> _monogramBorders(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(BookCover.monogramKey),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((DecoratedBox box) => box.decoration)
      .whereType<BoxDecoration>()
      .map((BoxDecoration decoration) => decoration.border)
      .whereType<BoxBorder>()
      .toList(growable: false);
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

  // 回归：播放台 300dp 大封面上、竖排字标上下方曾出现两条"游离横线"，
  // 真凶是字标内框（Border.all）的上/下两条边。这里不比对像素 golden
  // （CI 字体不同必挂），而是锁结构：字标内不得再有任何同时带上下两条边
  // 的描边，同时四角角饰仍在，守住"版框"的观感。
  testWidgets('字标用四角角饰，不再出现整框/游离横线', (WidgetTester tester) async {
    const List<(String, double)> cases = <(String, double)>[
      ('Santi', 300),
      ('山海经', 96),
      ('活着', 48),
    ];

    for (final (String title, double size) in cases) {
      await tester.pumpWidget(_host(BookCover(title: title, size: size)));

      expect(
        find.byKey(BookCover.markFrameKey),
        findsOneWidget,
        reason: '尺寸 $size 的四角角饰缺失',
      );

      for (final BoxBorder border in _monogramBorders(tester)) {
        if (border is Border) {
          final bool spansTopAndBottom =
              border.top.width > 0 && border.bottom.width > 0;
          expect(
            spansTopAndBottom,
            isFalse,
            reason: '尺寸 $size 的字标内出现了带上下两边的描边（即游离横线）',
          );
        }
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('coverImage 优先于 coverPath', (WidgetTester tester) async {
    final MemoryImage provider = MemoryImage(_onePixelPng);

    await tester.pumpWidget(
      _host(
        BookCover(
          title: '三体',
          size: 96,
          // 给一个绝对但不存在、必然读不到的文件路径做干扰项。
          coverPath: r'Z:\definitely-missing\cover.jpg',
          coverImage: provider,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.image, same(provider));
    // 字标仍在底层兜底。
    expect(find.byKey(BookCover.monogramKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('coverImage 解码失败时回落字标且不抛异常', (WidgetTester tester) async {
    final _FailingImageProvider provider = _FailingImageProvider();

    await tester.pumpWidget(
      _host(BookCover(title: '活着', size: 80, coverImage: provider)),
    );
    // 让图片流的错误回调跑完。
    await tester.pump();
    await tester.pump();

    expect(provider.requested, isTrue, reason: '图片加载路径没有被真正触发');
    expect(find.byType(Image), findsOneWidget);
    expect(find.byKey(BookCover.monogramKey), findsOneWidget);
    expect(find.text('活'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
