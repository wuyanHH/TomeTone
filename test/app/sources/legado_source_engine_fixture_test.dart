import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/legado_source_engine.dart';
import 'package:tometone/app/sources/source_rate_limiter.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';
import 'package:tometone/contracts/sources/source_http.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/domain/sources/source_import.dart';

String _fixture(String name) {
  return File('test/fixtures/sources/tingyou/$name').readAsStringSync();
}

BookSource _source() {
  final raw = jsonDecode(_fixture('source_m1b.json')) as Map<String, dynamic>;
  final parsed = const LegadoSourceImportParser().parse(jsonEncode(raw));
  final draft = parsed.candidates.single.draft;
  return BookSource(
    id: 'source-e2e',
    libraryRootId: 'root-e2e',
    name: draft.name,
    sourceUrl: draft.sourceUrl,
    sourceType: draft.sourceType,
    rawJson: draft.rawJson,
    header: draft.header,
    enabled: true,
    enabledExplore: true,
    customOrder: 0,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    exploreUrl: draft.exploreUrl,
    searchUrl: draft.searchUrl,
    concurrentRate: draft.concurrentRate,
  );
}

List<ExploreCategory> _categories(BookSource source) {
  return parseExploreCategories(
    exploreUrl: source.exploreUrl,
    enabledExplore: source.enabledExplore,
  );
}

class _FakeHttpClient implements SourceHttpClient {
  _FakeHttpClient(this.handler);

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

SourceHttpResponse _response(Uri url, String body, {int statusCode = 200}) {
  return SourceHttpResponse(
    finalUrl: url,
    statusCode: statusCode,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
    bytes: Uint8List.fromList(utf8.encode(body)),
  );
}

SourceHttpResponse _jsonFile(Uri url, String name) {
  return _response(url, _fixture(name));
}

bool _page2(SourceHttpRequest request) {
  return request.url.queryParameters['page'] == '2';
}

LegadoSourceEngine _engine(_FakeHttpClient http) {
  return LegadoSourceEngine(
    http: http,
    jsRuntime: _FakeJsRuntime(),
    rateLimiter: SourceRateLimiter(delay: (Duration _) async {}),
  );
}

void main() {
  test('夹具全链路：分类两页、POST 搜索、详情与两页目录', () async {
    final http = _FakeHttpClient((SourceHttpRequest request) async {
      if (request.url.path == '/api/explore/hot') {
        return _jsonFile(
          request.url,
          _page2(request) ? 'explore_hot_page2.json' : 'explore_hot_page1.json',
        );
      }
      if (request.url.path == '/api/search') {
        return _jsonFile(request.url, 'search_page1.json');
      }
      if (request.url.path == '/book/1') {
        return _jsonFile(request.url, 'book_info.json');
      }
      if (request.url.path == '/api/chapters/1') {
        return _jsonFile(
          request.url,
          _page2(request) ? 'toc_page2.json' : 'toc_page1.json',
        );
      }
      return _response(request.url, '{}', statusCode: 404);
    });
    final engine = _engine(http);
    final source = _source();
    final categories = _categories(source);

    expect(categories, hasLength(5));
    final SourcePage<SourceBookSummary> first = await engine.explore(
      source,
      categories.first,
      1,
    );
    expect(first.items.map((SourceBookSummary item) => item.title), <String>[
      '长安十二时辰',
      '三体',
    ]);
    expect(first.items.first.bookUrl, 'https://www.tingyou.fm/book/1');

    final SourcePage<SourceBookSummary> second = await engine.explore(
      source,
      categories.first,
      2,
    );
    expect(second.items.single.title, '第二页书目');

    final SourcePage<SourceBookSummary> search = await engine.search(
      source,
      'a"b 中文',
      1,
    );
    final SourceHttpRequest searchRequest = http.requests.firstWhere(
      (SourceHttpRequest request) => request.url.path == '/api/search',
    );
    expect(searchRequest.method, 'POST');
    expect(jsonDecode(searchRequest.body!), <String, Object?>{
      'keyword': 'a"b 中文',
      'page': 1,
    });
    expect(search.items.single.title, '搜索结果');

    final SourceBookInfo info = await engine.bookInfo(
      source,
      first.items.first.bookUrl,
    );
    expect(info.title, '长安十二时辰');
    expect(info.author, '马伯庸');
    expect(info.narrator, '演播者');
    expect(info.tocUrl, 'https://www.tingyou.fm/api/chapters/1');

    final SourceToc toc = await engine.toc(source, info);
    expect(toc.complete, isTrue);
    expect(toc.chapters, hasLength(3));
    expect(toc.chapters.map((SourceChapter chapter) => chapter.index), <int>[
      0,
      1,
      2,
    ]);
    expect(toc.chapters.map((SourceChapter chapter) => chapter.title), <String>[
      '第一章 长安',
      '第 2 章',
      '第三章 结尾',
    ]);

    expect(http.requests, hasLength(6));
    expect(
      http.requests.every(
        (SourceHttpRequest request) => request.url.host == 'www.tingyou.fm',
      ),
      isTrue,
    );
  });

  test('目录第二页 500：保留第一页章节并标记不完整', () async {
    final http = _FakeHttpClient((SourceHttpRequest request) async {
      if (request.url.path == '/api/chapters/1' && _page2(request)) {
        return _response(request.url, '{"error":"boom"}', statusCode: 500);
      }
      return _jsonFile(request.url, 'toc_page1.json');
    });
    final engine = _engine(http);
    final source = _source();
    const info = SourceBookInfo(
      title: '长安十二时辰',
      bookUrl: 'https://www.tingyou.fm/book/1',
      tocUrl: 'https://www.tingyou.fm/api/chapters/1',
    );

    final SourceToc toc = await engine.toc(source, info);

    expect(toc.complete, isFalse);
    expect(toc.chapters, hasLength(2));
    expect(toc.warnings, isNotEmpty);
    expect(http.requests, hasLength(2));
  });

  test('nextTocUrl 指回已访问页：停止且不重复章节', () async {
    final http = _FakeHttpClient((SourceHttpRequest request) async {
      if (request.url.path == '/api/chapters/1' && _page2(request)) {
        return _jsonFile(request.url, 'toc_loop_page2.json');
      }
      return _jsonFile(request.url, 'toc_page1.json');
    });
    final engine = _engine(http);
    final source = _source();
    const info = SourceBookInfo(
      title: '长安十二时辰',
      bookUrl: 'https://www.tingyou.fm/book/1',
      tocUrl: 'https://www.tingyou.fm/api/chapters/1',
    );

    final SourceToc toc = await engine.toc(source, info);

    expect(toc.complete, isFalse);
    expect(toc.chapters, hasLength(3));
    expect(toc.chapters.map((SourceChapter chapter) => chapter.index), <int>[
      0,
      1,
      2,
    ]);
    expect(toc.chapters.last.title, '第二章 循环页');
    expect(http.requests, hasLength(2));
  });
}
