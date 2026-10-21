import 'dart:async';

/// Legado `concurrentRate` 的速率配置。
///
/// - 缺失或数字：两次请求之间的最小间隔。
/// - `20/60000`：60 秒窗口内最多 20 次。
class SourceRateLimit {
  const SourceRateLimit({
    this.minInterval = const Duration(milliseconds: 300),
    this.maxRequests,
    this.window,
  });

  final Duration minInterval;
  final int? maxRequests;
  final Duration? window;

  factory SourceRateLimit.parse(Object? raw) {
    if (raw is int) {
      return raw > 0
          ? SourceRateLimit(minInterval: Duration(milliseconds: raw))
          : const SourceRateLimit();
    }
    if (raw is String) {
      final text = raw.trim();
      final windowed = RegExp(r'^(\d+)\s*/\s*(\d+)$').firstMatch(text);
      if (windowed != null) {
        final maxRequests = int.tryParse(windowed.group(1)!) ?? 0;
        final windowMs = int.tryParse(windowed.group(2)!) ?? 0;
        if (maxRequests > 0 && windowMs > 0) {
          return SourceRateLimit(
            minInterval: Duration.zero,
            maxRequests: maxRequests,
            window: Duration(milliseconds: windowMs),
          );
        }
        return const SourceRateLimit();
      }

      final millis = int.tryParse(text);
      if (millis != null && millis > 0) {
        return SourceRateLimit(minInterval: Duration(milliseconds: millis));
      }
    }
    return const SourceRateLimit();
  }
}

/// 按书源串行放行请求，并执行最小间隔/滑动窗口限速。
///
/// 只负责“什么时候可以发请求”，不负责执行请求；同一源的调用会排队。
class SourceRateLimiter {
  SourceRateLimiter({
    DateTime Function()? clock,
    Future<void> Function(Duration duration)? delay,
  }) : _clock = clock ?? DateTime.now,
       _delay = delay ?? _defaultDelay;

  final DateTime Function() _clock;
  final Future<void> Function(Duration duration) _delay;
  final Map<String, Future<void>> _tails = <String, Future<void>>{};
  final Map<String, _RateState> _states = <String, _RateState>{};

  static Future<void> _defaultDelay(Duration duration) {
    return Future<void>.delayed(duration);
  }

  Future<void> acquire(String sourceId, SourceRateLimit limit) {
    final previous = _tails[sourceId] ?? Future<void>.value();
    final next = previous.then((_) => _acquireNow(sourceId, limit));
    _tails[sourceId] = next.catchError((Object _) {});
    return next;
  }

  Future<void> _acquireNow(String sourceId, SourceRateLimit limit) async {
    final state = _states.putIfAbsent(sourceId, _RateState.new);
    var wait = Duration.zero;

    final maxRequests = limit.maxRequests;
    final window = limit.window;
    if (maxRequests != null &&
        maxRequests > 0 &&
        window != null &&
        window > Duration.zero) {
      final now = _clock();
      _prune(state.timestamps, now, window);
      if (state.timestamps.length >= maxRequests) {
        final oldest = state.timestamps.first;
        wait = _positive(oldest.add(window).difference(now));
      }
    }

    final lastStart = state.lastStart;
    if (limit.minInterval > Duration.zero && lastStart != null) {
      final intervalWait = _positive(
        limit.minInterval - _clock().difference(lastStart),
      );
      if (intervalWait > wait) {
        wait = intervalWait;
      }
    }

    if (wait > Duration.zero) {
      await _delay(wait);
    }

    final now = _clock();
    state.lastStart = now;
    if (maxRequests != null &&
        maxRequests > 0 &&
        window != null &&
        window > Duration.zero) {
      _prune(state.timestamps, now, window);
      state.timestamps.add(now);
    }
  }

  void _prune(List<DateTime> timestamps, DateTime now, Duration window) {
    timestamps.removeWhere((timestamp) => !timestamp.add(window).isAfter(now));
  }

  Duration _positive(Duration duration) {
    return duration.isNegative ? Duration.zero : duration;
  }
}

class _RateState {
  DateTime? lastStart;
  final List<DateTime> timestamps = <DateTime>[];
}
