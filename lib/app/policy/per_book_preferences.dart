import 'rewind_ladder.dart';

/// 每书播放偏好（《架构需求文档》§2.2 / §8.2 `per_book_prefs`）。
///
/// 「片头 / 片尾跳过」按**章**生效（每个音频文件的开头 / 结尾各跳过 N 秒）：
/// 长篇有声书常在每个文件里重复片头音乐，这是该功能真正要解决的问题。
class PerBookPreferences {
  /// 创建偏好。
  const PerBookPreferences({
    this.speed = 1,
    this.skipIntro = Duration.zero,
    this.skipOutro = Duration.zero,
    this.rewindLadder,
  });

  /// 默认偏好（1.0 倍速、不跳过、沿用全局阶梯）。
  static const PerBookPreferences defaults = PerBookPreferences();

  /// 倍速记忆。
  final double speed;

  /// 片头跳过秒数。
  final Duration skipIntro;

  /// 片尾跳过秒数。
  final Duration skipOutro;

  /// 回退阶梯覆盖（`null` 表示沿用全局标准阶梯）。
  final RewindLadder? rewindLadder;

  /// 实际生效的回退阶梯。
  RewindLadder get ladder => rewindLadder ?? const RewindLadder();

  /// 章节的实际播放区间。
  ///
  /// - [chapterDuration] 未知时 `end` 为 `null`：以"实际播放完毕"作为结束信号；
  /// - 跳过值超过时长时收敛到合法区间（不产生负长度）。
  ({Duration start, Duration? end}) playbackRange(Duration? chapterDuration) {
    final intro = skipIntro.isNegative ? Duration.zero : skipIntro;
    final outro = skipOutro.isNegative ? Duration.zero : skipOutro;

    final duration = chapterDuration;
    if (duration == null || duration.isNegative) {
      return (start: intro, end: null);
    }

    final start = intro > duration ? duration : intro;
    var end = duration - outro;
    if (end < start) {
      end = start;
    }
    return (start: start, end: end);
  }

  /// 复制并覆盖部分字段。
  PerBookPreferences copyWith({
    double? speed,
    Duration? skipIntro,
    Duration? skipOutro,
    RewindLadder? rewindLadder,
    bool clearRewindLadder = false,
  }) {
    return PerBookPreferences(
      speed: speed ?? this.speed,
      skipIntro: skipIntro ?? this.skipIntro,
      skipOutro: skipOutro ?? this.skipOutro,
      rewindLadder: clearRewindLadder
          ? null
          : (rewindLadder ?? this.rewindLadder),
    );
  }

  @override
  String toString() =>
      'PerBookPreferences(${speed}x, intro: ${skipIntro.inSeconds}s, '
      'outro: ${skipOutro.inSeconds}s)';
}
