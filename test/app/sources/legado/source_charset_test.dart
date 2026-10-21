import 'dart:convert';
import 'dart:typed_data';

import 'package:enough_convert/enough_convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/legado/source_charset.dart';

void main() {
  group('decodeSourceBytes', () {
    test('默认按 UTF-8 解码中文', () {
      final bytes = Uint8List.fromList(utf8.encode('中文'));
      expect(decodeSourceBytes(bytes), '中文');
    });

    test('contentType 的 charset 支持引号与大小写', () {
      final bytes = Uint8List.fromList(const GbkCodec().encode('中文'));
      expect(
        decodeSourceBytes(bytes, contentType: 'text/html; charset="GBK"'),
        '中文',
      );
    });

    test('声明的 charset 优先于 contentType', () {
      final gbkBytes = Uint8List.fromList(const GbkCodec().encode('中文'));
      expect(
        decodeSourceBytes(
          gbkBytes,
          declaredCharset: 'gb2312',
          contentType: 'text/html; charset=utf-8',
        ),
        '中文',
      );
    });

    test('gbk / gb2312 / gb18030 都走 GBK 解码', () {
      final bytes = Uint8List.fromList(const GbkCodec().encode('中文'));
      for (final charset in <String>['gbk', 'gb2312', 'gb18030']) {
        expect(decodeSourceBytes(bytes, declaredCharset: charset), '中文');
      }
    });

    test('不支持的编码抛 FormatException', () {
      expect(
        () => decodeSourceBytes(
          Uint8List.fromList(<int>[0x3f]),
          declaredCharset: 'shift_jis',
        ),
        throwsFormatException,
      );
    });
  });
}
