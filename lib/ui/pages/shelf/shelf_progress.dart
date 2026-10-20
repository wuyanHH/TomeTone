import 'package:flutter/material.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书架进度（网格卡片与列表行共用，口径唯一）。
///
/// 进度比例按「章序号」计算：`(progressChapterIndex + 1) / totalChapters`，
/// clamp 到 0..1。没有进度显示 `未听`，已听完显示 `已完`，否则显示百分比。
/// 网格与列表都从这里取口径，绝不写两套判定。
class ShelfProgress extends StatelessWidget {
  /// 创建书架进度。
  const ShelfProgress({required this.book, this.compact = false, super.key});

  /// 所属书（读进度与完听标记）。
  final BookSummary book;

  /// 紧凑形态：更细的进度条、更小的文案（网格卡片用）。
  final bool compact;

  /// 进度比例（0..1）。
  double get fraction {
    if (book.isFinished) {
      return 1;
    }
    if (!book.hasProgress || book.totalChapters <= 0) {
      return 0;
    }
    final int index = book.progressChapterIndex ?? 0;
    return ((index + 1) / book.totalChapters).clamp(0.0, 1.0);
  }

  /// 进度文案：已完 / 未听 / 百分比。
  String get label {
    if (book.isFinished) {
      return '已完';
    }
    if (!book.hasProgress) {
      return '未听';
    }
    return '${(fraction * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle labelStyle = (compact ? text.labelSmall : text.labelMedium)!
        .copyWith(color: scheme.onSurfaceVariant);

    return Row(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pillValue),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: compact ? 2 : 3,
            ),
          ),
        ),
        SizedBox(width: compact ? AppSpacing.xs : AppSpacing.sm),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: labelStyle,
        ),
      ],
    );
  }
}
