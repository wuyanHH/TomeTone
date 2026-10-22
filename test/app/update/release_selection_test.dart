import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/update/release_selection.dart';
import 'package:tometone/app/update/semver.dart';
import 'package:tometone/contracts/update/update_models.dart';

ReleaseInfo _createRelease({
  required String tag,
  String name = 'Release',
  String body = '',
  DateTime? publishedAt,
  String htmlUrl = 'https://example.com/release',
  bool prerelease = false,
  bool draft = false,
  List<ReleaseAsset> assets = const <ReleaseAsset>[],
}) {
  return ReleaseInfo(
    tag: tag,
    name: name,
    body: body,
    publishedAt: publishedAt ?? DateTime.utc(2026, 1, 1),
    htmlUrl: htmlUrl,
    prerelease: prerelease,
    draft: draft,
    assets: assets,
  );
}

ReleaseAsset _createAsset({
  required String name,
  int sizeBytes = 1024,
  String downloadUrl = 'https://example.com/dl.apk',
}) {
  return ReleaseAsset(
    name: name,
    sizeBytes: sizeBytes,
    downloadUrl: downloadUrl,
  );
}

void main() {
  group('selectLatestRelease', () {
    test('排除草稿 (draft == true)', () {
      final draftRelease = _createRelease(
        tag: 'v1.0.0',
        draft: true,
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );
      final result = selectLatestRelease(
        releases: <ReleaseInfo>[draftRelease],
        channel: AppChannel.stable,
      );
      expect(result, isNull);
    });

    test('排除 Tag 无法解析为 SemVer 的版本', () {
      final invalidTagRelease = _createRelease(
        tag: 'nightly-build',
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );
      final result = selectLatestRelease(
        releases: <ReleaseInfo>[invalidTagRelease],
        channel: AppChannel.stable,
      );
      expect(result, isNull);
    });

    test('排除没有任何 .apk 资产的版本', () {
      final noApkRelease = _createRelease(
        tag: 'v1.0.0',
        assets: <ReleaseAsset>[
          _createAsset(name: 'checksums.txt'),
          _createAsset(name: 'source.tar.gz'),
        ],
      );
      final result = selectLatestRelease(
        releases: <ReleaseInfo>[noApkRelease],
        channel: AppChannel.stable,
      );
      expect(result, isNull);
    });

    test('stable 通道排除 prerelease 或版本含预发布段的条目', () {
      final prereleaseFlag = _createRelease(
        tag: 'v1.0.0',
        prerelease: true,
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );
      final prereleaseTag = _createRelease(
        tag: 'v1.1.0-beta.1',
        prerelease: false,
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );
      final stableRelease = _createRelease(
        tag: 'v0.9.0',
        prerelease: false,
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );

      final stableResult = selectLatestRelease(
        releases: <ReleaseInfo>[
          prereleaseFlag,
          prereleaseTag,
          stableRelease,
        ],
        channel: AppChannel.stable,
      );
      expect(stableResult, isNotNull);
      expect(stableResult!.version, SemVer.tryParse('0.9.0'));
    });

    test('beta 通道接受 prerelease 版本并选出最高版本', () {
      final v100 = _createRelease(
        tag: 'v1.0.0',
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );
      final v110Beta = _createRelease(
        tag: 'v1.1.0-beta.1',
        prerelease: true,
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );

      final betaResult = selectLatestRelease(
        releases: <ReleaseInfo>[v100, v110Beta],
        channel: AppChannel.beta,
      );
      expect(betaResult, isNotNull);
      expect(betaResult!.version, SemVer.tryParse('1.1.0-beta.1'));
    });

    test('候选池中版本相同时优先选取列表中靠前者', () {
      final first = _createRelease(
        tag: 'v1.0.0',
        name: 'First Release',
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );
      final second = _createRelease(
        tag: 'v1.0.0',
        name: 'Second Release',
        assets: <ReleaseAsset>[_createAsset(name: 'app.apk')],
      );

      final result = selectLatestRelease(
        releases: <ReleaseInfo>[first, second],
        channel: AppChannel.stable,
      );
      expect(result, isNotNull);
      expect(result!.release.name, 'First Release');
    });

    test('全部被过滤后返回 null', () {
      final result = selectLatestRelease(
        releases: <ReleaseInfo>[],
        channel: AppChannel.stable,
      );
      expect(result, isNull);
    });
  });

  group('compareToCurrent', () {
    test('远端版本更高时判定为 available', () {
      final current = SemVer.tryParse('0.2.0-beta.1')!;
      final latest = SemVer.tryParse('0.2.0-beta.2')!;

      expect(
        compareToCurrent(current: current, latest: latest),
        UpdateVerdict.available,
      );
    });

    test('远端版本相同或更低时判定为 upToDate（避免降级）', () {
      final current = SemVer.tryParse('1.0.0')!;
      final same = SemVer.tryParse('1.0.0')!;
      final lower = SemVer.tryParse('0.9.0')!;

      expect(
        compareToCurrent(current: current, latest: same),
        UpdateVerdict.upToDate,
      );
      expect(
        compareToCurrent(current: current, latest: lower),
        UpdateVerdict.upToDate,
      );
    });

    test('当前为预发布版而远端为相同版本的正式版时判定为 available', () {
      final current = SemVer.tryParse('1.0.0-rc.1')!;
      final latest = SemVer.tryParse('1.0.0')!;

      expect(
        compareToCurrent(current: current, latest: latest),
        UpdateVerdict.available,
      );
    });
  });

  group('recommendedAbiAsset', () {
    final assets = <ReleaseAsset>[
      _createAsset(name: 'tometone-v1.0.0-armeabi-v7a.apk'),
      _createAsset(name: 'tometone-v1.0.0-arm64-v8a.apk'),
      _createAsset(name: 'tometone-v1.0.0-x86_64.apk'),
      _createAsset(name: 'mapping.txt'),
    ];

    test('按 deviceAbis 优先级推荐匹配的首个 APK 资产', () {
      final abis = <String>['arm64-v8a', 'armeabi-v7a'];
      final recommended = recommendedAbiAsset(abis, assets);

      expect(recommended, 'tometone-v1.0.0-arm64-v8a.apk');
    });

    test('高优先级 ABI 不在资产列表时回退匹配次优项', () {
      final abis = <String>['x86', 'armeabi-v7a'];
      final recommended = recommendedAbiAsset(abis, assets);

      expect(recommended, 'tometone-v1.0.0-armeabi-v7a.apk');
    });

    test('忽略非 APK 资产并无匹配时返回 null', () {
      final abis = <String>['riscv64'];
      final recommended = recommendedAbiAsset(abis, assets);

      expect(recommended, isNull);
    });

    test('大小写与首尾空格不敏感', () {
      final abis = <String>['  ARM64-V8A  '];
      final recommended = recommendedAbiAsset(abis, assets);

      expect(recommended, 'tometone-v1.0.0-arm64-v8a.apk');
    });
  });
}
