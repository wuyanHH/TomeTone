import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../contracts/sources/source_http.dart';

/// 基于 `dart:io` 的书源 HTTP 实现。
///
/// - 手动跟随重定向，方便在跨源时剥离认证头。
/// - 响应体流式读取，超过 [maxBytes] 立即中止。
/// - 4xx/5xx 作为正常响应返回，由规则引擎决定如何提示。
class IoSourceHttpClient implements SourceHttpClient {
  IoSourceHttpClient({this.maxBytes = 8 * 1024 * 1024, this.maxRedirects = 5});

  final int maxBytes;
  final int maxRedirects;

  static const Set<String> _safeRedirectHeaders = <String>{
    'user-agent',
    'accept',
    'accept-language',
  };

  @override
  Future<SourceHttpResponse> send(SourceHttpRequest request) async {
    _validate(request.url);

    final client = HttpClient();
    try {
      return await _send(client, request).timeout(
        request.timeout,
        onTimeout: () => throw const SourceTransportException(
          SourceTransportFailure.timeout,
          '请求超时',
        ),
      );
    } on SourceTransportException {
      rethrow;
    } on TimeoutException {
      throw const SourceTransportException(
        SourceTransportFailure.timeout,
        '请求超时',
      );
    } on SocketException {
      throw const SourceTransportException(
        SourceTransportFailure.network,
        '网络连接失败',
      );
    } on HttpException {
      throw const SourceTransportException(
        SourceTransportFailure.network,
        '网络请求失败',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<SourceHttpResponse> _send(
    HttpClient client,
    SourceHttpRequest request,
  ) async {
    var currentUrl = request.url;
    var method = request.method.toUpperCase();
    var headers = Map<String, String>.from(request.headers);
    var body = request.body;
    var redirects = 0;

    while (true) {
      final httpRequest = await client.openUrl(method, currentUrl);
      httpRequest
        ..followRedirects = false
        ..persistentConnection = false;
      headers.forEach(httpRequest.headers.set);
      if (body != null && method != 'GET' && method != 'HEAD') {
        httpRequest.add(utf8.encode(body));
      }
      final response = await httpRequest.close();

      final location = response.headers.value(HttpHeaders.locationHeader);
      if (_isRedirect(response.statusCode) && location != null) {
        await response.drain<void>();
        if (redirects >= maxRedirects) {
          throw const SourceTransportException(
            SourceTransportFailure.redirect,
            '重定向次数过多',
          );
        }

        final nextUrl = currentUrl.resolve(location);
        _validate(nextUrl);

        if (!_sameOrigin(currentUrl, nextUrl)) {
          headers = _stripUnsafeHeaders(headers);
        }
        if (response.statusCode == HttpStatus.seeOther ||
            ((response.statusCode == HttpStatus.movedPermanently ||
                    response.statusCode == HttpStatus.found) &&
                method != 'GET' &&
                method != 'HEAD')) {
          method = 'GET';
          body = null;
        }

        currentUrl = nextUrl;
        redirects++;
        continue;
      }

      final bytes = await _readLimited(response);
      return SourceHttpResponse(
        finalUrl: currentUrl,
        statusCode: response.statusCode,
        headers: _responseHeaders(response.headers),
        bytes: bytes,
      );
    }
  }

  Future<Uint8List> _readLimited(HttpClientResponse response) async {
    final builder = BytesBuilder(copy: false);
    var total = 0;
    await for (final chunk in response) {
      total += chunk.length;
      if (total > maxBytes) {
        throw const SourceTransportException(
          SourceTransportFailure.tooLarge,
          '响应体超过上限',
        );
      }
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Map<String, String> _responseHeaders(HttpHeaders headers) {
    final result = <String, String>{};
    headers.forEach((name, values) {
      result[name.toLowerCase()] = values.join(',');
    });
    return result;
  }

  Map<String, String> _stripUnsafeHeaders(Map<String, String> headers) {
    return <String, String>{
      for (final entry in headers.entries)
        if (_safeRedirectHeaders.contains(entry.key.toLowerCase()))
          entry.key: entry.value,
    };
  }

  bool _sameOrigin(Uri a, Uri b) {
    return a.scheme.toLowerCase() == b.scheme.toLowerCase() &&
        a.host.toLowerCase() == b.host.toLowerCase() &&
        _effectivePort(a) == _effectivePort(b);
  }

  int _effectivePort(Uri uri) {
    if (uri.hasPort) {
      return uri.port;
    }
    return uri.scheme.toLowerCase() == 'https' ? 443 : 80;
  }

  bool _isRedirect(int statusCode) {
    return statusCode == HttpStatus.movedPermanently ||
        statusCode == HttpStatus.found ||
        statusCode == HttpStatus.seeOther ||
        statusCode == HttpStatus.temporaryRedirect ||
        statusCode == HttpStatus.permanentRedirect;
  }

  void _validate(Uri url) {
    final scheme = url.scheme.toLowerCase();
    if ((scheme != 'http' && scheme != 'https') || url.host.isEmpty) {
      throw const SourceTransportException(
        SourceTransportFailure.invalidUrl,
        '只允许 http/https URL',
      );
    }
  }
}
