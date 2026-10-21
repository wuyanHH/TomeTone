import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/sources/source_http.dart';
import 'package:tometone/modules/source_http/io_source_http_client.dart';

Future<HttpServer> _startServer(
  Future<void> Function(HttpRequest request) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    try {
      await handler(request);
    } on Object {
      // 测试 handler 的异常不应变成未处理异步异常；由断言负责暴露。
    }
  });
  return server;
}

String _base(HttpServer server) =>
    'http://${server.address.host}:${server.port}';

Map<String, String> _headers(HttpHeaders headers) {
  final result = <String, String>{};
  headers.forEach((name, values) {
    result[name.toLowerCase()] = values.join(',');
  });
  return result;
}

Future<String> _body(HttpRequest request) => utf8.decoder.bind(request).join();

void main() {
  group('IoSourceHttpClient', () {
    test('GET 保留请求头并返回状态、最终 URL 与响应头', () async {
      late Map<String, String> receivedHeaders;
      final server = await _startServer((request) async {
        receivedHeaders = _headers(request.headers);
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.set('x-final', 'yes')
          ..write('ok');
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final client = IoSourceHttpClient();
      final response = await client.send(
        SourceHttpRequest(
          url: Uri.parse('${_base(server)}/hello'),
          headers: const <String, String>{'X-Test': 'v'},
        ),
      );

      expect(response.statusCode, 200);
      expect(utf8.decode(response.bytes), 'ok');
      expect(response.finalUrl.path, '/hello');
      expect(response.headers['x-final'], 'yes');
      expect(receivedHeaders['x-test'], 'v');
    });

    test('POST 发送 UTF-8 body', () async {
      late String received;
      final server = await _startServer((request) async {
        received = await _body(request);
        request.response.write('got:$received');
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final client = IoSourceHttpClient();

      final response = await client.send(
        SourceHttpRequest(
          url: Uri.parse('${_base(server)}/post'),
          method: 'POST',
          headers: const <String, String>{'content-type': 'application/json'},
          body: '{"q":"中文"}',
        ),
      );

      expect(received, '{"q":"中文"}');
      expect(utf8.decode(response.bytes), 'got:{"q":"中文"}');
    });

    test('307 保留 POST 方法与 body', () async {
      var nextMethod = '';
      var nextBody = '';
      final server = await _startServer((request) async {
        if (request.uri.path == '/start') {
          request.response
            ..statusCode = HttpStatus.temporaryRedirect
            ..headers.set(HttpHeaders.locationHeader, '/next');
          await request.response.close();
          return;
        }
        nextMethod = request.method;
        nextBody = await _body(request);
        request.response.write('$nextMethod:$nextBody');
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final client = IoSourceHttpClient();

      final response = await client.send(
        SourceHttpRequest(
          url: Uri.parse('${_base(server)}/start'),
          method: 'POST',
          body: 'a=1',
        ),
      );

      expect(response.statusCode, 200);
      expect(nextMethod, 'POST');
      expect(nextBody, 'a=1');
    });

    test('302 改为 GET 并丢弃 body', () async {
      var nextMethod = '';
      var nextHasBody = true;
      final server = await _startServer((request) async {
        if (request.uri.path == '/start') {
          request.response
            ..statusCode = HttpStatus.found
            ..headers.set(HttpHeaders.locationHeader, '/next');
          await request.response.close();
          return;
        }
        nextMethod = request.method;
        nextHasBody = (await _body(request)).isNotEmpty;
        request.response.write('ok');
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final client = IoSourceHttpClient();

      await client.send(
        SourceHttpRequest(
          url: Uri.parse('${_base(server)}/start'),
          method: 'POST',
          body: 'a=1',
        ),
      );

      expect(nextMethod, 'GET');
      expect(nextHasBody, isFalse);
    });

    test('跨源重定向只保留安全请求头', () async {
      late Map<String, String> targetHeaders;
      final target = await _startServer((request) async {
        targetHeaders = _headers(request.headers);
        request.response.write('ok');
        await request.response.close();
      });
      addTearDown(() => target.close(force: true));
      final source = await _startServer((request) async {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '${_base(target)}/target');
        await request.response.close();
      });
      addTearDown(() => source.close(force: true));
      final client = IoSourceHttpClient();

      await client.send(
        SourceHttpRequest(
          url: Uri.parse('${_base(source)}/start'),
          headers: const <String, String>{
            'Authorization': 'Bearer secret',
            'Cookie': 'session=1',
            'X-Custom': 'drop',
            'Accept': 'application/json',
            'Accept-Language': 'zh-CN',
            'User-Agent': 'TomeTone-test',
          },
        ),
      );

      expect(targetHeaders['authorization'], isNull);
      expect(targetHeaders['cookie'], isNull);
      expect(targetHeaders['x-custom'], isNull);
      expect(targetHeaders['accept'], 'application/json');
      expect(targetHeaders['accept-language'], 'zh-CN');
      expect(targetHeaders['user-agent'], 'TomeTone-test');
    });

    test('最多跟随 5 跳，超过抛 redirect', () async {
      final server = await _startServer((request) async {
        final index = int.parse(request.uri.path.substring(1));
        if (index < 6) {
          request.response
            ..statusCode = HttpStatus.found
            ..headers.set(HttpHeaders.locationHeader, '/${index + 1}');
        } else {
          request.response.write('done');
        }
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final client = IoSourceHttpClient();

      await expectLater(
        client.send(SourceHttpRequest(url: Uri.parse('${_base(server)}/0'))),
        throwsA(
          isA<SourceTransportException>().having(
            (error) => error.failure,
            'failure',
            SourceTransportFailure.redirect,
          ),
        ),
      );
    });

    test('响应超过 maxBytes 抛 tooLarge', () async {
      final server = await _startServer((request) async {
        request.response.write('x' * 100);
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final client = IoSourceHttpClient(maxBytes: 10);

      await expectLater(
        client.send(SourceHttpRequest(url: Uri.parse('${_base(server)}/big'))),
        throwsA(
          isA<SourceTransportException>().having(
            (error) => error.failure,
            'failure',
            SourceTransportFailure.tooLarge,
          ),
        ),
      );
    });

    test('请求超时抛 timeout', () async {
      final server = await _startServer((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        request.response.write('late');
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final client = IoSourceHttpClient();

      await expectLater(
        client.send(
          SourceHttpRequest(
            url: Uri.parse('${_base(server)}/slow'),
            timeout: const Duration(milliseconds: 50),
          ),
        ),
        throwsA(
          isA<SourceTransportException>().having(
            (error) => error.failure,
            'failure',
            SourceTransportFailure.timeout,
          ),
        ),
      );
    });

    test('非 http(s) 或缺少 host 抛 invalidUrl', () async {
      final client = IoSourceHttpClient();
      await expectLater(
        client.send(SourceHttpRequest(url: Uri.parse('ftp://e.test/a'))),
        throwsA(
          isA<SourceTransportException>().having(
            (error) => error.failure,
            'failure',
            SourceTransportFailure.invalidUrl,
          ),
        ),
      );
      await expectLater(
        client.send(SourceHttpRequest(url: Uri.parse('http:///a'))),
        throwsA(
          isA<SourceTransportException>().having(
            (error) => error.failure,
            'failure',
            SourceTransportFailure.invalidUrl,
          ),
        ),
      );
    });

    test('4xx 不抛异常，交给上层处理', () async {
      final server = await _startServer((request) async {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('missing');
        await request.response.close();
      });
      addTearDown(() => server.close(force: true));
      final client = IoSourceHttpClient();

      final response = await client.send(
        SourceHttpRequest(url: Uri.parse('${_base(server)}/404')),
      );

      expect(response.statusCode, 404);
      expect(utf8.decode(response.bytes), 'missing');
    });
  });
}
