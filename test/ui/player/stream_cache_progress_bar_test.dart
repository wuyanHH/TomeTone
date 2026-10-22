import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/ui/player/stream_cache_progress_bar.dart';

void main() {
  testWidgets('StreamCacheProgressBar renders dual track and thumb', (tester) async {
    Duration? seekedDuration;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 48,
              child: StreamCacheProgressBar(
                currentPosition: const Duration(minutes: 2),
                bufferedPosition: const Duration(minutes: 5),
                totalDuration: const Duration(minutes: 10),
                onSeek: (pos) => seekedDuration = pos,
              ),
            ),
          ),
        ),
      ),
    );

    // 验证时间文本展示 (02:00 与 10:00)
    expect(find.text('02:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);

    // 验证自定义双轨进度条组件被渲染
    expect(find.byType(StreamCacheProgressBar), findsOneWidget);

    // 点击进度条中间位置触发 seek
    await tester.tap(find.byKey(const Key('stream-cache-track')));
    await tester.pump();

    expect(seekedDuration, isNotNull);
  });

  testWidgets('StreamCacheProgressBar renders on 320dp narrow screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.5),
          ),
          child: Scaffold(
            body: Center(
              child: StreamCacheProgressBar(
                currentPosition: const Duration(hours: 1, minutes: 23, seconds: 45),
                bufferedPosition: const Duration(hours: 2, minutes: 0),
                totalDuration: const Duration(hours: 3, minutes: 45, seconds: 12),
                onSeek: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
