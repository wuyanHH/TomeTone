import 'dart:typed_data';

/// 一次书源 HTTP 请求。URL 必须已经由调用方规范化。
class SourceHttpRequest {
  const SourceHttpRequest({
    required this.url,
    this.method = 'GET',
    this.headers = const <String, String>{},
    this.body,
    this.timeout = const Duration(seconds: 15),
  });

  final Uri url;
  final String method;
  final Map<String, String> headers;
  final String? body;
  final Duration timeout;
}

/// 书源 HTTP 响应。body 保留原始字节，由字符集层解码。
class SourceHttpResponse {
  const SourceHttpResponse({
    required this.finalUrl,
    required this.statusCode,
    required this.headers,
    required this.bytes,
  });

  final Uri finalUrl;
  final int statusCode;
  final Map<String, String> headers;
  final Uint8List bytes;
}

enum SourceTransportFailure { network, timeout, tooLarge, invalidUrl, redirect }

class SourceTransportException implements Exception {
  const SourceTransportException(this.failure, this.message);

  final SourceTransportFailure failure;
  final String message;

  @override
  String toString() => message;
}

abstract interface class SourceHttpClient {
  Future<SourceHttpResponse> send(SourceHttpRequest request);
}
