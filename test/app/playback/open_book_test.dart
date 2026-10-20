import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/engine_capabilities.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/contracts/playback/playback_engine.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';

import 'fake_media_source_resolver.dart';

/// 计数包装：记录 [load] 调用次数（`alreadyOpen` 断言用）。
class _CountingEngine implements PlaybackEngine {
  _CountingEngine(this._inner);

  final FakePlaybackEngine _inner;
  int loadCalls = 0;

  @override
  Future<void> load(AudioSourceRef source) {
    loadCalls++;
    return _inner.load(source);
  }

  @override
  Future<void> play() => _inner.play();

  @override
  Future<void> pause() => _inner.pause();

  @override
  Future<void> seek(Duration position) => _inner.seek(position);

  @override
  Future<void> setSpeed(double speed) => _inner.setSpeed(speed);

  @override
  Future<void> setVolume(double volume) => _inner.setVolume(volume);

  @override
  Stream<EngineEvent> get events => _inner.events;

  @override
  EngineCapabilities get capabilities => _inner.capabilities;

  @override
  Future<void> dispose() => _inner.dispose();
}

BookDetail _detail({bool missing = false}) {
  ChapterView chapter(int index, {required bool gone}) {
    final int number = index + 1;
    return ChapterView(
      id: 'c$number',
      volumeId: 'v1',
      title: '第 $number 章',
      chapterIndex: index,
      filePath: 'books/book-1/chapter-$number.mp3',
      missing: gone,
      durationMs: 600000,
    );
  }

  return BookDetail(
    summary: BookSummary(
      id: 'book-1',
      title: '山海夜航',
      libraryRootId: 'root-1',
      rootPath: 'books/book-1',
      coverSource: CoverSource.typography,
      totalChapters: 2,
      totalDurationMs: 1200000,
      missingChapters: missing ? 2 : 0,
    ),
    volumes: <VolumeView>[
      VolumeView(
        id: 'v1',
        title: '第一卷',
        volumeIndex: 0,
        chapters: <ChapterView>[
          chapter(0, gone: missing),
          chapter(1, gone: missing),
        ],
      ),
    ],
    preferences: const PerBookPrefsSnapshot(),
  );
}

