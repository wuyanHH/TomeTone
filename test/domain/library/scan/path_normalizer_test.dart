import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/scan/path_normalizer.dart';

void main() {
  group('NFC 归一化', () {
    test('NFD 与 NFC 写法归一到同一结果（绑定键稳定）', () {
      // 'é' 的组合形式（e + U+0301）与预组合形式（U+00E9）。
      const decomposed = '\u0065\u0301';
      const composed = '\u00E9';

      expect(decomposed == composed, isFalse, reason: '两种写法字节不同');
      expect(
        PathNormalizer.normalize('三体/$decomposed.mp3'),
        PathNormalizer.normalize('三体/$composed.mp3'),
      );
    });
  });

  group('分隔符与前缀', () {
    test('反斜杠统一为斜杠并去掉前后导斜杠', () {
      expect(PathNormalizer.normalize(r'三体\卷一\001.mp3'), '三体/卷一/001.mp3');
      expect(PathNormalizer.normalize('/三体/卷一/'), '三体/卷一');
    });

    test('折叠 . 与 ..', () {
      expect(
        PathNormalizer.normalize('三体/./卷一/../卷二/001.mp3'),
        '三体/卷二/001.mp3',
      );
    });

    test('空路径与纯分隔符', () {
      expect(PathNormalizer.normalize(''), '');
      expect(PathNormalizer.normalize('///'), '');
    });
  });

  group('depthOf', () {
    test('按分段计数', () {
      expect(PathNormalizer.depthOf(''), 0);
      expect(PathNormalizer.depthOf('三体'), 1);
      expect(PathNormalizer.depthOf('三体/卷一/001.mp3'), 3);
      expect(PathNormalizer.depthOf('/三体//卷一/'), 2);
    });
  });
}
