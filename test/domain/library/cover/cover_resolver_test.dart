import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/cover/cover_resolver.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';

void main() {
  group('书的五级继承', () {
    test('书根图胜出（二级）', () {
      final resolution = CoverResolver.resolveBook(
        rootImages: <String>['三体/cover.jpg'],
        firstVolumeImages: <String>['三体/卷一/folder.png'],
      );

      expect(resolution.source, CoverSource.bookRoot);
      expect(resolution.relativePath, '三体/cover.jpg');
      expect(resolution.hasImage, isTrue);
    });

    test('无书根图时首卷封面反哺（三级）', () {
      final resolution = CoverResolver.resolveBook(
        rootImages: const <String>[],
        firstVolumeImages: <String>['三体/卷一/folder.png'],
      );

      expect(resolution.source, CoverSource.firstVolumeFeedback);
      expect(resolution.relativePath, '三体/卷一/folder.png');
    });

    test('首卷反哺优先于首章内嵌', () {
      final resolution = CoverResolver.resolveBook(
        rootImages: const <String>[],
        firstVolumeImages: <String>['三体/卷一/cover.png'],
        firstChapterHasEmbeddedCover: true,
      );

      expect(resolution.source, CoverSource.firstVolumeFeedback);
    });

    test('无任何图片但有内嵌封面（四级，路径待 Phase 2 抽取）', () {
      final resolution = CoverResolver.resolveBook(
        rootImages: const <String>[],
        firstVolumeImages: const <String>[],
        firstChapterHasEmbeddedCover: true,
      );

      expect(resolution.source, CoverSource.firstChapterEmbedded);
      expect(resolution.relativePath, isNull);
      expect(resolution.hasImage, isFalse);
    });

    test('全都拿不到 → 几何字标兜底（五级）', () {
      final resolution = CoverResolver.resolveBook(
        rootImages: const <String>[],
        firstVolumeImages: const <String>[],
      );

      expect(resolution.source, CoverSource.typography);
      expect(resolution.relativePath, isNull);
      expect(resolution.hasImage, isFalse);
    });
  });

  group('卷的继承', () {
    test('卷目录图优先（一级）', () {
      final resolution = CoverResolver.resolveVolume(
        volumeImages: <String>['三体/卷一/poster.png'],
        rootImages: <String>['三体/cover.jpg'],
      );

      expect(resolution.source, CoverSource.volumeDirectory);
      expect(resolution.relativePath, '三体/卷一/poster.png');
    });

    test('无卷图时回退书根图（二级）', () {
      final resolution = CoverResolver.resolveVolume(
        volumeImages: const <String>[],
        rootImages: <String>['三体/cover.jpg'],
      );

      expect(resolution.source, CoverSource.bookRoot);
      expect(resolution.relativePath, '三体/cover.jpg');
    });

    test('都没有 → 字标', () {
      final resolution = CoverResolver.resolveVolume(
        volumeImages: const <String>[],
        rootImages: const <String>[],
      );

      expect(resolution.source, CoverSource.typography);
      expect(resolution.hasImage, isFalse);
    });
  });

  group('候选挑选', () {
    test('名称优先级：cover > folder > front', () {
      expect(
        CoverResolver.pickPreferred(<String>[
          '三体/front.jpg',
          '三体/folder.png',
          '三体/cover.webp',
        ]),
        '三体/cover.webp',
      );
    });

    test('未登记名称排在登记名称之后', () {
      expect(
        CoverResolver.pickPreferred(<String>['三体/002.jpg', '三体/cover.jpg']),
        '三体/cover.jpg',
      );
    });

    test('同优先级按自然顺序（001 < 010）', () {
      expect(
        CoverResolver.pickPreferred(<String>['三体/010.jpg', '三体/001.jpg']),
        '三体/001.jpg',
      );
    });

    test('忽略非图片与隐藏文件', () {
      expect(
        CoverResolver.pickPreferred(<String>[
          '三体/notes.txt',
          '三体/.cover.jpg',
          '三体/anim.gif',
          '三体/._cover.png',
        ]),
        isNull,
      );
    });

    test('空候选返回 null', () {
      expect(CoverResolver.pickPreferred(const <String>[]), isNull);
    });
  });

  group('判定工具', () {
    test('isCoverImage 只认 jpg/jpeg/png/webp 且不看大小写', () {
      expect(CoverResolver.isCoverImage('a/cover.JPG'), isTrue);
      expect(CoverResolver.isCoverImage('a/cover.jpeg'), isTrue);
      expect(CoverResolver.isCoverImage('a/cover.png'), isTrue);
      expect(CoverResolver.isCoverImage('a/cover.webp'), isTrue);
      expect(CoverResolver.isCoverImage('a/cover.gif'), isFalse);
      expect(CoverResolver.isCoverImage('a/cover'), isFalse);
      expect(CoverResolver.isCoverImage('a/.cover.png'), isFalse);
    });

    test('priorityOf 返回登记序号或 unranked', () {
      expect(CoverResolver.priorityOf('a/cover.jpg'), 0);
      expect(CoverResolver.priorityOf('a/FOLDER.png'), 1);
      expect(
        CoverResolver.priorityOf('a/whatever.jpg'),
        CoverResolver.unranked,
      );
    });
  });
}
