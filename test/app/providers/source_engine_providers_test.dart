import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/sources/legado/legado_source_engine.dart';
import 'package:tometone/app/sources/legado/restricted_js_runtime.dart';
import 'package:tometone/app/sources/source_discovery.dart';
import 'package:tometone/app/sources/source_rate_limiter.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';
import 'package:tometone/contracts/sources/source_http.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';

void main() {
  test('缺少 HTTP override 时读取 sourceEngineProvider 抛错', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(sourceEngineProvider),
      throwsA(
        isA<ProviderException>().having(
          (ProviderException error) => error.exception,
          'exception',
          isA<ProviderException>().having(
            (ProviderException error) => error.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      ),
    );
  });

  test('provider 组合 HTTP、JS、限速器与发现服务', () {
    final db = TomeToneDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final http = _FakeSourceHttpClient();
    final js = _FakeJsRuntime();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sourceHttpClientProvider.overrideWithValue(http),
        jsRuntimeProvider.overrideWithValue(js),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(sourceHttpClientProvider), same(http));
    expect(container.read(jsRuntimeProvider), same(js));
    expect(container.read(sourceRateLimiterProvider), isA<SourceRateLimiter>());
    expect(container.read(sourceEngineProvider), isA<LegadoSourceEngine>());
    expect(
      container.read(sourceDiscoveryProvider),
      isA<SourceDiscoveryService>(),
    );
  });

  test('jsRuntimeProvider 默认使用受限运行时', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(jsRuntimeProvider), isA<RestrictedJsRuntime>());
  });

  test('selectedSourceIdProvider 默认空并可切换', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(selectedSourceIdProvider), isNull);

    container.read(selectedSourceIdProvider.notifier).state = 'source-1';
    expect(container.read(selectedSourceIdProvider), 'source-1');
  });
}

class _FakeSourceHttpClient implements SourceHttpClient {
  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) {
    throw UnimplementedError();
  }
}

class _FakeJsRuntime implements JsRuntime {
  @override
  Future<Object?> evaluate(String script, JsContext context) async => null;

  @override
  Future<void> dispose() async {}
}
