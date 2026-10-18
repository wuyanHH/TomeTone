import '../cover/cover_source.dart';

/// 书架列表项（跨表聚合视图，供 UI 直接渲染）。
class BookSummary {
  /// 创建列表项。
  const BookSummary({
    required this.id,
    required this.title,
    required this.libraryRootId,
    required this.rootPath,
    required this.coverSource,
    required this.totalChapters,
    required this.totalDurationMs,
    required this.missingChapters,
    this.author,
    this.narrator,
    this.seriesName,
    this.seriesIndex,
    this.coverPath,
    this.progressChapterId,
    this.progressChapterTitle,
    this.progressPositionMs,
    this.lastListenedAt,
  });

  /// 书 ID（不可变）。
  final String id;

  /// 书名。
  final String title;

  /// 作者。
  final String? author;

  /// 演播者。
  final String? narrator;

  /// 系列名。
  final String? seriesName;

  /// 系列序号。
  final int? seriesIndex;

  /// 封面路径（相对书库根）；`null` 表示走字标兜底。
  final String? coverPath;

  /// 封面来源档位。
  final CoverSource coverSource;

  /// 章节总数（含缺失占位）。
  final int totalChapters;

  /// 累计时长毫秒（不含缺失章节）。
  final int totalDurationMs;

  /// 缺失章节数（>0 时列表应高亮提示）。
  final int missingChapters;

  /// 所属书库根。
  final String libraryRootId;

  /// 书相对路径。
  final String rootPath;

  /// 当前进度所在章。
  final String? progressChapterId;

  /// 当前进度章标题（列表副标题用）。
  final String? progressChapterTitle;

  /// 章内位置毫秒。
  final int? progressPositionMs;

  /// 最近收听时间（用于"最近收听"排序）。
  final DateTime? lastListenedAt;

  /// 是否听过（有进度）。
  bool get hasProgress => progressPositionMs != null;

  /// 累计时长。
  Duration get totalDuration => Duration(milliseconds: totalDurationMs);

  @override
  String toString() => 'BookSummary($title, $totalChapters 章)';
}

/// 卷视图。
class VolumeView {
  /// 创建卷视图。
  const VolumeView({
    required this.id,
    required this.title,
    required this.volumeIndex,
    required this.chapters,
    this.coverPath,
  });

  /// 卷 ID。
  final String id;

  /// 卷标题。
  final String title;

  /// 卷序号。
  final int volumeIndex;

  /// 卷封面路径（相对书库根）。
  final String? coverPath;

  /// 章列表（按 `chapterIndex` 升序）。
  final List<ChapterView> chapters;

  @override
  String toString() => 'VolumeView($title, ${chapters.length} 章)';
}

/// 章视图。
class ChapterView {
  /// 创建章视图。
  const ChapterView({
    required this.id,
    required this.volumeId,
    required this.title,
    required this.chapterIndex,
    required this.filePath,
    required this.missing,
    this.durationMs,
  });

  /// 章 ID（不可变）。
  final String id;

  /// 所属卷。
  final String volumeId;

  /// 章标题。
  final String title;

  /// 全书序号。
  final int chapterIndex;

  /// 绑定路径（相对书库根）。
  final String filePath;

  /// 文件是否缺失。
  final bool missing;

  /// 时长毫秒。
  final int? durationMs;

  @override
  String toString() => 'ChapterView($chapterIndex, $title)';
}

/// 每书偏好的**存储快照**（领域层视图，不依赖应用层的策略类型）。
class PerBookPrefsSnapshot {
  /// 创建快照。
  const PerBookPrefsSnapshot({
    this.speed = 1,
    this.skipIntro = Duration.zero,
    this.skipOutro = Duration.zero,
    this.rewindOverrideJson,
  });

  /// 倍速。
  final double speed;

  /// 片头跳过。
  final Duration skipIntro;

  /// 片尾跳过。
  final Duration skipOutro;

  /// 回退阶梯覆盖（原始 JSON，由应用层解析成阶梯对象）。
  final String? rewindOverrideJson;

  @override
  String toString() => 'PerBookPrefsSnapshot(${speed}x)';
}

/// 播放进度的存储快照。
class ProgressSnapshot {
  /// 创建快照。
  const ProgressSnapshot({
    required this.bookId,
    required this.chapterId,
    required this.position,
    required this.updatedAt,
  });

  /// 书。
  final String bookId;

  /// 章。
  final String chapterId;

  /// 章内位置。
  final Duration position;

  /// 更新时间。
  final DateTime updatedAt;
}

/// 书库根视图。
class LibraryRootView {
  /// 创建书库根视图。
  const LibraryRootView({
    required this.id,
    required this.type,
    required this.uri,
    required this.displayName,
    this.lastScanAt,
  });

  /// 根 ID。
  final String id;

  /// `local` / `saf` / `webdav`。
  final String type;

  /// 根 URI。
  final String uri;

  /// 展示名。
  final String displayName;

  /// 最近扫描时间。
  final DateTime? lastScanAt;

  @override
  String toString() => 'LibraryRootView($displayName)';
}

/// 书详情（书 + 卷 + 章 + 进度 + 偏好）。
class BookDetail {
  /// 创建书详情。
  const BookDetail({
    required this.summary,
    required this.volumes,
    required this.preferences,
    this.progress,
  });

  /// 列表项（含封面与进度）。
  final BookSummary summary;

  /// 卷（按 `volumeIndex` 升序，章已排序）。
  final List<VolumeView> volumes;

  /// 每书偏好。
  final PerBookPrefsSnapshot preferences;

  /// 续播进度（可能为空）。
  final ProgressSnapshot? progress;

  /// 扁平章节列表（跨卷连播队列的输入）。
  List<ChapterView> get chapters => <ChapterView>[
    for (final volume in volumes) ...volume.chapters,
  ];

  @override
  String toString() => 'BookDetail(${summary.title})';
}
