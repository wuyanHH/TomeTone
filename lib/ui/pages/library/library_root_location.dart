import 'package:tometone/domain/library/queries/library_views.dart';

/// 书库根在界面上展示的「可读位置」。
///
/// 列表与浏览页都不把原始 SAF tree URI 摊给用户：`content://…` 又长又不可读，
/// 用户真正关心的是「这是内部存储里的哪个文件夹」。这里只做**展示翻译**，
/// 不参与任何读写 —— 真正访问目录仍然把 `root.uri` 原样交给 provider。
///
/// 输入不可识别时逐级退回：可读路径片段 → 展示名 → 原始 URI 末段。
/// 这个函数不允许抛异常：书库列表不能因为某一条来源格式奇怪就整页渲染失败。
String readableLibraryRootLocation(LibraryRootView root) {
  final String raw = root.uri.trim();
  final String displayName = root.displayName.trim();
  try {
    return _readableLocation(raw, displayName);
  } on Object {
    // 最后一道保险：解码器、正则或平台差异都不该让整张列表渲染失败。
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return raw.isEmpty ? '位置未知' : _lastUsefulSegment(raw);
  }
}

String _readableLocation(String raw, String displayName) {
  if (raw.isEmpty) {
    return displayName.isEmpty ? '位置未知' : displayName;
  }

  final String lower = raw.toLowerCase();
  if (lower.startsWith('content://')) {
    return _readableContentUri(raw, displayName);
  }
  if (lower.startsWith('file://')) {
    final String path = _fileUriToPath(raw);
    if (path.isNotEmpty) {
      return _readableLocalPath(path, displayName);
    }
  }
  return _readableLocalPath(raw, displayName);
}

/// Android 上能给出可读目录路径的文档提供方。
///
/// 其它提供方（网盘、第三方文件管理器）的 document id 常是不透明编号，
/// 硬翻译只会得到更奇怪的东西，因此退回展示名。
const Set<String> _readableAuthorities = <String>{
  'com.android.externalstorage.documents',
  'com.android.providers.downloads.documents',
};

String _readableContentUri(String raw, String displayName) {
  final Uri uri;
  try {
    uri = Uri.parse(raw);
  } on Object {
    return _fallbackLocation(raw, displayName);
  }

  final String authority = uri.authority.toLowerCase();
  // 先按 `/` 拆**原始**路径再逐段解码：直接解码整段会让目录名里的 `%2F`
  // 变成真正的分隔符，把一层目录误读成两层。
  final List<String> segments = <String>[
    for (final String segment in uri.path.split('/'))
      if (segment.isNotEmpty) _safeDecode(segment),
  ];
  if (segments.isEmpty) {
    return _fallbackLocation(raw, displayName);
  }

  String? documentId;
  if (segments.length >= 2 && segments.first == 'tree') {
    documentId = segments[1];
  } else if (segments.length >= 2 && segments.first == 'document') {
    documentId = segments[1];
  }
  // 从某个子文档打开的 tree URI 末尾还带 `/document/<id>`，那才是当前位置。
  final int documentIndex = segments.indexOf('document');
  if (documentIndex > 0 && documentIndex + 1 < segments.length) {
    documentId = segments[documentIndex + 1];
  }
  if (documentId == null || documentId.trim().isEmpty) {
    return _fallbackLocation(raw, displayName);
  }

  if (!_readableAuthorities.contains(authority)) {
    // 不透明编号翻译不出路径：展示名永远比一串 base64 更像「位置」。
    if (displayName.isNotEmpty) {
      return displayName;
    }
    return _lastUsefulSegment(documentId);
  }

  final String readable = _readableDocumentId(
    documentId,
    externalStorage: authority == 'com.android.externalstorage.documents',
  );
  return readable.isEmpty ? _fallbackLocation(raw, displayName) : readable;
}

/// 把 SAF 的 document id（`primary:Audiobooks/武侠`）翻成用户熟悉的位置。
String _readableDocumentId(String documentId, {required bool externalStorage}) {
  final String value = documentId.trim();
  if (value.isEmpty) {
    return '';
  }
  // `raw:` 后面本来就是绝对路径，直接按本地路径展示。
  if (value.toLowerCase().startsWith('raw:')) {
    return _readableLocalPath(value.substring(4), '');
  }

  final int colon = value.indexOf(':');
  final String volume = colon >= 0 ? value.substring(0, colon) : '';
  final String rawPath = colon >= 0 ? value.substring(colon + 1) : value;
  final String path = <String>[
    for (final String segment in rawPath.replaceAll('\\', '/').split('/'))
      if (segment.isNotEmpty && segment != '.') segment,
  ].join('/');

  final String volumeLabel = _volumeLabel(
    volume,
    externalStorage: externalStorage,
  );
  if (volumeLabel.isEmpty) {
    // 未知卷：宁可直接给路径，也不把 `1234-ABCD:` 这种编号当前缀。
    return path.isEmpty ? '' : path;
  }
  return path.isEmpty ? volumeLabel : '$volumeLabel/$path';
}

String _volumeLabel(String volume, {required bool externalStorage}) {
  switch (volume.toLowerCase()) {
    case 'primary':
      return '内部存储';
    case 'home':
      return '文档';
    case 'downloads':
      return '下载';
  }
  if (volume.isEmpty) {
    return '';
  }
  // externalstorage 的 SD 卡卷名通常是 `1234-ABCD`；其余卷名按原样展示，
  // 至少比省略卷名更能说明文件在哪。
  if (externalStorage &&
      RegExp(r'^[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}$').hasMatch(volume)) {
    return '存储卡';
  }
  return externalStorage ? volume : '';
}

/// 本地路径：完整保留盘符 / 根目录，不做「只留末级目录」的截断。
String _readableLocalPath(String raw, String fallback) {
  String path = raw.trim();
  if (path.isEmpty) {
    return fallback.isEmpty ? '位置未知' : fallback;
  }

  final bool windowsPath =
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path) || path.startsWith(r'\\');
  if (windowsPath) {
    // Windows 习惯用反斜杠；只换分隔符，不合并开头，避免破坏 UNC 的 `\\`。
    path = path.replaceAll('/', '\\');
  } else if (path.startsWith('/')) {
    path = path.replaceAll('\\', '/');
  }

  if (path.length > 1) {
    path = path.replaceFirst(RegExp(r'[\\/]+$'), '');
  }
  return path.isEmpty ? (fallback.isEmpty ? '位置未知' : fallback) : path;
}

String _fileUriToPath(String raw) {
  try {
    return Uri.parse(raw).toFilePath();
  } on Object {
    final String tail = raw.substring('file://'.length);
    return _safeDecode(tail);
  }
}

String _fallbackLocation(String raw, String displayName) {
  if (displayName.isNotEmpty) {
    return displayName;
  }
  try {
    final List<String> segments = Uri.parse(raw).pathSegments;
    for (final String segment in segments.reversed) {
      if (segment.trim().isNotEmpty) {
        return segment;
      }
    }
  } on Object {
    // 落到下面的手工拆分。
  }
  return _lastUsefulSegment(raw);
}

String _lastUsefulSegment(String value) {
  final List<String> segments = value.split(RegExp(r'[/\\]'));
  for (final String segment in segments.reversed) {
    final String trimmed = _safeDecode(segment).trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return '位置未知';
}

String _safeDecode(String value) {
  if (!value.contains('%')) {
    return value;
  }
  try {
    return Uri.decodeComponent(value);
  } on Object {
    // 编码坏掉时保留原样：显示一个带 `%` 的名字，也比抛异常或空白好。
    return value;
  }
}
