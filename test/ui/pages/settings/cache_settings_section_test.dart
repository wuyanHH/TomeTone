import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/audio/audio_cache_repository.dart';
import 'package:tometone/ui/pages/settings/cache_settings_section.dart';

class _FakeAudioCacheRepository implements AudioCacheRepository {
  bool clearedAll = false;
  int currentSizeBytes = 45 * 1024 * 1024; // 45 MB

  @override
  Future<void> clearAllCache() async {
    clearedAll = true;
    currentSizeBytes = 0;
  }

  @override
  Future<int> getTotalCacheSize() async => currentSizeBytes;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CacheSettingsSection renders wifiOnly switch, preload slider, and clear cache button', (tester) async {
    final fakeRepo = _FakeAudioCacheRepository();
    bool wifiOnlyVal = true;
    int preloadVal = 3;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CacheSettingsSection(
                cacheRepository: fakeRepo,
                initialWifiOnly: wifiOnlyVal,
                initialPreloadChapters: preloadVal,
                onWifiOnlyChanged: (val) => wifiOnlyVal = val,
                onPreloadChaptersChanged: (val) => preloadVal = val,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. 验证标题和开关
    expect(find.text('音频缓存与预下载'), findsOneWidget);
    expect(find.text('仅在 Wi-Fi 下预下载'), findsOneWidget);

    // 2. 验证预下载章节数滑块
    expect(find.textContaining('预下载未来章节数: 3 章'), findsOneWidget);

    // 3. 验证缓存容量展示
    expect(find.textContaining('已占用 45.0 MB / 上限 2.0 GB'), findsOneWidget);

    // 4. 点击清空缓存
    final clearBtn = find.text('清空音频缓存');
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    expect(fakeRepo.clearedAll, isTrue);
  });

  testWidgets('CacheSettingsSection renders cleanly on 320dp narrow screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final fakeRepo = _FakeAudioCacheRepository();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: CacheSettingsSection(
                  cacheRepository: fakeRepo,
                ),
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
