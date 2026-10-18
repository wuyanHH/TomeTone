import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/scan/media_format.dart';

void main() {
  group('isSupported', () {
    test('§2.1 列出的 8 种格式全部受支持', () {
      const formats = <String>[
        'mp3',
        'm4a',
        'm4b',
        'aac',
        'flac',
        'wav',
        'ogg',
        'opus',
      ];
      for (final format in formats) {
        expect(
          MediaFormat.isSupported('chapter.$format'),
          isTrue,
          reason: format,
        );
        expect(
          MediaFormat.isSupported('chapter.${format.toUpperCase()}'),
          isTrue,
          reason: '大写扩展名 $format',
        );
      }
    });

    test('非音频文件被忽略', () {
      for (final name in <String>[
        'cover.jpg',
        'folder.png',
        'notes.txt',
        'book.nfo',
        'no-extension',
      ]) {
        expect(MediaFormat.isSupported(name), isFalse, reason: name);
      }
    });

    test('隐藏文件与 macOS 资源分叉被忽略（SD 卡上的常见污染）', () {
      expect(MediaFormat.isSupported('.nomedia'), isFalse);
      expect(MediaFormat.isSupported('._001.mp3'), isFalse);
      expect(MediaFormat.isSupported('三体/._002.mp3'), isFalse);
    });

    test('接受完整相对路径', () {
      expect(MediaFormat.isSupported('三体/卷一/001.mp3'), isTrue);
      expect(MediaFormat.isSupported('三体/卷一/001.MP3'), isTrue);
    });

    test('多段扩展名按最后一段判定', () {
      expect(MediaFormat.isSupported('chapter.01.flac'), isTrue);
      expect(MediaFormat.isSupported('chapter.mp3.bak'), isFalse);
    });
  });

  group('extensionOf', () {
    test('返回小写扩展名', () {
      expect(MediaFormat.extensionOf('A.MP3'), 'mp3');
      expect(MediaFormat.extensionOf('a.tar.gz'), 'gz');
    });

    test('无扩展名 / 以点开头的隐藏文件返回 null', () {
      expect(MediaFormat.extensionOf('noext'), isNull);
      expect(MediaFormat.extensionOf('.mp3'), isNull);
      expect(MediaFormat.extensionOf('trailing.'), isNull);
    });
  });

  group('titleOf', () {
    test('去掉目录与扩展名', () {
      expect(MediaFormat.titleOf('三体/卷一/001.mp3'), '001');
      expect(MediaFormat.titleOf('第一章 远征.MP3'), '第一章 远征');
      expect(MediaFormat.titleOf('noext'), 'noext');
    });
  });
}
