import 'semver.dart';

/// 单个版本的更新记录条目。
class ChangelogEntry {
  /// 创建更新记录条目。
  const ChangelogEntry({
    required this.version,
    required this.title,
    required this.body,
  });

  /// 提取自方括号内的版本标识，如 `'0.2.0-beta.1'`、`'未发布'`。
  final String version;

  /// 完整标题行去掉开头的 `'## '`，如 `'[0.2.0-beta.1] - 2026-10-19'`。
  final String title;

  /// 该条目正文（到下一个 `'## '` 之前），已去掉首尾空白。
  final String body;

  /// 尝试从标题提取发布日期（`YYYY-MM-DD` 格式）。
  String? get releaseDate {
    final match = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(title);
    return match?.group(0);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangelogEntry &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          title == other.title &&
          body == other.body;

  @override
  int get hashCode => Object.hash(version, title, body);

  @override
  String toString() => 'ChangelogEntry(version: $version, title: $title)';
}

/// 解析 Markdown 格式的更新日志（纯 Dart，禁止 import flutter）。
///
/// 规则：
/// - 扫描匹配 `^## \[(.+?)\](.*)$` 的行切分版本段落；
/// - 提取方括号内版本标识与正文（去掉首尾空白）；
/// - 排序规则：
///   - 可解析为 [SemVer] 的版本按 SemVer 倒序排列（版本高的排前面）；
///   - 无法解析为 SemVer 的版本排在后面并保持原相对顺序；
///   - 带有 `'未发布'` / `'unreleased'` 的版本排在最末尾。
List<ChangelogEntry> parseChangelog(String markdown) {
  final headerRegex = RegExp(r'^## \[(.+?)\](.*)$');
  final lines = markdown.split(RegExp(r'\r?\n'));

  final rawEntries = <({ChangelogEntry entry, int originalIndex})>[];
  String? currentVersion;
  String? currentTitle;
  final currentBodyLines = <String>[];

  void flushEntry() {
    if (currentVersion != null && currentTitle != null) {
      rawEntries.add((
        entry: ChangelogEntry(
          version: currentVersion!,
          title: currentTitle!,
          body: currentBodyLines.join('\n').trim(),
        ),
        originalIndex: rawEntries.length,
      ));
    }
    currentVersion = null;
    currentTitle = null;
    currentBodyLines.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    final match = headerRegex.firstMatch(trimmed);
    if (match != null) {
      flushEntry();
      currentVersion = match.group(1)!.trim();
      currentTitle =
          trimmed.startsWith('## ') ? trimmed.substring(3).trim() : trimmed;
    } else if (trimmed.startsWith('## ')) {
      // 遇到非版本格式的二级标题，终止当前版本的正文收集
      flushEntry();
    } else if (currentVersion != null) {
      currentBodyLines.add(line);
    }
  }

  flushEntry();

  if (rawEntries.isEmpty) {
    return const <ChangelogEntry>[];
  }

  // 分类排序：
  // 1. SemVer 可解析版本
  // 2. 无法解析但非"未发布"版本
  // 3. "未发布" (unreleased) 版本
  final semverEntries =
      <({ChangelogEntry entry, SemVer semver, int originalIndex})>[];
  final otherUnparsable = <({ChangelogEntry entry, int originalIndex})>[];
  final unreleasedEntries = <({ChangelogEntry entry, int originalIndex})>[];

  for (final item in rawEntries) {
    final parsed = SemVer.tryParse(item.entry.version) ??
        versionFromTag(item.entry.version);
    if (parsed != null) {
      semverEntries.add((
        entry: item.entry,
        semver: parsed,
        originalIndex: item.originalIndex,
      ));
    } else {
      final lower = item.entry.version.trim().toLowerCase();
      if (lower == '未发布' || lower == 'unreleased') {
        unreleasedEntries.add(item);
      } else {
        otherUnparsable.add(item);
      }
    }
  }

  // SemVer 倒序排列，版本相同时保持原相对顺序
  semverEntries.sort((a, b) {
    final cmp = b.semver.compareTo(a.semver);
    if (cmp != 0) return cmp;
    return a.originalIndex.compareTo(b.originalIndex);
  });

  return <ChangelogEntry>[
    ...semverEntries.map((e) => e.entry),
    ...otherUnparsable.map((e) => e.entry),
    ...unreleasedEntries.map((e) => e.entry),
  ];
}
