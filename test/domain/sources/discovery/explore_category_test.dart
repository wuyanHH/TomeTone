import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/restricted_js_runtime.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';

void main() {
  group('parseExploreCategories', () {
    test('按换行解析名称与 URL 模板', () {
      final categories = parseExploreCategories(
        enabledExplore: true,
        exploreUrl:
            '热门::https://e.test/hot?page={{page}}\n'
            '最新::https://e.test/new?page={{page}}',
      );

      expect(categories, hasLength(2));
      expect(categories.first.name, '热门');
      expect(categories.first.urlTemplate, 'https://e.test/hot?page={{page}}');
      expect(categories.last.name, '最新');
    });

    test('支持 && 分隔与首尾空白', () {
      final categories = parseExploreCategories(
        enabledExplore: true,
        exploreUrl: '  热门 :: https://e.test/hot  && 最新 :: https://e.test/new  ',
      );

      expect(categories, hasLength(2));
      expect(categories.first.name, '热门');
      expect(categories.first.urlTemplate, 'https://e.test/hot');
      expect(categories.last.name, '最新');
    });

    test('停用发现时返回空列表', () {
      expect(
        parseExploreCategories(
          enabledExplore: false,
          exploreUrl: '热门::https://e.test/hot',
        ),
        isEmpty,
      );
    });

    test('空行、缺分隔符与空名称被跳过', () {
      final categories = parseExploreCategories(
        enabledExplore: true,
        exploreUrl:
            '\n'
            '没有分隔符\n'
            '::https://e.test/empty-name\n'
            '空地址::   \n'
            '有效::https://e.test/ok\n',
      );

      expect(categories, hasLength(1));
      expect(categories.single.name, '有效');
      expect(categories.single.urlTemplate, 'https://e.test/ok');
    });

    test('null 或空白返回空列表', () {
      expect(
        parseExploreCategories(enabledExplore: true, exploreUrl: null),
        isEmpty,
      );
      expect(
        parseExploreCategories(enabledExplore: true, exploreUrl: '  \n '),
        isEmpty,
      );
    });

    test('支持 Legado 3.0 标准的 JSON 数组格式（包含 title/name 与 url）', () {
      const jsonRaw = '''
[
  {"title": "热门榜单", "url": "/api/rank?type=hot&page={{page}}"},
  {"name": "分类精选", "url": "/api/category?page={{page}}", "style": {"layout_flexGrow": 1}},
  {"title": "", "url": "/invalid"},
  {"title": "缺url"}
]
''';
      final categories = parseExploreCategories(
        enabledExplore: true,
        exploreUrl: jsonRaw,
      );

      expect(categories, hasLength(2));
      expect(categories[0].name, '热门榜单');
      expect(categories[0].urlTemplate, '/api/rank?type=hot&page={{page}}');
    });

    test('resolves dynamic js exploreUrl with categories and lenient JSON', () async {
      final categories = await resolveExploreCategories(
        exploreUrl: r'''@js:
          sort = [];
          sort.push({title: '玄幻', url: '/xh_{{page}}', style: {layout_flexGrow: 1}});
          sort.push({title: '都市', url: '/ds_{{page}}'});
          JSON.stringify(sort);
        ''',
        enabledExplore: true,
        jsRuntime: RestrictedJsRuntime(),
        context: const JsContext(result: null, baseUrl: 'https://example.com'),
      );
      expect(categories.length, 2);
      expect(categories[0].name, '玄幻');
      expect(categories[0].urlTemplate, '/xh_{{page}}');
      expect(categories[1].name, '都市');
      expect(categories[1].urlTemplate, '/ds_{{page}}');
    });

    test('resolves unquoted loose JSON array string', () async {
      const looseJson = "[{title: '悬疑', url: '/xy_{{page}}'}, {name: '历史', url: '/ls_{{page}}'}]";
      final categories = await resolveExploreCategories(
        exploreUrl: looseJson,
        enabledExplore: true,
      );
      expect(categories.length, 2);
      expect(categories[0].name, '悬疑');
      expect(categories[0].urlTemplate, '/xy_{{page}}');
      expect(categories[1].name, '历史');
    });
  });
}
