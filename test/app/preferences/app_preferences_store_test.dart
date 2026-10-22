import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';
import 'package:tometone/app/providers/preferences_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryAppPreferencesStore', () {
    test('初始状态为默认配置且 saveCount 为 0', () async {
      final store = InMemoryAppPreferencesStore();
      expect(await store.load(), equals(AppPreferences.defaults));
      expect(store.saveCount, 0);
      expect(store.current, equals(AppPreferences.defaults));
    });

    test('支持自定义初始配置', () async {
      final initial = AppPreferences.defaults.copyWith(paletteId: 'bambooMist');
      final store = InMemoryAppPreferencesStore(initial);
      expect(await store.load(), equals(initial));
      expect(store.current.paletteId, 'bambooMist');
      expect(store.saveCount, 0);
    });

    test('保存后可正确读回，且 saveCount 递增', () async {
      final store = InMemoryAppPreferencesStore();
      final updated = AppPreferences.defaults.copyWith(
        paletteId: 'starryIndigo',
        oledDark: true,
      );

      await store.save(updated);
      expect(await store.load(), equals(updated));
      expect(store.current, equals(updated));
      expect(store.saveCount, 1);

      await store.save(updated.copyWith(brightness: BrightnessPreference.dark));
      expect(store.saveCount, 2);
    });
  });

  group('SharedPreferencesAppPreferencesStore', () {
    test('初次读取无存储数据时回退到默认配置', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = SharedPreferencesAppPreferencesStore();

      final prefs = await store.load();
      expect(prefs, equals(AppPreferences.defaults));
    });

    test('持久化写入与读取往返一致，底层键名为 tometone.preferences.v1', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = SharedPreferencesAppPreferencesStore();

      final target = AppPreferences.defaults.copyWith(
        paletteId: 'duskAloeswood',
        brightness: BrightnessPreference.dark,
        oledDark: true,
        autoCheckUpdates: false,
        skippedVersion: '0.2.0',
        lastCheckAt: DateTime.utc(2026, 10, 20, 10),
      );

      await store.save(target);

      final loaded = await store.load();
      expect(loaded, equals(target));

      // 验证底层 SharedPreferences 中的 JSON 内容
      final rawPrefs = await SharedPreferences.getInstance();
      final storedJsonString = rawPrefs.getString(
        SharedPreferencesAppPreferencesStore.preferencesKey,
      );
      expect(storedJsonString, isNotNull);
      final decoded = jsonDecode(storedJsonString!) as Map<String, dynamic>;
      expect(decoded['paletteId'], 'duskAloeswood');
      expect(decoded['brightness'], 'dark');
      expect(decoded['oledDark'], isTrue);
      expect(decoded['skippedVersion'], '0.2.0');
    });

    test('支持在构造函数中显式传入 SharedPreferences 实例', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final mockPrefs = await SharedPreferences.getInstance();
      final store = SharedPreferencesAppPreferencesStore(mockPrefs);

      await store.save(
        AppPreferences.defaults.copyWith(paletteId: 'shandanRed'),
      );
      final loaded = await store.load();
      expect(loaded.paletteId, 'shandanRed');
    });

    test('数据损坏为非合法 JSON 时优雅降级为默认配置，不抛异常', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesAppPreferencesStore.preferencesKey:
            '{invalid_json_format_here...',
      });
      final store = SharedPreferencesAppPreferencesStore();

      final prefs = await store.load();
      expect(prefs, equals(AppPreferences.defaults));
    });

    test('数据存储为空字符串或非 Map 的 JSON 时降级为默认配置', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesAppPreferencesStore.preferencesKey: '',
      });
      final store1 = SharedPreferencesAppPreferencesStore();
      expect(await store1.load(), equals(AppPreferences.defaults));

      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesAppPreferencesStore.preferencesKey: '12345',
      });
      final store2 = SharedPreferencesAppPreferencesStore();
      expect(await store2.load(), equals(AppPreferences.defaults));

      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesAppPreferencesStore.preferencesKey: '["a", "b"]',
      });
      final store3 = SharedPreferencesAppPreferencesStore();
      expect(await store3.load(), equals(AppPreferences.defaults));
    });

    test('部分字段损坏时独立容错，合法字段正常读取', () async {
      final partiallyCorruptedJson = jsonEncode(<String, Object?>{
        'paletteId': 'bambooMist',
        'brightness': 999, // 损坏枚举
        'oledDark': 'not-a-bool', // 损坏布尔
      });
      SharedPreferences.setMockInitialValues(<String, Object>{
        SharedPreferencesAppPreferencesStore.preferencesKey:
            partiallyCorruptedJson,
      });

      final store = SharedPreferencesAppPreferencesStore();
      final prefs = await store.load();

      expect(prefs.paletteId, 'bambooMist');
      expect(prefs.brightness, BrightnessPreference.system);
      expect(prefs.oledDark, isFalse);
    });
  });

  group('Preferences Providers 与 Notifier', () {
    test('未 override 依赖时抛出 UnimplementedError', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(preferencesStoreProvider),
        throwsA(
          isA<ProviderException>().having(
            (ProviderException error) => error.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
      expect(
        () => container.read(initialPreferencesProvider),
        throwsA(
          isA<ProviderException>().having(
            (ProviderException error) => error.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });

    test('update 能够同步更新状态并异步持久化', () async {
      final store = InMemoryAppPreferencesStore();
      const initial = AppPreferences.defaults;

      final container = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(store),
          initialPreferencesProvider.overrideWithValue(initial),
        ],
      );
      addTearDown(container.dispose);

      // 读取初始状态
      expect(container.read(preferencesProvider), equals(initial));

      // 执行 update
      container
          .read(preferencesProvider.notifier)
          .update((current) => current.copyWith(paletteId: 'bambooMist'));

      // 状态立即同步变更
      expect(
        container.read(preferencesProvider).paletteId,
        equals('bambooMist'),
      );

      // 等待异步持久化完成
      await Future<void>.delayed(Duration.zero);
      expect(store.saveCount, 1);
      expect(store.current.paletteId, equals('bambooMist'));
    });

    test('replace 能够替换状态并异步持久化', () async {
      final store = InMemoryAppPreferencesStore();
      const initial = AppPreferences.defaults;

      final container = ProviderContainer(
        overrides: [
          preferencesStoreProvider.overrideWithValue(store),
          initialPreferencesProvider.overrideWithValue(initial),
        ],
      );
      addTearDown(container.dispose);

      final next = AppPreferences.defaults.copyWith(
        paletteId: 'shandanRed',
        oledDark: true,
      );

      container.read(preferencesProvider.notifier).replace(next);

      expect(container.read(preferencesProvider), equals(next));

      await Future<void>.delayed(Duration.zero);
      expect(store.saveCount, 1);
      expect(store.current, equals(next));
    });
  });
}
