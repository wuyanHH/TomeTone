import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/update/changelog_parser.dart';

void main() {
  group('parseChangelog', () {
    test('按版本倒序切段并保留正文，“未发布”排最后', () {
      const text = '''
# 更新日志

## [未发布]

- 正在做

## [0.2.0-beta.1] - 2026-10-19

### 新增
- A

## [0.1.0] - 2026-10-01

- B
''';
      final entries = parseChangelog(text);
      expect(
        entries.map((e) => e.version),
        <String>['0.2.0-beta.1', '0.1.0', '未发布'],
      );
      expect(entries.first.body, contains('### 新增'));
      expect(entries.first.body, contains('- A'));
      expect(entries.first.body, isNot(contains('0.1.0')));
      expect(entries.first.title, '[0.2.0-beta.1] - 2026-10-19');
      expect(entries.first.releaseDate, '2026-10-19');

      expect(entries[1].version, '0.1.0');
      expect(entries[1].body, '- B');
      expect(entries[1].releaseDate, '2026-10-01');

      expect(entries[2].version, '未发布');
      expect(entries[2].body, '- 正在做');
      expect(entries[2].releaseDate, isNull);
    });

    test('SemVer 倒序排序正确（含 pre-release 规则）', () {
      const text = '''
## [1.0.0] - 2026-10-01
稳定版

## [1.0.0-beta.2] - 2026-09-20
Beta 2

## [1.0.0-beta.10] - 2026-09-25
Beta 10

## [1.0.0-alpha] - 2026-09-01
Alpha

## [0.9.0] - 2026-08-01
旧版
''';
      final entries = parseChangelog(text);
      expect(
        entries.map((e) => e.version),
        <String>[
          '1.0.0',
          '1.0.0-beta.10',
          '1.0.0-beta.2',
          '1.0.0-alpha',
          '0.9.0',
        ],
      );
    });

    test('无法解析为 SemVer 的版本排在 SemVer 之后且保留原顺序，未发布排最最后', () {
      const text = '''
## [未发布]
未发布内容

## [0.2.0] - 2026-10-10
正式发布

## [草稿版本] - 2026-10-05
草稿说明

## [特殊前瞻] - 2026-09-30
前瞻说明

## [0.1.0] - 2026-09-01
首发
''';
      final entries = parseChangelog(text);
      expect(
        entries.map((e) => e.version),
        <String>['0.2.0', '0.1.0', '草稿版本', '特殊前瞻', '未发布'],
      );
    });

    test('空输入或无版本头部输入返回空列表', () {
      expect(parseChangelog(''), isEmpty);
      expect(parseChangelog('   \n\n  '), isEmpty);
      expect(
        parseChangelog('# 只有一级标题\n\n正文描述，无二级版本头部'),
        isEmpty,
      );
    });

    test('非版本格式的二级标题会正确终止前一个版本的正文', () {
      const text = '''
## [0.1.0] - 2026-10-01
版本更新正文

## 常见问题与说明
这部分不属于任何版本正文

## [0.2.0] - 2026-10-02
新版本正文
''';
      final entries = parseChangelog(text);
      expect(entries.map((e) => e.version), <String>['0.2.0', '0.1.0']);
      expect(entries.last.body, '版本更新正文');
      expect(entries.last.body, isNot(contains('常见问题与说明')));
    });

    test('ChangelogEntry 的 == 与 hashCode 覆写', () {
      const a = ChangelogEntry(version: '1.0.0', title: '[1.0.0]', body: 'body');
      const b = ChangelogEntry(version: '1.0.0', title: '[1.0.0]', body: 'body');
      const c = ChangelogEntry(version: '1.0.0', title: '[1.0.0]', body: 'diff');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
