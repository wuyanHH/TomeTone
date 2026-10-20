import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/metadata/book_metadata.dart';
import 'package:tometone/domain/library/metadata/book_metadata_codec.dart';

void main() {
  group('BookMetadataCodec', () {
    test('编码后解码往返一致（中文书名与标签）', () {
      final bytes = BookMetadataCodec.encode(
        const BookMetadataDraft(title: '长夜行舟', tags: ['武侠']),
        updatedAt: DateTime.utc(2026, 10, 20),
      );
      final decoded = BookMetadataCodec.decode(bytes)!;
      expect(decoded.title, '长夜行舟');
      expect(decoded.tags, ['武侠']);
    });

    test('坏 JSON 返回 null', () {
      expect(BookMetadataCodec.decode(Uint8List.fromList([1, 2, 3])), isNull);
    });

    test('schema 超前返回 null', () {
      expect(
        BookMetadataCodec.decode(
          Uint8List.fromList(utf8.encode('{"schema":99}')),
        ),
        isNull,
      );
    });

    test('JSON 缺字段时对应值为 null，未知字段被忽略', () {
      final decoded = BookMetadataCodec.decode(
        Uint8List.fromList(utf8.encode('{"schema":1,"unknownField":"x"}')),
      )!;
      expect(decoded.title, isNull);
      expect(decoded.author, isNull);
      expect(decoded.narrator, isNull);
      expect(decoded.seriesName, isNull);
      expect(decoded.seriesIndex, isNull);
      expect(decoded.description, isNull);
      expect(decoded.tags, isEmpty);
      expect(decoded.isEmpty, isTrue);
    });

    test('输出含 schema 与 updatedAt（ISO8601，UTC）', () {
      final bytes = BookMetadataCodec.encode(
        const BookMetadataDraft(title: '书'),
        updatedAt: DateTime.utc(2026, 10, 20),
      );
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      expect(json['schema'], BookMetadataCodec.schemaVersion);
      expect(json['updatedAt'], '2026-10-20T00:00:00.000Z');
    });

    test('encode 会先归一化（标签拆分、trim）', () {
      final bytes = BookMetadataCodec.encode(
        const BookMetadataDraft(tags: ['武侠, 长篇', '武侠']),
        updatedAt: DateTime.utc(2026, 10, 20),
      );
      final decoded = BookMetadataCodec.decode(bytes)!;
      expect(decoded.tags, ['武侠', '长篇']);
    });
  });
}
