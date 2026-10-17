/// StorageProvider 能力声明（《架构需求文档》§5.3、§7.1）。
///
/// 上层只依据本声明决定降级路径（例如"服务器不支持 Range → 整文件重下"），
/// **不得**基于 `runtimeType` 判断实现。
class ProviderCapabilities {
  /// 创建能力声明。
  const ProviderCapabilities({
    required this.providerType,
    required this.supportsRange,
    required this.supportsWrite,
    required this.supportsDigest,
    required this.supportsAuth,
  });

  /// provider 类型稳定标识：`local` / `saf` / `webdav` / `smb` …
  /// 用于日志与诊断，不含 UI 文案。
  final String providerType;

  /// 是否支持分段读取（HTTP Range / 本地等价能力）。
  final bool supportsRange;

  /// 是否支持写回。
  ///
  /// v1 范围为**只读 + 复制出（入库）**（§7.1），因此实现通常为 `false`；
  /// 该开关为未来能力预留，上层必须在写操作前检查。
  final bool supportsWrite;

  /// 是否提供内容摘要 / 校验标识（ETag、checksum）。
  final bool supportsDigest;

  /// 是否需要认证。
  final bool supportsAuth;

  @override
  String toString() =>
      'ProviderCapabilities($providerType, range: $supportsRange, '
      'write: $supportsWrite, digest: $supportsDigest, auth: $supportsAuth)';
}
