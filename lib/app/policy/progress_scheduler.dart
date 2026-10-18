/// 播放进度写入节流（《架构需求文档》§2.2「进度写入可靠性」）。
///
/// 规则：
/// - **关键事件立即写**：暂停 / 切章 / 退后台（调用 [flush]）；
/// - **播放中每 10 秒最多写一次**（[updatePosition]）；
/// - 因此崩溃时最多丢 **≤10 秒**进度。
///
/// 纯粹的时间判定，不持有定时器、不碰数据库 —— 写入通道由 [onWrite] 注入，
/// 所以可以在测试里用可控时钟精确断言"第 7 秒不写、第 10 秒写"。
class ProgressScheduler {
  /// 创建节流器。
  ProgressScheduler({
    required this.onWrite,
    DateTime Function()? clock,
    this.interval = const Duration(seconds: 10),
  }) : _clock = clock ?? DateTime.now;

  /// 真正落库的回调（由领域层注入）。
  final void Function(Duration position) onWrite;

  /// 播放中的最小写入间隔。
  final Duration interval;

  final DateTime Function() _clock;

  DateTime? _lastWriteAt;
  Duration? _lastWritten;

  /// 最近一次成功写入的位置。
  Duration? get lastWritten => _lastWritten;

  /// 最近一次写入的时间。
  DateTime? get lastWriteAt => _lastWriteAt;

  /// 播放中的位置更新。返回是否真的写入了。
  bool updatePosition(Duration position) {
    final now = _clock();
    final last = _lastWriteAt;
    if (last != null && now.difference(last) < interval) {
      return false;
    }
    _write(position, now);
    return true;
  }

  /// 关键事件：无条件立即写，并重置节流窗口。
  void flush(Duration position) => _write(position, _clock());

  /// 清空节流状态（例如切换书籍）。
  void reset() {
    _lastWriteAt = null;
    _lastWritten = null;
  }

  void _write(Duration position, DateTime now) {
    _lastWriteAt = now;
    _lastWritten = position;
    onWrite(position);
  }
}
