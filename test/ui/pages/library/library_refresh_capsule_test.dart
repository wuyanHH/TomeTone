import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/batch_refresh_controller.dart';
import 'package:tometone/domain/library/batch_refresh_state.dart';
import 'package:tometone/ui/pages/library/library_refresh_capsule.dart';

void main() {
  testWidgets('LibraryRefreshCapsule is hidden when idle with no message', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LibraryRefreshCapsule(),
          ),
        ),
      ),
    );

    expect(find.byType(LibraryRefreshCapsule), findsOneWidget);
    // 内部应为 SizedBox.shrink，没有任何文本或指示器
    expect(find.textContaining('正在检查'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('displays progress text and indicator when isRunning == true', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: LibraryRefreshCapsule(),
          ),
        ),
      ),
    );

    // 设置为正在刷新 3/8
    container.read(batchRefreshControllerProvider.notifier).state = const BatchRefreshState(
      isRunning: true,
      total: 8,
      completed: 3,
      currentBookTitle: '遮天',
    );
    await tester.pump();

    expect(find.text('正在检查 3/8 本在线书更新...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows dismissible summary capsule on completion', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: LibraryRefreshCapsule(),
          ),
        ),
      ),
    );

    container.read(batchRefreshControllerProvider.notifier).state = const BatchRefreshState(
      isRunning: false,
      total: 8,
      completed: 8,
      updatedCount: 2,
      message: '2 本书发现新章节',
    );
    await tester.pump();

    expect(find.textContaining('2 本书发现新章节'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // 点击关闭胶囊
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(find.textContaining('2 本书发现新章节'), findsNothing);
  });

  testWidgets('renders cleanly on 320dp narrow screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: LibraryRefreshCapsule(),
            ),
          ),
        ),
      ),
    );

    container.read(batchRefreshControllerProvider.notifier).state = const BatchRefreshState(
      isRunning: true,
      total: 10,
      completed: 4,
      currentBookTitle: '这是一个非常长非常长的超长书名测试用例',
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
