/// 发现页的一个分类入口。
class ExploreCategory {
  const ExploreCategory({required this.name, required this.urlTemplate});

  final String name;
  final String urlTemplate;
}

/// 解析 Legado `exploreUrl`：每行或 `&&` 分隔的 `名称::URL 模板`。
List<ExploreCategory> parseExploreCategories({
  required String? exploreUrl,
  required bool enabledExplore,
}) {
  if (!enabledExplore) {
    return const <ExploreCategory>[];
  }
  final raw = exploreUrl?.trim();
  if (raw == null || raw.isEmpty) {
    return const <ExploreCategory>[];
  }

  final categories = <ExploreCategory>[];
  for (final part in raw.split(RegExp(r'\r?\n|&&'))) {
    final entry = part.trim();
    if (entry.isEmpty) {
      continue;
    }
    final separator = entry.indexOf('::');
    if (separator <= 0) {
      continue;
    }
    final name = entry.substring(0, separator).trim();
    final url = entry.substring(separator + 2).trim();
    if (name.isEmpty || url.isEmpty) {
      continue;
    }
    categories.add(ExploreCategory(name: name, urlTemplate: url));
  }
  return List<ExploreCategory>.unmodifiable(categories);
}
