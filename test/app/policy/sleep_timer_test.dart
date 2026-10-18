import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/sleep_timer.dart';

void main() {
  late DateTime now;
  late SleepTimer timer;

  setUp(() {
    now = DateTime.utc(2026, 10, 18, 3);
    timer = SleepTimer(clock: () => now);
  });

  group('相对倒计时', () {
    test('启动后剩余时间与渐弱系数正确', () {
      timer.startCountdown(const Duration(minutes: 30));

      expect(timer.mode, SleepMode.countdown);
      expect(timer.isActive, isTrue);
      expect(timer.remaining, const Duration(minutes: 30));
      expect(timer.fadeFactor, 1);
    });

    test('最后 10 秒线性渐弱', () {
      timer.startCountdown(const Duration(minutes: 1));

      now = now.add(const Duration(seconds: 51));
      expect(timer.fadeFactor, closeTo(0.9, 1e-9));

      now = now.add(const Duration(seconds: 5));
      expect(timer.fadeFactor, closeTo(0.4, 1e-9));

      now = now.add(const Duration(seconds: 4));
      expect(timer.fadeFactor, closeTo(0.0, 1e-9));
    });

    test('渐弱区间之外恒为 1', () {
      timer.startCountdown(const Duration(minutes: 30));
      now = now.add(const Duration(minutes: 20));
      expect(timer.fadeFactor, 1);
    });

    test('到点触发一次 tick，并自动关闭', () {
      timer.startCountdown(const Duration(minutes: 15));

      now = now.add(const Duration(minutes: 14));
      expect(timer.tick(), isFalse);

      now = now.add(const Duration(minutes: 1));
      expect(timer.tick(), isTrue);
      expect(timer.mode, SleepMode.off, reason: '到点后自动关闭，避免重复触发');
      expect(timer.tick(), isFalse);
    });

    test('非正时长视为关闭', () {
      timer.startCountdown(const Duration(minutes: 10));
      timer.startCountdown(Duration.zero);
      expect(timer.mode, SleepMode.off);
      expect(timer.remaining, isNull);
    });

    test('剩余时间不为负', () {
      timer.startCountdown(const Duration(seconds: 5));
      now = now.add(const Duration(minutes: 1));
      expect(timer.remaining, Duration.zero);
    });
  });

  group('播完当前章即停', () {
    test('章节完毕触发一次，并自动关闭', () {
      timer.stopAtChapterEnd();

      expect(timer.mode, SleepMode.endOfChapter);
      expect(timer.fadeFactor, 1, reason: '该模式不渐弱');
      expect(timer.onChapterCompleted(), isTrue);
      expect(timer.mode, SleepMode.off);
      expect(timer.onChapterCompleted(), isFalse);
    });

    test('倒计时模式下章节完毕不停止', () {
      timer.startCountdown(const Duration(minutes: 30));
      expect(timer.onChapterCompleted(), isFalse);
    });

    test('tick 对章节模式无副作用', () {
      timer.stopAtChapterEnd();
      now = now.add(const Duration(hours: 1));
      expect(timer.tick(), isFalse);
    });
  });

  test('cancel 关闭任意模式', () {
    timer.startCountdown(const Duration(minutes: 10));
    timer.cancel();
    expect(timer.mode, SleepMode.off);
    expect(timer.isActive, isFalse);
    expect(timer.tick(), isFalse);
  });

  group('回到 N 分钟前（第 3 模式）', () {
    test('默认回退 10 分钟', () {
      expect(
        SleepRewind.targetPosition(saved: const Duration(minutes: 25)),
        const Duration(minutes: 15),
      );
    });

    test('回退超过已播位置时钳制为 0', () {
      expect(
        SleepRewind.targetPosition(saved: const Duration(minutes: 4)),
        Duration.zero,
      );
    });

    test('可配置回退分钟数', () {
      expect(
        SleepRewind.targetPosition(
          saved: const Duration(minutes: 30),
          rewind: const Duration(minutes: 20),
        ),
        const Duration(minutes: 10),
      );
    });

    test('负回退按 0 处理', () {
      expect(
        SleepRewind.targetPosition(
          saved: const Duration(minutes: 3),
          rewind: const Duration(minutes: -5),
        ),
        const Duration(minutes: 3),
      );
    });
  });
}
