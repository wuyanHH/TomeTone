import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/playback_engine.dart';

/// 断言"抛出了指定错误码的 `EngineError`"。
Matcher throwsEngineError(EngineErrorCode code) =>
    throwsA(isA<EngineError>().having((error) => error.code, 'code', code));

/// 播放引擎统一契约测试套件（《架构需求文档》§5.3、§12）。
///
/// 任何 [PlaybackEngine] 实现（真实引擎 / Fake）都必须跑通本套件。
/// 实现方在自己的测试里调用：
///
/// ```dart
/// runPlaybackEngineConformance(
///   createEngine: FakePlaybackEngine.new,
///   validSource: () => LocalFileSource(uri: 'file:///tmp/ok.mp3'),
///   unsupportedSource: () => LocalFileSource(uri: 'file:///tmp/ok.xyz'),
/// );
/// ```
///
/// 套件只依赖契约本身可观测的行为（返回值 / 抛出的错误码 / 事件流），
/// 不假设任何实现细节，因此对真实引擎同样适用。
void runPlaybackEngineConformance({
  required PlaybackEngine Function() createEngine,
  required AudioSourceRef Function() validSource,
  required AudioSourceRef Function() unsupportedSource,
}) {
  group('PlaybackEngine 契约', () {
    late PlaybackEngine engine;

    setUp(() {
      engine = createEngine();
    });

    tearDown(() async {
      await engine.dispose();
    });

    test('能力声明自洽', () {
      final capabilities = engine.capabilities;
      expect(capabilities.isSelfConsistent, isTrue, reason: '$capabilities');
      expect(capabilities.minSpeed, lessThanOrEqualTo(capabilities.maxSpeed));
    });

    test('未 load 时 play / pause / seek 抛 illegalState', () async {
      await expectLater(
        engine.play(),
        throwsEngineError(EngineErrorCode.illegalState),
      );
      await expectLater(
        engine.pause(),
        throwsEngineError(EngineErrorCode.illegalState),
      );
      await expectLater(
        engine.seek(Duration.zero),
        throwsEngineError(EngineErrorCode.illegalState),
      );
    });

    test('load 成功后 play / pause / seek 均不抛错，越界 seek 钳制', () async {
      await engine.load(validSource());
      await engine.play();
      await engine.pause();
      await engine.seek(const Duration(seconds: 1));
      await engine.seek(const Duration(hours: 99));
      await engine.seek(const Duration(seconds: -5));
    });

    test('不支持的格式在 load 阶段被拦截，且状态未进入可播放', () async {
      await expectLater(
        engine.load(unsupportedSource()),
        throwsEngineError(EngineErrorCode.unsupportedFormat),
      );
      // 状态未离开 idle —— 通过契约可观测的方式验证：play 仍然非法。
      await expectLater(
        engine.play(),
        throwsEngineError(EngineErrorCode.illegalState),
      );
    });

    test('倍速边界值可用，越界与非有限值抛 unsupportedOperation', () async {
      final capabilities = engine.capabilities;
      await engine.load(validSource());

      await expectLater(engine.setSpeed(capabilities.minSpeed), completes);
      await expectLater(engine.setSpeed(capabilities.maxSpeed), completes);
      await expectLater(
        engine.setSpeed(capabilities.maxSpeed + 1),
        throwsEngineError(EngineErrorCode.unsupportedOperation),
      );
      await expectLater(
        engine.setSpeed(capabilities.minSpeed / 2),
        throwsEngineError(EngineErrorCode.unsupportedOperation),
      );
      await expectLater(
        engine.setSpeed(double.nan),
        throwsEngineError(EngineErrorCode.unsupportedOperation),
      );
      await expectLater(
        engine.setSpeed(double.infinity),
        throwsEngineError(EngineErrorCode.unsupportedOperation),
      );
    });

    test('load 至少播报一次时长事件', () async {
      final events = <EngineEvent>[];
      final subscription = engine.events.listen(events.add);

      await engine.load(validSource());
      await pumpEventQueue();
      await subscription.cancel();

      expect(events.whereType<EngineDurationChanged>(), isNotEmpty);
    });

    test('events 为广播语义，多个订阅者都能收到事件', () async {
      final first = <EngineEvent>[];
      final second = <EngineEvent>[];
      final subA = engine.events.listen(first.add);
      final subB = engine.events.listen(second.add);

      await engine.load(validSource());
      await engine.play();
      await pumpEventQueue();

      await subA.cancel();
      await subB.cancel();

      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
    });

    test('dispose 幂等，释放后任何调用抛 illegalState', () async {
      await engine.load(validSource());
      await engine.dispose();
      await engine.dispose();

      await expectLater(
        engine.load(validSource()),
        throwsEngineError(EngineErrorCode.illegalState),
      );
      await expectLater(
        engine.play(),
        throwsEngineError(EngineErrorCode.illegalState),
      );
      await expectLater(
        engine.pause(),
        throwsEngineError(EngineErrorCode.illegalState),
      );
      await expectLater(
        engine.seek(Duration.zero),
        throwsEngineError(EngineErrorCode.illegalState),
      );
      await expectLater(
        engine.setSpeed(1),
        throwsEngineError(EngineErrorCode.illegalState),
      );
    });

    test('dispose 后事件流关闭', () async {
      await engine.dispose();
      await expectLater(engine.events.toList(), completion(isEmpty));
    });
  });
}
