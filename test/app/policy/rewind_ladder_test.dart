import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/rewind_ladder.dart';

void main() {
  const ladder = RewindLadder();

  group('标准阶梯（文档 §2.2 表格）', () {
    test('边界逐档验证', () {
      expect(ladder.rewindFor(Duration.zero), Duration.zero);
      expect(
        ladder.rewindFor(const Duration(seconds: 29, milliseconds: 999)),
        Duration.zero,
      );
      expect(
        ladder.rewindFor(const Duration(seconds: 30)),
        const Duration(seconds: 3),
      );
      expect(
        ladder.rewindFor(const Duration(minutes: 4, seconds: 59)),
        const Duration(seconds: 3),
      );
      expect(
        ladder.rewindFor(const Duration(minutes: 5)),
        const Duration(seconds: 8),
      );
      expect(
        ladder.rewindFor(const Duration(minutes: 29, seconds: 59)),
        const Duration(seconds: 8),
      );
      expect(
        ladder.rewindFor(const Duration(minutes: 30)),
        const Duration(seconds: 15),
      );
      expect(
        ladder.rewindFor(const Duration(hours: 8)),
        const Duration(seconds: 15),
      );
    });

    test('负中断间隔按 0 处理', () {
      expect(ladder.rewindFor(const Duration(seconds: -5)), Duration.zero);
    });

    test('跨进程重启无视 ΔT，恒为 15 秒', () {
      expect(
        ladder.rewindFor(const Duration(seconds: 5), processRestarted: true),
        const Duration(seconds: 15),
      );
      expect(
        ladder.rewindFor(const Duration(hours: 3), processRestarted: true),
        const Duration(seconds: 15),
      );
    });
  });

  group('恢复目标位置', () {
    test('正常回退', () {
      expect(
        ladder.targetPosition(
          saved: const Duration(minutes: 10),
          interruption: const Duration(minutes: 10),
        ),
        const Duration(minutes: 10) - const Duration(seconds: 8),
      );
    });

    test('回退超过已播位置时钳制为 0（不产生负位置）', () {
      expect(
        ladder.targetPosition(
          saved: const Duration(seconds: 5),
          interruption: const Duration(minutes: 10),
        ),
        Duration.zero,
      );
    });

    test('短中断即点即播', () {
      const saved = Duration(minutes: 3);
      expect(
        ladder.targetPosition(
          saved: saved,
          interruption: const Duration(seconds: 10),
        ),
        saved,
      );
    });
  });

  group('自定义阶梯（每书偏好覆盖）', () {
    test('整体替换阶梯即可生效，无需改判定逻辑', () {
      const custom = RewindLadder(
        steps: <RewindStep>[
          RewindStep(lessThan: Duration(minutes: 1), rewind: Duration.zero),
          RewindStep(
            lessThan: Duration(hours: 1),
            rewind: Duration(seconds: 5),
          ),
        ],
        beyondLastStep: Duration(seconds: 20),
        restartRewind: Duration(seconds: 20),
      );

      expect(custom.rewindFor(const Duration(seconds: 30)), Duration.zero);
      expect(
        custom.rewindFor(const Duration(minutes: 30)),
        const Duration(seconds: 5),
      );
      expect(
        custom.rewindFor(const Duration(hours: 2)),
        const Duration(seconds: 20),
      );
      expect(
        custom.rewindFor(Duration.zero, processRestarted: true),
        const Duration(seconds: 20),
      );
    });
  });
}
