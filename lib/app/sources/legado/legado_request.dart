import 'dart:convert';

import '../../../domain/sources/rules/template_rule.dart';
import '../../../domain/sources/url_normalizer.dart';

/// 构造完成后的 Legado 请求。
class LegadoRequest {
  const LegadoRequest({
    required this.url,
    required this.method,
    required this.headers,
    this.body,
    this.charset,
  });

  final Uri url;
  final String method;
  final Map<String, String> headers;
  final String? body;
  final String? charset;
}

class LegadoRequestBuilder {
  const LegadoRequestBuilder();

  LegadoRequest build({
    required String raw,
    required Uri baseUrl,
    required Map<String, String> sourceHeaders,
    String? key,
    int? page,
    String? defaultCharset,
  }) {
    final parsed = _parse(raw);
    final renderer = SyncTemplateRenderer(
      resolve: (expression) {
        return switch (expression.trim()) {
          'page' => page,
          'key' => key,
          _ => null,
        };
      },
    );

    final renderedUrl = renderer.render(
      parsed.url,
      mode: TemplateOutputMode.url,
    );
    final resolved = baseUrl.resolve(renderedUrl);
    final url = Uri.parse(normalizeNetworkUrl(resolved.toString()));

    final method = _string(parsed.options['method'])?.trim();
    final headers = <String, String>{};
    for (final entry in sourceHeaders.entries) {
      _putHeader(headers, entry.key, entry.value);
    }
    final optionsHeaders = parsed.options['headers'];
    if (optionsHeaders is Map) {
      for (final entry in optionsHeaders.entries) {
        if (entry.key is String && entry.value is String) {
          _putHeader(
            headers,
            entry.key as String,
            renderer.render(
              entry.value as String,
              mode: TemplateOutputMode.text,
            ),
          );
        }
      }
    }

    final body = _string(parsed.options['body']);
    final charset = _string(parsed.options['charset']) ?? defaultCharset;

    return LegadoRequest(
      url: url,
      method: method == null || method.isEmpty ? 'GET' : method.toUpperCase(),
      headers: Map<String, String>.unmodifiable(headers),
      body: body == null
          ? null
          : renderer.render(body, mode: TemplateOutputMode.jsonBody),
      charset: charset,
    );
  }

  _ParsedRequest _parse(String raw) {
    final input = raw.trim();
    final separator = input.lastIndexOf(',{');
    if (separator >= 0) {
      try {
        final decoded = jsonDecode(input.substring(separator + 1));
        if (decoded is Map) {
          return _ParsedRequest(
            input.substring(0, separator).trim(),
            Map<String, Object?>.from(decoded),
          );
        }
      } on FormatException {
        // 不是合法 options，整串按 URL 处理。
      }
    }
    return _ParsedRequest(input, const <String, Object?>{});
  }

  String? _string(Object? value) => value is String ? value : null;

  void _putHeader(Map<String, String> headers, String key, String value) {
    final lower = key.toLowerCase();
    final existing = headers.keys
        .where((candidate) => candidate.toLowerCase() == lower)
        .toList(growable: false);
    for (final candidate in existing) {
      headers.remove(candidate);
    }
    headers[key] = value;
  }
}

class _ParsedRequest {
  const _ParsedRequest(this.url, this.options);

  final String url;
  final Map<String, Object?> options;
}
