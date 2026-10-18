/// 睡眠守夜（《架构需求文档》§2.2，三模式）。
///
/// 1. **相对倒计时**：到期后渐弱并暂停（[fadeFactor] 由播放层施加到音量）；
/// 2. **播完当前章即停**：由播放层在章节完毕时调用 [onChapterCompleted]；
/// 3. **回到 N 分钟前**：属于**恢复时**的动作而非计时器，见
///    `SleepRewind`（"无效收听段"的撤销）。
///
/// 本类只做时间判定与状态机，不持有 `Timer`：由播放层按帧 / 按秒驱动 [tick]，
/// 因此可以在测试里用可控时钟把"最后 10 秒渐弱"精确断言出来。
enum SleepMode {
  /// 未启用。
  off,

  /// 相对倒计时。
  countdown,

  /// 播完当前章即停。
  endOfChapter,
}

/// 睡眠守夜状态机。
class SleepTimer {
  /// 创建状态机。
  SleepTimer({
    DateTime Function()? clock,
    this.fadeOut = const Duration(seconds: 10),
  }) : _clock = clock ?? DateTime.now;

  /// 渐弱时长（倒计时的最后这段时间里音量线性降到 0）。
  final Duration fadeOut;

  final DateTime Function() _clock;

  SleepMode _mode = SleepMode.off;
  DateTime? _endsAt;

  /// 当前模式。
  SleepMode get mode => _mode;

  /// 倒计时到点时间（仅 [SleepMode.countdown]）。
  DateTime? get endsAt => _endsAt;

  /// 是否已启用。
  bool get isActive => _mode != SleepMode.off;

  /// 剩余时间（仅倒计时模式；已到期为 `Duration.zero`）。
  Duration? get remaining {
    final endsAt = _endsAt;
    if (_mode != SleepMode.countdown || endsAt == null) {
      return null;
    }
    final left = endsAt.difference(_clock());
    return left.isNegative ? Duration.zero : left;
  }

  /// 音量渐弱系数：`1.0`（正常）→ `0.0`（静音）。
  ///
  /// 只在倒计时**最后 [fadeOut]** 内小于 1；其它模式恒为 1。
  double get fadeFactor {
    final left = remaining;
    if (left == null) {
      return 1;
    }
    if (fadeOut <= Duration.zero) {
      return left > Duration.zero ? 1 : 0;
    }
    if (left >= fadeOut) {
      return 1;
    }
    final factor = left.inMilliseconds / fadeOut.inMilliseconds;
    return factor.clamp(0.0, 1.0).toDouble();
  }

  /// 启动相对倒计时。非正时长视为关闭。
  void startCountdown(Duration duration) {
    if (duration <= Duration.zero) {
      cancel();
      return;
    }
    _mode = SleepMode.countdown;
    _endsAt = _clock().add(duration);
  }

  /// 设定"播完当前章即停"。
  void stopAtChapterEnd() {
    _mode = SleepMode.endOfChapter;
    _endsAt = null;
  }

  /// 关闭睡眠守夜。
  void cancel() {
    _mode = SleepMode.off;
    _endsAt = null;
  }

  /// 驱动一次时间检查。返回 `true` 表示**倒计时到点，应立即暂停**。
  ///
  /// 到点后自动关闭（避免重复触发）。
  bool tick() {
    if (_mode != SleepMode.countdown) {
      return false;
    }
    final endsAt = _endsAt;
    if (endsAt == null) {
      return false;
    }
    if (_clock().isBefore(endsAt)) {
      return false;
    }
    cancel();
    return true;
  }

  /// 当前章播放完毕。返回 `true` 表示应暂停。
  ///
  /// 只有 [SleepMode.endOfChapter] 会命中；命中后自动关闭。
  bool onChapterCompleted() {
    if (_mode != SleepMode.endOfChapter) {
      return false;
    }
    cancel();
    return true;
  }
}

/// 「回到 N 分钟前」——睡眠守夜第 3 模式。
///
/// 针对"听睡着后产生的无效收听段"：恢复时一键回退 N 分钟（默认 10），
/// 且与智能微回退一样支持撤销。
abstract final class SleepRewind {
  /// 默认回退分钟数。
  static const int defaultMinutes = 10;

  /// 计算回退目标：`max(0, saved - N 分钟)`。
  static Duration targetPosition({
    required Duration saved,
    Duration rewind = const Duration(minutes: defaultMinutes),
  }) {
    final safe = rewind.isNegative ? Duration.zero : rewind;
    final target = saved - safe;
    return target.isNegative ? Duration.zero : target;
  }
}
