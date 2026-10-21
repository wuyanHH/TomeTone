import 'package:flutter/material.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 在线封面：网络图加载中显示占位，失败或没有 URL 时回退到耳机图标。
///
/// 不引入磁盘缓存依赖；缓存属于播放/预下载链路，封面只做尽力展示。
class NetworkCover extends StatelessWidget {
  /// 创建在线封面。
  const NetworkCover({
    super.key,
    required this.coverUrl,
    this.size = 64,
    this.headers,
    this.borderRadius,
  });

  /// 回退图标的定位键（测试与调试用）。
  static const Key fallbackKey = Key('network-cover-fallback');

  /// 回退图标。
  static const IconData fallbackIcon = Icons.headphones_rounded;

  /// 封面 URL；为空时直接回退。
  final String? coverUrl;

  /// 正方形边长。
  final double size;

  /// 图片请求头（源 header）；不得写入 URL。
  final Map<String, String>? headers;

  /// 圆角；默认使用 10dp。
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? url = coverUrl?.trim();
    final BorderRadius radius =
        borderRadius ?? BorderRadius.circular(AppRadii.smValue);

    final Widget fallback = Container(
      key: fallbackKey,
      width: size,
      height: size,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: size * 0.42,
        color: scheme.onSurfaceVariant,
      ),
    );

    final Widget content;
    if (url == null || url.isEmpty) {
      content = fallback;
    } else {
      content = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        headers: headers,
        loadingBuilder:
            (BuildContext context, Widget child, ImageChunkEvent? progress) {
              if (progress == null) {
                return child;
              }
              return SizedBox.square(
                dimension: size,
                child: Center(
                  child: SizedBox.square(
                    dimension: size * 0.3,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.primary,
                    ),
                  ),
                ),
              );
            },
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return fallback;
            },
      );
    }

    return ClipRRect(borderRadius: radius, child: content);
  }
}
