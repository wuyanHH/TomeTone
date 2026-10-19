import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/app/policy/per_book_preferences.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/policy/sleep_timer.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';

const Duration _chapterLength = Duration(minutes: 10);

ChapterSequencer _buildQueue() {
  QueueChapter chapter(String id, String volume) => QueueChapter(
    chapterId: id,
    volumeId: volume,
    title: id,
    source: LocalFileSource(uri: 'file:///library/$id.mp3'),
    duration: _chapterLength,
  );

  return ChapterSequencer(<QueueChapter>[
    chapter('c1', 'v1'),
    chapter('c2', 'v1'),
    chapter('c3', 'v2'),
  ]);
}

void main() {
  late DateTime now;
  late FakePlaybackEngine engine;
  late List<({String bookId, String chapterId, Duration position})> writes;
  late PlaybackController controller;

  setUp(() {
    now = DateTime.utc(2026, 10, 18, 3);
    engine = FakePlaybackEngine(
      durations: <String, Duration>{
        for (final id in <String>['c1', 'c2', 'c3'])
          'file:///library/$id.mp3': _chapterLength,
      },
    );
    writes = <({String bookId, String chapterId, Duration position})>[];
    controller = PlaybackController(
      engine: engine,
      writeProgress: (String bookId, String chapterId, Duration position) {
        writes.add((bookId: bookId, chapterId: chapterId, position: position));
      },
      clock: () => now,
    );
  });

  tearDown(() async {
    await controller.dispose();
  });

  group('恢复与微回退（§2.2）', () {
    test('暂停 10 分钟恢复 → 回退 8 秒，且 10 秒内可撤销', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
          savedPosition: const Duration(minutes: 5),
          interruption: const Duration(minutes: 10),
        ),
      );

      expect(
        engine.position,
        const Duration(minutes: 5) - const Duration(seconds: 8),
      );
      expect(controller.canUndoRewind, isTrue);

      expect(await controller.undoRewind(), isTrue);
      expect(engine.position, const Duration(minutes: 5));
      expect(controller.canUndoRewind, isFalse);
      expect(await controller.undoRewind(), isFalse);
    });

    test('撤销窗口过期后不可撤销', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
          savedPosition: const Duration(minutes: 5),
          interruption: const Duration(minutes: 10),
        ),
      );

      now = now.add(const Duration(seconds: 11));
      expect(controller.canUndoRewind, isFalse);
      expect(await controller.undoRewind(), isFalse);
    });

    test('跨进程重启强制回退 15 秒', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
          savedPosition: const Duration(minutes: 2),
          interruption: const Duration(seconds: 5),
          processRestarted: true,
        ),
      );

      expect(
        engine.position,
        const Duration(minutes: 2) - const Duration(seconds: 15),
      );
    });

    test('短暂中断即点即播，不产生撤销令牌', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
          savedPosition: const Duration(minutes: 3),
          interruption: const Duration(seconds: 10),
        ),
      );

      expect(engine.position, const Duration(minutes: 3));
      expect(controller.canUndoRewind, isFalse);
    });
  });

  group('跨卷连播与全书完毕（§2.2）', () {
    test('章末自动进入下一章并保持播放（含跨卷）', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.play();

      engine.advance(_chapterLength);
      await pumpEventQueue();

      expect(controller.current?.chapterId, 'c2');
      expect(engine.currentSource?.uri, 'file:///library/c2.mp3');
      expect(controller.state, EnginePlaybackState.playing);

      engine.advance(_chapterLength);
      await pumpEventQueue();

      expect(controller.current?.chapterId, 'c3', reason: '跨卷连播');
    });

    test('全书最后一章播完 → 完毕态并暂停，不越界', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c3',
        ),
      );
      await controller.play();

      engine.advance(_chapterLength);
      await pumpEventQueue();

      expect(controller.isBookFinished, isTrue);
      expect(controller.current?.chapterId, 'c3');
      expect(
        controller.state,
        EnginePlaybackState.completed,
        reason: '播放完毕是引擎的完成态，不是暂停态',
      );
    });

    test('下一曲在末章不越界', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c3',
        ),
      );
      await controller.skipToNext();

      expect(controller.current?.chapterId, 'c3');
      expect(controller.isBookFinished, isTrue);
    });
  });

  group('上一曲判定（§2.2）', () {
    test('> 3 秒重播本章', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.seek(const Duration(minutes: 1));

      await controller.skipToPrevious();

      expect(controller.current?.chapterId, 'c1');
      expect(engine.position, Duration.zero);
    });

    test('≤ 3 秒回上一章（可跨卷）', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c3',
        ),
      );
      await controller.seek(const Duration(seconds: 1));

      await controller.skipToPrevious();

      expect(controller.current?.chapterId, 'c2');
    });

    test('全书首章 ≤ 3 秒回到 0 秒', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.seek(const Duration(seconds: 1));

      await controller.skipToPrevious();

      expect(controller.current?.chapterId, 'c1');
      expect(engine.position, Duration.zero);
    });
  });

  group('章节目录跳转', () {
    test('跳到另一章：切换章节并保持播放意图，旧章进度先落盘', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.play();
      engine.advance(const Duration(seconds: 30));
      await pumpEventQueue();

      expect(await controller.seekToChapter('c2'), isTrue);
      await pumpEventQueue();

      expect(controller.current?.chapterId, 'c2');
      expect(controller.state, EnginePlaybackState.playing);
      expect(
        writes.any((w) => w.chapterId == 'c1'),
        isTrue,
        reason: '切章前必须先把旧章进度落盘',
      );
    });

    test('跳到当前章 = 回到章首（应用片头跳过）', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
          preferences: const PerBookPreferences(
            skipIntro: Duration(seconds: 5),
          ),
        ),
      );
      await controller.seek(const Duration(minutes: 1));

      expect(await controller.seekToChapter('c1'), isTrue);
      expect(engine.position, const Duration(seconds: 5));
    });

    test('缺失 / 未知章节返回 false 且不改变当前章', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );

      expect(await controller.seekToChapter('missing'), isFalse);
      expect(controller.current?.chapterId, 'c1');
    });
  });

  group('每书偏好', () {
    test('片头跳过：打开即定位到有效区间起点', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
          preferences: const PerBookPreferences(
            skipIntro: Duration(seconds: 30),
          ),
        ),
      );

      expect(engine.position, const Duration(seconds: 30));
      expect(controller.range.start, const Duration(seconds: 30));
    });

    test('片尾跳过：到达有效区间末尾即视为本章完毕并续播', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
          preferences: const PerBookPreferences(
            skipOutro: Duration(seconds: 20),
          ),
        ),
      );
      await controller.play();

      engine.advance(_chapterLength - const Duration(seconds: 20));
      await pumpEventQueue();

      expect(controller.current?.chapterId, 'c2');
    });

    test('倍速写入偏好', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.setSpeed(1.5);

      expect(engine.speed, 1.5);
      expect(controller.preferences.speed, 1.5);
    });
  });

  group('进度写入（§2.2）', () {
    test('播放中 10 秒节流，暂停立即写', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.play();

      engine.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(writes, hasLength(1), reason: '首次位置更新立即写');

      now = now.add(const Duration(seconds: 5));
      engine.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(writes, hasLength(1), reason: '5 秒内不写');

      now = now.add(const Duration(seconds: 5));
      engine.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(writes, hasLength(2), reason: '满 10 秒写一次');

      await controller.pause();
      await pumpEventQueue();
      expect(writes, hasLength(3), reason: '暂停是关键事件，立即写');
      expect(writes.last.chapterId, 'c1');
      expect(writes.last.bookId, 'b1');
    });

    test('切章前先落盘旧章进度', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.play();
      engine.advance(const Duration(seconds: 30));
      await pumpEventQueue();

      final before = writes.length;
      await controller.skipToNext();

      expect(writes.length, greaterThan(before));
      expect(writes.last.chapterId, 'c1');
    });
  });

  group('睡眠守夜（§2.2 三模式）', () {
    test('倒计时渐弱并在到点暂停', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      controller.sleep.startCountdown(const Duration(minutes: 1));
      await controller.play();

      now = now.add(const Duration(seconds: 51));
      engine.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      expect(engine.volume, closeTo(0.9, 0.02), reason: '进入最后 10 秒开始渐弱');

      now = now.add(const Duration(seconds: 9));
      engine.advance(const Duration(seconds: 1));
      await pumpEventQueue();

      expect(controller.state, EnginePlaybackState.paused);
      expect(engine.volume, 1, reason: '睡眠暂停后恢复音量');
      expect(controller.sleep.mode, SleepMode.off);
    });

    test('播完当前章即停，不续播', () async {
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      controller.sleep.stopAtChapterEnd();
      await controller.play();

      engine.advance(_chapterLength);
      await pumpEventQueue();

      expect(controller.current?.chapterId, 'c1', reason: '不续播');
      expect(controller.state, EnginePlaybackState.completed);
    });
  });

  group('切章加载失败的最小加固', () {
    /// 造一个「c2 加载失败」的独立控制器（setUp 里的引擎不支持故障注入）。
    ({PlaybackController controller, FakePlaybackEngine engine})
    failingController() {
      final failingEngine = FakePlaybackEngine(
        durations: <String, Duration>{'file:///library/c1.mp3': _chapterLength},
        loadFailures: <String, EngineErrorCode>{
          'file:///library/c2.mp3': EngineErrorCode.sourceNotFound,
        },
      );
      final c = PlaybackController(
        engine: failingEngine,
        writeProgress: (String bookId, String chapterId, Duration position) {},
      );
      addTearDown(c.dispose);
      return (controller: c, engine: failingEngine);
    }

    test('下一章 load 抛错：不抛给调用方，置位 lastError 并退出播放态', () async {
      final (:controller, :engine) = failingController();
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.play();

      // 旧实现会在此把 load 异常抛出来（即未捕获异步错误）。
      await controller.skipToNext();
      // 引擎状态事件经广播流异步投递，先排空再断言状态。
      await pumpEventQueue();

      expect(controller.lastError, isNotNull);
      expect(controller.lastError!.code, EngineErrorCode.sourceNotFound);
      expect(
        controller.state,
        isNot(EnginePlaybackState.playing),
        reason: '加载失败后必须退出播放态',
      );
    });

    test('章末自动续播时下一章 load 抛错：不产生未捕获异步错误', () async {
      final (:controller, :engine) = failingController();
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );
      await controller.play();

      // 章末自动续播走 unawaited(_onChapterCompleted()) —— 失败必须被收敛。
      engine.advance(_chapterLength);
      await pumpEventQueue();

      expect(controller.lastError, isNotNull);
      expect(controller.state, isNot(EnginePlaybackState.playing));
    });

    test('目录跳章 load 抛错：返回 false 且置位 lastError，不抛错', () async {
      final (:controller, :engine) = failingController();
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );

      final bool moved = await controller.seekToChapter('c2');

      expect(moved, isFalse);
      expect(controller.lastError, isNotNull);
    });

    test('失败后再跳到可播放章：加载成功必须清掉 lastError（错误残留不得挂在 UI 上）', () async {
      final (:controller, :engine) = failingController();
      await controller.open(
        PlaybackRequest(
          bookId: 'b1',
          queue: _buildQueue(),
          startChapterId: 'c1',
        ),
      );

      // 先制造一次失败残留。
      expect(await controller.seekToChapter('c2'), isFalse);
      await pumpEventQueue();
      expect(controller.lastError, isNotNull);

      // c3 可播放：加载成功应把残留清掉。
      expect(await controller.seekToChapter('c3'), isTrue);
      await pumpEventQueue();
      expect(
        controller.lastError,
        isNull,
        reason: '下一次成功加载即清 lastError，否则提示会一直挂着',
      );
    });
  });
}
