import '../diagnostics/redactor.dart';

/// 存储访问的结构化错误码（《架构需求文档》§2.5 错误模型 + §5.3）。
///
/// 前六项与 §2.5 的"网络 / 认证 / 权限 / 空间不足 / 文件冲突 / 服务器不支持"
/// 一一对应；本地 provider 另有若干等价语义。
enum StorageErrorCode {
  /// 网络不可达 / 超时。
  network,

  /// 认证失败（凭据错误或过期）。
  authentication,

  /// 无权限访问。
  permission,

  /// 空间不足。
  quotaExceeded,

  /// 文件冲突（命名冲突 / 并发修改）。
  conflict,

  /// 服务器不支持请求的操作（例如不支持 Range）。
  serverUnsupported,

  /// 路径不存在。
  notFound,

  /// 路径非法（越界、编码错误、非法字符）。
  invalidPath,

  /// 操作不受当前能力声明支持（例如在只读 provider 上写入）。
  unsupportedOperation,

  /// 本地 IO 失败。
  io,

  /// 兜底。
  unknown,
}

/// 存储访问的结构化错误。
///
/// 与 `EngineError` 一致：`toString` 只输出错误码，上下文需显式经 [Redactor] 脱敏。
class StorageError implements Exception {
  /// 创建结构化存储错误。
  const StorageError({
    required this.code,
    this.path,
    this.statusCode,
    this.cause,
    this.stackTrace,
  });

  /// 错误码。
  final StorageErrorCode code;

  /// 出错的路径（可能含账户名，记录前必须 `Redactor.path`）。
  final String? path;

  /// HTTP 状态码（远程 provider 适用）。
  final int? statusCode;

  /// 底层原因。
  final Object? cause;

  /// 底层堆栈。
  final StackTrace? stackTrace;

  /// 脱敏后的诊断描述，可直接用于日志。
  String toDiagnosticString() {
    final buffer = StringBuffer('StorageError(${code.name})');
    final target = path;
    if (target != null && target.isNotEmpty) {
      buffer.write(' path=${Redactor.path(target)}');
    }
    final status = statusCode;
    if (status != null) {
      buffer.write(' status=$status');
    }
    return buffer.toString();
  }

  @override
  String toString() => 'StorageError(${code.name})';
}
