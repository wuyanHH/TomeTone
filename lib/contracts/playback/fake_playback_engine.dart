import 'dart:async';

import 'audio_source_ref.dart';
import 'engine_capabilities.dart';
import 'engine_error.dart';
import 'engine_event.dart';
import 'playback_engine.dart';

/// 播放引擎的 Fake 实现：纯内存、确定性、**零真实定时器**。
///
/// 供上层（UI / 应用 / 领域）在没有真实引擎（just_audio，Step 5）时开发与测试；
/// 同时是契约测试套件的第二个"实现" —— 套件在真实引擎出现前先被 Fake 跑绿。
///
/// 时间完全由 [advance] 驱动，因此上层策略（30 秒心跳、10 秒进度节流、
/// 微回退阶梯）可以做成**确定性**测试，不需要 `sleep` 或真实时钟。
class FakePlaybackEngine implements PlaybackEngine {
  /// 创建 Fake 引擎。
  ///
  /// - [durations]：`uri → 时长`；未登记的源视为"时长未知"，仍可成功加载。
  /// - [loadFailures]：`uri → 错误码`，用于故障注入。
  FakePlaybackEngine({
    EngineCapabilities? capabilities,
    Map<String, Duration> durations = const <String, Duration>{},
    Map<String, EngineErrorCode> loadFailures =
        const <String, EngineErrorCode>{},
  }) : _capabilities = capabilities ?? defaultCapabilities,
       _durations = Map<String, Duration>.of(durations),
       _loadFailures = Map<String, EngineErrorCode>.of(loadFailures);

  /// Fake 引擎的默认能力声明（覆盖 §2.1 全部媒体格式）。
  static const EngineCapabilities defaultCapabilities = EngineCapabilities(
    engineId: 'fake',
    gapless: true,
    supportsSeek: true,
    supportsHeaderInjection: true,
    supportsBackgroundPlayback: true,
    minSpeed: 0.5,
    maxSpeed: 3,
    supportedFormats: <String>{
      'mp3',
      'm4a',
      'm4b',
      'aac',
      'flac',
      'wav',
      'ogg',
      'opus',
    },
  );

  final EngineCapabilities _capabilities;
  final Map<String, Duration> _durations;
  final Map<String, EngineErrorCode> _loadFailures;

  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();
  final List<EngineEvent> _emitted = <EngineEvent>[];

  EnginePlaybackState _state = EnginePlaybackState.idle;
  AudioSourceRef? _source;
  Duration _position = Duration.zero;
  Duration? _duration;
  double _speed = 1;
  double _volume = 1;
  bool _disposed = false;
  int _disposeCount = 0;

  /// 当前状态（非契约成员，供测试与上层调试使用）。
  EnginePlaybackState get state => _state;

  /// 当前源（非契约成员）。
  AudioSourceRef? get currentSource => _source;

  /// 当前播放位置（非契约成员）。
  Duration get position => _position;

  /// 当前源时长（未知时为 `null`）。
  Duration? get duration => _duration;

  /// 当前倍速。
  double get speed => _speed;

  /// 当前音量（`0.0`–`1.0`）。
  double get volume => _volume;

  /// 是否已释放。
  bool get isDisposed => _disposed;

  /// [dispose] 被调用的次数 —— 用于断言幂等性与"无重复释放"。
  int get disposeCount => _disposeCount;

  /// 已播报的全部事件。
  ///
  /// 直接记录而非让测试订阅流，可彻底避开订阅时序带来的不确定性。
  /// 仅用于测试与开发（会随运行增长，**不得**在生产路径使用）。
  List<EngineEvent> get emitted => List<EngineEvent>.unmodifiable(_emitted);

  @override
  EngineCapabilities get capabilities => _capabilities;

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  Future<void> load(AudioSourceRef source) async {
    _ensureUsable();

    final injectFailure = _loadFailures[source.uri];
    if (injectFailure != null) {
      throw _fail(injectFailure, source.uri);
    }

    final format = _formatOf(source.uri);
    if (format != null && !_capabilities.supportedFormats.contains(format)) {
      throw _fail(EngineErrorCode.unsupportedFormat, source.uri);
    }

    _setState(EnginePlaybackState.loading);
    _source = source;
    _position = Duration.zero;
    _duration = _durations[source.uri];
    _emit(EngineDurationChanged(_duration));
    _setState(EnginePlaybackState.ready);
  }

