import 'engine_error.dart';

/// 引擎对外播报的播放状态。
///
/// 状态语义直接服务于聆听纪年心跳（§2.3）：**仅 [playing] 计入收听时长**，
/// [buffering] / [paused] / [idle] 一律不计，防止挂机虚增。
enum EnginePlaybackState {
  /// 未加载任何源。
  idle,

  /// 正在加载源。
  loading,

  /// 已加载但正在缓冲（不计入收听）。
  buffering,

  /// 已就绪、未播放。
  ready,

  /// 真实播放中（**唯一计入收听时长**的状态）。
  playing,

  /// 已暂停。
  paused,

  /// 当前源播放完毕。
  ///
  /// 引擎**不自行推进**到下一源：跨卷连播属于核心层策略（§6.2）。
  completed,
}

/// 引擎事件（引擎 → 上层）。
sealed class EngineEvent {
  const EngineEvent();
}

/// 播放状态发生变化。
final class EngineStateChanged extends EngineEvent {
  /// 创建状态变化事件。
  const EngineStateChanged(this.state);

  /// 新状态。
  final EnginePlaybackState state;

  @override
  String toString() => 'EngineStateChanged(${state.name})';
}

/// 播放位置推进。
final class EnginePositionChanged extends EngineEvent {
  /// 创建位置事件。
  const EnginePositionChanged(this.position);

  /// 新位置。
  final Duration position;

  @override
  String toString() => 'EnginePositionChanged(${position.inMilliseconds}ms)';
}

/// 时长已就绪或发生变化（`null` 表示当前源时长未知）。
final class EngineDurationChanged extends EngineEvent {
  /// 创建时长事件。
  const EngineDurationChanged(this.duration);

  /// 时长。
  final Duration? duration;

  @override
  String toString() => 'EngineDurationChanged(${duration?.inMilliseconds}ms)';
}

/// 当前源播放完毕。
final class EngineCompleted extends EngineEvent {
  /// 创建播放完毕事件。
  const EngineCompleted();

  @override
  String toString() => 'EngineCompleted()';
}

/// 播放失败（结构化错误，不含 UI 文案）。
final class EngineFailed extends EngineEvent {
  /// 创建失败事件。
  const EngineFailed(this.error);

  /// 结构化错误。
  final EngineError error;

  @override
  String toString() => 'EngineFailed(${error.toDiagnosticString()})';
}
