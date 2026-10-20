/// 书架元数据的值对象（§2.1「书架与元数据」）。
///
/// [BookMetadataDraft] 是"待写入的元数据草稿"：所有字段可空，`normalized()`
/// 产出归一化后的草稿（字符串 trim、空串转 `null`、标签去重）。
library;

/// 归一化一组标签。
///
/// 规则（§2.1）：
/// - 每个输入项再按 `,` / `，` / `、` 拆分（支持"武侠,长篇"这类未拆分的整串）；
/// - 去首尾空格、丢弃空串；
/// - **大小写不敏感**去重，保留**首次出现的写法**（如 `A` / `a` 保留 `A`）。
List<String> normalizeTags(Iterable<String> raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final entry in raw) {
    for (final piece in entry.split(_tagSeparators)) {
      final tag = piece.trim();
      if (tag.isEmpty) {
        continue;
      }
      // 以 lower-case 作为去重键，保留首次写法。
      if (seen.add(tag.toLowerCase())) {
        result.add(tag);
      }
    }
  }
  return result;
}

/// 标签分隔符：半角逗号、全角逗号、顿号。
final RegExp _tagSeparators = RegExp('[,，、]');

/// 元数据草稿（§2.1）：待写入 `books` / `book_metadata_overrides` / `book_tags`
/// 的原始输入，字段均可空。
class BookMetadataDraft {
  /// 创建草稿。
  const BookMetadataDraft({
    this.title,
    this.author,
    this.narrator,
    this.seriesName,
    this.seriesIndex,
    this.description,
    this.tags = const <String>[],
  });

  /// 书名。
  final String? title;

  /// 作者。
  final String? author;

  /// 演播者。
  final String? narrator;

  /// 系列名。
  final String? seriesName;

  /// 系列序号。
  final int? seriesIndex;

  /// 简介。
  final String? description;

  /// 标签（原始输入，可能含空格、重复、未拆分整串）。
  final List<String> tags;

  /// 是否为空：所有字段为空且 `tags` 为空。
  bool get isEmpty =>
      _isBlank(title) &&
      _isBlank(author) &&
      _isBlank(narrator) &&
      _isBlank(seriesName) &&
      seriesIndex == null &&
      _isBlank(description) &&
      tags.isEmpty;

  /// 归一化副本：字符串字段 `trim()`、空串转 `null`，标签走 [normalizeTags]。
  BookMetadataDraft normalized() {
    return BookMetadataDraft(
      title: _normalizeString(title),
      author: _normalizeString(author),
      narrator: _normalizeString(narrator),
      seriesName: _normalizeString(seriesName),
      seriesIndex: seriesIndex,
      description: _normalizeString(description),
      tags: normalizeTags(tags),
    );
  }

  static String? _normalizeString(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _isBlank(String? value) =>
      value == null || value.trim().isEmpty;
}
