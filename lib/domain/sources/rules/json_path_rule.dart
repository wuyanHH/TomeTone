import 'package:json_path/json_path.dart';

import 'rule_error.dart';

/// 返回 JSONPath 的全部匹配值。
List<Object?> jsonPathMatches(String expression, Object? root) {
  try {
    return JsonPath(expression).readValues(root).toList(growable: false);
  } on FormatException {
    throw RuleEvaluationException('JSONPath 表达式无效', rule: expression);
  } on Object {
    throw RuleEvaluationException('JSONPath 求值失败', rule: expression);
  }
}

/// 返回单个匹配、多个匹配的列表，或无匹配时的 null。
Object? jsonPathValue(String expression, Object? root) {
  final matches = jsonPathMatches(expression, root);
  if (matches.isEmpty) {
    return null;
  }
  if (matches.length == 1) {
    return matches.single;
  }
  return matches;
}
