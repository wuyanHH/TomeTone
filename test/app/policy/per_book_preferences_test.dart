import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/policy/per_book_preferences.dart';
import 'package:tometone/app/policy/rewind_ladder.dart';

void main() {
  test('默认值符合文档', () {
    const prefs = PerBookPreferences.defaults;
    expect(prefs.speed, 1.0);
    expect(prefs.skipIntro, Duration.zero);
    expect(prefs.skipOutro, Duration.zero);
    expect(prefs.rewindLadder, isNull);
    expect(prefs.ladder.steps, RewindLadder.standardSteps);
  });

  group('片头 / 片尾跳过', () {
    test('时长未知时只给出起点', () {
      const prefs = PerBookPreferences(skipIntro: Duration(seconds: 5));
      expect(prefs.playbackRange(null), (
        start: const Duration(seconds: 5),
        end: null,
      ));
    });

    test('同时跳过片头与片尾', () {
      const prefs = PerBookPreferences(
        skipIntro: Duration(seconds: 5),
        skipOutro: Duration(seconds: 10),
      );
      expect(prefs.playbackRange(const Duration(minutes: 2)), (
        start: const Duration(seconds: 5),
        end: const Duration(seconds: 110),
      ));
    });

    test('跳过值超过时长时收敛，不产生负长度', () {
      const prefs = PerBookPreferences(
        skipIntro: Duration(seconds: 5),
        skipOutro: Duration(seconds: 100),
      );
      expect(prefs.playbackRange(const Duration(seconds: 30)), (
        start: const Duration(seconds: 5),
        end: const Duration(seconds: 5),
      ));
    });

    test('片头跳过超过整章时长时停在末尾', () {
      const prefs = PerBookPreferences(skipIntro: Duration(minutes: 5));
      expect(prefs.playbackRange(const Duration(seconds: 30)), (
        start: const Duration(seconds: 30),
        end: const Duration(seconds: 30),
      ));
    });

    test('负值按 0 处理', () {
      const prefs = PerBookPreferences(skipIntro: Duration(seconds: -10));
      expect(prefs.playbackRange(const Duration(seconds: 60)), (
        start: Duration.zero,
        end: const Duration(seconds: 60),
      ));
    });
  });

  group('copyWith', () {
    test('逐字段覆盖并保持其余不变', () {
      const base = PerBookPreferences(speed: 1.5);
      final updated = base.copyWith(skipOutro: const Duration(seconds: 3));

      expect(updated.speed, 1.5);
      expect(updated.skipOutro, const Duration(seconds: 3));
      expect(updated.skipIntro, Duration.zero);
    });

    test('clearRewindLadder 可清除覆盖', () {
      const custom = RewindLadder(
        steps: <RewindStep>[
          RewindStep(lessThan: Duration(minutes: 1), rewind: Duration.zero),
        ],
      );
      const base = PerBookPreferences(rewindLadder: custom);

      expect(base.copyWith().rewindLadder, same(custom));
      expect(base.copyWith(clearRewindLadder: true).rewindLadder, isNull);
    });
  });
}
