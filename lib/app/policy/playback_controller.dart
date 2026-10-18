import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/playback_engine.dart';

import 'chapter_sequencer.dart';
import 'per_book_preferences.dart';
import 'progress_scheduler.dart';
import 'sleep_timer.dart';

/// 恢复 / 打开一本书的请求。
class PlaybackRequest {
  /// 创建请求。
  const PlaybackRequest({
    required this.bookId,
    required this.queue,
    required this.startChapterId,
    this.savedPosition = Duration.zero,
    this.interruption = Duration.zero,
    this.processRestarted = false,
    this.preferences = PerBookPreferences.defaults,
  });

  /// 书 ID。
  final String bookId;

  /// 已排序的章节队列。
  final ChapterSequencer queue;

  /// 起始章节。
  final String startChapterId;

  /// 上次保存的位置。
  final Duration savedPosition;

  /// 暂停 → 恢复的中断间隔（决定微回退）。
  final Duration interruption;

  /// 是否跨进程重启（决定强制 15 秒回退）。
  final bool processRestarted;

  /// 每书偏好。
  final PerBookPreferences preferences;
}

/// 播放编排（《架构需求文档》§5.1 APP 层）。
///
/// **职责边界（§6.2 强制）**：睡眠、微回退、跨卷连播、每书偏好、进度写入
/// 全部在这里；[PlaybackEngine] 只负责解码与输出，不知道"书 / 卷 / 章"。
///
/// 所有时间判定都走注入的 `clock`，因此可以在测试里把"暂停 10 分钟 → 回退 8 秒
/// → 10 秒内撤销"这类时序完整跑出来，不依赖真机与真实时钟。
class PlaybackController {
  /// 创建编排器。
  ///
  /// [writeProgress] 由装配层注入（数据库写入），本层不感知存储实现。
  PlaybackController({
    required this._engine,
    required this._writeProgress,
    DateTime Function()? clock,
    SleepTimer? sleepTimer,
    this.rewindUndoWindow = const Duration(seconds: 10),
  }) : _clock = clock ?? DateTime.now,
       sleep = sleepTimer ?? SleepTimer(clock: clock) {
    _subscription = _engine.events.listen(_onEngineEvent);
  }

  /// 恢复后允许撤销微回退的时间窗（文档：10 秒）。
  final Duration rewindUndoWindow;

  /// 睡眠守夜状态机。
  final SleepTimer sleep;

  final PlaybackEngine _engine;
  final void Function(String bookId, String chapterId, Duration position)
  _writeProgress;
  final DateTime Function() _clock;
  late final StreamSubscription<EngineEvent> _subscription;
  late final ProgressScheduler _progress = _buildScheduler();
  final _Notifier _notifier = _Notifier();

  /// UI 订阅点：状态 / 章节 / 位置变化都会触发。
  ///
  /// 用 [Listenable] 而不是把控制器做成 `ChangeNotifier` 子类 —— 后者的
  /// `dispose()` 返回 `void`，会和这里的异步 `dispose()` 冲突。
  Listenable get listenable => _notifier;

  PlaybackRequest? _request;
  ChapterSequencer? _queue;
  QueueChapter? _current;
  PerBookPreferences _preferences = PerBookPreferences.defaults;
  ({Duration start, Duration? end}) _range = (start: Duration.zero, end: null);

  EnginePlaybackState _state = EnginePlaybackState.idle;
  Duration _position = Duration.zero;
  bool _autoPlayIntent = false;
  bool _finished = false;
  EngineError? _lastError;
  _RewindUndo? _rewindUndo;
  double _lastFade = 1;

  /// 当前队列（未打开时为 `null`）。
  ChapterSequencer? get queue => _queue;

  /// 当前章节。
  QueueChapter? get current => _current;

  /// 当前引擎状态。
  EnginePlaybackState get state => _state;

  /// 当前位置。
  Duration get position => _position;

  /// 当前章节的有效播放区间（已应用片头 / 片尾跳过）。
  ({Duration start, Duration? end}) get range => _range;

  /// 每书偏好。
  PerBookPreferences get preferences => _preferences;

  /// 全书是否已播放完毕（完毕态应归零，§2.2）。
  bool get isBookFinished => _finished;

