import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/cover_art.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/app/policy/per_book_preferences.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/media/media_source_resolver.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/theme/app_theme.dart';

import '../app/playback/fake_media_source_resolver.dart';

/// UI 测试共用的假数据与小工具。
const String testRootId = 'root-1';
const String testRootUri = '/library';

/// 测试书库根。
const LibraryRootView testRoot = LibraryRootView(
  id: testRootId,
  type: 'local',
  uri: testRootUri,
  displayName: '本机书库',
);

/// 造一条书架列表项。
BookSummary testSummary({
  String id = 'book-1',
  String title = '山海夜航',
  String? author = '沈砚',
  String? narrator,
  String? seriesName,
  int? seriesIndex,
  String libraryRootId = testRootId,
  String? coverPath,
  int totalChapters = 4,
  int missingChapters = 0,
  int totalDurationMs = 4 * 10 * 60 * 1000,
  int? progressPositionMs,
  String? progressChapterId,
  String? progressChapterTitle,
  int? progressChapterIndex,
  DateTime? lastListenedAt,
  String? description,
  List<String> tags = const <String>[],
  bool isFinished = false,
  bool metadataEdited = false,
  String sourceType = 'local',
  String? sourceId,
  bool onShelf = true,
  String? coverUrl,
  String? kind,
  String? wordCount,
  String? lastChapter,
  String? sourceName,
  bool? sourceEnabled,
  bool? sourceDeleted,
}) {
  return BookSummary(
    id: id,
    title: title,
    author: author,
    narrator: narrator,
    seriesName: seriesName,
    seriesIndex: seriesIndex,
    libraryRootId: libraryRootId,
    rootPath: 'books/$id',
    coverSource: coverPath == null
        ? CoverSource.typography
        : CoverSource.bookRoot,
    coverPath: coverPath,
    totalChapters: totalChapters,
    totalDurationMs: totalDurationMs,
    missingChapters: missingChapters,
    progressPositionMs: progressPositionMs,
    progressChapterId: progressChapterId,
    progressChapterTitle: progressChapterTitle,
    progressChapterIndex: progressChapterIndex,
    lastListenedAt: lastListenedAt,
    description: description,
    tags: tags,
    isFinished: isFinished,
    metadataEdited: metadataEdited,
    sourceType: sourceType,
    sourceId: sourceId,
    onShelf: onShelf,
    coverUrl: coverUrl,
    kind: kind,
    wordCount: wordCount,
    lastChapter: lastChapter,
    sourceName: sourceName,
    sourceEnabled: sourceEnabled,
    sourceDeleted: sourceDeleted,
  );
}

/// 造一卷章。
ChapterView testChapter(
  int index, {
  String volumeId = 'v1',
  String? title,
  bool missing = false,
  int durationMs = 10 * 60 * 1000,
}) {
  final int number = index + 1;
  return ChapterView(
    id: 'c$number',
    volumeId: volumeId,
    title: title ?? '第 $number 章 · 夜航',
    chapterIndex: index,
    filePath: 'books/book-1/chapter-$number.mp3',
    missing: missing,
    durationMs: durationMs,
  );
}

/// 两卷四章；默认第二章缺失，用来验证目录置灰。
List<VolumeView> testVolumes({bool secondChapterMissing = true}) {
  return <VolumeView>[
    VolumeView(
      id: 'v1',
      title: '第一卷 · 入山',
      volumeIndex: 0,
      chapters: <ChapterView>[
        testChapter(0, title: '第一章 · 山门'),
        testChapter(1, title: '第二章 · 夜航', missing: secondChapterMissing),
      ],
    ),
    VolumeView(
      id: 'v2',
      title: '第二卷 · 渡海',
      volumeIndex: 1,
      chapters: <ChapterView>[
        testChapter(2, volumeId: 'v2', title: '第三章 · 潮声'),
        testChapter(3, volumeId: 'v2', title: '第四章 · 灯影'),
      ],
    ),
  ];
}

