import 'dart:convert';
import 'dart:typed_data';

import 'package:tometone/domain/library/metadata/book_metadata.dart';

/// 书架元数据 sidecar 的编解码器（§2.1）。
///
/// 序列化格式为 JSON：`schema`（版本号）、各元数据字段与 `updatedAt`
/// （ISO8601，UTC）。[encode] 在落盘前先 [BookMetadataDraft.normalized]
/// 归一化；[decode] 对坏 JSON、`schema > schemaVersion` 返回 `null`，
/// 并对解析结果再次归一化（未知字段被忽略，缺字段为 `null`）。
class BookMetadataCodec {
  BookMetadataCodec._();

  /// 当前 sidecar schema 版本。
  static const int schemaVersion = 1;

  /// 编码草稿为 sidecar 字节。
  static Uint8List encode(
    BookMetadataDraft draft, {
    required DateTime updatedAt,
  }) {
    final normalized = draft.normalized();
    final json = <String, Object?>{
      'schema': schemaVersion,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'title': normalized.title,
      'author': normalized.author,
      'narrator': normalized.narrator,
      'seriesName': normalized.seriesName,
      'seriesIndex': normalized.seriesIndex,
      'description': normalized.description,
      'tags': normalized.tags,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(json)));
  }

  /// 解码 sidecar 字节；坏 JSON 或版本超前返回 `null`。
  static BookMetadataDraft? decode(Uint8List bytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    final map = decoded;
    final Object? schema = map['schema'];
    if (schema is! num || schema > schemaVersion) {
      return null;
    }
    return BookMetadataDraft(
      title: _stringOrNull(map['title']),
      author: _stringOrNull(map['author']),
      narrator: _stringOrNull(map['narrator']),
      seriesName: _stringOrNull(map['seriesName']),
      seriesIndex: _intOrNull(map['seriesIndex']),
      description: _stringOrNull(map['description']),
      tags: _stringList(map['tags']),
    ).normalized();
  }

  static String? _stringOrNull(Object? value) => value is String ? value : null;

  static int? _intOrNull(Object? value) => value is num ? value.toInt() : null;

  static List<String> _stringList(Object? value) {
    if (value is! List<Object?>) {
      return const <String>[];
    }
    return <String>[for (final item in value) if (item is String) item];
  }
}
