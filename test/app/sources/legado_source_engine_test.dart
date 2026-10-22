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
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/domain/sources/source_import.dart';

String _fixture(String name) {
  return File('test/fixtures/sources/tingyou/$name').readAsStringSync();
}

BookSource _source({void Function(Map<String, dynamic> raw)? mutate}) {
  final raw = jsonDecode(_fixture('source_m1b.json')) as Map<String, dynamic>;
  mutate?.call(raw);
  final parsed = const LegadoSourceImportParser().parse(jsonEncode(raw));
  final candidate = parsed.candidates.single;
  final draft = candidate.draft;
  return BookSource(
    id: 'source-1',
    libraryRootId: 'root-1',
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

class _FakeClock {
  _FakeClock(this.now);

  DateTime now;
}

class _RecordingRateLimiter extends SourceRateLimiter {
  _RecordingRateLimiter() : this._(_FakeClock(DateTime.utc(2026)));

  _RecordingRateLimiter._(_FakeClock clock)
    : super(
        clock: () => clock.now,
        delay: (duration) async {
          clock.now = clock.now.add(duration);
        },
      );

  final List<String> calls = <String>[];

  @override
  Future<void> acquire(String sourceId, SourceRateLimit limit) {
    calls.add(sourceId);
    return super.acquire(sourceId, limit);
  }
}

class _FakeJsRuntime implements JsRuntime {
  @override
  Future<Object?> evaluate(String script, JsContext context) async {
    throw const JsRuntimeException('未知脚本');
  }

  @override
  Future<void> dispose() async {}
}

SourceHttpResponse _response(
  Uri url,
  String body, {
  int statusCode = 200,
  Map<String, String>? headers,
}) {
  return SourceHttpResponse(
    finalUrl: url,
    statusCode: statusCode,
    headers: <String, String>{
      'content-type': 'application/json; charset=utf-8',
      ...?headers,
    },
    bytes: Uint8List.fromList(utf8.encode(body)),
  );
}

SourceHttpResponse _jsonFile(Uri url, String name) {
  return _response(url, _fixture(name));
}

void main() {
  group('LegadoSourceEngine.explore', () {
    test('按分类 URL 请求，解析相对 URL、去重并跳过坏条目', () async {
      final http = _FakeHttpClient(
        (request) async => _jsonFile(request.url, 'explore_hot_page1.json'),
      );
      final limiter = _RecordingRateLimiter();
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: limiter,
      );
      final source = _source();

      final page = await engine.explore(source, _categories(source).first, 1);

      expect(http.requests, hasLength(1));
      expect(
        http.requests.single.url.toString(),
        'https://www.tingyou.fm/api/explore/hot?page=1',
      );
      expect(http.requests.single.method, 'GET');
      expect(
        http.requests.single.headers['x-listening-session'],
        'test-session',
      );
      expect(limiter.calls, <String>['source-1']);
      expect(page.items.map((item) => item.title), <String>['长安十二时辰', '三体']);
      expect(page.items.first.bookUrl, 'https://www.tingyou.fm/book/1');
      expect(page.items.first.coverUrl, 'https://www.tingyou.fm/covers/1.jpg');
      expect(page.items.first.author, '马伯庸');
      expect(page.hasMore, isTrue);
      expect(page.warnings, isNotEmpty);
      expect(page.finalUrl.toString(), http.requests.single.url.toString());
    });

    test('分类页 page=2 进入 URL 模板', () async {
      final http = _FakeHttpClient(
        (request) async => _jsonFile(request.url, 'explore_hot_page2.json'),
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );
      final source = _source();

      final page = await engine.explore(source, _categories(source).first, 2);

      expect(http.requests.single.url.queryParameters['page'], '2');
      expect(page.items.single.title, '第二页书目');
    });

    test(r'支持省略 $. 的常规键名及 @json: 标记并正确解析列表与字段', () async {
      final http = _FakeHttpClient(
        (request) async => _response(
          request.url,
          jsonEncode(<String, Object?>{
            'data': <String, Object?>{
              'list': <Object?>[
                <String, Object?>{
                  'book_name': '斗罗大陆',
                  'target_url': '/book/101',
                  'author_name': '唐家三少',
                },
                <String, Object?>{
                  'book_name': '斗破苍穹',
                  'target_url': '/book/102',
                  'author_name': '天蚕土豆',
                },
              ],
            },
          }),
        ),
      );
      final source = _source(
        mutate: (raw) {
          raw['ruleExplore'] = <String, Object?>{
            'bookList': '@json:data.list[*]',
            'name': 'book_name',
            'bookUrl': 'target_url',
            'author': 'author_name',
          };
        },
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final page = await engine.explore(source, _categories(source).first, 1);

      expect(page.items, hasLength(2));
      expect(page.items[0].title, '斗罗大陆');
      expect(page.items[0].bookUrl, 'https://www.tingyou.fm/book/101');
      expect(page.items[0].author, '唐家三少');
      expect(page.items[1].title, '斗破苍穹');
    });

    test('ruleExplore 缺失时自动从 ruleSearch 继承并成功识别列表', () async {
      final http = _FakeHttpClient(
        (request) async => _response(
          request.url,
          jsonEncode(<String, Object?>{
            'items': <Object?>[
              <String, Object?>{'title': '继承书目', 'url': '/book/99'},
            ],
          }),
        ),
      );
      final source = _source(
        mutate: (raw) {
          raw.remove('ruleExplore');
          raw['ruleSearch'] = <String, Object?>{
            'bookList': 'items',
            'name': 'title',
            'bookUrl': 'url',
          };
        },
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final page = await engine.explore(source, _categories(source).first, 1);

      expect(page.items, hasLength(1));
      expect(page.items.single.title, '继承书目');
    });
  });

  group('LegadoSourceEngine.search', () {
    test('POST 搜索把关键词/页码放进 JSON body', () async {
      final http = _FakeHttpClient(
        (request) async => _jsonFile(request.url, 'search_page1.json'),
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );
      final source = _source();

      final page = await engine.search(source, 'a"b 中文', 1);

      final request = http.requests.single;
      expect(request.method, 'POST');
      expect(request.headers['Content-Type'], 'application/json');
      expect(jsonDecode(request.body!), <String, Object?>{
        'keyword': 'a"b 中文',
        'page': 1,
      });
      expect(page.items.single.title, '搜索结果');
      expect(page.items.single.bookUrl, 'https://www.tingyou.fm/book/5');
    });

    test('空关键词直接失败且不发请求', () async {
      final http = _FakeHttpClient(
        (request) async => _jsonFile(request.url, 'search_page1.json'),
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      await expectLater(
        engine.search(_source(), '   ', 1),
        throwsA(
          isA<SourceFailure>()
              .having((error) => error.kind, 'kind', SourceFailureKind.empty)
              .having((error) => error.stage, 'stage', SourceStage.search),
        ),
      );
      expect(http.requests, isEmpty);
    });
  });

  group('LegadoSourceEngine.bookInfo', () {
    test('解析详情字段、相对封面与 tocUrl 模板', () async {
      final http = _FakeHttpClient(
        (request) async => _jsonFile(request.url, 'book_info.json'),
      );
      final limiter = _RecordingRateLimiter();
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: limiter,
      );

      final info = await engine.bookInfo(
        _source(),
        'https://www.tingyou.fm/book/1',
      );

      expect(info.title, '长安十二时辰');
      expect(info.author, '马伯庸');
      expect(info.narrator, '演播者');
      expect(info.coverUrl, 'https://cdn.test/cover.jpg');
      expect(info.intro, '一天之内拯救长安。');
      expect(info.kind, '历史');
      expect(info.wordCount, '100 万字');
      expect(info.lastChapter, '第 24 章');
      expect(info.status, '完结');
      expect(info.tocUrl, 'https://www.tingyou.fm/api/chapters/1');
      expect(limiter.calls, <String>['source-1']);
    });

    test('tocUrl 缺失时回退 bookUrl', () async {
      final source = _source(
        mutate: (raw) {
          (raw['ruleBookInfo'] as Map<String, dynamic>).remove('tocUrl');
        },
      );
      final http = _FakeHttpClient(
        (request) async => _jsonFile(request.url, 'book_info.json'),
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final info = await engine.bookInfo(
        source,
        'https://www.tingyou.fm/book/1',
      );

      expect(info.tocUrl, info.bookUrl);
      expect(info.tocUrl, 'https://www.tingyou.fm/book/1');
    });

    test('标题缺失时回退 host + path，不留空白', () async {
      final http = _FakeHttpClient(
        (request) async => _response(request.url, '{"id":"9"}'),
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final info = await engine.bookInfo(
        _source(),
        'https://www.tingyou.fm/book/9',
      );

      expect(info.title, 'www.tingyou.fm/book/9');
    });
  });

  group('LegadoSourceEngine.toc', () {
    SourceBookInfo info() {
      return const SourceBookInfo(
        title: '长安十二时辰',
        bookUrl: 'https://www.tingyou.fm/book/1',
        tocUrl: 'https://www.tingyou.fm/api/chapters/1',
      );
    }

    test('跨两页目录，章节 index 连续，保留 URL options 并跳过坏 URL', () async {
      final http = _FakeHttpClient((request) async {
        if (request.url.query == 'page=2') {
          return _jsonFile(request.url, 'toc_page2.json');
        }
        return _jsonFile(request.url, 'toc_page1.json');
      });
      final limiter = _RecordingRateLimiter();
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: limiter,
      );

      final toc = await engine.toc(_source(), info());

      expect(toc.complete, isTrue);
      expect(toc.chapters.map((chapter) => chapter.index), <int>[0, 1, 2]);
      expect(toc.chapters.map((chapter) => chapter.title), <String>[
        '第一章 长安',
        '第 2 章',
        '第三章 结尾',
      ]);
      expect(toc.chapters.map((chapter) => chapter.url), <String>[
        'https://www.tingyou.fm/play/1',
        'https://www.tingyou.fm/play/2',
        'https://www.tingyou.fm/play/3',
      ]);
      expect(toc.chapters[1].isVip, isTrue);
      expect(toc.chapters[2].isVip, isTrue);
      expect(toc.chapters[2].rawUrl, contains(',{'));
      expect(toc.warnings, isNotEmpty);
      expect(limiter.calls, hasLength(2));
    });

    test('next 指回已访问 URL 时停止并标记不完整', () async {
      final http = _FakeHttpClient((request) async {
        return _response(
          request.url,
          jsonEncode(<String, Object?>{
            'chapters': <Object?>[
              <String, Object?>{'title': '一章', 'url': '/play/1'},
            ],
            'next': '/api/chapters/1',
          }),
        );
      });
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final toc = await engine.toc(_source(), info());

      expect(toc.chapters, hasLength(1));
      expect(toc.complete, isFalse);
      expect(http.requests, hasLength(1));
    });

    test(r'支持省略 $. 与带 @json: 的 chapterList 规则正确提取章节列表', () async {
      final source = _source(
        mutate: (raw) {
          raw['ruleToc'] = <String, Object?>{
            'chapterList': '@json:chapter_data.items',
            'chapterName': 'c_title',
            'chapterUrl': 'c_link',
          };
        },
      );
      final http = _FakeHttpClient((request) async {
        return _response(
          request.url,
          jsonEncode(<String, Object?>{
            'chapter_data': <String, Object?>{
              'items': <Object?>[
                <String, Object?>{'c_title': '序章', 'c_link': '/play/0'},
                <String, Object?>{'c_title': '正章', 'c_link': '/play/1'},
              ],
            },
          }),
        );
      });
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final toc = await engine.toc(source, info());

      expect(toc.chapters, hasLength(2));
      expect(toc.chapters[0].title, '序章');
      expect(toc.chapters[0].url, 'https://www.tingyou.fm/play/0');
      expect(toc.chapters[1].title, '正章');
    });

    test('第二页失败保留第一页章节并标记不完整', () async {
      var call = 0;
      final http = _FakeHttpClient((request) async {
        call++;
        if (call == 2) {
          throw const SourceTransportException(
            SourceTransportFailure.network,
            'network down',
          );
        }
        return _jsonFile(request.url, 'toc_page1.json');
      });
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final toc = await engine.toc(_source(), info());

      expect(toc.chapters, hasLength(2));
      expect(toc.complete, isFalse);
      expect(toc.warnings, isNotEmpty);
    });

    test('第二页 nextTocUrl 求值失败也保留已抓章节', () async {
      final source = _source(
        mutate: (raw) {
          (raw['ruleToc'] as Map<String, dynamic>)['nextTocUrl'] =
              r'$.next || $[';
        },
      );
      final http = _FakeHttpClient((request) async {
        if (request.url.query == 'page=2') {
          return _response(
            request.url,
            '{"chapters":[{"title":"第三章","url":"/play/3"}],"next":null}',
          );
        }
        return _jsonFile(request.url, 'toc_page1.json');
      });
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final toc = await engine.toc(source, info());

      expect(toc.chapters, hasLength(3));
      expect(toc.complete, isFalse);
      expect(toc.warnings, isNotEmpty);
    });

    test('目录最多抓 50 页，超过上限标记不完整', () async {
      final http = _FakeHttpClient((request) async {
        final page =
            int.tryParse(request.url.queryParameters['page'] ?? '') ?? 1;
        return _response(
          request.url,
          jsonEncode(<String, Object?>{
            'chapters': <Object?>[
              <String, Object?>{'title': '第 $page 章', 'url': '/play/$page'},
            ],
            'next': '/api/toc?page=${page + 1}',
          }),
        );
      });
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      final toc = await engine.toc(
        _source(),
        const SourceBookInfo(
          title: '长目录',
          bookUrl: 'https://www.tingyou.fm/book/1',
          tocUrl: 'https://www.tingyou.fm/api/toc',
        ),
      );

      expect(toc.chapters, hasLength(50));
      expect(toc.complete, isFalse);
      expect(http.requests, hasLength(50));
      expect(toc.chapters.last.index, 49);
    });
  });

  group('LegadoSourceEngine 错误映射', () {
    Future<SourceFailure> exploreFailure(SourceHttpResponse response) async {
      final engine = LegadoSourceEngine(
        http: _FakeHttpClient((request) async => response),
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );
      final source = _source();
      try {
        await engine.explore(source, _categories(source).first, 1);
      } on SourceFailure catch (error) {
        return error;
      }
      fail('应当抛 SourceFailure');
    }

    test('401 映射 authRequired', () async {
      final error = await exploreFailure(
        _response(Uri.parse('https://www.tingyou.fm/'), '{}', statusCode: 401),
      );
      expect(error.kind, SourceFailureKind.authRequired);
      expect(error.stage, SourceStage.explore);
      expect(error.message, '需要登录或会话已失效');
    });

    test('其他 HTTP 状态只保留 code', () async {
      final error = await exploreFailure(
        _response(Uri.parse('https://www.tingyou.fm/'), '{}', statusCode: 500),
      );
      expect(error.kind, SourceFailureKind.httpStatus);
      expect(error.statusCode, 500);
      expect(error.message, '服务返回 HTTP 500');
    });

    test('坏 JSON 映射 json', () async {
      final error = await exploreFailure(
        _response(Uri.parse('https://www.tingyou.fm/'), 'not-json'),
      );
      expect(error.kind, SourceFailureKind.json);
      expect(error.message, '返回内容不是有效 JSON');
    });

    test('超时映射 timeout', () async {
      final engine = LegadoSourceEngine(
        http: _FakeHttpClient((request) async {
          throw const SourceTransportException(
            SourceTransportFailure.timeout,
            'slow',
          );
        }),
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );
      final source = _source();

      await expectLater(
        engine.explore(source, _categories(source).first, 1),
        throwsA(
          isA<SourceFailure>().having(
            (error) => error.kind,
            'kind',
            SourceFailureKind.timeout,
          ),
        ),
      );
    });

    test('字符集失败映射 encoding 且保留请求 stage', () async {
      final source = _source(
        mutate: (raw) {
          raw['searchUrl'] =
              'https://www.tingyou.fm/api/search,{"charset":"shift_jis"}';
        },
      );
      final engine = LegadoSourceEngine(
        http: _FakeHttpClient(
          (request) async => _response(request.url, '{"items":[]}'),
        ),
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      await expectLater(
        engine.search(source, '测试', 1),
        throwsA(
          isA<SourceFailure>()
              .having((error) => error.kind, 'kind', SourceFailureKind.encoding)
              .having((error) => error.stage, 'stage', SourceStage.search),
        ),
      );
    });

    test('请求 URL 非法映射 rule', () async {
      final http = _FakeHttpClient(
        (request) async => _response(request.url, '{}'),
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      await expectLater(
        engine.bookInfo(_source(), 'ftp://e.test/book/1'),
        throwsA(
          isA<SourceFailure>()
              .having((error) => error.kind, 'kind', SourceFailureKind.rule)
              .having((error) => error.stage, 'stage', SourceStage.bookInfo),
        ),
      );
      expect(http.requests, isEmpty);
    });

    test('非法规则映射 rule', () async {
      final source = _source(
        mutate: (raw) {
          (raw['ruleExplore'] as Map<String, dynamic>)['bookList'] = r'$[';
        },
      );
      final engine = LegadoSourceEngine(
        http: _FakeHttpClient(
          (request) async => _response(request.url, '{"items":[]}'),
        ),
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );

      await expectLater(
        engine.explore(source, _categories(source).first, 1),
        throwsA(
          isA<SourceFailure>().having(
            (error) => error.kind,
            'kind',
            SourceFailureKind.rule,
          ),
        ),
      );
    });
  });

  group('LegadoSourceEngine.test', () {
    test('有分类时探测第一个分类，空结果也算成功', () async {
      final http = _FakeHttpClient(
        (request) async => _response(request.url, '{"items":[]}'),
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );
      final source = _source();

      final report = await engine.test(source);

      expect(report.resultCount, 0);
      expect(report.sampleTitle, isNull);
      expect(report.latency, greaterThanOrEqualTo(Duration.zero));
      expect(http.requests.single.url.path, '/api/explore/hot');
    });

    test('无分类时用“测试”搜索，失败映射为 test stage', () async {
      final http = _FakeHttpClient(
        (request) async => _jsonFile(request.url, 'search_page1.json'),
      );
      final engine = LegadoSourceEngine(
        http: http,
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );
      final source = _source(mutate: (raw) => raw.remove('exploreUrl'));

      final report = await engine.test(source);

      expect(report.resultCount, 1);
      expect(report.sampleTitle, '搜索结果');
      expect(jsonDecode(http.requests.single.body!)['keyword'], '测试');

      final failingEngine = LegadoSourceEngine(
        http: _FakeHttpClient(
          (request) async => _response(request.url, '{}', statusCode: 404),
        ),
        jsRuntime: _FakeJsRuntime(),
        rateLimiter: _RecordingRateLimiter(),
      );
      await expectLater(
        failingEngine.test(source),
        throwsA(
          isA<SourceFailure>()
              .having((error) => error.stage, 'stage', SourceStage.test)
              .having(
                (error) => error.kind,
                'kind',
                SourceFailureKind.httpStatus,
              ),
        ),
      );
    });
  });
}