/// 造一份书详情。
BookDetail testDetail({
  BookSummary? summary,
  List<VolumeView>? volumes,
  ProgressSnapshot? progress,
}) {
  final BookSummary book = summary ?? testSummary();
  return BookDetail(
    summary: book,
    volumes: volumes ?? testVolumes(),
    preferences: const PerBookPrefsSnapshot(),
    progress: progress,
  );
}

/// 用假引擎造一个真实控制器。
PlaybackController testController(FakePlaybackEngine engine) {
  return PlaybackController(
    engine: engine,
    writeProgress: (String bookId, String chapterId, Duration position) {},
  );
}

/// resolver 工厂：本地根按「根 + 相对路径」拼本地文件源。
///
/// UI 测试默认注入它，免得 `mediaSourceResolverFactoryProvider` 未装配就抛错；
/// 需要 SAF 行为时传入自定义 [resolver]。
MediaSourceResolverFactory testResolverFactory({
  MediaSourceResolver? resolver,
}) {
  return ({required String libraryRootUri, required LibraryRootKind kind}) =>
      resolver ??
      FakeMediaSourceResolver(
        resolve: (String path, bool _) =>
            LocalFileSource.fromPath('$libraryRootUri/$path'),
      );
}

/// 为某个封面键注入固定 [CoverArt]（SAF 走 `coverImage` 的断言用）。
Override coverArtOverride(CoverArtKey key, CoverArt? art) =>
    coverArtProvider(key).overrideWith((Ref ref) async => art);

/// 由书详情构建播放请求（与 `buildPlaybackQueue` 同口径：缺失章跳过）。
PlaybackRequest testRequest(
  BookDetail detail, {
  String? startChapterId,
  Duration savedPosition = Duration.zero,
  Duration interruption = Duration.zero,
  bool processRestarted = false,
}) {
  final List<QueueChapter> chapters = <QueueChapter>[
    for (final ChapterView chapter in detail.chapters)
      if (!chapter.missing)
        QueueChapter(
          chapterId: chapter.id,
          volumeId: chapter.volumeId,
          title: chapter.title,
          source: LocalFileSource.fromPath('$testRootUri/${chapter.filePath}'),
          duration: chapter.durationMs == null
              ? null
              : Duration(milliseconds: chapter.durationMs!),
        ),
  ];
  final ChapterSequencer queue = ChapterSequencer(chapters);
  return PlaybackRequest(
    bookId: detail.summary.id,
    queue: queue,
    startChapterId: startChapterId ?? queue.first!.chapterId,
    savedPosition: savedPosition,
    interruption: interruption,
    processRestarted: processRestarted,
    preferences: PerBookPreferences(
      speed: detail.preferences.speed,
      skipIntro: detail.preferences.skipIntro,
      skipOutro: detail.preferences.skipOutro,
    ),
  );
}

/// 常用 overrides：书架 / 书库根 / 控制器 / 书详情 / 媒体源 resolver 工厂。
List<Override> testOverrides({
  required PlaybackController controller,
  List<BookSummary> books = const <BookSummary>[],
  List<LibraryRootView> roots = const <LibraryRootView>[testRoot],
  BookDetail? detail,
  MediaSourceResolverFactory? resolverFactory,
  List<Override> extra = const <Override>[],
}) {
  return <Override>[
    mediaSourceResolverFactoryProvider.overrideWithValue(
      resolverFactory ?? testResolverFactory(),
    ),
    booksProvider.overrideWith((Ref ref) async => books),
    libraryRootsProvider.overrideWith((Ref ref) async => roots),
    playbackControllerProvider.overrideWithValue(controller),
    if (detail != null)
      bookDetailProvider.overrideWith(
        (Ref ref, String id) async => id == detail.summary.id ? detail : null,
      ),
    ...extra,
  ];
}

/// 统一视口：400×800 手机竖屏。
void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// 把页面塞进带主题与 Navigator 的最小应用。
Widget testApp(ProviderContainer container, Widget home) {
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.build(), home: home),
  );
}
