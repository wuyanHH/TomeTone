import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/modules/update_github/github_releases_source.dart';

void main() {
  const testOwner = 'test-owner';
  const testRepo = 'test-repo';
  const testUserAgent = 'TomeTone-Test/1.0';

  group('GithubReleasesSource 构造配置', () {
    test('未配置 owner 抛出 notConfigured 异常', () {
      expect(
        () => GithubReleasesSource(
          client: MockClient((_) async => http.Response('[]', 200)),
          owner: '',
          repo: testRepo,
          userAgent: testUserAgent,
        ),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.notConfigured,
          ),
        ),
      );
    });

    test('未配置 repo 抛出 notConfigured 异常', () {
      expect(
        () => GithubReleasesSource(
          client: MockClient((_) async => http.Response('[]', 200)),
          owner: testOwner,
          repo: '   ',
          userAgent: testUserAgent,
        ),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.notConfigured,
          ),
        ),
      );
    });
  });

  group('GithubReleasesSource.fetchReleases 请求与响应', () {
    test('正确设置 GitHub API 请求头与 ETag 条件头', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '[]',
          200,
          headers: <String, String>{'etag': 'W/"tag-123"'},
        );
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      final result = await source.fetchReleases(etag: 'W/"prev-etag"');

      expect(capturedRequest.url.scheme, 'https');
      expect(capturedRequest.url.host, 'api.github.com');
      expect(
        capturedRequest.url.path,
        '/repos/$testOwner/$testRepo/releases',
      );
      expect(capturedRequest.url.queryParameters['per_page'], '30');
      expect(
        capturedRequest.headers['accept'],
        'application/vnd.github+json',
      );
      expect(
        capturedRequest.headers['x-github-api-version'],
        '2022-11-28',
      );
      expect(capturedRequest.headers['user-agent'], testUserAgent);
      expect(capturedRequest.headers['if-none-match'], 'W/"prev-etag"');
      expect(result.etag, 'W/"tag-123"');
      expect(result.notModified, isFalse);
    });

    test('200 响应正确解析 Releases 与 Assets 列表并透传 ETag', () async {
      final mockData = <Map<String, Object?>>[
        <String, Object?>{
          'tag_name': 'v0.2.0-beta.1',
          'name': '版本 0.2.0-beta.1',
          'body': '测试发布更新说明',
          'published_at': '2026-10-22T10:00:00Z',
          'html_url': 'https://github.com/test-owner/test-repo/releases/tag/v0.2.0-beta.1',
          'prerelease': true,
          'draft': false,
          'assets': <Map<String, Object?>>[
            <String, Object?>{
              'name': 'tometone-v0.2.0-beta.1-arm64-v8a.apk',
              'size': 1234567,
              'browser_download_url':
                  'https://github.com/test-owner/test-repo/releases/download/v0.2.0-beta.1/app.apk',
            },
          ],
        },
      ];

      final mockClient = MockClient((_) async {
        return http.Response.bytes(
          utf8.encode(jsonEncode(mockData)),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
            'etag': '"resp-etag-001"',
          },
        );
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      final result = await source.fetchReleases();

      expect(result.notModified, isFalse);
      expect(result.etag, '"resp-etag-001"');
      expect(result.releases.length, 1);

      final release = result.releases.first;
      expect(release.tag, 'v0.2.0-beta.1');
      expect(release.name, '版本 0.2.0-beta.1');
      expect(release.body, '测试发布更新说明');
      expect(release.publishedAt, DateTime.utc(2026, 10, 22, 10, 0, 0));
      expect(release.prerelease, isTrue);
      expect(release.draft, isFalse);
      expect(release.assets.length, 1);

      final asset = release.assets.first;
      expect(asset.name, 'tometone-v0.2.0-beta.1-arm64-v8a.apk');
      expect(asset.sizeBytes, 1234567);
      expect(
        asset.downloadUrl,
        'https://github.com/test-owner/test-repo/releases/download/v0.2.0-beta.1/app.apk',
      );
    });

    test('304 响应返回 notModified 为 true 并保留 ETag', () async {
      final mockClient = MockClient((_) async {
        return http.Response('', 304);
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      final result = await source.fetchReleases(etag: '"cached-etag"');

      expect(result.notModified, isTrue);
      expect(result.releases, isEmpty);
      expect(result.etag, '"cached-etag"');
    });

    test('403 且 x-ratelimit-remaining 为 0 时识别为 rateLimited', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          '{"message": "API rate limit exceeded"}',
          403,
          headers: <String, String>{'x-ratelimit-remaining': '0'},
        );
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      expect(
        source.fetchReleases,
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.rateLimited,
          ),
        ),
      );
    });

    test('429 且 x-ratelimit-remaining 为 0 时识别为 rateLimited', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          'Too Many Requests',
          429,
          headers: <String, String>{'x-ratelimit-remaining': '0'},
        );
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      expect(
        source.fetchReleases,
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.rateLimited,
          ),
        ),
      );
    });

    test('403 但限流余额不为 0 时判定为 badResponse', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          '{"message": "Forbidden"}',
          403,
          headers: <String, String>{'x-ratelimit-remaining': '42'},
        );
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      expect(
        source.fetchReleases,
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.badResponse,
          ),
        ),
      );
    });

    test('其他 HTTP 错误状态码（如 500、404）抛出 badResponse', () async {
      final mockClient = MockClient((_) async {
        return http.Response('Not Found', 404);
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      expect(
        source.fetchReleases,
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.badResponse,
          ),
        ),
      );
    });

    test('返回非法 JSON 时抛出 badResponse', () async {
      final mockClient = MockClient((_) async {
        return http.Response('<html><body>error</body></html>', 200);
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      expect(
        source.fetchReleases,
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.badResponse,
          ),
        ),
      );
    });

    test('SocketException 转化为 network 异常', () async {
      final mockClient = MockClient((_) async {
        throw const SocketException('Failed host lookup');
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      expect(
        source.fetchReleases,
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.network,
          ),
        ),
      );
    });

    test('TimeoutException 转化为 network 异常', () async {
      final mockClient = MockClient((_) async {
        throw TimeoutException('Request timed out');
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      expect(
        source.fetchReleases,
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.network,
          ),
        ),
      );
    });

    test('http.ClientException 转化为 network 异常', () async {
      final mockClient = MockClient((_) async {
        throw http.ClientException('Connection closed before full header received');
      });

      final source = GithubReleasesSource(
        client: mockClient,
        owner: testOwner,
        repo: testRepo,
        userAgent: testUserAgent,
      );

      expect(
        source.fetchReleases,
        throwsA(
          isA<UpdateException>().having(
            (e) => e.kind,
            'kind',
            UpdateFailureKind.network,
          ),
        ),
      );
    });
  });
}