  /// 最近一次引擎错误。
  EngineError? get lastError => _lastError;

  /// 现在是否可以撤销微回退。
  bool get canUndoRewind {
    final undo = _rewindUndo;
    return undo != null && _clock().isBefore(undo.expiresAt);
  }

  /// 打开一本书并定位到恢复点（应用微回退），**不自动播放**。
  Future<void> open(PlaybackRequest request) async {
    final chapter =
        request.queue.byId(request.startChapterId) ?? request.queue.first;
    if (chapter == null) {
      throw StateError('播放队列为空，无法打开书籍 ${request.bookId}');
    }

    _request = request;
    _queue = request.queue;
    _preferences = request.preferences;
    _finished = false;
    _lastError = null;
    _autoPlayIntent = false;
    _progress.reset();

    final target = _preferences.ladder.targetPosition(
      saved: request.savedPosition,
      interruption: request.interruption,
      processRestarted: request.processRestarted,
    );
    await _loadChapter(chapter, seekTo: target);

    final rewind = request.savedPosition - target;
    _rewindUndo = rewind > Duration.zero
        ? _RewindUndo(
            originalPosition: request.savedPosition,
            expiresAt: _clock().add(rewindUndoWindow),
          )
        : null;
  }

  /// 开始 / 继续播放。
  Future<void> play() async {
    if (_current == null) {
      return;
    }
    _autoPlayIntent = true;
    _finished = false;
    await _engine.play();
  }

  /// 暂停。
  ///
  /// 进度写入由引擎的 `paused` 状态事件触发（见 [_onEngineEvent]），
  /// 此处不再重复 flush —— 否则每次暂停会写两次库。
  Future<void> pause() async {
    _autoPlayIntent = false;
    await _engine.pause();
  }

