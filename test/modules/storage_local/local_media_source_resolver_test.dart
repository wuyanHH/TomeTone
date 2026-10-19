import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/modules/storage_local/local_media_source_resolver.dart';

void main() {
  late Directory temp;
  late String libraryPath;
  late LocalMediaSourceResolver resolver;

  final List<int> chapterBytes = List<int>.generate(64, (int index) => index);

  setUpAll(() {
    temp = Directory.systemTemp.createTempSync('tometone_local_media_');
    final library = Directory('${temp.path}${Platform.pathSeparator}library');
    final volume = Directory('${library.path}${Platform.pathSeparator}第一卷 上');
    volume.createSync(recursive: true);
    File('${volume.path}${Platform.pathSeparator}001 章 #1.mp3')
        .writeAsBytesSync(chapterBytes);
  });

  tearDownAll(() {
    if (temp.existsSync()) {
      temp.deleteSync(recursive: true);
    }
  });

  setUp(() {
    libraryPath = '${temp.path}${Platform.pathSeparator}library';
    resolver = LocalMediaSourceResolver(libraryPath);
  });

  group('resolveAudio', () {
    test('命中时返回可直接播放的本地文件源', () async {
      final source = await resolver.resolveAudio(
        relativePath: '第一卷 上/001 章 #1.mp3',
      );

      expect(source, isA<LocalFileSource>());
      expect(
        source!.uri,
        Uri.file(
          '$libraryPath${Platform.pathSeparator}第一卷 上'
          '${Platform.pathSeparator}001 章 #1.mp3',
        ).toString(),
        reason: '中文 / 空格 / # 必须按路径段原样保留',
      );
    });

    test('文件不存在时返回 null，而不是把错误拖到引擎', () async {
      final source = await resolver.resolveAudio(relativePath: '第一卷 上/不存在.mp3');

      expect(source, isNull);
    });

    test('目录不会被当成音频源', () async {
      final source = await resolver.resolveAudio(relativePath: '第一卷 上');

      expect(source, isNull);
    });

    test('拒绝 .. 穿越与绝对路径', () async {
      for (final path in <String>[
        '../outside.mp3',
        '第一卷 上/../../outside.mp3',
        '/etc/passwd',
      ]) {
        expect(
          await resolver.resolveAudio(relativePath: path),
          isNull,
          reason: path,
        );
      }
    });
  });

  group('readBytes', () {
    test('命中时返回文件字节', () async {
      final bytes = await resolver.readBytes(
        relativePath: '第一卷 上/001 章 #1.mp3',
      );

      expect(bytes, chapterBytes);
    });

    test('文件不存在时返回 null', () async {
      final bytes = await resolver.readBytes(relativePath: '第一卷 上/不存在.jpg');

      expect(bytes, isNull);
    });

    test('超过上限的文件返回 null', () async {
      final large = File('$libraryPath${Platform.pathSeparator}large.bin');
      large.writeAsBytesSync(
        List<int>.filled(LocalMediaSourceResolver.maxReadBytes + 1, 0),
      );
      addTearDown(() {
        if (large.existsSync()) {
          large.deleteSync();
        }
      });

      expect(await resolver.readBytes(relativePath: 'large.bin'), isNull);
    });
  });
}
