/// 播放引擎能力声明（《架构需求文档》§5.3）。
///
/// 核心层只依据本声明决定策略分支（是否走 gapless、倍速上下限、是否可注入请求头、
/// 能否后台播放、能否播放某扩展名），**不得**基于 `runtimeType` 判断实现。
class EngineCapabilities {
  /// 创建能力声明。
  const EngineCapabilities({
    required this.engineId,
    required this.gapless,
    required this.supportsSeek,
    required this.supportsHeaderInjection,
    required this.supportsBackgroundPlayback,
    required this.minSpeed,
    required this.maxSpeed,
    required this.supportedFormats,
  });

  /// 引擎稳定标识，用于日志与"引擎自检"展示（不含 UI 文案）。
  final String engineId;

  /// 是否支持无缝连播（跨章 / 跨卷无间隙）。
  final bool gapless;

  /// 是否支持定位。
  final bool supportsSeek;

  /// 是否支持注入请求头（远程 Basic 认证依赖此项，§7.2 M1）。
  final bool supportsHeaderInjection;

  /// 是否支持后台播放（媒体会话 / 前台服务）。
  final bool supportsBackgroundPlayback;

  /// 倍速下限（含）。
  final double minSpeed;

  /// 倍速上限（含）。
  final double maxSpeed;

  /// 支持的容器 / 编码扩展名，**全小写、不含点**。
  ///
  /// 对应 §2.1 媒体格式清单：`mp3 / m4a / m4b / aac / flac / wav / ogg / opus`。
  final Set<String> supportedFormats;

  /// 能力声明是否自洽。
  ///
  /// 契约测试套件会断言本方法为真 —— 保证上层可以无条件信任这些开关。
  bool get isSelfConsistent {
    return engineId.isNotEmpty &&
        minSpeed > 0 &&
        maxSpeed >= minSpeed &&
        supportedFormats.isNotEmpty &&
        supportedFormats.every(
          (format) =>
              format.isNotEmpty &&
              format == format.toLowerCase() &&
              !format.startsWith('.'),
        );
  }

  @override
  String toString() =>
      'EngineCapabilities($engineId, gapless: $gapless, '
      'speed: $minSpeed..$maxSpeed, formats: ${supportedFormats.join('/')})';
}
