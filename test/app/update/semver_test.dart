import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/update/semver.dart';

void main() {
  group('SemVer.tryParse', () {
    test('解析基础三段式版本号', () {
      final v = SemVer.tryParse('1.2.3');
      expect(v, isNotNull);
      expect(v!.major, 1);
      expect(v.minor, 2);
      expect(v.patch, 3);
      expect(v.prerelease, isEmpty);
      expect(v.isPrerelease, isFalse);
    });

    test('解析包含 0 的版本号', () {
      final v = SemVer.tryParse('0.0.0');
      expect(v, isNotNull);
      expect(v!.major, 0);
      expect(v.minor, 0);
      expect(v.patch, 0);
      expect(v.prerelease, isEmpty);
    });

    test('解析多段预发布标识', () {
      final v = SemVer.tryParse('0.2.0-beta.1');
      expect(v, isNotNull);
      expect(v!.major, 0);
      expect(v.minor, 2);
      expect(v.patch, 0);
      expect(v.prerelease, <String>['beta', '1']);
      expect(v.isPrerelease, isTrue);

      final complex = SemVer.tryParse('1.0.0-x.7.z-92.0');
      expect(complex, isNotNull);
      expect(complex!.prerelease, <String>['x', '7', 'z-92', '0']);
    });

    test('解析附带 build 元数据的版本并忽略 build', () {
      final v1 = SemVer.tryParse('1.0.0+20130313144700');
      expect(v1, isNotNull);
      expect(v1!.major, 1);
      expect(v1.prerelease, isEmpty);

      final v2 = SemVer.tryParse('1.0.0-beta.1+sha.exp.123');
      expect(v2, isNotNull);
      expect(v2!.prerelease, <String>['beta', '1']);
    });

    test('自动剔除首尾空白', () {
      final v = SemVer.tryParse('   1.2.3   ');
      expect(v, isNotNull);
      expect(v!.major, 1);
    });

    test('非法格式返回 null', () {
      // 空或空白串
      expect(SemVer.tryParse(''), isNull);
      expect(SemVer.tryParse('   '), isNull);

      // 段数不合法
      expect(SemVer.tryParse('1'), isNull);
      expect(SemVer.tryParse('1.2'), isNull);
      expect(SemVer.tryParse('1.2.3.4'), isNull);
      expect(SemVer.tryParse('1.2.'), isNull);

      // 主版本/次版本/修订号含前导零或负数
      expect(SemVer.tryParse('01.2.3'), isNull);
      expect(SemVer.tryParse('1.02.3'), isNull);
      expect(SemVer.tryParse('1.2.03'), isNull);
      expect(SemVer.tryParse('-1.2.3'), isNull);

      // 核心段含非法字符
      expect(SemVer.tryParse('a.b.c'), isNull);
      expect(SemVer.tryParse('1.2.3a'), isNull);

      // 预发布标识格式不合法
      expect(SemVer.tryParse('1.2.3-'), isNull);
      expect(SemVer.tryParse('1.2.3-alpha..1'), isNull);
      expect(SemVer.tryParse('1.2.3-.alpha'), isNull);
      expect(SemVer.tryParse('1.2.3-alpha.'), isNull);
      expect(SemVer.tryParse('1.2.3-alpha@beta'), isNull);

      // 预发布纯数字段含前导零（单为 0 允许）
      expect(SemVer.tryParse('1.2.3-01'), isNull);
      expect(SemVer.tryParse('1.2.3-beta.002'), isNull);
      expect(SemVer.tryParse('1.2.3-0'), isNotNull);
      expect(SemVer.tryParse('1.2.3-beta.0'), isNotNull);

      // build 标识格式不合法
      expect(SemVer.tryParse('1.2.3+'), isNull);
      expect(SemVer.tryParse('1.2.3+build..1'), isNull);
      expect(SemVer.tryParse('1.2.3+build@1'), isNull);
    });
  });

  group('SemVer.compareTo 与比较运算符', () {
    test('核心版本号数值比较', () {
      final v1 = SemVer.tryParse('1.0.0')!;
      final v2 = SemVer.tryParse('2.0.0')!;
      final v3 = SemVer.tryParse('1.1.0')!;
      final v4 = SemVer.tryParse('1.0.1')!;

      expect(v1.compareTo(v2) < 0, isTrue);
      expect(v2.compareTo(v1) > 0, isTrue);
      expect(v1.compareTo(v3) < 0, isTrue);
      expect(v1.compareTo(v4) < 0, isTrue);
      expect(v1.compareTo(v1) == 0, isTrue);
    });

    test('正式版高于相同核心版本的预发布版', () {
      final release = SemVer.tryParse('1.0.0')!;
      final prerelease1 = SemVer.tryParse('1.0.0-alpha')!;
      final prerelease2 = SemVer.tryParse('1.0.0-rc.1')!;

      expect(release.compareTo(prerelease1) > 0, isTrue);
      expect(prerelease1.compareTo(release) < 0, isTrue);
      expect(release.compareTo(prerelease2) > 0, isTrue);
    });

    test('预发布版本纯数字段按数值比较（beta.2 < beta.10）', () {
      final beta2 = SemVer.tryParse('1.0.0-beta.2')!;
      final beta10 = SemVer.tryParse('1.0.0-beta.10')!;

      expect(beta2.compareTo(beta10) < 0, isTrue);
      expect(beta10.compareTo(beta2) > 0, isTrue);
    });

    test('纯数字段优先级低于非纯数字字符串段', () {
      final numSegment = SemVer.tryParse('1.0.0-alpha.1')!;
      final strSegment = SemVer.tryParse('1.0.0-alpha.beta')!;

      expect(numSegment.compareTo(strSegment) < 0, isTrue);
      expect(strSegment.compareTo(numSegment) > 0, isTrue);
    });

    test('非纯数字段按 ASCII 字典序比较', () {
      final alpha = SemVer.tryParse('1.0.0-alpha')!;
      final beta = SemVer.tryParse('1.0.0-beta')!;

      expect(alpha.compareTo(beta) < 0, isTrue);
      expect(beta.compareTo(alpha) > 0, isTrue);
    });

    test('前缀完全相同时段数多的版本更高', () {
      final shortPre = SemVer.tryParse('1.0.0-beta')!;
      final longPre = SemVer.tryParse('1.0.0-beta.1')!;

      expect(shortPre.compareTo(longPre) < 0, isTrue);
      expect(longPre.compareTo(shortPre) > 0, isTrue);
    });

    test('SemVer 2.0.0 官方递增测试序列验证', () {
      final versions = <String>[
        '1.0.0-alpha',
        '1.0.0-alpha.1',
        '1.0.0-alpha.beta',
        '1.0.0-beta',
        '1.0.0-beta.2',
        '1.0.0-beta.11',
        '1.0.0-rc.1',
        '1.0.0',
        '2.0.0',
        '2.1.0',
        '2.1.1',
      ].map((s) => SemVer.tryParse(s)!).toList();

      for (var i = 0; i < versions.length - 1; i++) {
        expect(
          versions[i].compareTo(versions[i + 1]) < 0,
          isTrue,
          reason: '${versions[i]} 应小于 ${versions[i + 1]}',
        );
      }
    });

    test('build 元数据不影响 compareTo 与相等判断', () {
      final v1 = SemVer.tryParse('1.0.0+build1')!;
      final v2 = SemVer.tryParse('1.0.0+build2')!;

      expect(v1.compareTo(v2) == 0, isTrue);
      expect(v1 == v2, isTrue);
      expect(v1.hashCode == v2.hashCode, isTrue);
    });

    test('toString 正确还原版本号', () {
      expect(SemVer.tryParse('1.2.3')!.toString(), '1.2.3');
      expect(
        SemVer.tryParse('0.2.0-beta.1')!.toString(),
        '0.2.0-beta.1',
      );
    });
  });

  group('versionFromTag', () {
    test('去除前导 v / V', () {
      expect(
        versionFromTag('v1.2.3'),
        SemVer.tryParse('1.2.3'),
      );
      expect(
        versionFromTag('V0.2.0-beta.1'),
        SemVer.tryParse('0.2.0-beta.1'),
      );
    });

    test('无前导 v 直接解析', () {
      expect(
        versionFromTag('1.2.3'),
        SemVer.tryParse('1.2.3'),
      );
    });

    test('非法 tag 返回 null', () {
      expect(versionFromTag(''), isNull);
      expect(versionFromTag('v'), isNull);
      expect(versionFromTag('release-1.0'), isNull);
      expect(versionFromTag('vv1.0.0'), isNull);
    });
  });
}
