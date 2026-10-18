import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';

void main() {
  test('rank 与文档 1–5 级一一对应', () {
    expect(CoverSource.volumeDirectory.rank, 0);
    expect(CoverSource.bookRoot.rank, 1);
    expect(CoverSource.firstVolumeFeedback.rank, 2);
    expect(CoverSource.firstChapterEmbedded.rank, 3);
    expect(CoverSource.typography.rank, 4);
    expect(CoverSource.typographyRank, CoverSource.typography.rank);
  });

  test('枚举声明顺序即优先级', () {
    for (var index = 0; index < CoverSource.values.length; index++) {
      expect(CoverSource.values[index].rank, index);
    }
  });

  test('fromRank 往返', () {
    for (final value in CoverSource.values) {
      expect(CoverSource.fromRank(value.rank), value);
    }
  });

  test('未知序号回退到字标（前向兼容，不崩溃）', () {
    expect(CoverSource.fromRank(99), CoverSource.typography);
    expect(CoverSource.fromRank(-1), CoverSource.typography);
  });

  test('转换器往返', () {
    const converter = CoverSourceConverter();
    for (final value in CoverSource.values) {
      expect(converter.fromSql(converter.toSql(value)), value);
    }
  });

  test('语义便捷判定', () {
    expect(CoverSource.typography.isTypography, isTrue);
    expect(CoverSource.bookRoot.isTypography, isFalse);
    expect(CoverSource.firstChapterEmbedded.needsEmbeddedArtwork, isTrue);
    expect(CoverSource.volumeDirectory.needsEmbeddedArtwork, isFalse);
  });
}
