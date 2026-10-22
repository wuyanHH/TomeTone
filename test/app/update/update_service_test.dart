import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/update/update_service.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/contracts/update/update_state.dart';

class FakeUpdateSource implements UpdateSource {
  int fetchCallCount = 0;
  String? lastPassedEtag;
  Future<UpdateFetchResult> Function(String? etag)? onFetch;

  @override
  Future<UpdateFetchResult> fetchReleases({String? etag}) async {
    fetchCallCount++;
    lastPassedEtag = etag;
    if (onFetch != null) {
      return onFetch!(etag);
    }
    return const UpdateFetchResult();
  }
}

ReleaseInfo makeRelease({
  String tag = 'v0.3.0',
  String name = 'Release 0.3.0',
  bool prerelease = false,
  bool draft = false,
  List<ReleaseAsset>? assets,
}) {
  return ReleaseInfo(
    tag: tag,
    name: name,
    body: 'Changelog body',
    publishedAt: DateTime.utc(2026, 10, 20),
    htmlUrl: 'https://github.com/example/releases/tag/$tag',
    prerelease: prerelease,
    draft: draft,
    assets: assets ??
        const [
          ReleaseAsset(
            name: 'tometone-arm64-v8a.apk',
            sizeBytes: 1024 * 1024,
            downloadUrl: 'https://example.com/download.apk',
          ),
        ],
  );
}

