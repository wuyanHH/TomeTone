import 'dart:io';

import 'provider_capabilities.dart';
import 'stat_info.dart';
import 'storage_entry.dart';

/// 统一存储访问契约（《架构需求文档》§7.1）。
///
/// 本地目录、SAF、WebDAV、SMB、直连网盘均实现同一契约；上层（书库扫描、入库通道）
/// 只面向本接口，从而实现"存储后端可替换"。
///
/// v1 范围：**只读 + 复制出（入库）**；远程写回不在范围（§7.1）。
///
/// ## 规范行为（实现必须满足）
///
/// 1. **路径不存在**抛 [StorageErrorCode.notFound]；路径非法抛
///    [StorageErrorCode.invalidPath]。
/// 2. **Range**：`capabilities.supportsRange == false` 时，`start > 0` 的
///    `readRange` 必须抛 [StorageErrorCode.serverUnsupported]（上层据此降级为整文件重下）。
/// 3. **流生命周期**：`readRange` 返回**单订阅**流；取消订阅必须中止底层传输
///    （HTTP 连接 / 文件句柄），不得留下悬挂资源。
/// 4. **进度回调**：`downloadTo` 的 `onProgress(received, total)`，
///    `total <= 0` 表示总长未知。
/// 5. **释放**：[dispose] 幂等；释放后任何方法调用抛
///    [StorageErrorCode.unsupportedOperation]。
abstract class StorageProvider {
  /// 列出 [path] 下的直接子项（不递归）。
  Future<List<StorageEntry>> list(String path);

  /// 获取 [path] 的元信息。
  Future<StatInfo> stat(String path);

  /// 读取 `[start, end]` 字节区间（**两端闭合**）；`end == null` 表示读到文件末尾。
  ///
  /// 返回单订阅流。
  Future<Stream<List<int>>> readRange(String path, int start, int? end);

  /// 把 [path] 完整下载到本地 [target]。
  Future<void> downloadTo(
    String path,
    File target, {
    void Function(int received, int total)? onProgress,
  });

  /// 能力声明。
  ProviderCapabilities get capabilities;

  /// 释放底层资源（HTTP 客户端、文件句柄池、缓存）。
  ///
  /// 属于对 §7.1 草案的补充：远程 provider 若持有连接池而不释放，
  /// 会在长生命周期进程里持续泄漏套接字 —— 契约必须强制可释放。
  Future<void> dispose();
}
