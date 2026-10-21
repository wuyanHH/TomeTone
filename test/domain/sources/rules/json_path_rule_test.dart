import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/sources/rules/json_path_rule.dart';
import 'package:tometone/domain/sources/rules/rule_error.dart';

void main() {
  group('jsonPathMatches', () {
    test('通配符返回全部匹配值', () {
      final matches = jsonPathMatches(r'$.items[*]', <String, Object?>{
        'items': <Object?>[
          <String, Object?>{'title': 'A'},
          <String, Object?>{'title': 'B'},
        ],
      });

      expect(matches, hasLength(2));
      expect((matches.first as Map)['title'], 'A');
      expect((matches.last as Map)['title'], 'B');
    });

    test('无匹配返回空列表', () {
      expect(jsonPathMatches(r'$.missing', <String, Object?>{'a': 1}), isEmpty);
    });

    test('非法表达式抛 RuleEvaluationException', () {
      expect(
        () => jsonPathMatches(r'$.[', <String, Object?>{'a': 1}),
        throwsA(isA<RuleEvaluationException>()),
      );
    });
  });

  group('jsonPathValue', () {
    test('单个匹配返回标量', () {
      expect(jsonPathValue(r'$.title', <String, Object?>{'title': 'A'}), 'A');
    });

    test('多个匹配返回列表', () {
      expect(
        jsonPathValue(r'$.items[*].title', <String, Object?>{
          'items': <Object?>[
            <String, Object?>{'title': 'A'},
            <String, Object?>{'title': 'B'},
          ],
        }),
        <Object?>['A', 'B'],
      );
    });

    test('无匹配返回 null', () {
      expect(jsonPathValue(r'$.missing', <String, Object?>{'a': 1}), isNull);
    });
  });
}
