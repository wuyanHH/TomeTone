import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/progress_scheduler.dart';

void main() {
  late DateTime now;
  late List<Duration> writes;
  late ProgressScheduler scheduler;

  setUp(() {
    now = DateTime.utc(2026, 10, 18, 3);
    writes = <Duration>[];
    scheduler = ProgressScheduler(onWrite: writes.add, clock: () => now);
  });

  test('首次位置更新立即写入', () {
    expect(scheduler.updatePosition(const Duration(seconds: 1)), isTrue);
    expect(writes, <Duration>[const Duration(seconds: 1)]);
  });

  test('10 秒内不再写，满 10 秒写一次（崩溃最多丢 10 秒）', () {
    expect(scheduler.updatePosition(const Duration(seconds: 1)), isTrue);

    now = now.add(const Duration(seconds: 5));
    expect(
      scheduler.updatePosition(const Duration(seconds: 6)),
      isFalse,
      reason: '第 5 秒不写',
    );

    now = now.add(const Duration(seconds: 5));
    expect(
      scheduler.updatePosition(const Duration(seconds: 11)),
      isTrue,
      reason: '第 10 秒写',
    );
    expect(writes.last, const Duration(seconds: 11));
  });

  test('关键事件立即写并重置窗口', () {
    scheduler.updatePosition(const Duration(seconds: 1));

    now = now.add(const Duration(seconds: 2));
    scheduler.flush(const Duration(seconds: 3));
    expect(writes.last, const Duration(seconds: 3), reason: '关键事件不节流');

    now = now.add(const Duration(seconds: 1));
    expect(
      scheduler.updatePosition(const Duration(seconds: 4)),
      isFalse,
      reason: 'flush 之后窗口重新计时',
    );

    now = now.add(const Duration(seconds: 9));
    expect(scheduler.updatePosition(const Duration(seconds: 13)), isTrue);
  });

  test('记录最近写入位置与时间', () {
    now = now.add(const Duration(seconds: 1));
    scheduler.updatePosition(const Duration(seconds: 7));

    expect(scheduler.lastWritten, const Duration(seconds: 7));
    expect(scheduler.lastWriteAt, now);
  });

  test('reset 后下一次更新立即写（切书场景）', () {
    scheduler.updatePosition(const Duration(seconds: 1));
    scheduler.reset();

    now = now.add(const Duration(seconds: 1));
    expect(scheduler.updatePosition(const Duration(seconds: 2)), isTrue);
  });

  test('自定义间隔可覆盖默认 10 秒', () {
    final custom = ProgressScheduler(
      onWrite: writes.add,
      clock: () => now,
      interval: const Duration(seconds: 3),
    );

    expect(custom.updatePosition(const Duration(seconds: 1)), isTrue);
    now = now.add(const Duration(seconds: 3));
    expect(custom.updatePosition(const Duration(seconds: 4)), isTrue);
  });
}
