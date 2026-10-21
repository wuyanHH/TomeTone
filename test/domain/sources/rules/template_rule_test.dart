import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/sources/rules/template_rule.dart';

TemplateRenderer _renderer() {
  return TemplateRenderer(
    resolve: (String expression) async {
      return switch (expression) {
        'page' => 2,
        'key' => 'a&b 中文',
        r'$.count' => 24,
        r'$.missing' => null,
        _ => null,
      };
    },
  );
}

void main() {
  group('TemplateRenderer', () {
    test('替换文本模板并保留字符串类型', () async {
      expect(
        await _renderer().render(
          r'共{{$.count}}章 / 第{{page}}页',
          mode: TemplateOutputMode.text,
        ),
        '共24章 / 第2页',
      );
    });

    test('null 占位符替换为空串', () async {
      expect(
        await _renderer().render(
          r'A{{$.missing}}B',
          mode: TemplateOutputMode.text,
        ),
        'AB',
      );
    });

    test('URL 模式对值做 percent-encode', () async {
      expect(
        await _renderer().render(
          'https://e.test/search?q={{key}}&page={{page}}',
          mode: TemplateOutputMode.url,
        ),
        'https://e.test/search?q=a%26b%20%E4%B8%AD%E6%96%87&page=2',
      );
    });

    test('JSON body 模式转义引号、反斜杠与换行', () async {
      final renderer = TemplateRenderer(
        resolve: (String expression) async => switch (expression) {
          'key' => 'a"b\\c\n',
          'page' => 2,
          _ => null,
        },
      );
      final body = await renderer.render(
        '{"q":"{{key}}","n":{{page}}}',
        mode: TemplateOutputMode.jsonBody,
      );

      expect(jsonDecode(body), <String, Object?>{'q': 'a"b\\c\n', 'n': 2});
    });

    test('一次替换不递归解析结果中的占位符', () async {
      final renderer = TemplateRenderer(
        resolve: (String expression) async =>
            expression == 'value' ? '{{page}}' : '2',
      );

      expect(
        await renderer.render('{{value}}', mode: TemplateOutputMode.text),
        '{{page}}',
      );
    });
  });
}
