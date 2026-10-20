import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';

void main() {
  group('normalizeTags', () {
    test('去首尾空格、去空串、去重（保留首次写法）', () {
      expect(
        normalizeTags([' 武侠 ', '', '武侠', '长篇', '长篇']),
        ['武侠', '长篇'],
      );
    });

    test('大小写不敏感去重，保留首次写法', () {
      expect(normalizeTags(['A', 'a']), ['A']);
    });

    test('按 , / ， / 、 拆分未拆分的整串', () {
      expect(normalizeTags(['武侠,长篇、科幻，武侠']), ['武侠', '长篇', '科幻']);
    });
  });

  group('BookMetadataDraft', () {
    test('空草稿归一化后仍为空', () {
      expect(const BookMetadataDraft().normalized().isEmpty, isTrue);
    });

    test('纯空白字符串归一化为 null', () {
      expect(const BookMetadataDraft(author: '  ').normalized().author, isNull);
    });

    test('含标签的草稿不为空', () {
      expect(const BookMetadataDraft(tags: ['武侠']).isEmpty, isFalse);
    });
  });
}
