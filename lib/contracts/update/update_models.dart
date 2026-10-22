/// 更新相关数据契约（《架构需求文档》2.7 与更新基础设施）。
///
/// 纯 Dart 类，严禁依赖 Flutter。
library;

/// 发布产物资产信息。
class ReleaseAsset {
  /// 创建资产信息。
  const ReleaseAsset({
    required this.name,
    required this.sizeBytes,
    required this.downloadUrl,
    this.digest,
  });

  /// 从 Map 容错解析资产信息（兼容内部序列化与 GitHub API 格式）。
  factory ReleaseAsset.fromJson(Map<String, Object?> json) {
    final name = (json['name'] ?? '').toString();

    final rawSize = json['sizeBytes'] ?? json['size'];
    final int sizeBytes;
    if (rawSize is int) {
      sizeBytes = rawSize;
    } else if (rawSize is num) {
      sizeBytes = rawSize.toInt();
    } else if (rawSize is String) {
      sizeBytes = int.tryParse(rawSize) ?? 0;
    } else {
      sizeBytes = 0;
    }

    final rawUrl = json['downloadUrl'] ??
        json['browser_download_url'] ??
        json['download_url'];
    final downloadUrl = (rawUrl ?? '').toString();

    final digest = json['digest'] as String?;

    return ReleaseAsset(
      name: name,
      sizeBytes: sizeBytes,
      downloadUrl: downloadUrl,
      digest: digest,
    );
  }

  /// 产物文件名（例如 `tometone-v0.2.0-beta.1-arm64-v8a.apk`）。
  final String name;

  /// 文件大小（字节）。
  final int sizeBytes;

  /// 产物下载直链。
  final String downloadUrl;

  /// 校验和哈希摘要（如 `sha256:xxx`），可选。
  final String? digest;

  /// 序列化为 JSON 字典。
  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        'sizeBytes': sizeBytes,
        'downloadUrl': downloadUrl,
        if (digest != null) 'digest': digest,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReleaseAsset &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          sizeBytes == other.sizeBytes &&
          downloadUrl == other.downloadUrl &&
          digest == other.digest;

  @override
  int get hashCode => Object.hash(name, sizeBytes, downloadUrl, digest);

  @override
  String toString() =>
      'ReleaseAsset(name: $name, sizeBytes: $sizeBytes, downloadUrl: $downloadUrl, digest: $digest)';
}

/// 发布版本信息。
class ReleaseInfo {
  /// 创建发布版本信息。
  const ReleaseInfo({
    required this.tag,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.htmlUrl,
    required this.prerelease,
    required this.draft,
    required this.assets,
  });

  /// 从 Map 容错解析版本信息（兼容内部序列化与 GitHub API 格式）。
  factory ReleaseInfo.fromJson(Map<String, Object?> json) {
    final tag = (json['tag'] ?? json['tag_name'] ?? '').toString();
    final name = (json['name'] ?? json['tag'] ?? json['tag_name'] ?? '').toString();
    final body = (json['body'] ?? '').toString();

    final rawDate =
        json['publishedAt'] ?? json['published_at'] ?? json['created_at'];
    final DateTime publishedAt;
    if (rawDate is String) {
      publishedAt =
          DateTime.tryParse(rawDate)?.toUtc() ?? _unixEpochUtc;
    } else if (rawDate is int) {
      publishedAt = DateTime.fromMillisecondsSinceEpoch(rawDate, isUtc: true);
    } else {
      publishedAt = _unixEpochUtc;
    }

    final htmlUrl = (json['htmlUrl'] ?? json['html_url'] ?? '').toString();

    final rawPrerelease = json['prerelease'];
    final bool prerelease;
    if (rawPrerelease is bool) {
      prerelease = rawPrerelease;
    } else if (rawPrerelease is String) {
      prerelease = rawPrerelease.toLowerCase() == 'true';
    } else {
      prerelease = false;
    }

    final rawDraft = json['draft'];
    final bool draft;
    if (rawDraft is bool) {
      draft = rawDraft;
    } else if (rawDraft is String) {
      draft = rawDraft.toLowerCase() == 'true';
    } else {
      draft = false;
    }

    final rawAssets = json['assets'];
    final List<ReleaseAsset> assets;
    if (rawAssets is List) {
      assets = rawAssets
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => ReleaseAsset.fromJson(item.cast<String, Object?>()))
          .toList(growable: false);
    } else {
      assets = const <ReleaseAsset>[];
    }

    return ReleaseInfo(
      tag: tag,
      name: name,
      body: body,
      publishedAt: publishedAt,
      htmlUrl: htmlUrl,
      prerelease: prerelease,
      draft: draft,
      assets: assets,
    );
  }

  static final DateTime _unixEpochUtc =
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Git 标签名（例如 `v0.2.0-beta.1`）。
  final String tag;

  /// Release 标题。
  final String name;

  /// 版本说明文案（Markdown 格式）。
  final String body;

  /// 发布时间（UTC）。
  final DateTime publishedAt;

  /// Release 页面 Web 地址。
  final String htmlUrl;

  /// 是否为预发布版本。
  final bool prerelease;

  /// 是否为草稿。
  final bool draft;

  /// 关联构建资产列表。
  final List<ReleaseAsset> assets;

  /// 序列化为 JSON 字典。
  Map<String, Object?> toJson() => <String, Object?>{
        'tag': tag,
        'name': name,
        'body': body,
        'publishedAt': publishedAt.toUtc().toIso8601String(),
        'htmlUrl': htmlUrl,
        'prerelease': prerelease,
        'draft': draft,
        'assets': assets.map((a) => a.toJson()).toList(growable: false),
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReleaseInfo || runtimeType != other.runtimeType) return false;
    if (tag != other.tag ||
        name != other.name ||
        body != other.body ||
        !publishedAt.isAtSameMomentAs(other.publishedAt) ||
        htmlUrl != other.htmlUrl ||
        prerelease != other.prerelease ||
        draft != other.draft ||
        assets.length != other.assets.length) {
      return false;
    }
    for (var i = 0; i < assets.length; i++) {
      if (assets[i] != other.assets[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        tag,
        name,
        body,
        publishedAt.millisecondsSinceEpoch,
        htmlUrl,
        prerelease,
        draft,
        Object.hashAll(assets),
      );

  @override
  String toString() =>
      'ReleaseInfo(tag: $tag, name: $name, prerelease: $prerelease, draft: $draft, assets: ${assets.length})';
}
