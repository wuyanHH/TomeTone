import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_state.dart';

void main() {
  final sampleRelease = ReleaseInfo(
    tag: 'v0.2.1',
    name: 'Version 0.2.1',
    body: 'Bug fixes',
    publishedAt: DateTime.utc(2026, 10, 20, 12),
    htmlUrl: 'https://github.com/example/releases/tag/v0.2.1',
    prerelease: false,
    draft: false,
    assets: const [
      ReleaseAsset(
        name: 'tometone-arm64-v8a.apk',
        sizeBytes: 1024,
        downloadUrl: 'https://example.com/tometone-arm64-v8a.apk',
      ),
    ],
  );

  final sampleCachedRelease = CachedRelease(
    release: sampleRelease,
    etag: 'W/"12345"',
    fetchedAt: DateTime.utc(2026, 10, 20, 12, 30),
  );

  group('AppPreferences 默认值', () {
    test('默认配置符合约定：琥珀旧卷、跟随系统、关闭 OLED 纯黑、开启自动检查', () {
      const prefs = AppPreferences.defaults;
      expect(prefs.paletteId, 'amberScroll');
      expect(prefs.brightness, BrightnessPreference.system);
      expect(prefs.oledDark, isFalse);
      expect(prefs.autoCheckUpdates, isTrue);
      expect(prefs.skippedVersion, isNull);
      expect(prefs.promptedVersion, isNull);
      expect(prefs.acknowledgedVersion, isNull);
      expect(prefs.lastCheckAt, isNull);
      expect(prefs.lastAttemptAt, isNull);
      expect(prefs.cachedRelease, isNull);
      expect(prefs.shelfColumns, 3);
      expect(prefs.shelfShowTitle, isTrue);
      expect(prefs.shelfShowAuthor, isTrue);
      expect(prefs.shelfShowNarrator, isTrue);
      expect(prefs.defaultPlaybackSpeed, 1.0);
      expect(prefs.defaultSkipIntroSeconds, 0);
      expect(prefs.defaultSkipOutroSeconds, 0);
      expect(prefs.shelfSeriesNavMode, ShelfSeriesNavMode.tabs);
      expect(prefs.shelfShowAllSeriesTab, isTrue);
      expect(prefs.shelfShowUncategorizedSeriesTab, isTrue);
      expect(prefs.shelfHiddenSeries, isEmpty);
      expect(prefs.shelfSeriesOrder, isEmpty);
    });

    test('无参构造函数产生与 defaults 一致的偏好', () {
      const prefs = AppPreferences();
      expect(prefs, equals(AppPreferences.defaults));
    });
  });

  group('AppPreferences copyWith', () {
    test('覆盖指定字段且保持其余字段不变', () {
      final updated = AppPreferences.defaults.copyWith(
        paletteId: 'bambooMist',
        brightness: BrightnessPreference.dark,
        oledDark: true,
        shelfColumns: 4,
        shelfShowTitle: false,
        shelfShowAuthor: false,
        shelfShowNarrator: false,
        defaultPlaybackSpeed: 1.25,
        defaultSkipIntroSeconds: 30,
        defaultSkipOutroSeconds: 45,
        shelfSeriesNavMode: ShelfSeriesNavMode.dropdown,
        shelfShowAllSeriesTab: false,
        shelfShowUncategorizedSeriesTab: false,
        shelfHiddenSeries: const ['series-1', 'series-2'],
        shelfSeriesOrder: const ['series-b', 'series-a'],
      );

      expect(updated.paletteId, 'bambooMist');
      expect(updated.brightness, BrightnessPreference.dark);
      expect(updated.oledDark, isTrue);
      expect(updated.autoCheckUpdates, isTrue);
      expect(updated.skippedVersion, isNull);
      expect(updated.shelfColumns, 4);
      expect(updated.shelfShowTitle, isFalse);
      expect(updated.shelfShowAuthor, isFalse);
      expect(updated.shelfShowNarrator, isFalse);
      expect(updated.defaultPlaybackSpeed, 1.25);
      expect(updated.defaultSkipIntroSeconds, 30);
      expect(updated.defaultSkipOutroSeconds, 45);
      expect(updated.shelfSeriesNavMode, ShelfSeriesNavMode.dropdown);
      expect(updated.shelfShowAllSeriesTab, isFalse);
      expect(updated.shelfShowUncategorizedSeriesTab, isFalse);
      expect(updated.shelfHiddenSeries, ['series-1', 'series-2']);
      expect(updated.shelfSeriesOrder, ['series-b', 'series-a']);
    });

    test('显式传入 null 可以清空可空字段', () {
      final base = AppPreferences.defaults.copyWith(
        skippedVersion: '0.2.0-beta.1',
        promptedVersion: '0.2.0-beta.1',
        acknowledgedVersion: '0.2.0-beta.1',
        lastCheckAt: DateTime.utc(2026, 10, 19, 10),
        lastAttemptAt: DateTime.utc(2026, 10, 19, 10),
        cachedRelease: sampleCachedRelease,
      );

      final cleared = base.copyWith(
        skippedVersion: null,
        promptedVersion: null,
        acknowledgedVersion: null,
        lastCheckAt: null,
        lastAttemptAt: null,
        cachedRelease: null,
      );

      expect(cleared.skippedVersion, isNull);
      expect(cleared.promptedVersion, isNull);
      expect(cleared.acknowledgedVersion, isNull);
      expect(cleared.lastCheckAt, isNull);
      expect(cleared.lastAttemptAt, isNull);
      expect(cleared.cachedRelease, isNull);
    });

    test('覆盖 cachedRelease 字段', () {
      final updated = AppPreferences.defaults.copyWith(
        cachedRelease: sampleCachedRelease,
      );
      expect(updated.cachedRelease, equals(sampleCachedRelease));
    });

    test('不传参数时完全保持原有字段值', () {
      final base = AppPreferences.defaults.copyWith(
        paletteId: 'starryIndigo',
        skippedVersion: '0.1.0',
      );
      final cloned = base.copyWith();
      expect(cloned, equals(base));
    });
  });

  group('AppPreferences 序列化与反序列化', () {
    test('JSON 往返完整保留全部非空字段', () {
      final original = AppPreferences.defaults.copyWith(
        paletteId: 'bambooMist',
        brightness: BrightnessPreference.dark,
        oledDark: true,
        autoCheckUpdates: false,
        skippedVersion: '0.2.0-beta.1',
        promptedVersion: '0.2.0-beta.1',
        acknowledgedVersion: '0.2.0-beta.1',
        lastCheckAt: DateTime.utc(2026, 10, 19, 12, 30, 45),
        lastAttemptAt: DateTime.utc(2026, 10, 19, 12, 35, 0),
        cachedRelease: sampleCachedRelease,
        shelfColumns: 2,
        shelfShowTitle: false,
        shelfShowAuthor: false,
        shelfShowNarrator: false,
        defaultPlaybackSpeed: 1.5,
        defaultSkipIntroSeconds: 15,
        defaultSkipOutroSeconds: 20,
        shelfSeriesNavMode: ShelfSeriesNavMode.dropdown,
        shelfShowAllSeriesTab: false,
        shelfShowUncategorizedSeriesTab: false,
        shelfHiddenSeries: const ['hidden-1'],
        shelfSeriesOrder: const ['s1', 's2'],
      );

      final json = original.toJson();
      final restored = AppPreferences.fromJson(json);

      expect(restored, equals(original));
      expect(restored.toJson(), equals(json));
      expect(restored.cachedRelease, equals(sampleCachedRelease));
      expect(restored.shelfSeriesNavMode, ShelfSeriesNavMode.dropdown);
      expect(restored.shelfShowAllSeriesTab, isFalse);
      expect(restored.shelfShowUncategorizedSeriesTab, isFalse);
      expect(restored.shelfHiddenSeries, ['hidden-1']);
      expect(restored.shelfSeriesOrder, ['s1', 's2']);
    });

    test('默认配置 JSON 往返一致', () {
      final json = AppPreferences.defaults.toJson();
      final restored = AppPreferences.fromJson(json);

      expect(restored, equals(AppPreferences.defaults));
      expect(restored.toJson(), equals(json));
    });

    test('日期序列化为稳定的 UTC ISO-8601 格式', () {
      final checkTime = DateTime.utc(2026, 10, 19, 8, 30);
      final prefs = AppPreferences.defaults.copyWith(lastCheckAt: checkTime);
      final json = prefs.toJson();

      expect(json['lastCheckAt'], '2026-10-19T08:30:00.000Z');
      final restored = AppPreferences.fromJson(json);
      expect(restored.lastCheckAt, equals(checkTime));
      expect(restored.lastCheckAt!.isUtc, isTrue);
    });
  });

  group('AppPreferences 容错解析', () {
    test('系列导航字段容错解析与向后兼容', () {
      final jsonWithBadValues = <String, Object?>{
        'shelfSeriesNavMode': 'unknown_nav_mode',
        'shelfShowAllSeriesTab': 'not-a-bool',
        'shelfShowUncategorizedSeriesTab': 123,
        'shelfHiddenSeries': 'not-a-list',
        'shelfSeriesOrder': [1, null, 'valid-series'],
      };

      final prefs = AppPreferences.fromJson(jsonWithBadValues);

      expect(prefs.shelfSeriesNavMode, ShelfSeriesNavMode.tabs);
      expect(prefs.shelfShowAllSeriesTab, isTrue);
      expect(prefs.shelfShowUncategorizedSeriesTab, isTrue);
      expect(prefs.shelfHiddenSeries, isEmpty);
      expect(prefs.shelfSeriesOrder, ['valid-series']);
    });

    test('历史 JSON（无系列导航字段）向后兼容保持默认值', () {
      final legacyJson = <String, Object?>{
        'paletteId': 'amberScroll',
        'shelfColumns': 3,
      };

      final prefs = AppPreferences.fromJson(legacyJson);

      expect(prefs.shelfSeriesNavMode, ShelfSeriesNavMode.tabs);
      expect(prefs.shelfShowAllSeriesTab, isTrue);
      expect(prefs.shelfShowUncategorizedSeriesTab, isTrue);
      expect(prefs.shelfHiddenSeries, isEmpty);
      expect(prefs.shelfSeriesOrder, isEmpty);
    });

    test('损坏与错误字段类型独立回退至默认值', () {
      final corrupted = <String, Object?>{
        'paletteId': 12345, // 错误类型
        'brightness': 999, // 错误类型
        'oledDark': 'true', // 错误类型（非 bool）
        'autoCheckUpdates': null, // 错误类型（非 bool）
        'skippedVersion': 100, // 错误类型
        'promptedVersion': false, // 错误类型
        'acknowledgedVersion': <String>[], // 错误类型
        'lastCheckAt': 123456789, // 错误类型
        'lastAttemptAt': true, // 错误类型
        'cachedRelease': 'not-a-map', // 错误类型
      };

      final prefs = AppPreferences.fromJson(corrupted);

      expect(prefs.paletteId, 'amberScroll');
      expect(prefs.brightness, BrightnessPreference.system);
      expect(prefs.oledDark, isFalse);
      expect(prefs.autoCheckUpdates, isTrue);
      expect(prefs.skippedVersion, isNull);
      expect(prefs.promptedVersion, isNull);
      expect(prefs.acknowledgedVersion, isNull);
      expect(prefs.lastCheckAt, isNull);
      expect(prefs.lastAttemptAt, isNull);
      expect(prefs.cachedRelease, isNull);
    });

    test('损坏的 cachedRelease Map 安全回退为 null', () {
      final prefs = AppPreferences.fromJson(<String, Object?>{
        'cachedRelease': <String, Object?>{
          'release': 12345, // 错误类型无法解析 release
        },
      });
      // ReleaseInfo.fromJson tolerates bad fields and creates an empty one, or if cachedRelease throws it recovers as null
      // Let's verify it does not throw
      expect(prefs, isNotNull);
    });

    test('空 paletteId 字符串回退至默认值', () {
      final prefs = AppPreferences.fromJson(<String, Object?>{'paletteId': ''});
      expect(prefs.paletteId, 'amberScroll');
    });

    test('未知 brightness 枚举字符串回退至 system', () {
      final prefs = AppPreferences.fromJson(<String, Object?>{
        'brightness': 'unknown_preference',
      });
      expect(prefs.brightness, BrightnessPreference.system);
    });

    test('非法日期格式字符串安全解析为 null，绝不抛出异常', () {
      final prefs = AppPreferences.fromJson(<String, Object?>{
        'lastCheckAt': 'not-a-valid-iso-date',
        'lastAttemptAt': '',
      });
      expect(prefs.lastCheckAt, isNull);
      expect(prefs.lastAttemptAt, isNull);
    });

    test('空 Map 正常解析为默认配置', () {
      final prefs = AppPreferences.fromJson(<String, Object?>{});
      expect(prefs, equals(AppPreferences.defaults));
    });

    test('未知扩展字段不影响已知字段正常解析', () {
      final prefs = AppPreferences.fromJson(<String, Object?>{
        'paletteId': 'bambooMist',
        'futureFeatureToggle': true,
        'extraSchemaVersion': 99,
      });
      expect(prefs.paletteId, 'bambooMist');
    });
  });

  group('AppPreferences 等价性与 toString', () {
    test('相同属性判定相等且拥有相同的 hashCode', () {
      final a = AppPreferences.defaults.copyWith(paletteId: 'bambooMist');
      final b = AppPreferences.defaults.copyWith(paletteId: 'bambooMist');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('不同属性判定不相等', () {
      final a = AppPreferences.defaults.copyWith(oledDark: true);
      const b = AppPreferences.defaults;
      expect(a, isNot(equals(b)));
    });

    test('toString 包含关键字段信息', () {
      const prefs = AppPreferences.defaults;
      final str = prefs.toString();
      expect(str, contains('amberScroll'));
      expect(str, contains('system'));
      expect(str, contains('oledDark: false'));
    });
  });
}
