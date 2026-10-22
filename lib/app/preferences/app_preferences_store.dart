import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tometone/app/preferences/app_preferences.dart';

/// 偏好存储抽象契约接口。
abstract interface class AppPreferencesStore {
  /// 读取偏好。
  Future<AppPreferences> load();

  /// 持久化保存偏好。
  Future<void> save(AppPreferences preferences);
}

/// 基于 [SharedPreferences] 的偏好持久化实现。
class SharedPreferencesAppPreferencesStore implements AppPreferencesStore {
  /// 偏好存储在 SharedPreferences 中的键。
  static const String preferencesKey = 'tometone.preferences.v1';

  /// 构造存储实现。
  ///
  /// 可传入既有 [SharedPreferences] 实例（如测试环境）；
  /// 若为 null，则在 [load] 或 [save] 时调用 [SharedPreferences.getInstance] 缓存实例。
  SharedPreferencesAppPreferencesStore([SharedPreferences? prefs])
      : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<AppPreferences> load() async {
    try {
      final prefs = await _getPrefs();
      final jsonString = prefs.getString(preferencesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return AppPreferences.defaults;
      }
      final Object? decoded = jsonDecode(jsonString);
      if (decoded is Map<String, Object?>) {
        return AppPreferences.fromJson(decoded);
      }
      if (decoded is Map) {
        return AppPreferences.fromJson(Map<String, Object?>.from(decoded));
      }
      return AppPreferences.defaults;
    } catch (_) {
      return AppPreferences.defaults;
    }
  }

  @override
  Future<void> save(AppPreferences preferences) async {
    try {
      final prefs = await _getPrefs();
      final jsonString = jsonEncode(preferences.toJson());
      await prefs.setString(preferencesKey, jsonString);
    } catch (_) {
      // 偏好保存失败容错，静默捕获不抛出
    }
  }
}

/// 基于内存的偏好存储实现，主要用于单元测试与内存环境。
class InMemoryAppPreferencesStore implements AppPreferencesStore {
  /// 构造内存存储实例。
  InMemoryAppPreferencesStore([AppPreferences? initial])
      : current = initial ?? AppPreferences.defaults;

  /// 内部当前保存的偏好。
  AppPreferences current;

  /// 记录 [save] 被调用的次数。
  int saveCount = 0;

  @override
  Future<AppPreferences> load() async => current;

  @override
  Future<void> save(AppPreferences preferences) async {
    current = preferences;
    saveCount++;
  }
}
