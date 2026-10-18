import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/scan/natural_order.dart';

void main() {
  group('parseChineseNumeral', () {
    test('个位与「两」', () {
      expect(NaturalOrder.parseChineseNumeral('零'), 0);
      expect(NaturalOrder.parseChineseNumeral('一'), 1);
      expect(NaturalOrder.parseChineseNumeral('两'), 2);
      expect(NaturalOrder.parseChineseNumeral('九'), 9);
    });

    test('十位', () {
      expect(NaturalOrder.parseChineseNumeral('十'), 10);
      expect(NaturalOrder.parseChineseNumeral('十一'), 11);
      expect(NaturalOrder.parseChineseNumeral('二十'), 20);
      expect(NaturalOrder.parseChineseNumeral('二十一'), 21);
    });

    test('百 / 千 / 万 与零位', () {
      expect(NaturalOrder.parseChineseNumeral('一百'), 100);
      expect(NaturalOrder.parseChineseNumeral('一百零八'), 108);
      expect(NaturalOrder.parseChineseNumeral('一百一十'), 110);
      expect(NaturalOrder.parseChineseNumeral('一千零一'), 1001);
      expect(NaturalOrder.parseChineseNumeral('一万'), 10000);
      expect(NaturalOrder.parseChineseNumeral('一万零三'), 10003);
    });

    test('非法序数返回 null（不会把普通词语误当数值）', () {
      expect(NaturalOrder.parseChineseNumeral('一二'), isNull);
      expect(NaturalOrder.parseChineseNumeral('序'), isNull);
      expect(NaturalOrder.parseChineseNumeral('abc'), isNull);
      expect(NaturalOrder.parseChineseNumeral(''), isNull);
      expect(NaturalOrder.parseChineseNumeral('万万'), isNull);
      expect(NaturalOrder.parseChineseNumeral('万万没想到'), isNull);
    });

    test('四位章号仍然正确', () {
      expect(NaturalOrder.parseChineseNumeral('九千九百九十九'), 9999);
    });
  });

  group('阿拉伯数字按数值比较', () {
    test('第1章 < 第2章 < 第10章', () {
      expect(NaturalOrder.compare('第1章', '第2章'), lessThan(0));
      expect(NaturalOrder.compare('第2章', '第10章'), lessThan(0));
    });

    test('文件名 1/2/10 不再按字典序错排', () {
      expect(
        NaturalOrder.sorted(<String>[
          '10.mp3',
          '1.mp3',
          '001.mp3',
          '2.mp3',
          'chapter 2.mp3',
          'chapter 10.mp3',
        ]),
        <String>[
          '001.mp3',
          '1.mp3',
          '2.mp3',
          '10.mp3',
          'chapter 2.mp3',
          'chapter 10.mp3',
        ],
      );
    });
  });

  group('中文序数与阿拉伯数字等价', () {
    test('第一章与第1章自然键相同，靠原始字符串确定性兜底', () {
      final chinese = NaturalOrder.key('第一章');
      final arabic = NaturalOrder.key('第1章');
      expect(
        chinese.tokens.toString(),
        arabic.tokens.toString(),
        reason: '两者都应为 [第, 1, 章]',
      );
      // 全序：同名键仍可比较，且方向固定。
      expect(NaturalOrder.compare('第1章', '第一章'), lessThan(0));
      expect(NaturalOrder.compare('第一章', '第1章'), greaterThan(0));
    });

    test('卷三 < 卷十', () {
      expect(NaturalOrder.compare('卷三', '卷十'), lessThan(0));
      expect(NaturalOrder.sorted(<String>['卷十', '卷三', '卷一', '卷二十']), <String>[
        '卷一',
        '卷三',
        '卷十',
        '卷二十',
      ]);
    });
  });

  group('前缀分组：序 → 楔子 → 正文 → 番外', () {
    test('验收语料的完整顺序', () {
      expect(
        NaturalOrder.sorted(<String>[
          '番外一',
          '第十章',
          '序',
          '第一章',
          '楔子',
          '第2章',
          '第10章',
          '附录',
        ]),
        <String>['序', '楔子', '第一章', '第2章', '第10章', '第十章', '番外一', '附录'],
      );
    });

    test('分组归属正确', () {
      expect(NaturalOrder.key('序').groupRank, 0);
      expect(NaturalOrder.key('前言').groupRank, 0);
      expect(NaturalOrder.key('楔子').groupRank, 1);
      expect(NaturalOrder.key('序章').groupRank, 1);
      expect(NaturalOrder.key('第一章').groupRank, 2);
      expect(NaturalOrder.key('番外一').groupRank, 3);
      expect(NaturalOrder.key('附录A').groupRank, 3);
    });

    test('标记必须整词命中：序曲不被误分组', () {
      expect(NaturalOrder.key('序曲').groupRank, 2);
    });

    test('番外 + 序号属于番外组（最常见的番外命名）', () {
      expect(NaturalOrder.key('番外一').groupRank, 3);
      expect(NaturalOrder.key('番外十').groupRank, 3);
      expect(NaturalOrder.key('番外1').groupRank, 3);
      expect(NaturalOrder.key('番外篇').groupRank, 3);
      expect(NaturalOrder.key('番外（一）').groupRank, 3);
    });

    test('番外编号仍按自然顺序', () {
      expect(NaturalOrder.sorted(<String>['番外二', '番外十', '番外一']), <String>[
        '番外一',
        '番外二',
        '番外十',
      ]);
    });
  });

  group('确定性', () {
    test('sortedIndices 对同名标题按原始下标兜底', () {
      expect(NaturalOrder.sortedIndices(<String>['第一章', '第一章', '序']), <int>[
        2,
        0,
        1,
      ]);
    });

    test('空串与纯符号不抛异常', () {
      expect(() => NaturalOrder.key(''), returnsNormally);
      expect(NaturalOrder.key('').groupRank, 2);
      expect(NaturalOrder.sorted(<String>['', '第1章']), <String>['', '第1章']);
    });

    test('超长数字按文本处理（毫秒时间戳命名不会中断扫描）', () {
      expect(
        () => NaturalOrder.key('20261018030000123456.mp3'),
        returnsNormally,
      );
      expect(
        NaturalOrder.sorted(<String>['20261018030000123456.mp3', '第1章']),
        hasLength(2),
      );
    });

    test('万级标题排序不退化（防 O(n²)）', () {
      final titles = <String>[for (var i = 1; i <= 10000; i++) '第$i章'];
      final watch = Stopwatch()..start();
      final sorted = NaturalOrder.sorted(titles);
      watch.stop();

      expect(sorted, hasLength(10000));
      expect(sorted.first, '第1章');
      expect(sorted.last, '第10000章');
      // 15s 是**宽松护栏**：`flutter test` 会并行执行测试文件，墙钟时间不能精确断言；
      // 真实性能目标按附录 D 的方法在真机定标。
      expect(
        watch.elapsedMilliseconds,
        lessThan(15000),
        reason: '排序算法退化（万级标题应在数百毫秒内完成）',
      );
    });
  });
}
