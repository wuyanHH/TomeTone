import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/diagnostics/log_tag.dart';
import 'package:tometone/contracts/diagnostics/redactor.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';

void main() {
  group('Redactor.url', () {
    test('丢弃 userinfo / query / fragment，保留 host:port 与 path', () {
      expect(
        Redactor.url(
          'https://user:pw@nas.local:5006/dav/books/a.mp3?token=abc',
        ),
        'https://nas.local:5006/dav/books/a.mp3?<redacted>',
      );
    });

    test('无认证信息的 URL 原样保留主干', () {
      expect(
        Redactor.url('http://192.168.1.10/books/%E4%B8%89%E4%BD%93/001.mp3'),
        'http://192.168.1.10/books/%E4%B8%89%E4%BD%93/001.mp3',
      );
    });

    test('非 URL 字符串按不透明凭据整体处理', () {
      final redacted = Redactor.url('sk-live-abcdef1234567890');
      expect(redacted, isNot(contains('abcdef1234567890')));
      expect(redacted, contains('…'));
    });

    test('Windows 盘符路径不被误判为 URL，且不泄漏目录名', () {
      final redacted = Redactor.url(r'C:\Users\alice\secret.txt');
      expect(redacted, isNot(contains('alice')));
      expect(redacted, isNot(contains('secret.txt')));
    });

    test('空串安全', () {
      expect(Redactor.url(''), '');
    });
  });

  group('Redactor.headers', () {
    test('敏感头被替换，其余保留', () {
      final headers = Redactor.headers(const <String, String>{
        'Authorization': 'Basic dXNlcjpwYXNzd29yZA==',
        'Cookie': 'session=0123456789',
        'X-Auth-Token': 'abcdef123456',
        'User-Agent': 'TomeTone/0.1.0',
      });

      expect(headers['User-Agent'], 'TomeTone/0.1.0');
      for (final key in const <String>[
        'Authorization',
        'Cookie',
        'X-Auth-Token',
      ]) {
        expect(headers[key], isNot(contains('0123456789')));
        expect(headers[key], isNot(contains('dXNlcjpwYXNzd29yZA==')));
        expect(headers[key], isNot(contains('abcdef123456')));
      }
    });

    test('大小写不敏感', () {
      final headers = Redactor.headers(const <String, String>{
        'AUTHORIZATION': 'Bearer supersecrettoken',
      });
      expect(headers['AUTHORIZATION'], isNot(contains('supersecrettoken')));
    });
  });

  group('Redactor.path', () {
    test('仅保留最后一段', () {
      expect(
        Redactor.path('/storage/emulated/0/Books/三体/001.mp3'),
        '…/001.mp3',
      );
      expect(Redactor.path(r'C:\Users\alice\book.mp3'), '…/book.mp3');
    });

    test('空串与纯分隔符安全', () {
      expect(Redactor.path(''), '');
      expect(Redactor.path('/'), '/');
    });
  });

  group('Redactor.token', () {
    test('短值整体替换，长值只留首尾', () {
      expect(Redactor.token('abc'), '<redacted>');
      expect(Redactor.token('abcdef'), '<redacted>');
      expect(Redactor.token('abcdefg'), 'ab…fg');
      expect(Redactor.token(''), '');
    });
  });

  group('引用类型的 toString 不泄漏凭据', () {
    test('RemoteUrlSource 不输出请求头内容', () {
      const source = RemoteUrlSource(
        uri: 'https://nas.local/dav/a.mp3',
        headers: <String, String>{
          'Authorization': 'Basic dXNlcjpwYXNzd29yZA==',
        },
      );
      expect(source.toString(), isNot(contains('dXNlcjpwYXNzd29yZA==')));
      expect(source.toString(), isNot(contains('Basic')));
      expect(source.toString(), contains('nas.local'));
    });

    test('LocalFileSource 只输出文件名', () {
      const source = LocalFileSource(
        uri: 'file:///storage/emulated/0/Books/三体/001.mp3',
      );
      expect(source.toString(), isNot(contains('emulated')));
      expect(source.toString(), contains('001.mp3'));
    });
  });

  group('LogTag', () {
    test('标签稳定且唯一', () {
      final labels = LogTag.values.map((LogTag tag) => tag.label).toList();
      expect(labels.toSet(), hasLength(labels.length));
      expect(labels, contains('engine'));
      expect(labels, contains('storage'));
    });
  });
}
