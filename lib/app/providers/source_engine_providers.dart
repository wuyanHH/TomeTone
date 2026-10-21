import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/app/sources/legado/legado_source_engine.dart';
import 'package:tometone/app/sources/legado/restricted_js_runtime.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/app/sources/source_engine.dart';
import 'package:tometone/app/sources/source_rate_limiter.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';
import 'package:tometone/contracts/sources/source_http.dart';

/// 书源 HTTP 客户端。**必须**在 `main.dart` 中 override。
final Provider<SourceHttpClient> sourceHttpClientProvider =
    Provider<SourceHttpClient>(
      (Ref ref) => throw UnimplementedError('未装配 HTTP 客户端'),
    );

/// JS 运行时。默认使用受限求值器；设备级 QuickJS 可通过 override 替换。
final Provider<JsRuntime> jsRuntimeProvider = Provider<JsRuntime>(
  (Ref ref) => RestrictedJsRuntime(),
);

/// 按书源串行放行的限速器。
final Provider<SourceRateLimiter> sourceRateLimiterProvider =
    Provider<SourceRateLimiter>((Ref ref) => SourceRateLimiter());

/// Legado 听书源引擎。
final Provider<SourceEngine> sourceEngineProvider = Provider<SourceEngine>((
  Ref ref,
) {
  return LegadoSourceEngine(
    http: ref.watch(sourceHttpClientProvider),
    jsRuntime: ref.watch(jsRuntimeProvider),
    rateLimiter: ref.watch(sourceRateLimiterProvider),
  );
});

/// 带源健康记录的发现编排。
final Provider<SourceDiscovery> sourceDiscoveryProvider =
    Provider<SourceDiscovery>((Ref ref) {
      return SourceDiscoveryService(
        engine: ref.watch(sourceEngineProvider),
        sources: ref.watch(bookSourceQueriesProvider),
      );
    });

/// 发现页当前选中的书源；空值表示尚未选择，由发现页回退到首个可用源。
final StateProvider<String?> selectedSourceIdProvider = StateProvider<String?>(
  (Ref ref) => null,
);
