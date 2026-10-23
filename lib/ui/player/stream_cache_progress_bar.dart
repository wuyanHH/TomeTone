import 'package:flutter/material.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 双层流式缓冲与播放进度条 (StreamCacheProgressBar)。
///
/// 包含三层：
/// 1. 底轨 (Base Inactive Track)
/// 2. 缓冲/预载副轨 (Secondary Buffered Track)
/// 3. 主播放进度与拖拽游标 (Active Progress Track & Thumb)
class StreamCacheProgressBar extends StatelessWidget {
  const StreamCacheProgressBar({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    this.bufferedPosition = Duration.zero,
    this.onSeek,
  });

  final Duration currentPosition;
  final Duration totalDuration;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalMs = totalDuration.inMilliseconds;
    final currentMs = currentPosition.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);
    final bufferedMs = bufferedPosition.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);

    final double playRatio = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final double bufferRatio = totalMs > 0 ? (bufferedMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 可交互轨道区域
            GestureDetector(
              key: const Key('stream-cache-track'),
              behavior: HitTestBehavior.opaque,
              onTapDown: onSeek != null && totalMs > 0
                  ? (details) {
                      final localX = details.localPosition.dx.clamp(0.0, trackWidth);
                      final ratio = trackWidth > 0 ? (localX / trackWidth).clamp(0.0, 1.0) : 0.0;
                      final targetMs = (ratio * totalMs).round();
                      onSeek!(Duration(milliseconds: targetMs));
                    }
                  : null,
              onHorizontalDragUpdate: onSeek != null && totalMs > 0
                  ? (details) {
                      final localX = details.localPosition.dx.clamp(0.0, trackWidth);
                      final ratio = trackWidth > 0 ? (localX / trackWidth).clamp(0.0, 1.0) : 0.0;
                      final targetMs = (ratio * totalMs).round();
                      onSeek!(Duration(milliseconds: targetMs));
                    }
                  : null,
              child: SizedBox(
                height: 24,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // 1. 底轨
                    Container(
                      height: AppSpacing.xs,
                      width: trackWidth,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadii.xs,
                      ),
                    ),

                    // 2. 缓冲副轨
                    Container(
                      height: AppSpacing.xs,
                      width: trackWidth * bufferRatio,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(90),
                        borderRadius: AppRadii.xs,
                      ),
                    ),

                    // 3. 主播放进度轨
                    Container(
                      height: AppSpacing.xs,
                      width: trackWidth * playRatio,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: AppRadii.xs,
                      ),
                    ),

                    // 4. 游标 (Thumb)
                    Positioned(
                      left: (trackWidth * playRatio - 6).clamp(0.0, trackWidth - 12),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 时间文本栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(currentPosition),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  _formatDuration(totalDuration),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hStr = hours.toString().padLeft(2, '0');
      return '$hStr:$mStr:$sStr';
    }
    return '$mStr:$sStr';
  }
}
