import 'package:tometone/contracts/playback/audio_source_ref.dart';

/// 播放队列中的一章。
///
/// 队列顺序即「卷序 → 章序」，由领域层按 `(volume_index, chapter_index)` 排好；
/// 核心层不做排序，只做相邻关系判定 —— 跨卷连播因此不需要额外分支。
class QueueChapter {
  /// 创建队列章节。
  const QueueChapter({
    required this.chapterId,
    required this.volumeId,
    required this.title,
    required this.source,
    this.duration,
  });

  /// 不可变章节 ID。
  final String chapterId;

  /// 所属卷 ID（跨卷连播时用于提示 / 统计）。
  final String volumeId;

  /// 显示标题。
  final String title;

  /// 播放源引用。
  final AudioSourceRef source;

  /// 时长（未知为 `null`）。
  final Duration? duration;

  @override
  String toString() => 'QueueChapter($title)';
}

/// 「上一曲」判定结果。
class PreviousResolution {
  /// 创建判定结果。
  const PreviousResolution({required this.chapter, required this.restartOnly});

  /// 目标章节。
  final QueueChapter chapter;

  /// `true` = 重播本章（从头）；`false` = 切换到上一章。
  final bool restartOnly;

  @override
  String toString() =>
      'PreviousResolution(${chapter.title}, restartOnly: $restartOnly)';
}

/// 章节队列与相邻关系（跨卷连播 / 上一曲判定，§2.2）。
class ChapterSequencer {
  /// 用已排序的章节创建队列。重复 [QueueChapter.chapterId] 视为调用方错误。
  ChapterSequencer(List<QueueChapter> chapters)
    : chapters = List<QueueChapter>.unmodifiable(chapters),
      _indexById = <String, int>{
        for (var index = 0; index < chapters.length; index++)
          chapters[index].chapterId: index,
      } {
    if (_indexById.length != chapters.length) {
      throw ArgumentError('播放队列存在重复 chapterId');
    }
  }

  /// 队列（只读，顺序即播放顺序）。
  final List<QueueChapter> chapters;

  final Map<String, int> _indexById;

  /// 队列是否为空。
  bool get isEmpty => chapters.isEmpty;

  /// 第一章；空队列为 `null`。
  QueueChapter? get first => chapters.isEmpty ? null : chapters.first;

  /// 最后一章；空队列为 `null`。
  QueueChapter? get last => chapters.isEmpty ? null : chapters.last;

  /// 按 ID 取章。
  QueueChapter? byId(String chapterId) {
    final index = _indexById[chapterId];
    return index == null ? null : chapters[index];
  }

  /// 下一章（跨卷，自动进入下一卷首章）；全书完成为 `null`。
  QueueChapter? nextOf(String chapterId) {
    final index = _indexById[chapterId];
    if (index == null || index + 1 >= chapters.length) {
      return null;
    }
    return chapters[index + 1];
  }

  /// 上一章（跨卷）；全书首章为 `null`。
  QueueChapter? previousOf(String chapterId) {
    final index = _indexById[chapterId];
    if (index == null || index == 0) {
      return null;
    }
    return chapters[index - 1];
  }

  /// 是否全书首章。
  bool isFirst(String chapterId) => _indexById[chapterId] == 0;

  /// 是否全书末章。
  bool isLast(String chapterId) {
    final index = _indexById[chapterId];
    return index != null && index == chapters.length - 1;
  }

  /// 「上一曲」判定（§2.2）：
  ///
  /// - 播放位置 > [restartThreshold]（默认 3 秒）→ **重播本章**；
  /// - 否则回到上一章（可跨卷）；
  /// - 已是全书首章 → 仍重播本章（等价于"回到 0 秒"）。
  ///
  /// 未知章节返回 `null`（调用方状态已损坏，不应静默猜测）。
  PreviousResolution? resolvePrevious({
    required String chapterId,
    required Duration position,
    Duration restartThreshold = const Duration(seconds: 3),
  }) {
    final current = byId(chapterId);
    if (current == null) {
      return null;
    }
    if (position > restartThreshold) {
      return PreviousResolution(chapter: current, restartOnly: true);
    }
    final previous = previousOf(chapterId);
    if (previous == null) {
      return PreviousResolution(chapter: current, restartOnly: true);
    }
    return PreviousResolution(chapter: previous, restartOnly: false);
  }
}
