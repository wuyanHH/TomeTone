import 'audio_source_ref.dart';
import 'engine_capabilities.dart';
import 'engine_event.dart';

/// 播放引擎契约（《架构需求文档》§6.1）。
///
/// **策略 / 机制分离（§6.2，强制）**：睡眠定时、智能微回退、跨卷连播调度、
/// 每书偏好、统计心跳、进度写入全部在核心层；引擎不知道"书 / 卷 / 章"的存在。
///
/// 所有实现必须通过 `test/contracts/playback_engine_conformance.dart`
/// 中的统一契约测试套件，并附一份 Fake 实现。
///
/// ## 规范行为（实现必须满足）
///
/// 1. **调用顺序**：未 [load] 就调用 [play] / [pause] / [seek] 必须抛
///    [EngineErrorCode.illegalState]；其余重复调用是幂等的（不抛错）。
/// 2. **倍速**：超出 `capabilities.minSpeed..maxSpeed` 或非有限值必须抛
///    [EngineErrorCode.unsupportedOperation]。
/// 3. **定位**：越界位置**钳制**到合法区间而不是抛错（恢复进度场景需要宽容语义）；
///    时长未知时接受任意非负位置。
/// 4. **失败**：加载失败必须抛 [EngineError]，并保证当前状态**不进入**
///    [EnginePlaybackState.playing]。
/// 5. **事件流**：[events] 支持多次订阅（广播语义）；实现不得丢弃已订阅期间的事件。
/// 6. **释放**：[dispose] 幂等；释放后 [events] 关闭，任何方法调用抛
///    [EngineErrorCode.illegalState]。
/// 7. **不自动推进**：播放完毕后只播报 [EngineCompleted]，是否续播由核心层决定。
/// 8. **时长必报**：`load` 成功后必须至少播报一次 [EngineDurationChanged]
///    （时长未知时参数为 `null`），使上层无需额外交互即可获知时长。
abstract class PlaybackEngine {
  /// 加载播放源。失败时抛 `EngineError`。
  Future<void> load(AudioSourceRef source);

  /// 开始 / 继续播放。
  Future<void> play();

  /// 暂停播放。
  Future<void> pause();

  /// 定位到 [position]（越界钳制）。
  Future<void> seek(Duration position);

  /// 设置倍速。超出引擎能力范围时抛 `EngineError`。
  Future<void> setSpeed(double speed);

  /// 设置输出音量（`0.0`–`1.0`）。
  ///
  /// 用于睡眠定时的渐弱（§2.2）与 DSP 音量增强（§6.5）。
  /// 越界值**钳制**到 `[0, 1]`；非有限值抛 [EngineErrorCode.unsupportedOperation]。
  Future<void> setVolume(double volume);

  /// 引擎事件流（位置 / 时长 / 状态 / 完毕 / 失败）。广播语义。
  Stream<EngineEvent> get events;

  /// 能力声明。核心层据此决定策略分支。
  EngineCapabilities get capabilities;

  /// 释放资源。必须幂等，且必须关闭 [events]。
  Future<void> dispose();
}
