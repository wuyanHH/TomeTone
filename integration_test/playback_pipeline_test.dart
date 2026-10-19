import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tometone/app/library/library_root_service.dart';
import 'package:tometone/app/playback/queue_builder.dart';
import 'package:tometone/app/policy/per_book_preferences.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';
import 'package:tometone/domain/library/database/tometone_database.dart';
import 'package:tometone/domain/library/queries/library_queries.dart';
import 'package:tometone/modules/playback_just_audio/just_audio_playback_engine.dart';
import 'package:tometone/modules/storage_local/local_media_source_resolver.dart';
import 'package:tometone/modules/storage_local/local_storage_provider.dart';

/// 设备端端到端：**真实文件系统 + 真实扫描器 + 真实 ExoPlayer + 真实 SQLite**。
///
/// 这个测试回答的是单测回答不了的问题：整条链路在 Android 上到底能不能跑通。
///
/// 运行：`flutter test integration_test/playback_pipeline_test.dart -d emulator-5554`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('导入 → 建库 → 播放 → 进度落盘', (WidgetTester tester) async {
    final workDir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}tometone_e2e',
    );
    if (workDir.existsSync()) {
      workDir.deleteSync(recursive: true);
    }
    final volume = Directory(
      '${workDir.path}${Platform.pathSeparator}三体'
      '${Platform.pathSeparator}卷一',
    )..createSync(recursive: true);

    // 真实可播放的 WAV（16-bit 单声道 8kHz，6 秒静音）。
    for (final name in <String>['001.wav', '002.wav']) {
      File('${volume.path}${Platform.pathSeparator}$name')
          .writeAsBytesSync(_silentWav(const Duration(seconds: 6)));
    }
    File('${volume.path}${Platform.pathSeparator}cover.jpg')
        .writeAsBytesSync(Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xD9]));

    final database = TomeToneDatabase(NativeDatabase.memory());
    final queries = DriftLibraryQueries(database);
    final service = LibraryRootService(
      database: database,
      idGenerator: UlidIdGenerator(),
      providerFactory: LocalStorageProvider.new,
    );

    final rootId = await service.addLocalRoot(absolutePath: workDir.path);
    final report = await service.scan(rootId);

    expect(report.booksAdded, 1, reason: '应识别出 1 本书');
    expect(report.volumesAdded, 1, reason: '卷一');
    expect(report.chaptersAdded, 2, reason: '两个 wav；cover.jpg 不计为章节');
    expect(report.failedPaths, isEmpty);

    final books = await queries.listBooks();
    expect(books, hasLength(1));
    final detail = await queries.bookDetail(books.single.id);
    expect(detail, isNotNull);
    expect(detail!.chapters, hasLength(2));

    final queue = await buildPlaybackQueue(
      detail: detail,
      resolver: LocalMediaSourceResolver(workDir.path),
    );
    expect(queue.chapters, hasLength(2));

    final engine = JustAudioPlaybackEngine();
    final controller = PlaybackController(
      engine: engine,
      writeProgress: (String bookId, String chapterId, Duration position) {
        // 真实落库，验证 WAL 事务写入路径在设备上可用。
        queries.saveProgress(
          bookId: bookId,
          chapterId: chapterId,
          position: position,
        );
      },
    );

    await controller.open(
      PlaybackRequest(
        bookId: detail.summary.id,
        queue: queue,
        startChapterId: queue.first!.chapterId,
        preferences: const PerBookPreferences(),
      ),
    );

    // 引擎加载完成：能力与时长必须被真实读到。
    expect(controller.current, isNotNull);
    expect(engine.capabilities.supportedFormats, contains('wav'));

    await controller.play();
    // 让 ExoPlayer 真正推进一小段。
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      if (controller.position > const Duration(milliseconds: 300)) {
        break;
      }
    }

    expect(
      controller.position,
      greaterThan(Duration.zero),
      reason: '真实引擎必须推进播放位置，否则说明解码/输出链路没通',
    );

    await controller.pause();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final progress = await database.select(database.playbackProgress).get();
    expect(progress, hasLength(1), reason: '暂停是关键事件，必须立即落盘');
    expect(progress.single.positionMs, greaterThan(0));

    await controller.dispose();
    await database.close();
    if (workDir.existsSync()) {
      workDir.deleteSync(recursive: true);
    }
  });
}

/// 生成 16-bit 单声道静音 WAV。
Uint8List _silentWav(Duration duration, {int sampleRate = 8000}) {
  final samples = (sampleRate * duration.inMilliseconds / 1000).round();
  final dataSize = samples * 2;
  final builder = BytesBuilder();

  void ascii(String value) => builder.add(value.codeUnits);
  void u32(int value) => builder.add(<int>[
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ]);
  void u16(int value) => builder.add(<int>[value & 0xFF, (value >> 8) & 0xFF]);

  ascii('RIFF');
  u32(36 + dataSize);
  ascii('WAVE');
  ascii('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // 单声道
  u32(sampleRate);
  u32(sampleRate * 2); // 字节率
  u16(2); // 块对齐
  u16(16); // 位深
  ascii('data');
  u32(dataSize);
  builder.add(Uint8List(dataSize));
  return builder.toBytes();
}
