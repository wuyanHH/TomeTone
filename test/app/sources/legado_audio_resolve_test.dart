import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/legado_source_engine.dart';
import 'package:tometone/app/sources/source_rate_limiter.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';
import 'package:tometone/contracts/sources/source_http.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';

void main() {
  test('字符串 URL 按章响应最终 URL 解析', () async {
    final http = _FakeHttp((request) async {
      return _response(request.url, '{"play_url":"/audio/1.mp3"}');
    });

    final audio = await _engine(http).resolveAudio(_source(), _chapter());

    expect(audio.url, 'https://e.test/audio/1.mp3');
    expect(audio.headers, isEmpty);
    expect(http.requests.single.url.path, '/play/1');
  });

  test('JSON map 的 headers 覆盖源 header 与章 options header', () async {
    final http = _FakeHttp((request) async {
      return _response(
        request.url,
        '{"audio":{"url":"/a.mp3","headers":{"X-A":"content","X-Source":"override"}}}',
      );
    });
    final source = _source(
      rule: r'$.audio',
      headers: <String, String>{'X-Source': 'source', 'X-Keep': '1'},
    );
    final chapter = _chapter(
      rawUrl: 'https://e.test/play/1,{"headers":{"X-Chapter":"chapter"}}',
    );

    final audio = await _engine(http).resolveAudio(source, chapter);

    expect(audio.url, 'https://e.test/a.mp3');
    expect(audio.headers['X-Source'], 'override');
    expect(audio.headers['X-Chapter'], 'chapter');
    expect(audio.headers['X-Keep'], '1');
    expect(audio.headers['X-A'], 'content');
  });

  test('数组取第一段', () async {
    final http = _FakeHttp((request) async {
      return _response(request.url, '{"list":["/a.mp3","/b.mp3"]}');
    });

    final audio = await _engine(http)
        .resolveAudio(_source(rule: r'$.list'), _chapter());

    expect(audio.url, 'https://e.test/a.mp3');
  });

  test('VIP 章不发请求，抛 vipRequired', () async {
    final http = _FakeHttp((request) async {
      return _response(request.url, '{"play_url":"/a.mp3"}');
    });

    await expectLater(
      _engine(http).resolveAudio(_source(), _chapter(isVip: true)),
      throwsA(
        isA<SourceFailure>().having(
          (SourceFailure error) => error.kind,
          'kind',
          SourceFailureKind.vipRequired,
        ),
      ),
    );
    expect(http.requests, isEmpty);
  });

  test('403 映射 authRequired，非法 scheme 映射 rule，非 JSON 映射 json', () async {
    Future<SourceFailure> resolve(
      Future<SourceHttpResponse> Function(SourceHttpRequest) handler,
    ) async {
      try {
        await _engine(_FakeHttp(handler)).resolveAudio(_source(), _chapter());
        fail('应当失败');
      } on SourceFailure catch (failure) {
        return failure;
      }
    }

    expect(
      (await resolve(
        (request) async => _response(request.url, '{}', status: 403),
      )).kind,
      SourceFailureKind.authRequired,
    );
    expect(
      (await resolve(
        (request) async =>
            _response(request.url, '{"play_url":"javascript:alert(1)"}'),
      )).kind,
      SourceFailureKind.rule,
    );
    expect(
      (await resolve((request) async => _response(request.url, 'not json')))
          .kind,
      SourceFailureKind.json,
    );
  });
}

LegadoSourceEngine _engine(_FakeHttp http) {
  return LegadoSourceEngine(
    http: http,
    jsRuntime: _FakeJsRuntime(),
    rateLimiter: SourceRateLimiter(delay: (Duration _) async {}),
  );
}

BookSource _source({
  String rule = r'$.play_url',
  Map<String, String> headers = const <String, String>{},
}) {
  final raw = <String, Object?>{
    'ruleContent': <String, Object?>{'content': rule},
  };
  return BookSource(
    id: 'source-1',
    libraryRootId: 'root-1',
    name: '测试源',
    sourceUrl: 'https://e.test',
    sourceType: 1,
    rawJson: jsonEncode(raw),
    header: headers,
    enabled: true,
    enabledExplore: true,
    customOrder: 0,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

SourceChapter _chapter({String? rawUrl, bool isVip = false}) {
  return SourceChapter(
    index: 0,
    title: '第一章',
    rawUrl: rawUrl ?? 'https://e.test/play/1',
    url: 'https://e.test/play/1',
    isVip: isVip,
  );
}

class _FakeHttp implements SourceHttpClient {
  _FakeHttp(this.handler);

  final Future<SourceHttpResponse> Function(SourceHttpRequest request) handler;
  final List<SourceHttpRequest> requests = <SourceHttpRequest>[];

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    requests.add(request);
    return handler(request);
  }
}

class _FakeJsRuntime implements JsRuntime {
  @override
  Future<Object?> evaluate(String script, JsContext context) async {
    throw const JsRuntimeException('fixture 不需要 JS');
  }

  @override
  Future<void> dispose() async {}
}

SourceHttpResponse _response(Uri url, String body, {int status = 200}) {
  return SourceHttpResponse(
    finalUrl: url,
    statusCode: status,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
    bytes: Uint8List.fromList(utf8.encode(body)),
  );
}
