import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/sources/source_rate_limiter.dart';

void main() {
  group('SourceRateLimiter', () {
    test('同源按 minInterval 等待', () async {
      var now = DateTime.utc(2026);
      final waits = <Duration>[];
      final limiter = SourceRateLimiter(
        clock: () => now,
        delay: (duration) async {
          waits.add(duration);
          now = now.add(duration);
        },
      );
      const limit = SourceRateLimit(minInterval: Duration(milliseconds: 300));

      await limiter.acquire('source-a', limit);
      await limiter.acquire('source-a', limit);

      expect(waits, <Duration>[const Duration(milliseconds: 300)]);
    });

    test('不同源互不阻塞', () async {
      var now = DateTime.utc(2026);
      final waits = <Duration>[];
      final limiter = SourceRateLimiter(
        clock: () => now,
        delay: (duration) async {
          waits.add(duration);
          now = now.add(duration);
        },
      );
      const limit = SourceRateLimit(minInterval: Duration(milliseconds: 300));

      await Future.wait(<Future<void>>[
        limiter.acquire('source-a', limit),
        limiter.acquire('source-b', limit),
      ]);

      expect(waits, isEmpty);
    });

    test('窗口限速在第 N+1 次等待窗口过去', () async {
      var now = DateTime.utc(2026);
      final waits = <Duration>[];
      final limiter = SourceRateLimiter(
        clock: () => now,
        delay: (duration) async {
          waits.add(duration);
          now = now.add(duration);
        },
      );
      final limit = SourceRateLimit.parse('3/1000');

      for (var i = 0; i < 3; i++) {
        await limiter.acquire('source-a', limit);
      }
      expect(waits, isEmpty);

      await limiter.acquire('source-a', limit);
      expect(waits, <Duration>[const Duration(seconds: 1)]);
    });

    test('同一源的并发调用按队列顺序逐个放行', () async {
      var now = DateTime.utc(2026);
      final waits = <Duration>[];
      final limiter = SourceRateLimiter(
        clock: () => now,
        delay: (duration) async {
          waits.add(duration);
          now = now.add(duration);
        },
      );
      const limit = SourceRateLimit(minInterval: Duration(milliseconds: 10));

      await Future.wait(<Future<void>>[
        limiter.acquire('source-a', limit),
        limiter.acquire('source-a', limit),
        limiter.acquire('source-a', limit),
      ]);

      expect(waits, <Duration>[
        const Duration(milliseconds: 10),
        const Duration(milliseconds: 10),
      ]);
    });
  });
}
