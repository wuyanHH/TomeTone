enum SourceStage { explore, search, bookInfo, toc, audio, test }

enum SourceFailureKind {
  network,
  timeout,
  httpStatus,
  encoding,
  json,
  rule,
  authRequired,
  vipRequired,
  empty,
  aborted,
}

/// 书源请求/解析失败。消息只用于展示，不得包含响应体、请求头或 query。
class SourceFailure implements Exception {
  const SourceFailure({
    required this.kind,
    required this.stage,
    required this.message,
    this.statusCode,
  });

  final SourceFailureKind kind;
  final SourceStage stage;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