  /// 切换播放 / 暂停。
  Future<void> togglePlayPause() async {
    if (_state == EnginePlaybackState.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// 定位（钳制到当前章的有效区间）。
  Future<void> seek(Duration position) async {
    if (_current == null) {
      return;
    }
    final target = _clamp(position);
    await _engine.seek(target);
    _position = target;
  }

  /// 设置倍速并记住到偏好。
  Future<void> setSpeed(double speed) async {
    await _engine.setSpeed(speed);
    _preferences = _preferences.copyWith(speed: speed);
  }

  /// 下一章（跨卷；全书完毕则停在末尾）。
  Future<void> skipToNext() async {
    final current = _current;
    if (current == null) {
      return;
    }
    final shouldPlay = _autoPlayIntent;
    _flushProgress();

    final next = _queue?.nextOf(current.chapterId);
    if (next == null) {
      _finished = true;
      _autoPlayIntent = false;
      await _engine.pause();
      return;
    }
    await _loadChapter(next);
    if (shouldPlay) {
      await _engine.play();
    }
  }

  /// 上一曲（§2.2）：> 3 秒重播本章，≤ 3 秒回上一章（可跨卷）。
  Future<void> skipToPrevious() async {
    final current = _current;
    if (current == null) {
      return;
    }
    final shouldPlay = _autoPlayIntent;
    _flushProgress();

    final resolution = _queue?.resolvePrevious(
      chapterId: current.chapterId,
      position: _position,
    );
    if (resolution == null) {
      return;
    }
    if (resolution.restartOnly) {
      await _engine.seek(_range.start);
      _position = _range.start;
      return;
    }
    await _loadChapter(resolution.chapter);
    if (shouldPlay) {
      await _engine.play();
    }
  }

  /// 跳到指定章节（章节目录用）。
  ///
  /// 与 [open] 的区别：**不重建会话**、不清撤销令牌、不改当前书 ——
  /// 只在同一本书的队列内移动，因此当前进度会先落盘、播放意图保持不变。
  ///
  /// 目标不在队列（含缺失章，已构建队列时就已剔除）时返回 `false`。
  Future<bool> seekToChapter(String chapterId, {Duration? position}) async {
    final target = _queue?.byId(chapterId);
    if (target == null) {
      return false;
    }
    if (_current?.chapterId == chapterId) {
      await seek(position ?? _range.start);
      return true;
    }

    final shouldPlay = _autoPlayIntent;
    _flushProgress();
    await _loadChapter(target, seekTo: position);
    if (shouldPlay) {
      await _engine.play();
    }
    return true;
  }

  /// 撤销微回退（恢复后 [rewindUndoWindow] 内有效）。返回是否成功。
  Future<bool> undoRewind() async {
    final undo = _rewindUndo;
    if (undo == null || !_clock().isBefore(undo.expiresAt)) {
      _rewindUndo = null;
      return false;
    }
    final target = _clamp(undo.originalPosition);
    await _engine.seek(target);
    _position = target;
    _rewindUndo = null;
    return true;
  }

  /// 释放引擎与事件订阅。
  Future<void> dispose() async {
    _flushProgress();
    await _subscription.cancel();
    _notifier.dispose();
    await _engine.dispose();
  }

  // ---------------------------------------------------------------------------

  Future<void> _loadChapter(QueueChapter chapter, {Duration? seekTo}) async {
    _current = chapter;
    _range = _preferences.playbackRange(chapter.duration);

    await _engine.load(chapter.source);
    await _engine.setSpeed(_preferences.speed);

    final target = _clamp(seekTo ?? _range.start);
    await _engine.seek(target);
    _position = target;
    _notifier.notify();
  }

  void _onEngineEvent(EngineEvent event) {
    switch (event) {
      case EngineStateChanged(:final state):
        _state = state;
        if (state == EnginePlaybackState.paused) {
          _flushProgress();
        }
      case EnginePositionChanged(:final position):
        _position = position;
        _onPosition(position);
      case EngineDurationChanged():
        break;
      case EngineCompleted():
        unawaited(_onChapterCompleted());
      case EngineFailed(:final error):
        _lastError = error;
    }
    _notifier.notify();
  }

  void _onPosition(Duration position) {
    // §2.3：只有真实播放态才推进进度与计时，缓冲 / 暂停一律不计。
    if (_state != EnginePlaybackState.playing) {
      return;
    }
    _progress.updatePosition(position);

    if (sleep.isActive) {
      _applyFade();
      if (sleep.tick()) {
        unawaited(_stopForSleep());
        return;
      }
    }

    final end = _range.end;
    if (end != null && position >= end) {
      unawaited(_onChapterCompleted());
    }
  }

  Future<void> _onChapterCompleted() async {
    final current = _current;
    if (current == null) {
      return;
    }
    _flushProgress();

    if (sleep.onChapterCompleted()) {
      _autoPlayIntent = false;
      await _engine.pause();
      return;
    }

    final next = _queue?.nextOf(current.chapterId);
    if (next == null) {
      _finished = true;
      _autoPlayIntent = false;
      await _engine.pause();
      return;
    }

    final shouldPlay = _autoPlayIntent;
    await _loadChapter(next);
    if (shouldPlay) {
      await _engine.play();
    }
  }

  Future<void> _stopForSleep() async {
    _autoPlayIntent = false;
    await _engine.pause();
    _lastFade = 1;
    await _engine.setVolume(1);
  }

  void _applyFade() {
    final factor = sleep.fadeFactor;
    if ((factor - _lastFade).abs() < 0.01) {
      return;
    }
    _lastFade = factor;
    unawaited(_engine.setVolume(factor));
  }

  void _flushProgress() {
    if (_current == null) {
      return;
    }
    _progress.flush(_position);
  }

  Duration _clamp(Duration position) {
    var value = position.isNegative ? Duration.zero : position;
    if (value < _range.start) {
      value = _range.start;
    }
    final end = _range.end;
    if (end != null && value > end) {
      value = end;
    }
    return value;
  }

  ProgressScheduler _buildScheduler() {
    return ProgressScheduler(
      clock: _clock,
      onWrite: (Duration position) {
        final bookId = _request?.bookId;
        final chapterId = _current?.chapterId;
        if (bookId != null && chapterId != null) {
          _writeProgress(bookId, chapterId, position);
        }
      },
    );
  }
}

class _RewindUndo {
  const _RewindUndo({required this.originalPosition, required this.expiresAt});

  final Duration originalPosition;
  final DateTime expiresAt;
}

/// 只暴露 `notify()` 的内部通知器（`notifyListeners` 是 protected）。
class _Notifier extends ChangeNotifier {
  void notify() => notifyListeners();
}
