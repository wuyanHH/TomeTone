/// 智能微回退阶梯（《架构需求文档》§2.2）。
///
/// | 中断间隔 ΔT（暂停 → 恢复） | 回退 Rewind |
/// | :--- | :--- |
/// | < 30 秒 | 0 秒（即点即播，不回退） |
/// | 30 秒 – 5 分钟 | 3 秒 |
/// | 5 – 30 分钟 | 8 秒 |
/// | ≥ 30 分钟或跨进程重启 | 15 秒 |
///
/// `TargetPos = max(0, SavedPos - Rewind(ΔT))`。
///
/// 阶梯是**数据**而不是分支：每书偏好可以整体替换 [steps]，无需改判定逻辑。
library;

/// 阶梯的一档：中断间隔小于 [lessThan] 时回退 [rewind]。
class RewindStep {
  /// 创建一档。
  const RewindStep({required this.lessThan, required this.rewind});

  /// 上界（开区间）。
  final Duration lessThan;

  /// 回退秒数。
  final Duration rewind;

  @override
  String toString() =>
      'RewindStep(<${lessThan.inSeconds}s → ${rewind.inSeconds}s)';
}

/// 可配置的回退阶梯。
class RewindLadder {
  /// 创建阶梯。
  const RewindLadder({
    this.steps = standardSteps,
    this.beyondLastStep = defaultBeyondLastStep,
    this.restartRewind = defaultRestartRewind,
  });

  /// 文档标准阶梯（<30s / <5min / <30min 三档）。
  static const List<RewindStep> standardSteps = <RewindStep>[
    RewindStep(lessThan: Duration(seconds: 30), rewind: Duration.zero),
    RewindStep(lessThan: Duration(minutes: 5), rewind: Duration(seconds: 3)),
    RewindStep(lessThan: Duration(minutes: 30), rewind: Duration(seconds: 8)),
  ];

  /// 超过最后一档上界时的回退（文档：≥30 分钟 → 15 秒）。
  static const Duration defaultBeyondLastStep = Duration(seconds: 15);

  /// 跨进程重启的回退（文档：≥30 分钟或跨进程重启 → 15 秒）。
  static const Duration defaultRestartRewind = Duration(seconds: 15);

  /// 阶梯各档（升序）。
  final List<RewindStep> steps;

  /// 超过最后一档上界时的回退。
  final Duration beyondLastStep;

  /// 跨进程重启时的回退。
  final Duration restartRewind;

  /// 按中断间隔取回退秒数。
  ///
  /// [processRestarted] 为真时**无视** ΔT 直接取 [restartRewind]：
  /// 跨进程重启后 ΔT 已不可信（应用可能被杀掉数天）。
  Duration rewindFor(Duration interruption, {bool processRestarted = false}) {
    if (processRestarted) {
      return restartRewind;
    }
    final safe = interruption.isNegative ? Duration.zero : interruption;
    for (final step in steps) {
      if (safe < step.lessThan) {
        return step.rewind;
      }
    }
    return beyondLastStep;
  }

  /// 计算恢复目标位置（永不为负）。
  Duration targetPosition({
    required Duration saved,
    Duration interruption = Duration.zero,
    bool processRestarted = false,
  }) {
    final target =
        saved - rewindFor(interruption, processRestarted: processRestarted);
    return target.isNegative ? Duration.zero : target;
  }

  @override
  String toString() => 'RewindLadder($steps, beyond: $beyondLastStep)';
}
