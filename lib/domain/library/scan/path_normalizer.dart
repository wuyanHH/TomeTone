import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// 路径归一化（《架构需求文档》§8.2：绑定键使用 NFC 规范化相对路径）。
///
/// 为什么必须做 NFC：同一份文件在不同来源下可能是 NFC 或 NFD 形式
/// （macOS / 云同步客户端常见的坑），字节不同但显示完全相同。
/// 若不做归一化，同一个文件会生成两个绑定键 → 重复书、进度错位。
abstract final class PathNormalizer {
  /// 归一化为「NFC + `/` 分隔 + 无前导 / 尾随 `/` + 折叠 `.` 与空段」。
  ///
  /// `..` 也会被折叠（provider 不应返回它，这里是防御性处理）。
  static String normalize(String path) {
    final replaced = path.replaceAll('\\', '/');
    final segments = <String>[];
    for (final raw in replaced.split('/')) {
      if (raw.isEmpty || raw == '.') {
        continue;
      }
      if (raw == '..') {
        if (segments.isNotEmpty) {
          segments.removeLast();
        }
        continue;
      }
      segments.add(unorm.nfc(raw));
    }
    return segments.join('/');
  }

  /// 路径深度（分段数）。空路径为 0。
  static int depthOf(String path) {
    final normalized = normalize(path);
    return normalized.isEmpty ? 0 : normalized.split('/').length;
  }
}
