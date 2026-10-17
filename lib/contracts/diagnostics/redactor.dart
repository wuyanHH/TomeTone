/// 日志脱敏（《架构需求文档》§9.5 强制规则）。
///
/// 铁律：URL / Cookie / Token / 路径在**进入任何日志之前**必须脱敏。
/// 宁可少记，不可泄漏 —— 诊断价值永远排在用户隐私之后。
///
/// 本类为无状态纯函数工具，任何分层都可使用（含 `modules` 与 `platform`）。
abstract final class Redactor {
  /// 被替换内容的占位符。
  static const String placeholder = '<redacted>';

  /// 需要整体脱敏的请求头（按小写比较）。
  static const Set<String> sensitiveHeaders = <String>{
    'authorization',
    'cookie',
    'set-cookie',
    'proxy-authorization',
    'x-auth-token',
    'x-api-key',
    'x-token',
  };

  /// 脱敏 URL：丢弃 userinfo（`user:pass@`）、query 与 fragment。
  ///
  /// `https://user:pw@nas.local:5006/books/a.mp3?token=abc` →
  /// `https://nas.local:5006/books/a.mp3?<redacted>`
  ///
  /// 非 URL 形态的字符串按不透明凭据处理（整体脱敏），避免"看起来像路径的密钥"泄漏。
  static String url(String value) {
    if (value.isEmpty) {
      return value;
    }
    final uri = Uri.tryParse(value);
    // 单字符 scheme（如 Windows 盘符 `C:\...`）不视为 URL。
    if (uri == null || !uri.hasScheme || uri.scheme.length <= 1) {
      return token(value);
    }

    final buffer = StringBuffer('${uri.scheme}://');
    if (uri.host.isNotEmpty) {
      buffer.write(uri.host);
      if (uri.hasPort) {
        buffer.write(':${uri.port}');
      }
    }
    buffer.write(uri.path.isEmpty ? '/' : uri.path);
    if (uri.hasQuery) {
      buffer.write('?$placeholder');
    }
    if (uri.hasFragment) {
      buffer.write('#$placeholder');
    }
    return buffer.toString();
  }

  /// 脱敏请求头：敏感头整体按不透明凭据处理，其余原样保留。
  static Map<String, String> headers(Map<String, String> headers) {
    return <String, String>{
      for (final entry in headers.entries)
        entry.key: sensitiveHeaders.contains(entry.key.toLowerCase())
            ? token(entry.value)
            : entry.value,
    };
  }

  /// 脱敏文件 / 远端路径：仅保留最后一段（丢弃可能含有账户名的父目录）。
  ///
  /// `/storage/emulated/0/Books/三体/001.mp3` → `…/001.mp3`
  static String path(String value) {
    if (value.isEmpty) {
      return value;
    }
    final segments = value
        .replaceAll('\\', '/')
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      return '/';
    }
    return '…/${segments.last}';
  }

  /// 脱敏不透明凭据：长度 ≤ 6 全部替换，否则只保留首尾各 2 个字符。
  static String token(String value) {
    if (value.isEmpty) {
      return value;
    }
    if (value.length <= 6) {
      return placeholder;
    }
    return '${value.substring(0, 2)}…${value.substring(value.length - 2)}';
  }
}
