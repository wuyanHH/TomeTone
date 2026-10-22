import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/update_providers.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/contracts/update/update_state.dart';

class FakeUpdateSource implements UpdateSource {
  int fetchCallCount = 0;
  Future<UpdateFetchResult> Function(String? etag)? onFetch;

  @override
  Future<UpdateFetchResult> fetchReleases({String? etag}) async {
    fetchCallCount++;
    if (onFetch != null) {
      return onFetch!(etag);
    }
    return const UpdateFetchResult();
  }
}

ReleaseInfo makeRelease({
  String tag = 'v0.3.0',
  String name = 'Release 0.3.0',
}) {
  return ReleaseInfo(
    tag: tag,
    name: name,
    body: 'Body',
    publishedAt: DateTime.utc(2026, 10, 20),
    htmlUrl: 'https://example.com/tag/$tag',
    prerelease: false,
    draft: false,
    assets: const [
      ReleaseAsset(
        name: 'tometone-arm64-v8a.apk',
        sizeBytes: 1024,
        downloadUrl: 'https://example.com/download.apk',
      ),
    ],
  );
}

void main() {
  group('updateSourceProvider', () {
    test('未 override 依赖时抛出 UnimplementedError', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(updateSourceProvider),
        throwsA(
          isA<ProviderException>().having(
            (ProviderException e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });
  });

  group('UpdateController 行为测试', () {
    late InMemoryAppPreferencesStore store;
    late FakeUpdateSource source;
    late ProviderContainer container;

    setUp(() {
      store = InMemoryAppPreferencesStore();
      source = FakeUpdateSource();
      container = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(store),
          initialPreferencesProvider.overrideWithValue(AppPreferences.defaults),
          updateSourceProvider.overrideWithValue(source),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态为 UpdateStatus.idle', () {
      final state = container.read(updateControllerProvider);
      expect(state, const UpdateState(status: UpdateStatus.idle));
    });

    test('check 成功拉取新版本更新 preferences 与 state', () async {
      source.onFetch = (etag) async => UpdateFetchResult(
            releases: [makeRelease(tag: 'v0.3.0')],
            etag: 'etag-123',
          );

      await container
          .read(updateControllerProvider.notifier)
          .check(manual: true);

      final state = container.read(updateControllerProvider);
      expect(state.status, UpdateStatus.available);
      expect(state.release?.tag, 'v0.3.0');
      expect(state.fromCache, isFalse);

      final prefs = container.read(preferencesProvider);
      expect(prefs.cachedRelease?.release.tag, 'v0.3.0');
      expect(prefs.cachedRelease?.etag, 'etag-123');
      expect(prefs.lastCheckAt, isNotNull);
    });

    test('check 防重复触发机制生效', () async {
      final completer = Completer<UpdateFetchResult>();
      source.onFetch = (etag) => completer.future;

      // 首次发起检查（尚未完成）
      final future1 =
          container.read(updateControllerProvider.notifier).check(manual: true);
      expect(
        container.read(updateControllerProvider).status,
        UpdateStatus.checking,
      );

      // 第二次发起检查，应被防重复拦截直接 return
      final future2 =
          container.read(updateControllerProvider.notifier).check(manual: true);

      expect(source.fetchCallCount, 1);

      completer.complete(
        UpdateFetchResult(releases: [makeRelease(tag: 'v0.3.0')]),
      );
      await Future.wait([future1, future2]);

      expect(source.fetchCallCount, 1);
      expect(
        container.read(updateControllerProvider).status,
        UpdateStatus.available,
      );
    });

    test('skipVersion 规范化版本号并写入偏好，更新状态为 skipped', () async {
      source.onFetch = (etag) async => UpdateFetchResult(
            releases: [makeRelease(tag: 'v0.3.0')],
          );

      await container
          .read(updateControllerProvider.notifier)
          .check(manual: true);
      expect(
        container.read(updateControllerProvider).status,
        UpdateStatus.available,
      );

      await container
          .read(updateControllerProvider.notifier)
          .skipVersion('v0.3.0');

      expect(
        container.read(updateControllerProvider).status,
        UpdateStatus.skipped,
      );
      final prefs = container.read(preferencesProvider);
      expect(prefs.skippedVersion, '0.3.0');
      expect(prefs.acknowledgedVersion, '0.3.0');
    });

    test('clearSkip 清除跳过版本并触发手动更新检查', () async {
      source.onFetch = (etag) async => UpdateFetchResult(
            releases: [makeRelease(tag: 'v0.3.0')],
          );

      await container
          .read(updateControllerProvider.notifier)
          .skipVersion('v0.3.0');
      expect(
        container.read(preferencesProvider).skippedVersion,
        '0.3.0',
      );

      await container.read(updateControllerProvider.notifier).clearSkip();

      expect(container.read(preferencesProvider).skippedVersion, isNull);
      expect(
        container.read(updateControllerProvider).status,
        UpdateStatus.available,
      );
      expect(source.fetchCallCount, 1);
    });

    test('acknowledge 规范化并记录已确认版本', () async {
      await container
          .read(updateControllerProvider.notifier)
          .acknowledge('v0.3.0');

      expect(
        container.read(preferencesProvider).acknowledgedVersion,
        '0.3.0',
      );
    });

    test('markPrompted 规范化并记录已提示版本', () async {
      await container
          .read(updateControllerProvider.notifier)
          .markPrompted('v0.3.0');

      expect(
        container.read(preferencesProvider).promptedVersion,
        '0.3.0',
      );
    });

    test('setAutoCheck 更新自动检查偏好', () async {
      await container
          .read(updateControllerProvider.notifier)
          .setAutoCheck(false);

      expect(
        container.read(preferencesProvider).autoCheckUpdates,
        isFalse,
      );
    });

    test('maybeAutoCheck 在开启时触发检查，关闭时不触发', () async {
      source.onFetch = (etag) async => UpdateFetchResult(
            releases: [makeRelease(tag: 'v0.3.0')],
          );

      // 默认开启，调用 maybeAutoCheck
      await container.read(updateControllerProvider.notifier).maybeAutoCheck();
      expect(source.fetchCallCount, 1);

      // 关闭自动检查
      await container
          .read(updateControllerProvider.notifier)
          .setAutoCheck(false);
      await container.read(updateControllerProvider.notifier).maybeAutoCheck();
      expect(source.fetchCallCount, 1); // 依然为 1，未新增请求
    });
  });

  group('updateBadgeProvider 红点计算测试', () {
    late InMemoryAppPreferencesStore store;
    late FakeUpdateSource source;
    late ProviderContainer container;

    setUp(() {
      store = InMemoryAppPreferencesStore();
      source = FakeUpdateSource();
      container = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(store),
          initialPreferencesProvider.overrideWithValue(AppPreferences.defaults),
          updateSourceProvider.overrideWithValue(source),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态无红点', () {
      expect(container.read(updateBadgeProvider), isFalse);
    });

    test('发现新版且未确认时显示红点，确认后红点消失', () async {
      source.onFetch = (etag) async => UpdateFetchResult(
            releases: [makeRelease(tag: 'v0.3.0')],
          );

      await container
          .read(updateControllerProvider.notifier)
          .check(manual: true);

      // 状态为 available，且未 acknowledge
      expect(
        container.read(updateControllerProvider).status,
        UpdateStatus.available,
      );
      expect(container.read(updateBadgeProvider), isTrue);

      // 确认该版本后红点消除
      await container
          .read(updateControllerProvider.notifier)
          .acknowledge('v0.3.0');
      expect(container.read(updateBadgeProvider), isFalse);
    });

    test('关闭自动检查更新时不显示红点', () async {
      source.onFetch = (etag) async => UpdateFetchResult(
            releases: [makeRelease(tag: 'v0.3.0')],
          );

      await container
          .read(updateControllerProvider.notifier)
          .check(manual: true);
      expect(container.read(updateBadgeProvider), isTrue);

      await container
          .read(updateControllerProvider.notifier)
          .setAutoCheck(false);
      expect(container.read(updateBadgeProvider), isFalse);
    });

    test('状态变为 skipped 时不显示红点', () async {
      source.onFetch = (etag) async => UpdateFetchResult(
            releases: [makeRelease(tag: 'v0.3.0')],
          );

      await container
          .read(updateControllerProvider.notifier)
          .check(manual: true);
      expect(container.read(updateBadgeProvider), isTrue);

      await container
          .read(updateControllerProvider.notifier)
          .skipVersion('v0.3.0');
      expect(container.read(updateBadgeProvider), isFalse);
    });
  });
}
