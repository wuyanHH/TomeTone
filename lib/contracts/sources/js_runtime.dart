import 'source_http.dart';

/// JS 求值上下文。脚本只能通过这里的变量读取数据。
class JsContext {
  const JsContext({
    required this.result,
    required this.baseUrl,
    this.page,
    this.key,
    this.source = const <String, Object?>{},
    this.http,
    this.variables = const <String, Object?>{},
  });

  final Object? result;
  final String baseUrl;
  final int? page;
  final String? key;
  final Map<String, Object?> source;
  final SourceHttpClient? http;
  final Map<String, Object?> variables;
}

/// JS 执行失败。消息不得包含完整脚本、响应体或请求头。
class JsRuntimeException implements Exception {
  const JsRuntimeException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 书源规则使用的 JS 运行时。
abstract interface class JsRuntime {
  Future<Object?> evaluate(String script, JsContext context);

  Future<void> dispose();
}
