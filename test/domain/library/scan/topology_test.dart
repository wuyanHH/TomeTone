import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/scan/topology.dart';

ScanNode _file(String path, {int? sizeBytes}) =>
    ScanNode(path: path, sizeBytes: sizeBytes);

List<String> _titles(List<ChapterTopology> chapters) => <String>[
  for (final chapter in chapters) chapter.title,
];

List<int> _indices(List<ChapterTopology> chapters) => <int>[
  for (final chapter in chapters) chapter.chapterIndex,
];

void main() {
  group('单卷平铺', () {
    test('书目录下的音频直接构成一个根卷，并按自然顺序排章', () {
      final books = TopologyBuilder.build(<ScanNode>[
        _file('三体/010.mp3'),
        _file('三体/002.mp3'),
        _file('三体/001.mp3'),
        _file('三体/cover.jpg'),
      ]);

      expect(books, hasLength(1));
      final book = books.single;
      expect(book.rootPath, '三体');
      expect(book.title, '三体');
      expect(book.volumes, hasLength(1));

      final volume = book.volumes.single;
      expect(volume.path, '');
      expect(volume.volumeIndex, 0);
      expect(volume.title, '三体');
      expect(_titles(volume.chapters), <String>['001', '002', '010']);
      expect(_indices(volume.chapters), <int>[0, 1, 2]);
      expect(volume.chapters.first.filePath, '三体/001.mp3');
      expect(book.totalChapters, 3);
    });
  });

  group('多卷嵌套', () {
    test('书目录下的第一层子目录成为卷，卷序与章序都按自然顺序', () {
      final books = TopologyBuilder.build(<ScanNode>[
        _file('三体/卷十/001.mp3'),
        _file('三体/卷一/001.mp3'),
        _file('三体/卷一/002.mp3'),
        _file('三体/卷二/001.mp3'),
      ]);

      final book = books.single;
      expect(book.volumes.map((VolumeTopology v) => v.path).toList(), <String>[
        '卷一',
        '卷二',
        '卷十',
      ]);
      expect(
        book.volumes.map((VolumeTopology v) => v.volumeIndex).toList(),
        <int>[0, 1, 2],
      );
      expect(_titles(book.volumes.first.chapters), <String>['001', '002']);
      // chapterIndex 全书连续，卷内即升序子序列。
      expect(_indices(book.volumes[0].chapters), <int>[0, 1]);
      expect(_indices(book.volumes[1].chapters), <int>[2]);
      expect(_indices(book.volumes[2].chapters), <int>[3]);
      expect(book.totalChapters, 4);
    });

    test('根卷与子卷混排时根卷优先', () {
      final books = TopologyBuilder.build(<ScanNode>[
        _file('三体/002.mp3'),
        _file('三体/001.mp3'),
        _file('三体/卷二/001.mp3'),
      ]);

      final book = books.single;
      expect(book.volumes.map((VolumeTopology v) => v.path).toList(), <String>[
        '',
        '卷二',
      ]);
      expect(_indices(book.volumes[0].chapters), <int>[0, 1]);
      expect(_indices(book.volumes[1].chapters), <int>[2]);
    });

    test('卷内可继续嵌套，按卷内相对路径排序', () {
      final books = TopologyBuilder.build(<ScanNode>[
        _file('三体/卷一/10/001.mp3'),
        _file('三体/卷一/01/001.mp3'),
        _file('三体/卷一/02/001.mp3'),
      ]);

      final volume = books.single.volumes.single;
      expect(
        volume.chapters.map((ChapterTopology c) => c.filePath).toList(),
        <String>['三体/卷一/01/001.mp3', '三体/卷一/02/001.mp3', '三体/卷一/10/001.mp3'],
      );
    });
  });

  group('过滤规则', () {
    test('非音频、隐藏文件、目录、书库根下裸文件全部忽略', () {
      final books = TopologyBuilder.build(<ScanNode>[
        _file('三体/001.mp3'),
        _file('三体/cover.jpg'),
        _file('三体/.nomedia'),
        _file('三体/._001.mp3'),
        const ScanNode(path: '三体/子目录', isDirectory: true),
        _file('裸文件.mp3'),
      ]);

      expect(books, hasLength(1));
      expect(books.single.totalChapters, 1);
    });

    test('全部无效时返回空列表', () {
      expect(
        TopologyBuilder.build(<ScanNode>[
          _file('三体/cover.jpg'),
          _file('裸文件.mp3'),
        ]),
        isEmpty,
      );
    });

    test('超过最大深度的条目被丢弃（防御异常目录结构）', () {
      expect(
        TopologyBuilder.build(<ScanNode>[_file('a/b/c/d/e/f/g/h/i.mp3')]),
        isEmpty,
      );
    });
  });

  group('多书与深度配置', () {
    test('多书按路径自然排序输出', () {
      final books = TopologyBuilder.build(<ScanNode>[
        _file('B/001.mp3'),
        _file('A/001.mp3'),
        _file('书十/001.mp3'),
        _file('书二/001.mp3'),
      ]);

      expect(books.map((BookTopology b) => b.rootPath).toList(), <String>[
        'A',
        'B',
        '书二',
        '书十',
      ]);
    });

    test('bookDepth = 2 时按两层目录识别书', () {
      final books = TopologyBuilder.build(<ScanNode>[
        _file('作者/书名/001.mp3'),
      ], bookDepth: 2);

      final book = books.single;
      expect(book.rootPath, '作者/书名');
      expect(book.title, '书名');
      expect(book.volumes.single.path, '');
    });

    test('空输入返回空列表', () {
      expect(TopologyBuilder.build(<ScanNode>[]), isEmpty);
    });

    test('bookDepth 非法时抛 ArgumentError', () {
      expect(
        () => TopologyBuilder.build(const <ScanNode>[], bookDepth: 0),
        throwsArgumentError,
      );
    });
  });
}
