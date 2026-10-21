import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';

QueueChapter _chapter(String id, {String volume = 'v1', String? title}) {
  return QueueChapter(
    chapterId: id,
    volumeId: volume,
    title: title ?? id,
    source: LocalFileSource(uri: 'file:///library/$id.mp3'),
  );
}

ChapterSequencer _threeChaptersAcrossTwoVolumes() {
  return ChapterSequencer(<QueueChapter>[
    _chapter('c1', volume: 'v1'),
    _chapter('c2', volume: 'v1'),
    _chapter('c3', volume: 'v2'),
  ]);
}

void main() {
  group('相邻关系与跨卷连播', () {
    test('nextOf 跨卷推进，末章为 null', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      expect(queue.nextOf('c1')?.chapterId, 'c2');
      expect(queue.nextOf('c2')?.chapterId, 'c3', reason: '跨卷连播');
      expect(queue.nextOf('c3'), isNull, reason: '全书完毕');
    });

    test('previousOf 跨卷回退，首章为 null', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      expect(queue.previousOf('c3')?.chapterId, 'c2', reason: '跨卷回退');
      expect(queue.previousOf('c1'), isNull, reason: '全书首章');
    });

    test('isFirst / isLast', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      expect(queue.isFirst('c1'), isTrue);
      expect(queue.isFirst('c2'), isFalse);
      expect(queue.isLast('c3'), isTrue);
      expect(queue.isLast('c2'), isFalse);
    });

    test('未知章节返回 null，不猜测', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      expect(queue.byId('missing'), isNull);
      expect(queue.nextOf('missing'), isNull);
      expect(queue.previousOf('missing'), isNull);
      expect(queue.isFirst('missing'), isFalse);
      expect(queue.isLast('missing'), isFalse);
    });

    test('空队列安全', () {
      final queue = ChapterSequencer(const <QueueChapter>[]);
      expect(queue.isEmpty, isTrue);
      expect(queue.first, isNull);
      expect(queue.last, isNull);
    });
  });

  group('按章惰性解析', () {
    test('已有 source 时直接返回，不调用 resolver', () async {
      var calls = 0;
      final chapter = QueueChapter(
        chapterId: 'c1',
        volumeId: 'v1',
        title: '第一章',
        source: const LocalFileSource(uri: 'file:///a.mp3'),
        resolveSource: () async {
          calls++;
          return const LocalFileSource(uri: 'file:///b.mp3');
        },
      );

      expect(await chapter.resolve(), isA<LocalFileSource>());
      expect(calls, 0);
    });

    test('只有 resolver 时调用一次并返回', () async {
      var calls = 0;
      final chapter = QueueChapter(
        chapterId: 'c1',
        volumeId: 'v1',
        title: '第一章',
        resolveSource: () async {
          calls++;
          return const RemoteUrlSource(uri: 'https://e.test/a.mp3');
        },
      );

      final source = await chapter.resolve();
      expect(source, isA<RemoteUrlSource>());
      expect(calls, 1);
    });

    test('source 与 resolver 都为空时构造失败', () {
      expect(
        () => QueueChapter(chapterId: 'c1', volumeId: 'v1', title: '第一章'),
        throwsArgumentError,
      );
    });
  });

  group('上一曲判定（§2.2）', () {
    test('> 3 秒：重播本章', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      final resolution = queue.resolvePrevious(
        chapterId: 'c2',
        position: const Duration(seconds: 4),
      );

      expect(resolution!.restartOnly, isTrue);
      expect(resolution.chapter.chapterId, 'c2');
    });

    test('恰好 3 秒：不算 > 3 秒，回上一章', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      final resolution = queue.resolvePrevious(
        chapterId: 'c2',
        position: const Duration(seconds: 3),
      );

      expect(resolution!.restartOnly, isFalse);
      expect(resolution.chapter.chapterId, 'c1');
    });

    test('≤ 3 秒：回上一章（可跨卷）', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      final resolution = queue.resolvePrevious(
        chapterId: 'c3',
        position: const Duration(seconds: 1),
      );

      expect(resolution!.restartOnly, isFalse);
      expect(resolution.chapter.chapterId, 'c2');
    });

    test('全书首章 ≤ 3 秒：回到 0 秒（等价重播）', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      final resolution = queue.resolvePrevious(
        chapterId: 'c1',
        position: const Duration(seconds: 2),
      );

      expect(resolution!.restartOnly, isTrue);
      expect(resolution.chapter.chapterId, 'c1');
    });

    test('可自定义阈值', () {
      final queue = _threeChaptersAcrossTwoVolumes();
      final resolution = queue.resolvePrevious(
        chapterId: 'c2',
        position: const Duration(seconds: 10),
        restartThreshold: const Duration(seconds: 15),
      );

      expect(resolution!.restartOnly, isFalse);
    });
  });

  group('构造约束', () {
    test('重复 chapterId 视为调用方错误', () {
      expect(
        () => ChapterSequencer(<QueueChapter>[_chapter('c1'), _chapter('c1')]),
        throwsArgumentError,
      );
    });

    test('队列对外只读', () {
      final queue = ChapterSequencer(<QueueChapter>[_chapter('c1')]);
      expect(() => queue.chapters.add(_chapter('c2')), throwsUnsupportedError);
    });
  });
}
