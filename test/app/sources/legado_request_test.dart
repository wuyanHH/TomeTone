import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/legado_request.dart';

const _base = 'https://e.test/api/';

LegadoRequest _build(
  String raw, {
  Map<String, String> sourceHeaders = const <String, String>{},
  String? key,
  int? page,
  String? defaultCharset,
}) {
  return const LegadoRequestBuilder().build(
    raw: raw,
    baseUrl: Uri.parse(_base),
    sourceHeaders: sourceHeaders,
    key: key,
    page: page,
    defaultCharset: defaultCharset,
  );
}

void main() {
  group('LegadoRequestBuilder', () {
    test('缺 options 时默认 GET，URL 模板支持 page/key', () {
      final request = _build(
        'search?q={{key}}&page={{page}}',
        key: 'a&b 中文',
        page: 2,
      );

      expect(request.method, 'GET');
      expect(request.body, isNull);
      expect(
        request.url.toString(),
        'https://e.test/api/search?q=a%26b%20%E4%B8%AD%E6%96%87&page=2',
      );
    });

    test('POST JSON body 中的引号、& 与中文仍可 jsonDecode', () {
      final raw =
          'search,${jsonEncode(<String, Object?>{
            'method': 'POST',
            'headers': <String, String>{'content-type': 'application/json'},
            'body': '{"q":"{{key}}"}',
          })}';
      final request = _build(raw, key: 'a"b&中文');

      expect(request.method, 'POST');
      expect(request.headers['content-type'], 'application/json');
      expect(jsonDecode(request.body!), <String, Object?>{'q': 'a"b&中文'});
    });

    test('相对路径先按 baseUrl 解析再规范化', () {
      final request = _build('../book/{{page}}', page: 3);

      expect(request.url.toString(), 'https://e.test/book/3');
    });

    test('headers 合并时 options 大小写不敏感覆盖 source', () {
      final raw =
          'search,${jsonEncode(<String, Object?>{
            'headers': <String, String>{'x-token': 'new', 'X-Extra': '{{key}}'},
          })}';
      final request = _build(
        raw,
        key: 'k',
        sourceHeaders: const <String, String>{
          'X-Token': 'old',
          'Accept': 'application/json',
        },
      );

      expect(request.headers['Accept'], 'application/json');
      expect(request.headers['X-Extra'], 'k');
      expect(
        request.headers.entries
            .where((entry) => entry.key.toLowerCase() == 'x-token')
            .single
            .value,
        'new',
      );
    });

    test('非法 options JSON 时整串当 URL', () {
      final request = _build('a,{not-json');

      expect(request.url.toString(), 'https://e.test/api/a,%7Bnot-json');
    });

    test('charset 透传，缺省时使用 defaultCharset', () {
      final withOptions = _build(
        'search,${jsonEncode(<String, Object?>{'charset': 'gbk'})}',
        defaultCharset: 'utf-8',
      );
      expect(withOptions.charset, 'gbk');

      final withoutOptions = _build('search', defaultCharset: 'utf-8');
      expect(withoutOptions.charset, 'utf-8');
    });

    test('有 body 但未显式 method 时仍是 GET', () {
      final request = _build(
        'search,${jsonEncode(<String, Object?>{'body': 'a=1'})}',
      );

      expect(request.method, 'GET');
      expect(request.body, 'a=1');
    });

    test('options 中的非字符串字段被忽略', () {
      final request = _build(
        'search,${jsonEncode(<String, Object?>{
          'method': 7,
          'headers': <String, Object?>{'X-Number': 1, 'X-Valid': 'v'},
          'charset': false,
        })}',
      );

      expect(request.method, 'GET');
      expect(request.headers, <String, String>{'X-Valid': 'v'});
      expect(request.charset, isNull);
    });

    test('builds request when body option is raw JSON map with placeholder interpolation', () {
      const raw =
          'https://api.example.com/search,{"method":"POST","headers":{"Content-Type":"application/json"},"body":{"keyword":"{{key}}","page":"{{page}}"}}';
      final req = const LegadoRequestBuilder().build(
        raw: raw,
        baseUrl: Uri.parse('https://api.example.com'),
        sourceHeaders: const {},
        key: '遮天',
        page: 2,
      );
      expect(req.method, 'POST');
      expect(jsonDecode(req.body!), {'keyword': '遮天', 'page': 2});
    });
  });
}
