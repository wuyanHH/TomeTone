import 'package:flutter/material.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 章节目录弹层（详情页「章节目录 / 卷册」共用）。
///
/// 按卷分组，当前章高亮；缺失章置灰且不可点。点正常章先关闭弹层，再把
/// [ChapterView] 交给调用方起播。
Future<void> showChapterListSheet(
  BuildContext context, {
  required BookDetail detail,
  required String? currentChapterId,
  required ValueChanged<ChapterView> onChapterSelected,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return _ChapterListSheet(
        detail: detail,
        currentChapterId: currentChapterId,
        onChapterSelected: onChapterSelected,
      );
    },
  );
}

class _ChapterListSheet extends StatelessWidget {
  const _ChapterListSheet({
    required this.detail,
    required this.currentChapterId,
    required this.onChapterSelected,
  });

  final BookDetail detail;
  final String? currentChapterId;
  final ValueChanged<ChapterView> onChapterSelected;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<_SheetEntry> entries = _buildEntries(detail);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController controller) {
        return Column(
          children: <Widget>[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: AppRadii.pill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('章节目录', style: text.titleMedium),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '第 ${detail.chapters.length} 章 · ${detail.volumes.length} 卷',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int index) {
                  final _SheetEntry entry = entries[index];
                  if (entry.retiredHeader != null) {
                    return _RetiredHeader(count: entry.retiredHeader!);
                  }
                  final VolumeView? volume = entry.volume;
                  if (volume != null) {
                    return _VolumeHeader(volume: volume);
                  }
                  final ChapterView chapter = entry.chapter!;
                  final bool playable =
                      !chapter.missing && !chapter.retired && !chapter.isVip;
                  return _ChapterTile(
                    chapter: chapter,
                    current: chapter.id == currentChapterId,
                    onTap: playable
                        ? () {
                            Navigator.of(context).pop();
                            onChapterSelected(chapter);
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  static List<_SheetEntry> _buildEntries(BookDetail detail) {
    final List<_SheetEntry> entries = <_SheetEntry>[];
    for (final VolumeView volume in detail.volumes) {
      final List<ChapterView> active = volume.chapters
          .where((chapter) => !chapter.retired)
          .toList(growable: false);
      if (active.isNotEmpty) {
        entries.add(_SheetEntry.volume(volume));
        for (final ChapterView chapter in active) {
          entries.add(_SheetEntry.chapter(chapter));
        }
      }
    }
    final List<ChapterView> retired = detail.retiredChapters;
    if (retired.isNotEmpty) {
      entries.add(_SheetEntry.retired(retired.length));
      for (final ChapterView chapter in retired) {
        entries.add(_SheetEntry.chapter(chapter));
      }
    }
    return entries;
  }
}

class _RetiredHeader extends StatelessWidget {
  const _RetiredHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        '已下架 $count 章',
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _SheetEntry {
  const _SheetEntry._({this.volume, this.chapter, this.retiredHeader});

  factory _SheetEntry.volume(VolumeView volume) =>
      _SheetEntry._(volume: volume);

  factory _SheetEntry.chapter(ChapterView chapter) =>
      _SheetEntry._(chapter: chapter);

  factory _SheetEntry.retired(int count) => _SheetEntry._(retiredHeader: count);

  final VolumeView? volume;
  final ChapterView? chapter;
  final int? retiredHeader;
}

class _VolumeHeader extends StatelessWidget {
  const _VolumeHeader({required this.volume});

  final VolumeView volume;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              volume.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelLarge?.copyWith(color: scheme.primary),
            ),
          ),
          Text(
            '${volume.chapters.length} 章',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    required this.chapter,
    required this.current,
    required this.onTap,
  });

  final ChapterView chapter;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String duration = _formatDuration(chapter.durationMs);
    return ListTile(
      enabled: onTap != null,
      selected: current,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
      leading: Icon(
        current ? Icons.graphic_eq_rounded : Icons.play_circle_outline_rounded,
        color: onTap == null
            ? scheme.onSurfaceVariant.withValues(alpha: 0.4)
            : current
            ? scheme.primary
            : scheme.onSurfaceVariant,
      ),
      title: Text(
        chapter.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: text.bodyMedium?.copyWith(
          color: onTap == null ? scheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Text(
        chapter.missing
            ? '文件缺失'
            : <String>[
                '第 ${chapter.chapterIndex + 1} 章',
                if (chapter.isVip) '需要登录/购买',
                if (chapter.retired) '已下架',
                if (duration.isNotEmpty) duration,
              ].join(' · '),
        style: text.labelSmall?.copyWith(
          color: chapter.missing || chapter.isVip
              ? scheme.tertiary
              : scheme.onSurfaceVariant,
        ),
      ),
      trailing: chapter.isVip
          ? Icon(
              Icons.lock_outline_rounded,
              color: scheme.onSurfaceVariant,
              size: 20,
            )
          : chapter.retired
          ? Icon(
              Icons.link_off_rounded,
              color: scheme.onSurfaceVariant,
              size: 20,
            )
          : current
          ? Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20)
          : null,
      onTap: onTap,
    );
  }

  static String _formatDuration(int? ms) {
    if (ms == null || ms <= 0) {
      return '';
    }
    final Duration duration = Duration(milliseconds: ms);
    final int minutes = duration.inMinutes;
    if (minutes < 60) {
      return '$minutes 分钟';
    }
    final int hours = minutes ~/ 60;
    final int rest = minutes % 60;
    return rest == 0 ? '$hours 小时' : '$hours 小时 $rest 分';
  }
}
