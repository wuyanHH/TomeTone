import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';

void main() {
  group('ReleaseAsset', () {
    test('toJson 与 fromJson 互转', () {
      const asset = ReleaseAsset(
        name: 'app.apk',
        sizeBytes: 12345,
        downloadUrl: 'https://example.com/app.apk',
        digest: 'sha256:abc',
      );

      final json = asset.toJson();
      final parsed = ReleaseAsset.fromJson(json);

      expect(parsed, asset);
      expect(parsed.hashCode, asset.hashCode);
    });

    test('fromJson 容错兼容 GitHub API 资产结构', () {
      final githubAssetJson = <String, Object?>{
        'name': 'tometone.apk',
        'size': 99999,
        'browser_download_url': 'https://github.com/dl.apk',
      };

      final asset = ReleaseAsset.fromJson(githubAssetJson);
      expect(asset.name, 'tometone.apk');
      expect(asset.sizeBytes, 99999);
      expect(asset.downloadUrl, 'https://github.com/dl.apk');
      expect(asset.digest, isNull);
    });
  });

  group('ReleaseInfo', () {
    test('toJson 与 fromJson 互转', () {
      final release = ReleaseInfo(
        tag: 'v1.0.0',
        name: 'Release 1.0.0',
        body: 'Notes',
        publishedAt: DateTime.utc(2026, 5, 1, 12, 0, 0),
        htmlUrl: 'https://example.com/rel',
        prerelease: false,
        draft: false,
        assets: const <ReleaseAsset>[
          ReleaseAsset(
            name: 'app.apk',
            sizeBytes: 100,
            downloadUrl: 'https://example.com/app.apk',
          ),
        ],
      );

      final json = release.toJson();
      final parsed = ReleaseInfo.fromJson(json);

      expect(parsed, release);
      expect(parsed.hashCode, release.hashCode);
    });

    test('日期解析失败时回退 Unix 0 UTC', () {
      final json = <String, Object?>{
        'tag_name': 'v1.0.0',
        'published_at': 'invalid-date',
      };

      final parsed = ReleaseInfo.fromJson(json);
      expect(
        parsed.publishedAt,
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    });
  });

  group('UpdateFetchResult 与 UpdateException', () {
    test('UpdateFetchResult 相等性与 hashCode', () {
      const r1 = UpdateFetchResult(etag: 'etag1', notModified: true);
      const r2 = UpdateFetchResult(etag: 'etag1', notModified: true);
      const r3 = UpdateFetchResult(etag: 'etag2', notModified: false);

      expect(r1, r2);
      expect(r1.hashCode, r2.hashCode);
      expect(r1 == r3, isFalse);
    });

    test('UpdateException toString 格式化', () {
      const e1 = UpdateException(
        kind: UpdateFailureKind.rateLimited,
        message: '超限',
      );
      expect(e1.toString(), contains('rateLimited'));
      expect(e1.toString(), contains('超限'));

      const e2 = UpdateException(kind: UpdateFailureKind.network);
      expect(e2.toString(), contains('network'));
    });
  });
}