  @override
  Future<void> play() async {
    _ensureUsable();
    if (_state == EnginePlaybackState.idle) {
      throw const EngineError(code: EngineErrorCode.illegalState);
    }
    if (_state == EnginePlaybackState.completed) {
      // 播放完毕后再按播放：从头开始（引擎只做这件事，续播策略在核心层）。
      _position = Duration.zero;
      _emit(EnginePositionChanged(_position));
    }
    _setState(EnginePlaybackState.playing);
  }

  @override
  Future<void> pause() async {
    _ensureUsable();
    if (_state == EnginePlaybackState.idle) {
      throw const EngineError(code: EngineErrorCode.illegalState);
    }
    if (_state == EnginePlaybackState.playing ||
        _state == EnginePlaybackState.buffering) {
      _setState(EnginePlaybackState.paused);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    _ensureUsable();
    if (_state == EnginePlaybackState.idle) {
      throw const EngineError(code: EngineErrorCode.illegalState);
    }
    _position = _clamp(position);
    _emit(EnginePositionChanged(_position));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _ensureUsable();
    if (!speed.isFinite ||
        speed < _capabilities.minSpeed ||
        speed > _capabilities.maxSpeed) {
      throw EngineError(
        code: EngineErrorCode.unsupportedOperation,
        sourceUri: _source?.uri,
      );
    }
    _speed = speed;
  }

  @override
  Future<void> setVolume(double volume) async {
    _ensureUsable();
    if (!volume.isFinite) {
      throw EngineError(
        code: EngineErrorCode.unsupportedOperation,
        sourceUri: _source?.uri,
      );
    }
    _volume = volume.clamp(0.0, 1.0).toDouble();
  }

  @override
  Future<void> dispose() async {
    _disposeCount++;
    if (_disposed) {
      return;
    }
    _disposed = true;
    _state = EnginePlaybackState.idle;
    _source = null;
    await _events.close();
  }

  // ---------------------------------------------------------------------------
  // 测试驱动接口
  // ---------------------------------------------------------------------------

  /// 推进播放位置（**仅在 [EnginePlaybackState.playing] 时生效**）。
  ///
  /// 暂停 / 缓冲 / 停止时推进无效 —— 与 §2.3"仅真实播放态采计"的口径一致。
  void advance(Duration delta) {
    if (_disposed || _state != EnginePlaybackState.playing) {
      return;
    }
    _position += delta;
    final duration = _duration;
    if (duration != null && _position >= duration) {
      _position = duration;
      _setState(EnginePlaybackState.completed);
      _emit(const EngineCompleted());
      return;
    }
    _emit(EnginePositionChanged(_position));
  }

  /// 模拟播放中失败（网络中断 / 音频焦点丢失等）。
  void emitFailure(EngineError error) {
    if (_disposed) {
      return;
    }
    _emit(EngineFailed(error));
    _setState(EnginePlaybackState.paused);
  }

  // ---------------------------------------------------------------------------

  Duration _clamp(Duration position) {
    var value = position;
    if (value < Duration.zero) {
      value = Duration.zero;
    }
    final duration = _duration;
    if (duration != null && value > duration) {
      value = duration;
    }
    return value;
  }

  EngineError _fail(EngineErrorCode code, String uri) {
    final error = EngineError(code: code, sourceUri: uri);
    _emit(EngineFailed(error));
    // 契约要求"加载失败后绝不处于 playing"：如果此前正在播放，
    // 必须显式退出播放态，否则上层会以为还在出声。
    if (_state == EnginePlaybackState.playing ||
        _state == EnginePlaybackState.buffering) {
      _setState(EnginePlaybackState.paused);
    }
    return error;
  }

  void _setState(EnginePlaybackState next) {
    if (_state == next) {
      return;
    }
    _state = next;
    _emit(EngineStateChanged(next));
  }

  void _emit(EngineEvent event) {
    if (_disposed) {
      return;
    }
    _emitted.add(event);
    _events.add(event);
  }

  void _ensureUsable() {
    if (_disposed) {
      throw const EngineError(code: EngineErrorCode.illegalState);
    }
  }

  static String? _formatOf(String uri) {
    final path = Uri.tryParse(uri)?.path ?? uri;
    final index = path.lastIndexOf('.');
    if (index < 0 || index == path.length - 1) {
      return null;
    }
    final extension = path.substring(index + 1).toLowerCase();
    return extension.isEmpty ? null : extension;
  }
}
