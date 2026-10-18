import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/app.dart';
import 'package:tometone/ui/app_shell.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/app_theme.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 固定视口尺寸，避免测试默认 800×600 落到平板布局。
void _useViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  late FakePlaybackEngine engine;
  late PlaybackController controller;

  setUp(() {
    engine = FakePlaybackEngine();
    controller = PlaybackController(
      engine: engine,
      writeProgress: (String bookId, String chapterId, Duration position) {},
    );
  });

  tearDown(() async {
    await controller.dispose();
  });

  /// 外壳现在会读取书架 / 书库根 / 播放控制器，测试必须注入假数据。
  List<Override> overrides() {
    return <Override>[
      booksProvider.overrideWith((Ref ref) async => const <BookSummary>[]),
      libraryRootsProvider.overrideWith(
        (Ref ref) async => const <LibraryRootView>[],
      ),
      playbackControllerProvider.overrideWithValue(controller),
    ];
  }

  testWidgets('装配入口 → 外壳渲染成功：3 个 tab 存在且无异常', (WidgetTester tester) async {
    _useViewport(tester, const Size(400, 800));

    await tester.pumpWidget(
      ProviderScope(overrides: overrides(), child: const TomeToneApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('纪年'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('书卷藏馆'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换 tab 后显示对应页面，设置页读取注入的书库根', (WidgetTester tester) async {
    _useViewport(tester, const Size(400, 800));

    await tester.pumpWidget(
      ProviderScope(overrides: overrides(), child: const TomeToneApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('纪年'));
    await tester.pumpAndSettle();
    expect(find.text('聆听纪年'), findsOneWidget);
    expect(find.text('书卷藏馆'), findsNothing);

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('系统偏好'), findsOneWidget);
    // 设置页现在是真实页面：空态来自 overrides 里注入的空书库根列表。
    expect(find.text('还没有书库根'), findsOneWidget);
    expect(find.text('书库根'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('MiniPlayer 槽位渲染在底部栏之上', (WidgetTester tester) async {
    _useViewport(tester, const Size(400, 800));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const AppShell(
            miniPlayer: SizedBox(
              height: 56,
              child: Center(child: Text('正在播放 · 第一章')),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('正在播放 · 第一章'), findsOneWidget);
    final double miniBottom = tester.getBottomLeft(find.text('正在播放 · 第一章')).dy;
    final double barTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    expect(miniBottom, lessThanOrEqualTo(barTop));
    expect(tester.takeException(), isNull);
  });

  testWidgets('≥600dp 切换为 NavigationRail，布局不崩', (WidgetTester tester) async {
    _useViewport(tester, const Size(900, 720));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          theme: AppTheme.build(palette: AppColorPalettes.starryIndigo),
          home: const AppShell(miniPlayer: Text('播放器')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('书架'), findsOneWidget);
    expect(find.text('纪年'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('书卷藏馆'), findsOneWidget);
    expect(find.text('播放器'), findsOneWidget);

    await tester.tap(find.text('纪年'));
    await tester.pumpAndSettle();
    expect(find.text('聆听纪年'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('系统开启"减弱动效"时过渡时长为 0', (WidgetTester tester) async {
    _useViewport(tester, const Size(400, 800));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          theme: AppTheme.build(),
          home: const AppShell(),
          builder: (BuildContext context, Widget? child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, Duration.zero);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('设置'));
    await tester.pump();
    expect(find.text('系统偏好'), findsOneWidget);
  });

  testWidgets('默认动效时长为克制档（200ms）', (WidgetTester tester) async {
    _useViewport(tester, const Size(400, 800));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(theme: AppTheme.build(), home: const AppShell()),
      ),
    );
    await tester.pumpAndSettle();

    final AnimatedSwitcher switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    expect(switcher.duration, AppDurations.standard);
  });
}
