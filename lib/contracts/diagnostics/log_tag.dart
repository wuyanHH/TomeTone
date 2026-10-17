/// 模块级日志标签（《架构需求文档》§5.3 诊断）。
///
/// 所有模块日志必须以标签开头，便于按模块过滤；日志仅存本地（§9.5）。
enum LogTag {
  /// 播放引擎。
  engine('engine'),

  /// 存储与网盘访问。
  storage('storage'),

  /// 下载子系统。
  download('download'),

  /// 备份与恢复。
  backup('backup'),

  /// 检查更新。
  update('update'),

  /// 书库扫描与检索。
  library('library'),

  /// 播放策略编排（连播 / 回退 / 睡眠）。
  playback('playback'),

  /// 聆听纪年统计。
  chronicle('chronicle'),

  /// 平台适配（媒体会话 / 前台服务 / SAF）。
  platform('platform'),

  /// 数据库与迁移。
  database('database');

  const LogTag(this.label);

  /// 日志中使用的稳定标签 —— 不随 UI 文案与语言变化。
  final String label;
}
