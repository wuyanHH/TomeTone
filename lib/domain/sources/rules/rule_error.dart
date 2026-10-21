/// 书源规则求值失败。
///
/// 消息只描述规则本身，不得包含响应体、请求头或会话值。
class RuleEvaluationException implements Exception {
  const RuleEvaluationException(this.message, {this.rule});

  final String message;
  final String? rule;

  @override
  String toString() => message;
}
