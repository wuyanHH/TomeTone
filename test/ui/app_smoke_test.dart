import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/ui/app.dart';

void main() {
  testWidgets('装配入口 → 首屏链路可用', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TomeToneApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text(AppInfo.appName), findsOneWidget);
    expect(find.text(AppInfo.appNameLatin), findsOneWidget);
    expect(find.textContaining(AppInfo.version), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
