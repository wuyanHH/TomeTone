import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/legado_source_rules.dart';
import 'package:tometone/app/sources/source_rate_limiter.dart';
import 'package:tometone/domain/sources/book_source.dart';

BookSource _source(Map<String, Object?> raw) {
  return BookSource(
    id: 'source-1',
    libraryRootId: 'root-1',
    name: '测试源',
    sourceUrl: 'https://e.test/',
    sourceType: 1,
    rawJson: jsonEncode(raw),
    header: const <String, String>{},
    enabled: true,
    enabledExplore: true,
    customOrder: 0,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    exploreUrl: raw['exploreUrl'] is String
        ? raw['exploreUrl'] as String
        : null,
    searchUrl: raw['searchUrl'] is String ? raw['searchUrl'] as String : null,
    concurrentRate: raw['concurrentRate'] is int
        ? raw['concurrentRate'] as int
        : null,
  );
}

void main() {
  group('LegadoSourceRules.parse', () {
    test('只收字符串规则字段，非字符串忽略', () {
      final rules = LegadoSourceRules.parse(
        _source(<String, Object?>{
          'exploreUrl': 'https://e.test/hot',
          'searchUrl': 'https://e.test/search',
          'ruleExplore': <String, Object?>{
            'bookList': r'$.items[*]',
            'name': r'$.title',
            'bad': 1,
          },
          'ruleSearch': <String, Object?>{'bookList': r'$.books[*]'},
          'ruleBookInfo': <String, Object?>{'name': r'$.name', 'author': false},
          'ruleToc': <String, Object?>{'chapterList': r'$.chapters[*]'},
          'ruleContent': <String, Object?>{'content': r'$.play_url'},
        }),
      );

      expect(rules.exploreUrl, 'https://e.test/hot');
      expect(rules.searchUrl, 'https://e.test/search');
      expect(rules.exploreFields, <String, String>{
        'bookList': r'$.items[*]',
        'name': r'$.title',
      });
      expect(rules.searchFields, <String, String>{'bookList': r'$.books[*]'});
      expect(rules.bookInfoFields, <String, String>{'name': r'$.name'});
      expect(rules.tocFields, <String, String>{
        'chapterList': r'$.chapters[*]',
      });
      expect(rules.contentFields, <String, String>{'content': r'$.play_url'});
    });

    test('concurrentRate 从 rawJson 解析，raw 优先于模型字段', () {
      final rules = LegadoSourceRules.parse(
        _source(<String, Object?>{
          'searchUrl': 'https://e.test/search',
          'concurrentRate': '20/60000',
          'ruleSearch': <String, Object?>{'bookList': r'$.items[*]'},
        }),
      );

      expect(rules.rateLimit.maxRequests, 20);
      expect(rules.rateLimit.window, const Duration(seconds: 60));
      expect(rules.rateLimit.minInterval, Duration.zero);
    });

    test('缺少规则对象时返回空 map，不在 parse 阶段抛错', () {
      final rules = LegadoSourceRules.parse(
        _source(<String, Object?>{'searchUrl': 'https://e.test/search'}),
      );

      expect(rules.exploreFields, isEmpty);
      expect(rules.searchFields, isEmpty);
      expect(rules.bookInfoFields, isEmpty);
      expect(rules.tocFields, isEmpty);
      expect(rules.contentFields, isEmpty);
    });
  });

  group('SourceRateLimit.parse', () {
    test('缺省 300ms，数字与数字字符串按毫秒', () {
      expect(
        SourceRateLimit.parse(null).minInterval,
        const Duration(milliseconds: 300),
      );
      expect(
        SourceRateLimit.parse(500).minInterval,
        const Duration(milliseconds: 500),
      );
      expect(
        SourceRateLimit.parse('250').minInterval,
        const Duration(milliseconds: 250),
      );
    });

    test('N/window 解析为窗口限速', () {
      final limit = SourceRateLimit.parse('20/60000');
      expect(limit.maxRequests, 20);
      expect(limit.window, const Duration(seconds: 60));
    });

    test('非法值回退默认', () {
      for (final raw in <Object?>['bad', '0/1000', '10/0', -1, 0]) {
        expect(
          SourceRateLimit.parse(raw).minInterval,
          const Duration(milliseconds: 300),
          reason: '$raw',
        );
      }
    });
  });
}
