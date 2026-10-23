import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/restricted_js_runtime.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';
import 'package:tometone/contracts/sources/source_http.dart';

import '../../support/js_runtime_contract.dart';

class _FakeSourceHttpClient implements SourceHttpClient {
  _FakeSourceHttpClient(this.responses);

  final Map<Uri, String> responses;

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    final body = responses[request.url];
    if (body == null) {
      throw const SourceTransportException(
        SourceTransportFailure.invalidUrl,
        'Not found',
      );
    }
    return SourceHttpResponse(
      finalUrl: request.url,
      statusCode: 200,
      headers: const {'content-type': 'application/json'},
      bytes: Uint8List.fromList(utf8.encode(body)),
    );
  }
}

void main() {
  group('RestrictedJsRuntime', () {
    test('满足 JsRuntime 共享契约', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      await expectJsRuntimeContract(runtime);
    });

    test('复现附录 A 的字符串拼接与 match 表达式', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      const context = JsContext(
        result: <String, Object?>{'index': 7},
        baseUrl: 'https://www.tingyou.fm/api/chapters/123',
      );

      final value = await runtime.evaluate(
        "'https://www.tingyou.fm/play?album=' + "
        "baseUrl.match(/chapters\\/(\\d+)/)[1] + '&index=' + result.index",
        context,
      );

      expect(value, 'https://www.tingyou.fm/play?album=123&index=7');
    });

    test('evaluates multi-line script with var statements', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      const script = '''
        var albumId = baseUrl.match(/chapters\\/(\\d+)/)[1];
        'https://example.com/play?id=' + albumId + '&idx=' + result.index
      ''';
      final result = await runtime.evaluate(
        script,
        const JsContext(
          result: {'index': 5},
          baseUrl: 'https://example.com/chapters/12345',
        ),
      );
      expect(result, 'https://example.com/play?id=12345&idx=5');
    });

    test('evaluates for-loop with array push and Math.ceil', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      const script = '''
        var list = [];
        var total = Math.ceil(result.total / result.pageSize);
        for (var i = 2; i <= total; i++) {
          list.push(baseUrl + '&page=' + i);
        }
        list;
      ''';
      final result = await runtime.evaluate(
        script,
        const JsContext(
          result: {'total': 25, 'pageSize': 10},
          baseUrl: 'https://example.com/toc?id=1',
        ),
      );
      expect(result, [
        'https://example.com/toc?id=1&page=2',
        'https://example.com/toc?id=1&page=3',
      ]);
    });

    test('evaluates object literal, array methods and JSON.stringify', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      const script = '''
        sort = [];
        sort.push({title: '玄幻', url: '/xh_{{page}}', style: {layout_flexGrow: 1}});
        sort.push({title: '都市', url: '/ds_{{page}}'});
        JSON.stringify(sort);
      ''';
      final result = await runtime.evaluate(
        script,
        const JsContext(result: null, baseUrl: 'https://example.com'),
      );
      expect(result, isA<String>());
      expect(jsonDecode(result as String), [
        {'title': '玄幻', 'url': '/xh_{{page}}', 'style': {'layout_flexGrow': 1}},
        {'title': '都市', 'url': '/ds_{{page}}'},
      ]);
    });

    test('supports java.get/put and source.get/put variables', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      final vars = <String, Object?>{'initial': 'val'};
      const script = '''
        var prev = java.get('initial');
        java.put('entityType', 2);
        source.put('custom', 'saved');
        prev;
      ''';
      final result = await runtime.evaluate(
        script,
        JsContext(result: null, baseUrl: '', variables: vars),
      );
      expect(result, 'val');
      expect(vars['entityType'], 2);
      expect(vars['custom'], 'saved');
    });

    test('supports java.ajax via context.http', () async {
      final runtime = RestrictedJsRuntime();
      addTearDown(runtime.dispose);
      final mockHttp = _FakeSourceHttpClient({
        Uri.parse('https://api.example.com/data'): '{"status": "ok", "code": 200}',
      });
      const script = '''
        var raw = java.ajax('https://api.example.com/data');
        var parsed = JSON.parse(raw);
        parsed.code;
      ''';
      final result = await runtime.evaluate(
        script,
        JsContext(result: null, baseUrl: '', http: mockHttp),
      );
      expect(result, 200);
    });
  });
}
