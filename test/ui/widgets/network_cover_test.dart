import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

void main() {
  testWidgets('没有 URL 时直接显示回退图标', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: NetworkCover(coverUrl: null, size: 64)),
        ),
      ),
    );

    expect(find.byKey(NetworkCover.fallbackKey), findsOneWidget);
    expect(find.byIcon(NetworkCover.fallbackIcon), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('传入的请求头透传给网络图片', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: NetworkCover(
              coverUrl: 'http://127.0.0.1:1/missing.jpg',
              size: 64,
              headers: <String, String>{'Referer': 'https://e.test/'},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    expect((image.image as NetworkImage).headers, <String, String>{
      'Referer': 'https://e.test/',
    });
  });

  testWidgets('图片加载失败时回退图标，不抛异常', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: NetworkCover(
              coverUrl: 'http://127.0.0.1:1/missing.jpg',
              size: 64,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(NetworkCover.fallbackKey), findsOneWidget);
    expect(find.byIcon(NetworkCover.fallbackIcon), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
