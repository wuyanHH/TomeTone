/// 一次规则求值的上下文。`result` 是上一步解析出的 JSON/对象。
class RuleEvaluationContext {
  const RuleEvaluationContext({
    required this.result,
    required this.baseUrl,
    this.page,
    this.key,
    this.source = const <String, Object?>{},
  });

  final Object? result;
  final String baseUrl;
  final int? page;
  final String? key;
  final Map<String, Object?> source;
}