void main() {
  final fixedNow = DateTime.utc(2026, 10, 22, 14, 0);

  group('UpdateService 自动检查与节流', () {
    test('自动检查关闭时零网络调用且无缓存返回 upToDate', () async {
      final source = FakeUpdateSource();
      final service = UpdateService(source: source, now: () => fixedNow);

      final prefs = AppPreferences.defaults.copyWith(autoCheckUpdates: false);
      final outcome = await service.check(preferences: prefs, manual: false);

      expect(source.fetchCallCount, 0);
      expect(outcome.status, UpdateStatus.upToDate);
      expect(outcome.fromCache, isFalse);
      expect(outcome.preferences, equals(prefs));
    });

    test('自动检查关闭时存在缓存则基于缓存评估状态', () async {
      final source = FakeUpdateSource();
      final service = UpdateService(source: source, now: () => fixedNow);

      final cached = CachedRelease(
        release: makeRelease(tag: 'v0.3.0'),
        etag: 'etag-1',
        fetchedAt: fixedNow.subtract(const Duration(days: 2)),
      );
      final prefs = AppPreferences.defaults.copyWith(
        autoCheckUpdates: false,
        cachedRelease: cached,
      );
      final outcome = await service.check(preferences: prefs, manual: false);

      expect(source.fetchCallCount, 0);
      expect(outcome.status, UpdateStatus.available);
      expect(outcome.release, equals(cached.release));
      expect(outcome.fromCache, isTrue);
    });

    test('24 小时内节流生效阻断网络调用，无缓存返回 idle', () async {
      final source = FakeUpdateSource();
      final service = UpdateService(source: source, now: () => fixedNow);

      final prefs = AppPreferences.defaults.copyWith(
        lastAttemptAt: fixedNow.subtract(const Duration(hours: 5)),
      );
      final outcome = await service.check(preferences: prefs, manual: false);

      expect(source.fetchCallCount, 0);
      expect(outcome.status, UpdateStatus.idle);
      expect(outcome.fromCache, isFalse);
      expect(outcome.preferences, equals(prefs));
    });

    test('24 小时内节流生效且有缓存时重新评估缓存版本状态', () async {
      final source = FakeUpdateSource();
      final service = UpdateService(source: source, now: () => fixedNow);

      final cached = CachedRelease(
        release: makeRelease(tag: 'v0.3.0'),
        etag: 'etag-1',
        fetchedAt: fixedNow.subtract(const Duration(hours: 5)),
      );
      final prefs = AppPreferences.defaults.copyWith(
        lastAttemptAt: fixedNow.subtract(const Duration(hours: 5)),
        cachedRelease: cached,
        skippedVersion: '0.3.0',
      );
      final outcome = await service.check(preferences: prefs, manual: false);

      expect(source.fetchCallCount, 0);
      expect(outcome.status, UpdateStatus.skipped);
      expect(outcome.release, equals(cached.release));
      expect(outcome.fromCache, isTrue);
      expect(outcome.preferences, equals(prefs));
    });

    test('手动检查绕过 24 小时节流与 autoCheckUpdates 开关', () async {
      final source = FakeUpdateSource()
        ..onFetch = (etag) async => UpdateFetchResult(
              releases: [makeRelease(tag: 'v0.3.0')],
              etag: 'etag-new',
            );
      final service = UpdateService(source: source, now: () => fixedNow);

      final prefs = AppPreferences.defaults.copyWith(
        autoCheckUpdates: false,
        lastAttemptAt: fixedNow.subtract(const Duration(minutes: 30)),
      );
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(source.fetchCallCount, 1);
      expect(outcome.status, UpdateStatus.available);
      expect(outcome.fromCache, isFalse);
    });

    test('超过 24 小时节流失效发起网络请求', () async {
      final source = FakeUpdateSource()
        ..onFetch = (etag) async => UpdateFetchResult(
              releases: [makeRelease(tag: 'v0.3.0')],
            );
      final service = UpdateService(source: source, now: () => fixedNow);

      final prefs = AppPreferences.defaults.copyWith(
        lastAttemptAt: fixedNow.subtract(const Duration(hours: 25)),
      );
      final outcome = await service.check(preferences: prefs, manual: false);

      expect(source.fetchCallCount, 1);
      expect(outcome.status, UpdateStatus.available);
    });
  });

  group('UpdateService 200 响应与状态判定', () {
    test('发现高于当前版本的 Release 判定为 available 并写入缓存', () async {
      final source = FakeUpdateSource()
        ..onFetch = (etag) async => UpdateFetchResult(
              releases: [makeRelease(tag: 'v0.3.0')],
              etag: 'etag-200',
            );
      final service = UpdateService(source: source, now: () => fixedNow);

      const prefs = AppPreferences.defaults;
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(source.fetchCallCount, 1);
      expect(outcome.status, UpdateStatus.available);
      expect(outcome.release?.tag, 'v0.3.0');
      expect(outcome.fromCache, isFalse);
      expect(outcome.preferences.lastCheckAt, fixedNow);
      expect(outcome.preferences.lastAttemptAt, fixedNow);
      expect(outcome.preferences.cachedRelease?.release.tag, 'v0.3.0');
      expect(outcome.preferences.cachedRelease?.etag, 'etag-200');
      expect(outcome.preferences.cachedRelease?.fetchedAt, fixedNow);
    });

    test('发现的新版本与 skippedVersion 匹配判定为 skipped', () async {
      final source = FakeUpdateSource()
        ..onFetch = (etag) async => UpdateFetchResult(
              releases: [makeRelease(tag: 'v0.3.0')],
            );
      final service = UpdateService(source: source, now: () => fixedNow);

      final prefs = AppPreferences.defaults.copyWith(skippedVersion: '0.3.0');
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(outcome.status, UpdateStatus.skipped);
      expect(outcome.release?.tag, 'v0.3.0');
    });

    test('远端版本小于或等于当前版本判定为 upToDate', () async {
      // 当前 AppInfo.version 为 0.2.0-beta.1
      final source = FakeUpdateSource()
        ..onFetch = (etag) async => UpdateFetchResult(
              releases: [makeRelease(tag: 'v0.2.0-beta.1')],
            );
      final service = UpdateService(source: source, now: () => fixedNow);

      const prefs = AppPreferences.defaults;
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(outcome.status, UpdateStatus.upToDate);
      expect(outcome.release?.tag, 'v0.2.0-beta.1');
      expect(outcome.preferences.cachedRelease?.release.tag, 'v0.2.0-beta.1');
    });

    test('远端无任何可用 Release 判定为 noRelease', () async {
      final source = FakeUpdateSource()
        ..onFetch = (etag) async => const UpdateFetchResult(
              releases: [],
            );
      final service = UpdateService(source: source, now: () => fixedNow);

      const prefs = AppPreferences.defaults;
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(outcome.status, UpdateStatus.noRelease);
      expect(outcome.release, isNull);
      expect(outcome.preferences.lastCheckAt, fixedNow);
      expect(outcome.preferences.lastAttemptAt, fixedNow);
      expect(outcome.preferences.cachedRelease, isNull);
    });
  });

  group('UpdateService 304 未修改处理', () {
    test('304 刷新时间戳并复用已有缓存 Release 评估状态', () async {
      final cached = CachedRelease(
        release: makeRelease(tag: 'v0.3.0'),
        etag: 'old-etag',
        fetchedAt: fixedNow.subtract(const Duration(days: 1)),
      );
      final source = FakeUpdateSource()
        ..onFetch = (etag) async {
          expect(etag, 'old-etag');
          return const UpdateFetchResult(notModified: true, etag: 'new-etag');
        };
      final service = UpdateService(source: source, now: () => fixedNow);

      final prefs = AppPreferences.defaults.copyWith(
        cachedRelease: cached,
        lastCheckAt: fixedNow.subtract(const Duration(days: 1)),
      );
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(source.fetchCallCount, 1);
      expect(outcome.status, UpdateStatus.available);
      expect(outcome.fromCache, isTrue);
      expect(outcome.release?.tag, 'v0.3.0');
      expect(outcome.preferences.lastCheckAt, fixedNow);
      expect(outcome.preferences.lastAttemptAt, fixedNow);
      expect(outcome.preferences.cachedRelease?.etag, 'new-etag');
      expect(outcome.preferences.cachedRelease?.fetchedAt, fixedNow);
    });

    test('304 且无缓存边缘情况安全返回 upToDate', () async {
      final source = FakeUpdateSource()
        ..onFetch = (etag) async =>
            const UpdateFetchResult(notModified: true);
      final service = UpdateService(source: source, now: () => fixedNow);

      const prefs = AppPreferences.defaults;
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(outcome.status, UpdateStatus.upToDate);
      expect(outcome.fromCache, isFalse);
      expect(outcome.preferences.lastCheckAt, fixedNow);
      expect(outcome.preferences.lastAttemptAt, fixedNow);
    });
  });

  group('UpdateService 异常降级处理', () {
    test('请求异常且有缓存时降级返回缓存状态与 failure 信息', () async {
      final cached = CachedRelease(
        release: makeRelease(tag: 'v0.3.0'),
        etag: 'etag-cached',
        fetchedAt: fixedNow.subtract(const Duration(hours: 12)),
      );
      final source = FakeUpdateSource()
        ..onFetch = (etag) async =>
            throw const UpdateException(kind: UpdateFailureKind.network);
      final service = UpdateService(source: source, now: () => fixedNow);

      final prefs = AppPreferences.defaults.copyWith(cachedRelease: cached);
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(source.fetchCallCount, 1);
      expect(outcome.status, UpdateStatus.available);
      expect(outcome.release?.tag, 'v0.3.0');
      expect(outcome.failure, UpdateFailureKind.network);
      expect(outcome.fromCache, isTrue);
      expect(outcome.preferences.lastAttemptAt, fixedNow);
      // 检查成功时间戳不应被更新
      expect(outcome.preferences.lastCheckAt, isNull);
    });

    test('请求异常且无缓存时返回 UpdateStatus.failure', () async {
      final source = FakeUpdateSource()
        ..onFetch = (etag) async =>
            throw const UpdateException(kind: UpdateFailureKind.rateLimited);
      final service = UpdateService(source: source, now: () => fixedNow);

      const prefs = AppPreferences.defaults;
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(outcome.status, UpdateStatus.failure);
      expect(outcome.release, isNull);
      expect(outcome.failure, UpdateFailureKind.rateLimited);
      expect(outcome.fromCache, isFalse);
      expect(outcome.preferences.lastAttemptAt, fixedNow);
    });

    test('非 UpdateException 异常统一捕获为 network 失败', () async {
      final source = FakeUpdateSource()
        ..onFetch = (etag) async => throw Exception('Socket error');
      final service = UpdateService(source: source, now: () => fixedNow);

      const prefs = AppPreferences.defaults;
      final outcome = await service.check(preferences: prefs, manual: true);

      expect(outcome.status, UpdateStatus.failure);
      expect(outcome.failure, UpdateFailureKind.network);
      expect(outcome.fromCache, isFalse);
      expect(outcome.preferences.lastAttemptAt, fixedNow);
    });
  });
}
