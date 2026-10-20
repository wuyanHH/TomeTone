/// 规范化网络 URL，供书源身份与章 URL 缓存键使用。
///
/// 规则：
/// - 只接受 `http` / `https`；空地址、无 host、非法 URL 抛 [FormatException]。
/// - 有 [baseUrl] 时先按 RFC 3986 解析相对地址。
/// - scheme / host 小写，去默认端口（80/443）与 fragment。
/// - 路径做点段与重复斜杠折叠，保留大小写、末尾斜杠与 query 参数顺序。
///
/// 不排序、不剥离 query：签名参数与顺序可能参与服务端校验。
String normalizeNetworkUrl(String raw, {Uri? baseUrl}) {
  final input = raw.trim();
  if (input.isEmpty) {
    throw const FormatException('URL 为空');
  }

  final Uri parsed;
  try {
    parsed = baseUrl == null ? Uri.parse(input) : baseUrl.resolve(input);
  } on FormatException {
    throw FormatException('非法 URL: $input');
  }

  final scheme = parsed.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    throw FormatException('只允许 http/https: $input');
  }
  if (parsed.host.isEmpty) {
    throw FormatException('URL 缺少 host: $input');
  }

  final normalized = parsed.normalizePath().removeFragment();
  final host = normalized.host.toLowerCase();
  final isDefaultPort =
      normalized.hasPort &&
      ((scheme == 'http' && normalized.port == 80) ||
          (scheme == 'https' && normalized.port == 443));

  final path = _collapseSlashes(normalized.path);
  return Uri(
    scheme: scheme,
    userInfo: normalized.userInfo.isEmpty ? null : normalized.userInfo,
    host: host,
    port: isDefaultPort || !normalized.hasPort ? null : normalized.port,
    path: path.isEmpty ? '/' : path,
    query: normalized.hasQuery ? normalized.query : null,
  ).toString();
}

String _collapseSlashes(String path) => path.replaceAll(RegExp('/+'), '/');
