import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/legado_rule_evaluator.dart';
import 'package:tometone/contracts/sources/js_runtime.dart';
import 'package:tometone/domain/sources/rules/rule_context.dart';
import 'package:tometone/domain/sources/rules/rule_error.dart';

class _FakeJsRuntime implements JsRuntime {
  _FakeJsRuntime([this.values = const <String, Object?>{}]);

  final Map<String, Object?> values;
  bool disposed = false;

  @override
  Future<Object?> evaluate(String script, JsContext context) async {
    if (!values.containsKey(script)) {
      throw const JsRuntimeException('未知脚本');
    }
    return values[script];
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

RuleEvaluationContext _context({
  Map<String, Object?> result = const <String, Object?>{},
  int? page,
  String? key,
}) {
  return RuleEvaluationContext(
    result: result,
    baseUrl: 'https://e.test/api/',
    page: page,
    key: key,
    source: const <String, Object?>{'name': '测试源'},
  );
}

void main() {
  group('LegadoRuleEvaluator', () {
    test('顶层 || 逐个尝试，首个非空返回', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());

      expect(
        await evaluator.evaluate(
          r'$.title || $.name',
          _context(result: <String, Object?>{'title': '主标题', 'name': '备用'}),
        ),
        '主标题',
      );
      expect(
        await evaluator.evaluate(
          r'$.title || $.name',
          _context(result: <String, Object?>{'name': '备用'}),
        ),
        '备用',
      );
    });

    test('## 去掉匹配的空白', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());

      expect(
        await evaluator.evaluate(
          r'$.title##\s+',
          _context(result: <String, Object?>{'title': ' 长 安 十 二 时 辰 '}),
        ),
        '长安十二时辰',
      );
    });

    test('模板混合 JSONPath、page 与 key', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());

      expect(
        await evaluator.evaluate(
          r'{{$.author}} - 第{{page}}页 - {{key}}',
          _context(
            result: <String, Object?>{'author': '马伯庸'},
            page: 2,
            key: '长安',
          ),
        ),
        '马伯庸 - 第2页 - 长安',
      );
    });

    test('@js 与 <js> 整段交给 JS', () async {
      final evaluator = LegadoRuleEvaluator(
        jsRuntime: _FakeJsRuntime(<String, Object?>{
          'result.title': 'JS 标题',
          'result.index + 1': 4,
        }),
      );

      expect(
        await evaluator.evaluate('@js: result.title', _context()),
        'JS 标题',
      );
      expect(
        await evaluator.evaluate('<js>result.index + 1</js>', _context()),
        4,
      );
    });

    test('模板中的非 JSONPath 表达式走 JS', () async {
      final evaluator = LegadoRuleEvaluator(
        jsRuntime: _FakeJsRuntime(<String, Object?>{'result.title': '模板 JS'}),
      );

      expect(await evaluator.evaluate('{{result.title}}', _context()), '模板 JS');
    });

    test('JS 异常映射为 RuleEvaluationException', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());

      await expectLater(
        evaluator.evaluate('@js: missing', _context()),
        throwsA(isA<RuleEvaluationException>()),
      );
    });

    test('|| 切分忽略引号与模板内部', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());

      expect(await evaluator.evaluate("'a||b'", _context()), "'a||b'");
      expect(
        await evaluator.evaluate('{{key}}', _context(key: 'a||b')),
        'a||b',
      );
    });

    test('M1 不支持的规则给可读错误', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());

      for (final rule in <String>[
        '@css:.title',
        '@xpath://title',
        r'$.title && $.name',
        'a%%b',
        'a#####b',
      ]) {
        await expectLater(
          evaluator.evaluate(rule, _context()),
          throwsA(
            isA<RuleEvaluationException>().having(
              (error) => error.message,
              'message',
              contains('M1 暂不支持该规则'),
            ),
          ),
          reason: rule,
        );
      }
    });

    test('@json 前缀支持剥离并正常执行 JSONPath', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());
      final context = _context(
        result: <String, Object?>{
          'data': <String, Object?>{
            'list': <Object?>[
              <String, Object?>{'title': '书目1'},
              <String, Object?>{'title': '书目2'},
            ],
          },
        },
      );

      final res1 = await evaluator.evaluate(r'@json:$.data.list[*]', context);
      expect(res1, isA<List<Object?>>());
      expect((res1 as List<Object?>).length, 2);

      final res2 = await evaluator.evaluate(r'@json:data.list', context);
      expect(res2, isA<List<Object?>>());
      expect((res2 as List<Object?>).length, 2);
    });

    test(r'支持 $ 直接提取根 JSON 数组或根对象', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());
      const listContext = RuleEvaluationContext(
        result: <Object?>[
          <String, Object?>{'title': 'A'},
          <String, Object?>{'title': 'B'},
        ],
        baseUrl: 'https://e.test',
      );

      final res = await evaluator.evaluate(r'$', listContext);
      expect(res, isA<List<Object?>>());
      expect((res as List<Object?>).length, 2);
    });

    test(r'省略 $. 前缀的相对键路径规则能正确从 Map/List 中提取', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());
      final context = _context(
        result: <String, Object?>{
          'title': '长安十二时辰',
          'bookUrl': '/book/1',
          'nested': <String, Object?>{'author': '马伯庸'},
        },
      );

      expect(await evaluator.evaluate('title', context), '长安十二时辰');
      expect(await evaluator.evaluate('bookUrl', context), '/book/1');
      expect(await evaluator.evaluate('nested.author', context), '马伯庸');
      // 不存在的键且无法作为 JSONPath 匹配时，回退为文本字面量
      expect(await evaluator.evaluate('完结', context), '完结');
    });

    test('|| 回退在首项为空列表 [] 时继续尝试后续备选', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());
      final context = _context(
        result: <String, Object?>{
          'items': <Object?>[],
          'data': <Object?>[
            <String, Object?>{'title': '备用书目'},
          ],
        },
      );

      final res = await evaluator.evaluate(r'$.items || $.data', context);
      expect(res, isA<List<Object?>>());
      expect((res as List<Object?>).length, 1);
    });

    test('空规则返回 null，普通文本原样返回', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());

      expect(await evaluator.evaluate('  ', _context()), isNull);
      expect(await evaluator.evaluate('普通文本', _context()), '普通文本');
    });

    test('非法 ## 正则给 RuleEvaluationException', () async {
      final evaluator = LegadoRuleEvaluator(jsRuntime: _FakeJsRuntime());

      await expectLater(
        evaluator.evaluate(
          r'$.title##[',
          _context(result: <String, Object?>{'title': 'x'}),
        ),
        throwsA(isA<RuleEvaluationException>()),
      );
    });
  });
}
