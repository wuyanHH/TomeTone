import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/engine_capabilities.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/playback_engine.dart';

/// `just_audio` 实现的播放引擎（《架构需求文档》§6.3 候选·首选）。
///
/// 只做**机制**：解码、输出、位置与时长播报。书 / 卷 / 章、睡眠、回退、连播
/// 全部在 `lib/app/policy/` 里（§6.2）。
///
/// ## 两个必须知道的上游行为
///
/// 1. `AudioPlayer.play()` 返回的 Future **在播放结束时才完成**。直接 `await` 会
///    把调用方挂到章节末尾，所以这里 `unawaited` 启动它 —— 契约里的 `play()`
///    语义是"开始播放"，不是"播放完"。
/// 2. `paused` 与 `ready` 在 `just_audio` 里都是 `ready + !playing`；本实现用
///    [_hasPlayed] 区分"从未播放"与"播放后暂停"，避免上层把暂停误判成就绪。
class JustAudioPlaybackEngine implements PlaybackEngine {
  /// 创建引擎。可注入 [player] 以便测试替换。
  JustAudioPlaybackEngine({ja.AudioPlayer? player})
    : _player = player ?? ja.AudioPlayer() {
    _subscriptions.addAll(<StreamSubscription<Object?>>[
      _player.playerStateStream.listen(_onPlayerState),
      _player.positionStream.listen(_onPosition),
      _player.durationStream.listen(_onDuration),
      _player.playbackEventStream.listen((_) {}, onError: _onPlaybackError),
    ]);
  }

  /// 能力声明：ExoPlayer / Media3 覆盖 §2.1 全部格式。
  static const EngineCapabilities capabilitiesForJustAudio = EngineCapabilities(
    engineId: 'just_audio',
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

  final ja.AudioPlayer _player;
  final StreamController<EngineEvent> _events =
      StreamController<EngineEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  AudioSourceRef? _currentSource;
  EnginePlaybackState _state = EnginePlaybackState.idle;
  bool _hasPlayed = false;
  bool _disposed = false;

  @override
  Stream<EngineEvent> get events => _events.stream;

  @override
  EngineCapabilities get capabilities => capabilitiesForJustAudio;

  @override
  Future<void> load(AudioSourceRef source) async {
    _ensureUsable();
    _currentSource = source;
    _emitState(EnginePlaybackState.loading);

    try {
      final audioSource = switch (source) {
        LocalFileSource() => ja.AudioSource.uri(Uri.parse(source.uri)),
        RemoteUrlSource() => ja.AudioSource.uri(
          Uri.parse(source.uri),
          headers: source.headers.isEmpty ? null : source.headers,
        ),
      };

      final duration = await _player.setAudioSource(audioSource);
      _emit(EngineDurationChanged(duration));
      _hasPlayed = false;
      _emitState(EnginePlaybackState.ready);
    } on ja.PlayerException catch (error) {
      throw _fail(_mapError(error), source.uri);
    } on ja.PlayerInterruptedException catch (error) {
      // 被新的 load / dispose 打断：不是用户可见错误，但仍要复位状态。
      throw _fail(EngineErrorCode.interrupted, source.uri, error);
    }
  }

  @override
  Future<void> play() async {
    _ensureUsable();
    _hasPlayed = true;
    // just_audio 的 play() 在**播放结束**时才完成，不能 await（见类注释）。
    unawaited(
      _player.play().catchError((Object error) {
        if (!_disposed) {
          _emit(EngineFailed(EngineError(code: _mapError(error))));
        }
      }),
    );
  }

  @override
  Future<void> pause() async {
    _ensureUsable();
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    _ensureUsable();
    final duration = _player.duration;
    var target = position.isNegative ? Duration.zero : position;
    if (duration != null && target > duration) {
      target = duration;
    }
    await _player.seek(target);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _ensureUsable();
    if (!speed.isFinite ||
        speed < capabilities.minSpeed ||
        speed > capabilities.maxSpeed) {
      throw EngineError(
        code: EngineErrorCode.unsupportedOperation,
        sourceUri: _currentSource?.uri,
      );
    }
    await _player.setSpeed(speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    _ensureUsable();
    if (!volume.isFinite) {
      throw EngineError(
        code: EngineErrorCode.unsupportedOperation,
        sourceUri: _currentSource?.uri,
      );
    }
    await _player.setVolume(volume.clamp(0.0, 1.0).toDouble());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    await _events.close();
    await _player.dispose();
  }

  // ---------------------------------------------------------------------------

  void _onPlayerState(ja.PlayerState state) {
    if (_disposed) {
      return;
    }
    final mapped = _mapState(state);
    if (mapped == EnginePlaybackState.playing) {
      _hasPlayed = true;
    }
    _emitState(mapped);
    if (state.processingState == ja.ProcessingState.completed) {
      _emit(const EngineCompleted());
    }
  }

  EnginePlaybackState _mapState(ja.PlayerState state) {
    switch (state.processingState) {
      case ja.ProcessingState.idle:
        return EnginePlaybackState.idle;
      case ja.ProcessingState.loading:
        return EnginePlaybackState.loading;
      case ja.ProcessingState.buffering:
        return EnginePlaybackState.buffering;
      case ja.ProcessingState.completed:
        return EnginePlaybackState.completed;
      case ja.ProcessingState.ready:
        if (state.playing) {
          return EnginePlaybackState.playing;
        }
        return _hasPlayed
            ? EnginePlaybackState.paused
            : EnginePlaybackState.ready;
    }
  }

  void _onPosition(Duration position) {
    if (_disposed || _currentSource == null) {
      return;
    }
    _emit(EnginePositionChanged(position));
  }

  void _onDuration(Duration? duration) {
    if (_disposed || _currentSource == null) {
      return;
    }
    _emit(EngineDurationChanged(duration));
  }

  void _onPlaybackError(Object error, StackTrace stackTrace) {
    if (_disposed) {
      return;
    }
    _emit(EngineFailed(EngineError(code: _mapError(error))));
  }

  void _emit(EngineEvent event) {
    if (!_disposed) {
      _events.add(event);
    }
  }

  void _emitState(EnginePlaybackState next) {
    if (_state == next) {
      return;
    }
    _state = next;
    _emit(EngineStateChanged(next));
  }

  EngineError _fail(EngineErrorCode code, String uri, [Object? cause]) {
    final error = EngineError(code: code, sourceUri: uri, cause: cause);
    _emitState(EnginePlaybackState.idle);
    _emit(EngineFailed(error));
    return error;
  }

  void _ensureUsable() {
    if (_disposed) {
      throw const EngineError(code: EngineErrorCode.illegalState);
    }
  }

  /// 把上游异常折算成结构化错误码。
  ///
  /// `just_audio` 没有稳定的错误码枚举，这里按消息特征归类；归类失败一律
  /// `decodeFailed`（宁可提示"文件无法播放"，也不要吞掉错误）。
  static EngineErrorCode _mapError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('404') || message.contains('not found')) {
      return EngineErrorCode.sourceNotFound;
    }
    if (message.contains('401') ||
        message.contains('403') ||
        message.contains('unauthorized') ||
        message.contains('forbidden')) {
      return EngineErrorCode.authenticationFailed;
    }
    if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('host')) {
      return EngineErrorCode.networkUnavailable;
    }
    if (message.contains('unsupported') || message.contains('codec')) {
      return EngineErrorCode.unsupportedFormat;
    }
    return EngineErrorCode.decodeFailed;
  }
}
