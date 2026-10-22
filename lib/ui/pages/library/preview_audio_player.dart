// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../contracts/playback/audio_source_ref.dart';
import '../../../contracts/playback/playback_engine.dart';

/// 换源试听片头独立播放器（最多自动播放 10 秒后暂停，避免干扰主播放器）。
class PreviewAudioPlayer extends ChangeNotifier {
  PreviewAudioPlayer({PlaybackEngine? engine}) : _engine = engine;

  final PlaybackEngine? _engine;
  Timer? _autoStopTimer;
  String? _currentUrl;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;
  String? get currentUrl => _currentUrl;

  Future<void> play(String url) async {
    if (_currentUrl == url && _isPlaying) {
      await stop();
      return;
    }

    await stop();

    _currentUrl = url;
    _isPlaying = true;
    notifyListeners();

    if (_engine != null) {
      try {
        await _engine.load(RemoteUrlSource(uri: url));
        await _engine.play();
      } catch (_) {
        _isPlaying = false;
        _currentUrl = null;
        notifyListeners();
        return;
      }
    }

    _autoStopTimer = Timer(const Duration(seconds: 10), stop);
  }

  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
      try {
        await _engine?.pause();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    try {
      _engine?.dispose();
    } catch (_) {}
    super.dispose();
  }
}
