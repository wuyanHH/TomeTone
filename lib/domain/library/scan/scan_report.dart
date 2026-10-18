/// 一次结构扫描（Phase 1）的结果统计。
///
/// 只统计**实际发生的写入**：二次扫描同一棵树时全部为 0 —— 这正是
/// "增量扫描：仅处理新增 / 变更 / 消失"（§2.1）的可观测证据。
class ScanReport {
  /// 创建扫描报告。
  const ScanReport({
    required this.libraryRootId,
    required this.booksSeen,
    required this.booksAdded,
    required this.booksUpdated,
    required this.volumesAdded,
    required this.chaptersSeen,
    required this.chaptersAdded,
    required this.chaptersUpdated,
    required this.chaptersMarkedMissing,
    required this.chaptersRestored,
    required this.ignoredFiles,
    required this.failedPaths,
    required this.elapsed,
  });

  /// 书库根。
  final String libraryRootId;

  /// 本次推导出的书数量。
  final int booksSeen;

  /// 新增书。
  final int booksAdded;

  /// 变更书（标题 / 计数变化）。
  final int booksUpdated;

  /// 新增卷。
  final int volumesAdded;

  /// 本次推导出的章数量。
  final int chaptersSeen;

  /// 新增章。
  final int chaptersAdded;

  /// 变更章（标题 / 序号 / 大小 / 归属变化，或从缺失恢复）。
  final int chaptersUpdated;

  /// 被标记为缺失的章（**只标记，不删除**，§9.2）。
  final int chaptersMarkedMissing;

  /// 从缺失状态恢复的章。
  final int chaptersRestored;

  /// 被忽略的非音频文件数。
  final int ignoredFiles;

  /// 读取失败的目录路径（单目录不可读不中断整次扫描）。
  final List<String> failedPaths;

  /// 扫描耗时。
  final Duration elapsed;

  /// 是否有任何写入发生。
  bool get hasChanges =>
      booksAdded +
          booksUpdated +
          volumesAdded +
          chaptersAdded +
          chaptersUpdated +
          chaptersMarkedMissing >
      0;

  @override
  String toString() =>
      'ScanReport(书 $booksSeen, 章 $chaptersSeen, 新增 $chaptersAdded, '
      '变更 $chaptersUpdated, 缺失 $chaptersMarkedMissing, '
      '恢复 $chaptersRestored, 忽略 $ignoredFiles, ${elapsed.inMilliseconds}ms)';
}

/// 一次元信息回填（Phase 2）的结果统计。
class BackfillReport {
  /// 创建回填报告。
  const BackfillReport({
    required this.updated,
    required this.failed,
    required this.remaining,
  });

  /// 成功回填的章数。
  final int updated;

  /// 读取失败的章数（已跳过，不影响其它章）。
  final int failed;

  /// 仍未回填的章数（> 0 表示需要再来一轮）。
  final int remaining;

  @override
  String toString() => 'BackfillReport(成功 $updated, 失败 $failed, 剩余 $remaining)';
}
