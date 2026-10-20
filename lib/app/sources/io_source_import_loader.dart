import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../contracts/sources/source_import_loader.dart';
import '../../domain/sources/url_normalizer.dart';

/// 生产环境的书源加载器：HTTP(S) 下载或系统文件选择器。
class IoSourceImportLoader implements SourceImportLoader {
  const IoSourceImportLoader();

  static const int maxBytes = 5 * 1024 * 1024;
  static const Duration timeout = Duration(seconds: 15);
  static const int maxRedirects = 5;

  @override
  Future<String> loadFromUrl(String url) async {
    final Uri uri;
    try {
      uri = Uri.parse(normalizeNetworkUrl(url));
    } on FormatException {
      throw ArgumentError.value(url, 'url', '只允许带 host 的 http/https URL');
    }

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.maxRedirects = maxRedirects;
      final response = await request.close().timeout(timeout);

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('下载书源失败：HTTP ${response.statusCode}', uri: uri);
      }
      if (response.contentLength > maxBytes) {
        throw const FormatException('书源文件超过 5 MB 上限');
      }

      final builder = BytesBuilder(copy: false);
      await for (final chunk in response.timeout(timeout)) {
        if (builder.length + chunk.length > maxBytes) {
          throw const FormatException('书源文件超过 5 MB 上限');
        }
        builder.add(chunk);
      }

      return _decodeUtf8(builder.takeBytes(), source: '下载内容');
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<SourceImportFile?> pickJsonFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
    );
    if (files.isEmpty) {
      return null;
    }

    final file = files.single;
    final length = await file.length();
    if (length != null && length > maxBytes) {
      throw const FormatException('书源文件超过 5 MB 上限');
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw const FormatException('书源文件超过 5 MB 上限');
    }

    return SourceImportFile(
      name: file.name,
      content: _decodeUtf8(bytes, source: '文件'),
    );
  }

  String _decodeUtf8(Uint8List bytes, {required String source}) {
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw FormatException('$source不是 UTF-8 JSON');
    }
    return text.startsWith('\uFEFF') ? text.substring(1) : text;
  }
}
