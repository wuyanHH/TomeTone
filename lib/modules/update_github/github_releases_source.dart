/// GitHub Releases 更新源实现（《架构需求文档》2.7）。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';

/// 基于 GitHub REST API 的更新源。
class GithubReleasesSource implements UpdateSource {
  /// 创建 GitHub 更新源。
  ///
  /// 若 [owner] 或 [repo] 为空，抛出 [UpdateFailureKind.notConfigured] 异常。
  GithubReleasesSource({
    required this.client,
    required String owner,
    required String repo,
    required String userAgent,
    this.timeout = const Duration(seconds: 10),
  })  : owner = owner.trim(),
        repo = repo.trim(),
        userAgent = userAgent.trim() {
    if (this.owner.isEmpty || this.repo.isEmpty) {
      throw const UpdateException(
        kind: UpdateFailureKind.notConfigured,
        message: 'GitHub 更新源未配置 owner 或 repo',
      );
    }
  }

  /// HTTP 客户端。
  final http.Client client;

  /// GitHub 组织或用户名。
  final String owner;

  /// GitHub 仓库名。
  final String repo;

  /// 请求 User-Agent。
  final String userAgent;

  /// 网络请求超时时间。
  final Duration timeout;

  @override
  Future<UpdateFetchResult> fetchReleases({String? etag}) async {
    if (owner.isEmpty || repo.isEmpty) {
      throw const UpdateException(
        kind: UpdateFailureKind.notConfigured,
        message: 'GitHub 更新源未配置 owner 或 repo',
      );
    }

    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/releases',
      const <String, String>{'per_page': '30'},
    );

    final headers = <String, String>{
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': userAgent,
      if (etag != null && etag.trim().isNotEmpty) 'If-None-Match': etag.trim(),
    };

    final http.Response response;
    try {
      response = await client.get(uri, headers: headers).timeout(timeout);
    } on SocketException catch (e) {
      throw UpdateException(
        kind: UpdateFailureKind.network,
        message: '网络连接失败: ${e.message}',
      );
    } on TimeoutException catch (e) {
      throw UpdateException(
        kind: UpdateFailureKind.network,
        message: '网络请求超时: ${e.message ?? '未在限定时间内响应'}',
      );
    } on http.ClientException catch (e) {
      throw UpdateException(
        kind: UpdateFailureKind.network,
        message: 'HTTP 客户端异常: ${e.message}',
      );
    } on IOException catch (e) {
      throw UpdateException(
        kind: UpdateFailureKind.network,
        message: '网络 I/O 异常: $e',
      );
    }

    final responseEtag = _findHeader(response.headers, 'etag');

    if (response.statusCode == 200) {
      final Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException catch (e) {
        throw UpdateException(
          kind: UpdateFailureKind.badResponse,
          message: 'GitHub 响应非有效 JSON: ${e.message}',
        );
      }

      if (decoded is! List) {
        throw const UpdateException(
          kind: UpdateFailureKind.badResponse,
          message: 'GitHub releases 响应结构不符合预期（非列表）',
        );
      }

      final releases = <ReleaseInfo>[];
      for (final item in decoded) {
        if (item is Map) {
          releases.add(ReleaseInfo.fromJson(item.cast<String, Object?>()));
        }
      }

      return UpdateFetchResult(
        releases: releases,
        etag: responseEtag,
      );
    }

    if (response.statusCode == 304) {
      return UpdateFetchResult(
        notModified: true,
        etag: responseEtag ?? etag,
      );
    }

    if (response.statusCode == 403 || response.statusCode == 429) {
      final remaining =
          _findHeader(response.headers, 'x-ratelimit-remaining')?.trim();
      if (remaining == '0') {
        throw const UpdateException(
          kind: UpdateFailureKind.rateLimited,
          message: 'GitHub API 调用频次已达上限',
        );
      }
      throw UpdateException(
        kind: UpdateFailureKind.badResponse,
        message: 'GitHub API 请求失败 (HTTP ${response.statusCode})',
      );
    }

    throw UpdateException(
      kind: UpdateFailureKind.badResponse,
      message: 'GitHub API 请求失败 (HTTP ${response.statusCode})',
    );
  }

  static String? _findHeader(Map<String, String> headers, String target) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == target.toLowerCase()) {
        return entry.value;
      }
    }
    return null;
  }
}
