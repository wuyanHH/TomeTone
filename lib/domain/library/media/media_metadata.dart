/// 章级媒体元信息（两阶段扫描 Phase 2 的回填内容，§2.1）。
class ChapterMediaMetadata {
  /// 创建元信息。
  const ChapterMediaMetadata({
    this.duration,
    this.embeddedCover,
    this.title,
    this.artist,
    this.album,
  });

  /// 时长。
  final Duration? duration;

  /// 内嵌封面原始字节（ID3v2 APIC / MP4 covr）—— §2.1 封面五级继承的第 4 级。
  final List<int>? embeddedCover;

  /// 内嵌标题。
  final String? title;

  /// 内嵌作者 / 演播者。
  final String? artist;

  /// 内嵌专辑 / 系列。
  final String? album;
}
