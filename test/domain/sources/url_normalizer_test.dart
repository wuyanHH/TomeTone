import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/sources/url_normalizer.dart';

void main() {
  group('normalizeNetworkUrl', () {
    test('相对地址按 baseUrl 解析', () {
      expect(
        normalizeNetworkUrl(
          '../b?x=1',
          baseUrl: Uri.parse('https://example.com/a/c'),
        ),
        'https://example.com/b?x=1',
      );
    });

    test('scheme / host 小写，去默认端口、fragment 与点段', () {
      expect(
        normalizeNetworkUrl('HTTPS://Example.COM:443/a/../b#frag'),
        'https://example.com/b',
      );
      expect(
        normalizeNetworkUrl('http://Example.com:80'),
        'http://example.com/',
      );
    });

    test('保留 path 大小写与末尾斜杠', () {
      expect(
        normalizeNetworkUrl('https://example.com/A/B/'),
        'https://example.com/A/B/',
      );
      expect(
        normalizeNetworkUrl('https://example.com/A/B'),
        'https://example.com/A/B',
      );
    });

    test('折叠重复斜杠', () {
      expect(
        normalizeNetworkUrl('https://example.com/a//b///c'),
        'https://example.com/a/b/c',
      );
    });

    test('保留 query 顺序与签名，不排序不剥离', () {
      expect(
        normalizeNetworkUrl(
          'https://example.com/a?z=1&a=2&sig=AbC%2F123&empty=',
        ),
        'https://example.com/a?z=1&a=2&sig=AbC%2F123&empty=',
      );
    });

    test('非默认端口保留', () {
      expect(
        normalizeNetworkUrl('https://example.com:8443/a'),
        'https://example.com:8443/a',
      );
    });

    test('拒绝非 http(s) scheme', () {
      for (final raw in <String>[
        'file:///tmp/a.json',
        'content://books/a',
        'javascript:alert(1)',
        'data:text/plain,hi',
        'ftp://example.com/a',
      ]) {
        expect(
          () => normalizeNetworkUrl(raw),
          throwsFormatException,
          reason: raw,
        );
      }
    });

    test('拒绝空地址、缺 host 与非法 URL', () {
      for (final raw in <String>['', '   ', 'not a url', 'http://']) {
        expect(
          () => normalizeNetworkUrl(raw),
          throwsFormatException,
          reason: raw,
        );
      }
    });
  });
}
