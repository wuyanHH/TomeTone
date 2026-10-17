import '../diagnostics/redactor.dart';

/// 播放源引用 —— 本地文件与远程 URL 的统一抽象（《架构需求文档》§6.1）。
///
/// 引擎**不感知**书 / 卷 / 章（§6.2 策略与机制分离）：它只认识"一个可播放的 URI"，
/// 以及可选的请求头。跨卷连播、片头片尾跳过等策略全部由核心层承担。
sealed class AudioSourceRef {
  const AudioSourceRef({required this.uri});

  /// 绝对 URI。本地源为 `file://`，远程源为 `http(s)://`。
  final String uri;
}

/// 本地文件源。
final class LocalFileSource extends AudioSourceRef {
  /// 以绝对 `file://` URI 创建本地源。
  const LocalFileSource({required super.uri});

  /// 以绝对文件系统路径创建本地源。
  factory LocalFileSource.fromPath(String absolutePath) =>
      LocalFileSource(uri: Uri.file(absolutePath).toString());

  @override
  String toString() => 'LocalFileSource(${Redactor.path(uri)})';
}

/// 远程源。
///
/// M1 使用引擎自带的请求头注入能力（Basic over HTTPS 覆盖 NAS / 坚果云 / Nextcloud，
/// 见 §7.2）；M2+ 引入本地回环代理后，本类型退化为"指向 127.0.0.1 的本地源"。
final class RemoteUrlSource extends AudioSourceRef {
  /// 以绝对 URL 与可选请求头创建远程源。
  const RemoteUrlSource({
    required super.uri,
    this.headers = const <String, String>{},
  });

  /// 请求头。可能包含凭据，**禁止直接写入日志**（先经 `Redactor.headers`）。
  final Map<String, String> headers;

  /// 安全副本：仅暴露脱敏后的 URL，绝不输出请求头内容。
  @override
  String toString() => 'RemoteUrlSource(${Redactor.url(uri)})';
}
