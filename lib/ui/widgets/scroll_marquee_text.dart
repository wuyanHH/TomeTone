import 'package:flutter/material.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 单行文本：放得下就静止；放不下就「停留 → 缓慢滚动 → 停留」循环。
///
/// 为什么不用 `overflow: ellipsis` 了事：书库根的可读路径常常是
/// `内部存储/有声书/武侠/长篇合集` 这种层层目录，省略号会恰好省掉最有辨识度
/// 的末级目录。滚动能完整展示，又不换行撑高卡片。
///
/// 系统开启「减少动态效果」时完全不建动画，退化为普通省略号单行文本。
class ScrollMarqueeText extends StatefulWidget {
  /// 创建滚动文本。
  const ScrollMarqueeText({
    required this.text,
    required this.style,
    this.pause = const Duration(milliseconds: 2200),
    this.pixelsPerSecond = 28,
    super.key,
  });

  /// 完整文本（语义标签也用它，读屏一次读全）。
  final String text;

  /// 文本样式；行高会用于固定可视高度，避免动画期间上下跳动。
  final TextStyle? style;

  /// 滚动到两端后各停留多久。
  final Duration pause;

  /// 滚动速度；长文本会被时长上下限夹住，避免一屏字滚半分钟。
  final double pixelsPerSecond;

  @override
  State<ScrollMarqueeText> createState() => _ScrollMarqueeTextState();
}

class _ScrollMarqueeTextState extends State<ScrollMarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1),
  );

  /// 当前这段文本的滚动曲线；不溢出 / 减弱动效时为 null。
  Animation<double>? _offsetAnimation;

  /// 已配置的滚动距离；未配置时为 -1。
  double _distance = -1;

  double _pendingDistance = 0;
  bool _syncScheduled = false;

  @override
  void didUpdateWidget(ScrollMarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.style != widget.style) {
      // 文本换了就回到起点，等这一帧量完宽度再决定要不要重新滚。
      _distance = -1;
      _offsetAnimation = null;
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = AppMotion.reduced(context);
    final TextDirection direction = Directionality.of(context);
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    // Text 最终会把外部样式与 DefaultTextStyle 合并；测量也必须用合并后的
    // 样式，否则只传了颜色或字重时量出来的宽度会偏小，滚动距离就不准。
    final TextStyle effectiveStyle = DefaultTextStyle.of(context).style
        .merge(widget.style);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth;
        final TextPainter painter = TextPainter(
          text: TextSpan(text: widget.text, style: effectiveStyle),
          maxLines: 1,
          textDirection: direction,
          textScaler: textScaler,
        )..layout();

        final double textWidth = painter.width;
        final double textHeight = painter.height;
        painter.dispose();

        final bool overflows = maxWidth.isFinite && textWidth > maxWidth + 0.5;
        final bool scrolls = overflows && !reduceMotion;
        final double distance = scrolls ? textWidth - maxWidth : 0;
        _scheduleSync(distance);

        final Widget visual = scrolls
            ? _buildScrolling(textHeight: textHeight, style: effectiveStyle)
            : _buildStatic(overflows: overflows, style: effectiveStyle);

        return Semantics(
          label: widget.text,
          excludeSemantics: true,
          child: visual,
        );
      },
    );
  }

  /// 宽度足够（或方向不可测）时完全不参与动画，避免无意义的重绘。
  Widget _buildStatic({required bool overflows, required TextStyle style}) {
    return Text(
      widget.text,
      maxLines: 1,
      softWrap: false,
      overflow: overflows ? TextOverflow.ellipsis : TextOverflow.clip,
      style: style,
    );
  }

  Widget _buildScrolling({
    required double textHeight,
    required TextStyle style,
  }) {
    return SizedBox(
      width: double.infinity,
      height: textHeight,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          child: AnimatedBuilder(
            animation: _controller,
            child: Text(
              widget.text,
              maxLines: 1,
              softWrap: false,
              style: style,
            ),
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: Offset(_currentOffset, 0),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }

  double get _currentOffset => _offsetAnimation?.value ?? 0;

  /// 只在「量出来的距离」变化时排一次后帧同步。
  ///
  /// 动画不能在这里直接启动：`build` 里改状态会触发「build 期间又 build」，
  /// 也会让每次父级重绘都把动画重置回起点。
  void _scheduleSync(double distance) {
    if ((distance - _distance).abs() <= 0.5) {
      return;
    }
    _pendingDistance = distance;
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) {
        return;
      }
      _applyDistance(_pendingDistance);
    });
  }

  void _applyDistance(double distance) {
    if (distance <= 0.5) {
      _distance = 0;
      _offsetAnimation = null;
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return;
    }

    if (_offsetAnimation != null && (distance - _distance).abs() <= 0.5) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
      return;
    }

    _distance = distance;
    final int pauseMs = widget.pause.inMilliseconds.clamp(400, 8000).toInt();
    final double speed = widget.pixelsPerSecond > 0
        ? widget.pixelsPerSecond
        : 28;
    final int travelMs = (distance / speed * 1000)
        .round()
        .clamp(2500, 14000)
        .toInt();

    _offsetAnimation = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(0),
        weight: pauseMs.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: -distance),
        weight: travelMs.toDouble(),
      ),
      TweenSequenceItem<double>(
        tween: ConstantTween<double>(-distance),
        weight: pauseMs.toDouble(),
      ),
    ]).animate(_controller);

    _controller
      ..duration = Duration(milliseconds: pauseMs * 2 + travelMs)
      ..value = 0
      ..repeat();
  }
}
