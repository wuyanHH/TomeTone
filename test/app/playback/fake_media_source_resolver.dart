import 'dart:typed_data';

import 'package:tometone/contracts/media/media_source_resolver.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';

/// 解析回调：给定库内相对路径与是否要求缓存副本，返回可播放源（`null` = 解析失败）。
typedef ResolveStub = AudioSourceRef? Function(
  String relativePath,
  bool preferCachedCopy,
);

/// 可注入的 [MediaSourceResolver]：记录每次调用参数，便于断言重试行为。
///
/// - [resolve] 决定 [resolveAudio] 的返回；不传则一律解析失败。
/// - [bytes] 是 [readBytes] 的返回；不传则读不出封面。
class FakeMediaSourceResolver implements MediaSourceResolver {
  /// 创建 fake resolver。
  FakeMediaSourceResolver({this.resolve, this.bytes});

  /// 解析回调。
  final ResolveStub? resolve;

  /// `readBytes` 的返回字节。
  final Uint8List? bytes;

  /// 每次 [resolveAudio] 的入参（含 `preferCachedCopy`）。
  final List<({String relativePath, bool preferCachedCopy})> resolveCalls =
      <({String relativePath, bool preferCachedCopy})>[];

  /// 每次 [readBytes] 的入参。
  final List<String> readBytesCalls = <String>[];

  @override
  Future<AudioSourceRef?> resolveAudio({
    required String relativePath,
    bool preferCachedCopy = false,
  }) async {
    resolveCalls.add((
      relativePath: relativePath,
      preferCachedCopy: preferCachedCopy,
    ));
    return resolve?.call(relativePath, preferCachedCopy);
  }

  @override
  Future<Uint8List?> readBytes({required String relativePath}) async {
    readBytesCalls.add(relativePath);
    return bytes;
  }
}

/// 本地根语义的 fake：把「根 + 相对路径」拼成本地文件源。
FakeMediaSourceResolver localFakeResolver(String rootUri) {
  return FakeMediaSourceResolver(
    resolve: (String relativePath, bool _) =>
        LocalFileSource.fromPath('$rootUri/$relativePath'),
  );
}
