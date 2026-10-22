import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/preferences/app_preferences_store.dart';

/// 偏好存储 Provider，装配层必须覆盖。
final Provider<AppPreferencesStore> preferencesStoreProvider =
    Provider<AppPreferencesStore>((Ref ref) {
  throw UnimplementedError('preferencesStoreProvider must be overridden');
});

/// 初始偏好 Provider，装配层必须覆盖。
final Provider<AppPreferences> initialPreferencesProvider =
    Provider<AppPreferences>((Ref ref) {
  throw UnimplementedError('initialPreferencesProvider must be overridden');
});

/// 应用偏好 Notifier。
class PreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => ref.watch(initialPreferencesProvider);

  /// 更新偏好并异步持久化。
  void update(AppPreferences Function(AppPreferences current) updater) {
    state = updater(state);
    unawaited(ref.read(preferencesStoreProvider).save(state));
  }

  /// 替换偏好并异步持久化。
  void replace(AppPreferences preferences) {
    state = preferences;
    unawaited(ref.read(preferencesStoreProvider).save(preferences));
  }
}

/// 全局偏好 Provider。
final NotifierProvider<PreferencesNotifier, AppPreferences> preferencesProvider =
    NotifierProvider<PreferencesNotifier, AppPreferences>(
  PreferencesNotifier.new,
);
