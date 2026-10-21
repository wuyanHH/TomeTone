/// 在线书源发现/搜索的一条书目摘要。
class SourceBookSummary {
  const SourceBookSummary({
    required this.title,
    required this.bookUrl,
    this.author,
    this.narrator,
    this.coverUrl,
    this.intro,
    this.kind,
    this.wordCount,
    this.lastChapter,
    this.status,
  });

  final String title;
  final String bookUrl;
  final String? author;
  final String? narrator;
  final String? coverUrl;
  final String? intro;
  final String? kind;
  final String? wordCount;
  final String? lastChapter;
  final String? status;
}

/// 在线书详情；[tocUrl] 已解析为绝对 URL。
class SourceBookInfo extends SourceBookSummary {
  const SourceBookInfo({
    required super.title,
    required super.bookUrl,
    required this.tocUrl,
    super.author,
    super.narrator,
    super.coverUrl,
    super.intro,
    super.kind,
    super.wordCount,
    super.lastChapter,
    super.status,
  });

  final String tocUrl;
}

/// 在线目录的一章。
class SourceChapter {
  const SourceChapter({
    required this.index,
    required this.title,
    required this.rawUrl,
    required this.url,
    required this.isVip,
  });

  /// 跨页连续的 0-based 序号。
  final int index;
  final String title;

  /// 规则求值后的原始 URL，可能带 `,{options}`。
  final String rawUrl;

  /// 去掉 options 并规范化后的绝对 URL，用于书身份/缓存键。
  final String url;
  final bool isVip;
}

class SourcePage<T> {
  const SourcePage({
    required this.items,
    required this.hasMore,
    required this.finalUrl,
    this.warnings = const <String>[],
  });

  final List<T> items;
  final bool hasMore;
  final Uri finalUrl;
  final List<String> warnings;
}

class SourceToc {
  const SourceToc({
    required this.chapters,
    required this.complete,
    this.warnings = const <String>[],
  });

  final List<SourceChapter> chapters;

  /// 是否完整跟随到 `nextTocUrl` 的终点。
  final bool complete;
  final List<String> warnings;
}

/// 解析后的音频地址与请求头。
class ResolvedAudio {
  const ResolvedAudio({
    required this.url,
    this.headers = const <String, String>{},
  });

  final String url;
  final Map<String, String> headers;
}

class SourceTestReport {
  const SourceTestReport({
    required this.latency,
    required this.resultCount,
    this.sampleTitle,
  });

  final Duration latency;
  final int resultCount;
  final String? sampleTitle;
}
