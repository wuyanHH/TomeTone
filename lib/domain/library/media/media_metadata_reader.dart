import 'package:tometone/contracts/playback/audio_source_ref.dart';

import 'media_metadata.dart';

/// 媒体元信息读取端口（§2.1 两阶段扫描的 Phase 2）。
///
/// 实现必须**宽容**：读不到返回 `null` 即可 —— 单个坏文件绝不能阻塞整本书的回填，
/// 调用方会把异常计入 `BackfillReport.failed` 并继续下一个。
///
/// 真实实现（纯 Dart 标签解析 / 引擎探测）在 Step 4–5 接入；此处只锁定契约。
abstract interface class MediaMetadataReader {
  /// 读取 [source] 的元信息；无法解析时返回 `null`。
  Future<ChapterMediaMetadata?> read(AudioSourceRef source);
}
