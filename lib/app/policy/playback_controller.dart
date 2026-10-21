import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
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
    this.onBookFinished,
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

  /// 全书播放完毕时的回调（装配层注入，用于写入 `finishedAt` 的完成标记）。
  final Future<void> Function(
    String bookId,
    String chapterId,
    Duration position,
  )?
  onBookFinished;
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

  /// 最近一次加载 / 播放失败的**残留**。
  ///
  /// 语义：只要是「此后没有成功加载过」的失败就仍为可见状态。下列任一发生即清：
  /// - 下一次章节加载成功（[_loadChapter] 成功尾部，覆盖 [open] 与所有切章路径）；
  /// - 新会话开始（[open] 开头 / [clearSession]）。
  ///
  /// 但它**不**在 [pause] / [play] 时清 —— 引擎失败（[EngineFailed]）依然置位，
  /// 让 UI 能持续表达「这一章打不开」直到真正恢复。
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
      await _markFinished();
      return;
    }
    final bool loaded = await _loadChapterSafely(next);
    if (loaded && shouldPlay) {
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
    final bool loaded = await _loadChapterSafely(resolution.chapter);
    if (loaded && shouldPlay) {
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
    final bool loaded = await _loadChapterSafely(target, seekTo: position);
    if (loaded && shouldPlay) {
      await _engine.play();
    }
    return loaded;
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

  /// 清空当前会话状态（**仅用于「打开失败回滚」**）。
  ///
  /// 只把控制器退回「未打开」的初始态，让 UI（迷你播放器 / 播放台）立刻
  /// 不再显示一条假的「正在播放」：**不写进度、不碰引擎、不 dispose**。
  /// 不要拿它当「停止」用 —— 正常停止 / 暂停一律走 [pause] / [dispose]。
  void clearSession() {
    _request = null;
    _queue = null;
    _current = null;
    _range = (start: Duration.zero, end: null);
    _state = EnginePlaybackState.idle;
    _position = Duration.zero;
    _autoPlayIntent = false;
    _finished = false;
    _lastError = null;
    _rewindUndo = null;
    _notifier.notify();
  }

  // ---------------------------------------------------------------------------

  Future<void> _loadChapter(QueueChapter chapter, {Duration? seekTo}) async {
    _current = chapter;
    _range = _preferences.playbackRange(chapter.duration);

    final AudioSourceRef? source = await chapter.resolve();
    if (source == null) {
      throw const EngineError(code: EngineErrorCode.sourceNotFound);
    }
    await _engine.load(source);
    await _engine.setSpeed(_preferences.speed);

    final target = _clamp(seekTo ?? _range.start);
    await _engine.seek(target);
    _position = target;
    // 加载成功即清掉上一次的失败残留（见 [lastError] 语义）：这样用户跳到
    // 可播放的章后，迷你播放器 / 播放台不会一直挂着「这一章打不开」。
    // 放在成功尾部（而非方法开头）是为了让失败尝试继续由 catch 置位错误。
    _lastError = null;
    _notifier.notify();
  }

  /// 切章加载的**最小加固**（不是完整错误体系）。
  ///
  /// [skipToNext] / [skipToPrevious] / [seekToChapter] / 章末自动续播
  /// 都会切章加载；其中章末续播走 `unawaited(_onChapterCompleted())`，
  /// 一旦 [_loadChapter] 抛错就会变成**未捕获异步错误**，UI 只会静默卡住。
  /// 这里把异常收敛在控制器内：置位 [lastError]、退出播放态（尽力 [pause]
  /// 一次）、[notify] 让 UI 能表达「这一章打不开」。返回是否加载成功，
  /// 调用方据此决定要不要继续 `play()`（避免在失败章上再次 play 抛错）。
  ///
  /// 注意：打开整本书仍走 [open]，其 [_loadChapter] 失败继续向上抛，
  /// 由 `openBook` 回滚整本书 —— 本方法**不**改变那条语义。
  Future<bool> _loadChapterSafely(
    QueueChapter chapter, {
    Duration? seekTo,
  }) async {
    try {
      await _loadChapter(chapter, seekTo: seekTo);
      return true;
    } on Object catch (error) {
      _lastError = _toEngineError(error);
      _autoPlayIntent = false;
      try {
        await _engine.pause();
      } on Object {
        // 引擎可能已在失败中进入不可用态；pause 的失败不再外溢，
        // 失败状态由 _lastError + notify 表达。
      }
      _notifier.notify();
      return false;
    }
  }

  /// 把任意异常折叠成结构化 [EngineError]（已是则原样返回）。
  static EngineError _toEngineError(Object error) => error is EngineError
      ? error
      : EngineError(code: EngineErrorCode.unknown, cause: error);

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
      await _markFinished();
      return;
    }

    final shouldPlay = _autoPlayIntent;
    final bool loaded = await _loadChapterSafely(next);
    if (loaded && shouldPlay) {
      await _engine.play();
    }
  }

  /// 标记全书完毕并通知装配层（写入 `finishedAt`）。
  ///
  /// `_finished` 在 `await _engine.pause()` **之前**置位：paused 事件经广播流
  /// 异步投递、到达时 [_buildScheduler] 已处于完成态，普通进度写入被直接忽略，
  /// 因此完成回调的 finished=true 写入是最后一次，不会被之后排队的 flush 清掉。
  Future<void> _markFinished() async {
    _finished = true;
    _autoPlayIntent = false;
    await _engine.pause();

    final bookId = _request?.bookId;
    final chapterId = _current?.chapterId;
    final callback = onBookFinished;
    if (callback != null && bookId != null && chapterId != null) {
      // 完成位置优先取章末（有效区间末尾）：引擎完成前最后播报的 position 可能
      // 不是章末（如 9:00），用它写进度会低估；未知时长（end == null）时才退回
      // 当前 position。
      final end = _range.end;
      final finishedPosition = (end != null && end > _position)
          ? end
          : _position;
      unawaited(callback(bookId, chapterId, finishedPosition));
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
        // 进入完成态后忽略任何普通进度写入：`_markFinished` 里 paused 事件经
        // 广播流异步投递，到达时可能晚于完成回调，若不在此拦截，finished=false
        // 的 flush 会反过来把 `finishedAt` 清掉。
        if (_finished) {
          return;
        }
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