void main() {
  late ProviderContainer container;
  late CurrentBookNotifier currentBook;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    currentBook = container.read(currentBookProvider.notifier);
  });

  PlaybackController controllerWith(_CountingEngine engine) {
    final controller = PlaybackController(
      engine: engine,
      writeProgress: (String bookId, String chapterId, Duration position) {},
    );
    addTearDown(controller.dispose);
    return controller;
  }

  test('已是当前书：返回 alreadyOpen，且不再 load', () async {
    final engine = _CountingEngine(FakePlaybackEngine());
    final controller = controllerWith(engine);
    final resolver = localFakeResolver('/library');
    final detail = _detail();

    final first = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: resolver,
      detail: detail,
    );
    expect(first.status, OpenBookStatus.opened);
    final int loadsAfterOpen = engine.loadCalls;
    expect(loadsAfterOpen, 1, reason: '只加载起始章');

    // 健康会话（无残留错误）才短路。
    expect(controller.lastError, isNull);
    final second = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: resolver,
      detail: detail,
    );
    expect(second.status, OpenBookStatus.alreadyOpen);
    expect(
      engine.loadCalls,
      loadsAfterOpen,
      reason: 'alreadyOpen 不得重建队列 / 重新 load',
    );
  });

  test('空队列：failed + 零副作用（不 set 当前书、不动 controller）', () async {
    final engine = _CountingEngine(FakePlaybackEngine());
    final controller = controllerWith(engine);

    final result = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: localFakeResolver('/library'),
      detail: _detail(missing: true),
    );

    expect(result.status, OpenBookStatus.failed);
    expect(result.message, contains('没有可播放的章节'));
    expect(currentBook.current, isNull);
    expect(controller.current, isNull);
    expect(engine.loadCalls, 0, reason: '空队列不应触碰引擎');
  });

  test('引擎 load 抛错：failed + 回滚干净（无幽灵播放态）', () async {
    final uri = LocalFileSource.fromPath('/library/books/book-1/chapter-1.mp3')
        .uri;
    final engine = _CountingEngine(
      FakePlaybackEngine(
        loadFailures: <String, EngineErrorCode>{
          uri: EngineErrorCode.sourceNotFound,
        },
      ),
    );
    final controller = controllerWith(engine);

    final result = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: localFakeResolver('/library'),
      detail: _detail(),
    );

    expect(result.status, OpenBookStatus.failed);
    expect(result.message, contains('音频读取失败'));
    expect(currentBook.current, isNull, reason: '失败必须回滚当前书');
    expect(controller.current, isNull, reason: '失败必须回滚会话');
    expect(controller.state, EnginePlaybackState.idle);
    expect(engine.loadCalls, 1, reason: '本地根不做缓存副本重试');
  });

  test('SAF 首次失败 → preferCachedCopy 重试一次并成功', () async {
    final resolver = FakeMediaSourceResolver(
      resolve: (String path, bool cached) => cached
          ? LocalFileSource.fromPath('/cache/$path')
          : LocalFileSource(uri: 'content://tree/$path'),
    );
    final failUri = const LocalFileSource(
      uri: 'content://tree/books/book-1/chapter-1.mp3',
    ).uri;
    final engine = _CountingEngine(
      FakePlaybackEngine(
        loadFailures: <String, EngineErrorCode>{
          failUri: EngineErrorCode.sourceNotFound,
        },
      ),
    );
    final controller = controllerWith(engine);

    final result = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: resolver,
      detail: _detail(),
    );

    expect(result.status, OpenBookStatus.opened);
    final Set<String> cachedPaths = resolver.resolveCalls
        .where((c) => c.preferCachedCopy)
        .map((c) => c.relativePath)
        .toSet();
    expect(cachedPaths, <String>{
      'books/book-1/chapter-1.mp3',
    }, reason: '重试只复制即将播放的起始章，绝不整书逐章复制');
    expect(
      resolver.resolveCalls
          .where((c) => c.relativePath == 'books/book-1/chapter-2.mp3')
          .every((c) => !c.preferCachedCopy),
      isTrue,
      reason: '其余章必须始终直传 content://',
    );
    expect(currentBook.current?.summary.id, 'book-1');
    expect(controller.current, isNotNull);
    // 引擎状态事件经广播流异步投递，先排空事件队列再断言。
    await pumpEventQueue();
    expect(controller.state, EnginePlaybackState.playing);
  });

  test('SAF 起始章复制失败（resolve 返回 null）：failed + 回滚，文案为源不可读', () async {
    final resolver = FakeMediaSourceResolver(
      // 直传给 content://（首次失败），缓存副本一律解析不出（模拟 copyToCache 失败）。
      resolve: (String path, bool cached) =>
          cached ? null : LocalFileSource(uri: 'content://tree/$path'),
    );
    final failUri = const LocalFileSource(
      uri: 'content://tree/books/book-1/chapter-1.mp3',
    ).uri;
    final engine = _CountingEngine(
      FakePlaybackEngine(
        loadFailures: <String, EngineErrorCode>{
          failUri: EngineErrorCode.sourceNotFound,
        },
      ),
    );
    final controller = controllerWith(engine);

    final result = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: resolver,
      detail: _detail(),
    );

    expect(result.status, OpenBookStatus.failed);
    expect(result.message, contains('音频读取失败'));
    expect(currentBook.current, isNull);
    expect(controller.current, isNull);
  });

  test('会话带残留错误时点同一本书：不短路 alreadyOpen，走完整 open 路径恢复', () async {
    final resolver = localFakeResolver('/library');
    final String failUri = LocalFileSource.fromPath(
      '/library/books/book-1/chapter-2.mp3',
    ).uri;
    final engine = _CountingEngine(
      FakePlaybackEngine(
        loadFailures: <String, EngineErrorCode>{
          failUri: EngineErrorCode.sourceNotFound,
        },
      ),
    );
    final controller = controllerWith(engine);
    final detail = _detail();

    final first = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: resolver,
      detail: detail,
    );
    expect(first.status, OpenBookStatus.opened);

    // 让会话进入「带错误」态：切到 c2 失败（_current 仍指向 c2）。
    await controller.skipToNext();
    await pumpEventQueue();
    expect(controller.lastError, isNotNull);
    expect(controller.current, isNotNull);

    final int resolvesBefore = resolver.resolveCalls.length;
    final second = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: resolver,
      detail: detail,
    );

    expect(
      second.status,
      OpenBookStatus.opened,
      reason: '带错误时不得短路成 alreadyOpen，必须重开以恢复',
    );
    expect(
      resolver.resolveCalls.length,
      greaterThan(resolvesBefore),
      reason: '必须重新建队列，而不是 alreadyOpen 直接返回',
    );
    expect(controller.lastError, isNull, reason: '重开成功后应清掉残留错误');
  });

  test('指定 startChapterId：跳过 alreadyOpen，定位到目标章起点且不触发微回退', () async {
    final engine = _CountingEngine(FakePlaybackEngine());
    final controller = controllerWith(engine);
    final resolver = localFakeResolver('/library');

    // 带续播进度的书：默认从 c1 的 5:00 恢复（中断 10 分钟 → 回退 8 秒）。
    final base = _detail();
    final detail = BookDetail(
      summary: base.summary,
      volumes: base.volumes,
      preferences: const PerBookPrefsSnapshot(),
      progress: ProgressSnapshot(
        bookId: 'book-1',
        chapterId: 'c1',
        position: const Duration(minutes: 5),
        updatedAt: DateTime(2026, 10, 18),
      ),
    );

    final first = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: resolver,
      detail: detail,
    );
    expect(first.status, OpenBookStatus.opened);
    expect(controller.current?.chapterId, 'c1');
    expect(
      controller.position,
      isNot(Duration.zero),
      reason: '默认续播应恢复到非零位置',
    );

    // 显式指定 c2：书已打开也必须跳过 alreadyOpen，定位到 c2 起点（0 秒）。
    final second = await openBook(
      controller: controller,
      currentBook: currentBook,
      resolver: resolver,
      detail: detail,
      startChapterId: 'c2',
    );
    expect(
      second.status,
      OpenBookStatus.opened,
      reason: '指定章时不得短路成 alreadyOpen',
    );
    expect(controller.current?.chapterId, 'c2');
    expect(
      controller.position,
      Duration.zero,
      reason: '指定章起播位置为 0，不触发微回退',
    );
    expect(controller.canUndoRewind, isFalse, reason: '指定章起播无撤销令牌');
  });
}
