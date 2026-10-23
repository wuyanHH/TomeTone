import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/legado_source_engine.dart';
import 'package:tometone/app/sources/legado/restricted_js_runtime.dart';
import 'package:tometone/app/sources/source_rate_limiter.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';
import 'package:tometone/contracts/sources/source_http.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';

class _MockHttp implements SourceHttpClient {
  _MockHttp(this.handler);

  final Future<SourceHttpResponse> Function(SourceHttpRequest request) handler;

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) => handler(request);
}

SourceHttpResponse _jsonResponse(Uri url, Object? data) {
  return SourceHttpResponse(
    finalUrl: url,
    statusCode: 200,
    headers: const {'content-type': 'application/json'},
    bytes: Uint8List.fromList(utf8.encode(jsonEncode(data))),
  );
}

void main() {
  group('听友听书基准源回归', () {
    late BookSource tingyouSource;

    setUp(() {
      final raw = <String, dynamic>{
        'bookSourceUrl': 'https://www.tingyou.fm',
        'bookSourceName': '听友听书',
        'bookSourceType': 1,
        'ruleSearch': <String, dynamic>{
          'bookList': r'$.data[*]',
          'name': r'$.title',
          'author': r'$.author',
          'bookUrl': r'https://www.tingyou.fm/api/book/{{$.id}}',
        },
        'ruleBookInfo': <String, dynamic>{
          'name': r'$.title',
          'author': r'$.author',
          'tocUrl': r'https://www.tingyou.fm/api/chapters/{{$.id}}',
        },
        'ruleToc': <String, dynamic>{
          'chapterList': r'$.chapters[*]',
          'chapterName': r'$.name',
          'chapterUrl': r'''@js:
            var albumId = baseUrl.match(/chapters\/(\d+)/)[1];
            'https://www.tingyou.fm/play?album=' + albumId + '&index=' + result.index
          ''',
        },
      };

      tingyouSource = BookSource(
        id: 'source-tingyou',
        libraryRootId: 'root-1',
        name: '听友听书',
        sourceUrl: 'https://www.tingyou.fm',
        sourceType: 1,
        rawJson: jsonEncode(raw),
        header: const <String, String>{},
        enabled: true,
        enabledExplore: true,
        customOrder: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        searchUrl:
            'https://www.tingyou.fm/api/search,{"method":"POST","headers":{"Content-Type":"application/json"},"body":{"q":"{{key}}","page":"{{page}}"}}',
      );
    });

    test('听友听书搜索与多行 JS 目录解析全流程', () async {
      final http = _MockHttp((request) async {
        final urlStr = request.url.toString();
        if (urlStr.contains('/api/search')) {
          expect(request.method, 'POST');
          final decodedBody = jsonDecode(request.body!);
          expect(decodedBody['q'], '大奉打更人');
          return _jsonResponse(request.url, {
            'data': [
              {
                'id': 1234,
                'title': '大奉打更人',
                'author': '卖报小郎君',
              }
            ]
          });
        }
        if (urlStr.contains('/api/book/1234')) {
          return _jsonResponse(request.url, {
            'id': 1234,
            'title': '大奉打更人',
            'author': '卖报小郎君',
          });
        }
        if (urlStr.contains('/api/chapters/1234')) {
          return _jsonResponse(request.url, {
            'chapters': [
              {'index': 1, 'name': '第一章 牢狱之灾'},
              {'index': 2, 'name': '第二章 炼金术师'},
            ]
          });
        }
        return _jsonResponse(request.url, {});
      });

      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: RestrictedJsRuntime(),
        rateLimiter: SourceRateLimiter(),
      );

      // 1. 搜索
      final searchPage = await engine.search(tingyouSource, '大奉打更人', 1);
      expect(searchPage.items, hasLength(1));
      final book = searchPage.items.first;
      expect(book.title, '大奉打更人');
      expect(book.bookUrl, 'https://www.tingyou.fm/api/book/1234');

      // 2. 详情与目录获取
      final bookInfo = await engine.bookInfo(tingyouSource, book.bookUrl);
      expect(bookInfo.tocUrl, 'https://www.tingyou.fm/api/chapters/1234');

      // 3. 目录抓取并验证多行 JS chapterUrl
      final toc = await engine.toc(tingyouSource, bookInfo);
      expect(toc.chapters, hasLength(2));
      expect(toc.chapters[0].title, '第一章 牢狱之灾');
      expect(
        toc.chapters[0].url,
        'https://www.tingyou.fm/play?album=1234&index=1',
      );
      expect(
        toc.chapters[1].url,
        'https://www.tingyou.fm/play?album=1234&index=2',
      );
    });
  });

  group('懒人听书基准源回归', () {
    late BookSource lrtsSource;

    setUp(() {
      final raw = <String, dynamic>{
        'bookSourceUrl': 'https://www.lrts.me',
        'bookSourceName': '懒人听书（优+++）',
        'bookSourceType': 1,
        'exploreUrl': r'''@js:
          var sort = [];
          sort.push({title: '玄幻修真', url: '/category/1_{{page}}'});
          sort.push({title: '都市言情', url: '/category/2_{{page}}', style: {layout_flexGrow: 1}});
          JSON.stringify(sort);
        ''',
        'ruleBookInfo': <String, dynamic>{
          'init': r'$.data.bookDetail',
          'name': r'$.name@put:{sections: $.sections, entityType: $.entityType}',
          'author': r'$.author',
          'tocUrl': r'https://www.lrts.me/api/toc?bookId={{$.id}}',
        },
        'ruleToc': <String, dynamic>{
          'chapterList': r'$.chapters[*]',
          'chapterName': r'$.title',
          'chapterUrl': r'https://www.lrts.me/audio?id={{$.id}}&type={{java.get("entityType")}}',
          'nextTocUrl': r'''@js:
            var list = [];
            list.push(baseUrl + "&page=2");
            list.push(baseUrl + "&page=3");
            list;
          ''',
        },
      };

      lrtsSource = BookSource(
        id: 'source-lrts',
        libraryRootId: 'root-2',
        name: '懒人听书（优+++）',
        sourceUrl: 'https://www.lrts.me',
        sourceType: 1,
        rawJson: jsonEncode(raw),
        header: const <String, String>{},
        enabled: true,
        enabledExplore: true,
        customOrder: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        exploreUrl: raw['exploreUrl'] as String,
      );
    });

    test('懒人听书动态分类、init解包、@put与数组翻页全流程', () async {
      final http = _MockHttp((request) async {
        final urlStr = request.url.toString();
        if (urlStr.contains('/api/detail')) {
          return _jsonResponse(request.url, {
            'data': {
              'bookDetail': {
                'id': 8888,
                'name': '遮天',
                'author': '辰东',
                'sections': 1800,
                'entityType': 4,
              }
            }
          });
        }
        if (urlStr.contains('/api/toc?bookId=8888') && !urlStr.contains('page=')) {
          return _jsonResponse(request.url, {
            'chapters': [
              {'id': 1, 'title': '第 1 回 九龙拉棺'},
            ]
          });
        }
        if (urlStr.contains('page=2')) {
          return _jsonResponse(request.url, {
            'chapters': [
              {'id': 2, 'title': '第 2 回 冰冷与黑暗'},
            ]
          });
        }
        if (urlStr.contains('page=3')) {
          return _jsonResponse(request.url, {
            'chapters': [
              {'id': 3, 'title': '第 3 回 青铜巨棺'},
            ]
          });
        }
        return _jsonResponse(request.url, {});
      });

      final runtime = RestrictedJsRuntime();
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: runtime,
        rateLimiter: SourceRateLimiter(),
      );

      // 1. 测试动态 @js: 分类解析
      final categories = await resolveExploreCategories(
        exploreUrl: lrtsSource.exploreUrl,
        enabledExplore: lrtsSource.enabledExplore,
        jsRuntime: runtime,
        context: JsContext(result: null, baseUrl: lrtsSource.sourceUrl),
      );
      expect(categories, hasLength(2));
      expect(categories[0].name, '玄幻修真');
      expect(categories[0].urlTemplate, '/category/1_{{page}}');
      expect(categories[1].name, '都市言情');

      // 2. 测试详情页 init 数据解包与 @put:{entityType: ...} 变量提取
      final bookInfo = await engine.bookInfo(
        lrtsSource,
        'https://www.lrts.me/api/detail?id=8888',
      );
      expect(bookInfo.title, '遮天');
      expect(bookInfo.author, '辰东');
      expect(bookInfo.variables['sections'], 1800);
      expect(bookInfo.variables['entityType'], 4);

      // 3. 测试目录抓取：变量 {{java.get("entityType")}} 自动回填 + nextTocUrl 数组翻页合并
      final toc = await engine.toc(lrtsSource, bookInfo);
      expect(toc.chapters, hasLength(3));
      expect(toc.chapters[0].title, '第 1 回 九龙拉棺');
      expect(toc.chapters[0].url, 'https://www.lrts.me/audio?id=1&type=4');
      expect(toc.chapters[1].title, '第 2 回 冰冷与黑暗');
      expect(toc.chapters[1].url, 'https://www.lrts.me/audio?id=2&type=4');
      expect(toc.chapters[2].title, '第 3 回 青铜巨棺');
      expect(toc.chapters[2].url, 'https://www.lrts.me/audio?id=3&type=4');
      expect(toc.complete, isTrue);
    });
  });
}
