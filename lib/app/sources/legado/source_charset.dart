import 'dart:convert';
import 'dart:typed_data';

import 'package:enough_convert/enough_convert.dart';

/// 按书源声明或响应头字符集把原始字节解码成文本。
///
/// 书源 `charset` 字段优先于响应头；未声明时按 UTF-8。
String decodeSourceBytes(
  Uint8List bytes, {
  String? declaredCharset,
  String? contentType,
}) {
  final charset =
      _normalizeCharset(declaredCharset) ??
      _normalizeCharset(_charsetFromContentType(contentType)) ??
      'utf-8';

  switch (charset) {
    case 'utf-8':
    case 'utf8':
      return utf8.decode(bytes, allowMalformed: true);
    case 'gbk':
    case 'gb2312':
    case 'gb18030':
      return const GbkCodec(allowInvalid: true).decode(bytes);
    default:
      throw FormatException('不支持的字符集: $charset');
  }
}

String? _charsetFromContentType(String? contentType) {
  if (contentType == null || contentType.isEmpty) {
    return null;
  }
  final match = RegExp(
    r'''charset\s*=\s*["']?([^;"'\s]+)''',
    caseSensitive: false,
  ).firstMatch(contentType);
  return match?.group(1);
}

String? _normalizeCharset(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll('"', '')
      .replaceAll("'", '');
  return normalized.isEmpty ? null : normalized;
}
