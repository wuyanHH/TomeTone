import '../diagnostics/redactor.dart';

/// 播放引擎的结构化错误码（《架构需求文档》§5.3）。
///
/// 模块只抛**错误码 + 上下文**，绝不携带 UI 文案；本地化由 UI 层负责。
enum EngineErrorCode {
  /// 格式不受当前引擎 / 平台支持（§6.4 引擎自检可见）。
  unsupportedFormat,

  /// 调用顺序非法（例如未 `load` 就 `seek`）。
  illegalState,

  /// 操作不受当前能力声明支持（例如超出 `minSpeed..maxSpeed`）。
  unsupportedOperation,

  /// 源不存在或不可读。
  sourceNotFound,

  /// 无网络 / 网络不可达。
  networkUnavailable,

  /// 认证失败。
  authenticationFailed,

  /// 无权限访问源。
  permissionDenied,

  /// 服务器不支持该操作（例如不支持 Range）。
  serverUnsupported,

  /// 解码失败（文件损坏 / 编码不支持）。
  decodeFailed,

  /// 播放被外部因素打断（音频焦点丢失、设备切换等）。
  interrupted,

  /// 兜底。
  unknown,
}

/// 播放引擎的结构化错误。
///
/// 注意：`toString` **只输出错误码**，不输出 URI 与底层异常信息 ——
/// 需要记录上下文时必须显式使用 [Redactor] 脱敏，防止凭据随异常链泄漏。
class EngineError implements Exception {
  /// 创建结构化引擎错误。
  const EngineError({
    required this.code,
    this.sourceUri,
    this.cause,
    this.stackTrace,
  });

  /// 错误码。
  final EngineErrorCode code;

  /// 出错的源 URI（**可能含凭据**，记录前必须 `Redactor.url`）。
  final String? sourceUri;

  /// 底层原因（平台异常等）。
  final Object? cause;

  /// 底层堆栈。
  final StackTrace? stackTrace;

  /// 脱敏后的诊断描述，可直接用于日志。
  String toDiagnosticString() {
    final buffer = StringBuffer('EngineError(${code.name})');
    final uri = sourceUri;
    if (uri != null && uri.isNotEmpty) {
      buffer.write(' source=${Redactor.url(uri)}');
    }
    return buffer.toString();
  }

  @override
  String toString() => 'EngineError(${code.name})';
}
