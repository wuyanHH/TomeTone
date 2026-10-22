import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/sources/source_import.dart';

const _fixturePath = 'test/fixtures/sources/tingyou/source.json';
const _parser = LegadoSourceImportParser();

Map<String, dynamic> _fixtureJson() {
  return jsonDecode(File(_fixturePath).readAsStringSync())
      as Map<String, dynamic>;
}

String _encode(Object value) => jsonEncode(value);

void main() {
  group('LegadoSourceImportParser', () {
    test('单对象合法源：字段、header、规范 URL 与 rawJson 保留', () {
      final result = _parser.parse(File(_fixturePath).readAsStringSync());

      expect(result.issues, isEmpty);
      final candidate = result.candidates.single;
      expect(candidate.index, 0);
      expect(candidate.draft.name, '听友听书');
      expect(candidate.draft.groupName, '听书');
      expect(candidate.draft.sourceType, 1);
      expect(candidate.draft.sourceUrl, 'https://www.tingyou.fm/');
      expect(candidate.draft.exploreUrl, contains('{{page}}'));
      expect(
        candidate.draft.searchUrl,
        'https://www.tingyou.fm/listening-api/search',
      );
      expect(candidate.draft.header['x-listening-session'], 'test-session');
      expect(candidate.draft.header['User-Agent'], 'TomeTone-Test');
      expect(candidate.draft.rawJson, contains('customUnknown'));
    });

    test('数组逐项解析：坏项进 issues，好项保留原索引', () {
      final good = _fixtureJson();
      final bad = _fixtureJson()..['bookSourceType'] = 0;

      final result = _parser.parse(_encode(<Map<String, dynamic>>[good, bad]));

      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.index, 0);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.index, 1);
      expect(result.issues.single.code, SourceImportErrorCode.unsupportedType);
    });

    test('header 支持 JSON 对象与空字符串', () {
      final objectHeader = _fixtureJson()
        ..['header'] = <String, String>{'X-Test': '1'};
      final objectResult = _parser.parse(_encode(objectHeader));
      expect(objectResult.candidates.single.draft.header, {'X-Test': '1'});

      final emptyHeader = _fixtureJson()..['header'] = '';
      final emptyResult = _parser.parse(_encode(emptyHeader));
      expect(emptyResult.candidates.single.draft.header, isEmpty);
    });

    test('bookSourceType 0 与缺失类型都拒绝', () {
      final typeZero = _fixtureJson()..['bookSourceType'] = 0;
      final zeroResult = _parser.parse(_encode(typeZero));
      expect(zeroResult.candidates, isEmpty);
      expect(
        zeroResult.issues.single.code,
        SourceImportErrorCode.unsupportedType,
      );

      final missingType = _fixtureJson()..remove('bookSourceType');
      final missingResult = _parser.parse(_encode(missingType));
      expect(missingResult.candidates, isEmpty);
      expect(
        missingResult.issues.single.code,
        SourceImportErrorCode.unsupportedType,
      );
    });

    test('数字字符串类型 1 兼容', () {
      final json = _fixtureJson()..['bookSourceType'] = '1';
      final result = _parser.parse(_encode(json));
      expect(result.candidates.single.draft.sourceType, 1);
    });

    test('没有 searchUrl 也没有 exploreUrl 时拒绝', () {
      final json = _fixtureJson()
        ..remove('searchUrl')
        ..remove('exploreUrl');
      final result = _parser.parse(_encode(json));

      expect(result.candidates, isEmpty);
      expect(
        result.issues.single.code,
        SourceImportErrorCode.noDiscoveryOrSearch,
      );
    });

    test('ruleToc 缺 chapterUrl 时 malformedRule', () {
      final json = _fixtureJson();
      final toc = Map<String, dynamic>.from(
        json['ruleToc'] as Map<String, dynamic>,
      )..remove('chapterUrl');
      json['ruleToc'] = toc;

      final result = _parser.parse(_encode(json));
      expect(result.candidates, isEmpty);
      expect(result.issues.single.code, SourceImportErrorCode.malformedRule);
    });

    test('有 exploreUrl 但无 ruleExplore 时，可从合法的 ruleSearch 继承并成功导入', () {
      final json = _fixtureJson()
        ..remove('ruleExplore');
      final result = _parser.parse(_encode(json));
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.draft.exploreUrl, isNotNull);
    });

    test('非 http(s) 书源 URL 拒绝', () {
      final json = _fixtureJson()
        ..['bookSourceUrl'] = 'file:///tmp/source.json';
      final result = _parser.parse(_encode(json));

      expect(result.candidates, isEmpty);
      expect(result.issues.single.code, SourceImportErrorCode.invalidUrl);
    });

    test('URL 规范化后用 sourceUrl 身份', () {
      final json = _fixtureJson()
        ..['bookSourceUrl'] = 'HTTPS://WWW.TINGYOU.FM:443/a/../b#frag';
      final result = _parser.parse(_encode(json));

      expect(
        result.candidates.single.draft.sourceUrl,
        'https://www.tingyou.fm/b',
      );
      expect(result.candidates.single.draft.rawJson, contains('HTTPS://'));
    });

    test('空数组与非法 JSON 分别报错', () {
      final empty = _parser.parse('[]');
      expect(empty.candidates, isEmpty);
      expect(empty.issues.single.code, SourceImportErrorCode.emptyBatch);

      final invalid = _parser.parse('{not json');
      expect(invalid.candidates, isEmpty);
      expect(invalid.issues.single.code, SourceImportErrorCode.invalidJson);
    });

    test('数组中的非对象项报 notObject 且不影响其他项', () {
      final result = _parser.parse('[1, ${_encode(_fixtureJson())}]');

      expect(result.candidates.single.index, 1);
      expect(result.issues.single.index, 0);
      expect(result.issues.single.code, SourceImportErrorCode.notObject);
    });
  });
}
