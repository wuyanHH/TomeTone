import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/common/ulid_id_generator.dart';

final DateTime _t0 = DateTime.utc(2026, 10, 18, 3);

void main() {
  group('编码格式', () {
    test('长度 26 且只使用 Crockford Base32 字母表', () {
      final generator = UlidIdGenerator(random: Random(7), clock: () => _t0);
      for (var i = 0; i < 200; i++) {
        final id = generator.next();
        expect(id, hasLength(UlidIdGenerator.length));
        for (final char in id.split('')) {
          expect(
            UlidIdGenerator.alphabet.contains(char),
            isTrue,
            reason: '非法字符 $char in $id',
          );
        }
      }
    });

    test('字母表不含易混淆字符 I / L / O / U', () {
      for (final char in <String>['I', 'L', 'O', 'U']) {
        expect(UlidIdGenerator.alphabet.contains(char), isFalse);
      }
    });
  });

  group('时间戳', () {
    test('编码后可解码回原始时间（毫秒精度）', () {
      final id = UlidIdGenerator.encode(timestamp: _t0, random: Random(1));
      expect(UlidIdGenerator.decodeTimestamp(id), _t0);
    });

    test('字典序即时间序', () {
      final earlier = UlidIdGenerator.encode(timestamp: _t0, random: Random(1));
      final later = UlidIdGenerator.encode(
        timestamp: _t0.add(const Duration(milliseconds: 1)),
        random: Random(1),
      );
      expect(earlier.compareTo(later), lessThan(0));
    });

    test('非法长度 / 非法字符被拒绝', () {
      expect(
        () => UlidIdGenerator.decodeTimestamp('short'),
        throwsArgumentError,
      );
      expect(
        () => UlidIdGenerator.decodeTimestamp('I' * 26),
        throwsArgumentError,
      );
    });
  });

  group('唯一性', () {
    test('同毫秒内批量生成不重复', () {
      final generator = UlidIdGenerator(random: Random(42), clock: () => _t0);
      final ids = <String>{for (var i = 0; i < 5000; i++) generator.next()};
      expect(ids, hasLength(5000));
    });

    test('相同随机种子在相同时间下产出相同序列（可测试性）', () {
      final a = UlidIdGenerator(random: Random(9), clock: () => _t0);
      final b = UlidIdGenerator(random: Random(9), clock: () => _t0);
      for (var i = 0; i < 10; i++) {
        expect(a.next(), b.next());
      }
    });
  });
}
