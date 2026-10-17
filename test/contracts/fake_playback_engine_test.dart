import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/playback/audio_source_ref.dart';
import 'package:tometone/contracts/playback/engine_error.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/contracts/playback/fake_playback_engine.dart';

import 'playback_engine_conformance.dart';

const String _chapterUri = 'file:///library/vol-1/chapter-001.mp3';

void main() {
  // 先跑统一契约套件：Fake 是"真实引擎出现之前的第二个实现"。
  runPlaybackEngineConformance(
    createEngine: FakePlaybackEngine.new,
    validSource: () => const LocalFileSource(uri: _chapterUri),
    unsupportedSource: () => const LocalFileSource(uri: 'file:///notes.txt'),
  );

  group('FakePlaybackEngine 专属行为', () {
    test('默认能力覆盖《架构需求文档》§2.1 的全部媒体格式', () {
      final formats = FakePlaybackEngine.defaultCapabilities.supportedFormats;
      expect(
        formats,
        containsAll(<String>[
          'mp3',
          'm4a',
          'm4b',
          'aac',
          'flac',
          'wav',
          'ogg',
          'opus',
        ]),
      );
    });

    test('advance 仅在真实播放态推进位置', () async {
      final engine = FakePlaybackEngine(
        durations: const <String, Duration>{_chapterUri: Duration(minutes: 2)},
      );
      addTearDown(engine.dispose);

      await engine.load(const LocalFileSource(uri: _chapterUri));

      engine.advance(const Duration(seconds: 30));
      expect(engine.position, Duration.zero, reason: 'ready 态不计入');

      await engine.play();
      engine.advance(const Duration(seconds: 30));
      expect(engine.position, const Duration(seconds: 30));

      await engine.pause();
      engine.advance(const Duration(seconds: 30));
      expect(
        engine.position,
        const Duration(seconds: 30),
        reason: 'paused 不计入',
      );
    });

    test('到达末尾播报 completed，且绝不自动续播', () async {
      final engine = FakePlaybackEngine(
        durations: const <String, Duration>{_chapterUri: Duration(seconds: 60)},
      );
      addTearDown(engine.dispose);

      await engine.load(const LocalFileSource(uri: _chapterUri));
      await engine.play();
      engine.advance(const Duration(seconds: 60));

      expect(engine.state, EnginePlaybackState.completed);
      expect(engine.position, const Duration(seconds: 60));
      expect(engine.emitted.whereType<EngineCompleted>(), hasLength(1));

      final eventCount = engine.emitted.length;
      engine.advance(const Duration(seconds: 30));
      expect(engine.emitted.length, eventCount, reason: '引擎不推进，续播属核心层');
    });

    test('播放完毕后再 play 从头开始', () async {
      final engine = FakePlaybackEngine(
        durations: const <String, Duration>{_chapterUri: Duration(seconds: 60)},
      );
      addTearDown(engine.dispose);

      await engine.load(const LocalFileSource(uri: _chapterUri));
      await engine.play();
      engine.advance(const Duration(seconds: 60));

      await engine.play();
      expect(engine.state, EnginePlaybackState.playing);
      expect(engine.position, Duration.zero);
    });

    test('seek 钳制到 [0, duration]', () async {
      final engine = FakePlaybackEngine(
        durations: const <String, Duration>{_chapterUri: Duration(seconds: 60)},
      );
      addTearDown(engine.dispose);

      await engine.load(const LocalFileSource(uri: _chapterUri));
      await engine.seek(const Duration(hours: 5));
      expect(engine.position, const Duration(seconds: 60));

      await engine.seek(const Duration(seconds: -1));
      expect(engine.position, Duration.zero);
    });

    test('可注入加载失败，并播报 EngineFailed', () async {
      final engine = FakePlaybackEngine(
        loadFailures: const <String, EngineErrorCode>{
          _chapterUri: EngineErrorCode.networkUnavailable,
        },
      );
      addTearDown(engine.dispose);

      await expectLater(
        engine.load(const LocalFileSource(uri: _chapterUri)),
        throwsEngineError(EngineErrorCode.networkUnavailable),
      );
      expect(
        engine.emitted.whereType<EngineFailed>().single.error.code,
        EngineErrorCode.networkUnavailable,
      );
      expect(engine.state, EnginePlaybackState.idle);
    });

    test('播放中加载失败必须退出播放态', () async {
      final engine = FakePlaybackEngine();
      addTearDown(engine.dispose);

      await engine.load(const LocalFileSource(uri: _chapterUri));
      await engine.play();
      expect(engine.state, EnginePlaybackState.playing);

      await expectLater(
        engine.load(const LocalFileSource(uri: 'file:///notes.txt')),
        throwsEngineError(EngineErrorCode.unsupportedFormat),
      );
      expect(engine.state, isNot(EnginePlaybackState.playing));
    });

    test('emitFailure 播报失败并转入 paused', () async {
      final engine = FakePlaybackEngine();
      addTearDown(engine.dispose);

      await engine.load(const LocalFileSource(uri: _chapterUri));
      await engine.play();
      engine.emitFailure(const EngineError(code: EngineErrorCode.interrupted));

      expect(engine.state, EnginePlaybackState.paused);
      expect(engine.emitted.whereType<EngineFailed>(), hasLength(1));
    });

    test('dispose 幂等且计数可观测', () async {
      final engine = FakePlaybackEngine();
      expect(engine.isDisposed, isFalse);

      await engine.dispose();
      await engine.dispose();

      expect(engine.isDisposed, isTrue);
      expect(engine.disposeCount, 2);
      await expectLater(
        engine.load(const LocalFileSource(uri: _chapterUri)),
        throwsEngineError(EngineErrorCode.illegalState),
      );
    });

    test('异常 toString 不泄漏源地址', () {
      const error = EngineError(
        code: EngineErrorCode.authenticationFailed,
        sourceUri: 'https://user:pw@nas.local/dav/a.mp3?token=secret',
      );
      expect(error.toString(), isNot(contains('secret')));
      expect(error.toString(), isNot(contains('user')));
      expect(error.toDiagnosticString(), contains('nas.local/dav/a.mp3'));
      expect(error.toDiagnosticString(), isNot(contains('secret')));
      expect(error.toDiagnosticString(), isNot(contains('user:pw')));
    });
  });
}
