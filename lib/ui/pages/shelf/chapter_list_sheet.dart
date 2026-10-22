import 'package:flutter/material.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 章节目录弹层（详情页「章节目录 / 卷册」共用）。
///
/// 按卷分组，当前章高亮；缺失章置灰且不可点。点正常章先关闭弹层，再把
/// [ChapterView] 交给调用方起播。支持卷册折叠与正倒序切换。
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

class _ChapterListSheet extends StatefulWidget {
  const _ChapterListSheet({
    required this.detail,
    required this.currentChapterId,
    required this.onChapterSelected,
  });

  final BookDetail detail;
  final String? currentChapterId;
  final ValueChanged<ChapterView> onChapterSelected;

  @override
  State<_ChapterListSheet> createState() => _ChapterListSheetState();
}

class _ChapterListSheetState extends State<_ChapterListSheet> {
  bool _ascending = true;
  final Set<String> _collapsedVolumeIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<_SheetEntry> entries = _buildEntries(widget.detail);

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
                          '第 ${widget.detail.chapters.length} 章 · ${widget.detail.volumes.length} 卷',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _ascending ? '切换为倒序' : '切换为正序',
                    onPressed: () => setState(() => _ascending = !_ascending),
                    icon: Icon(
                      _ascending
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
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
                    final bool isCollapsed =
                        _collapsedVolumeIds.contains(volume.id);
                    return _VolumeHeader(
                      volume: volume,
                      isCollapsed: isCollapsed,
                      onToggle: () {
                        setState(() {
                          if (isCollapsed) {
                            _collapsedVolumeIds.remove(volume.id);
                          } else {
                            _collapsedVolumeIds.add(volume.id);
                          }
                        });
                      },
                    );
                  }
                  final ChapterView chapter = entry.chapter!;
                  final bool playable =
                      !chapter.missing && !chapter.retired && !chapter.isVip;
                  return _ChapterTile(
                    chapter: chapter,
                    current: chapter.id == widget.currentChapterId,
                    onTap: playable
                        ? () {
                            Navigator.of(context).pop();
                            widget.onChapterSelected(chapter);
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

  List<_SheetEntry> _buildEntries(BookDetail detail) {
    final List<_SheetEntry> entries = <_SheetEntry>[];
    final List<VolumeView> volumes = _ascending
        ? detail.volumes
        : detail.volumes.reversed.toList();

    for (final VolumeView volume in volumes) {
      List<ChapterView> active = volume.chapters
          .where((chapter) => !chapter.retired)
          .toList(growable: false);
      if (!_ascending) {
        active = active.reversed.toList();
      }
      if (active.isNotEmpty) {
        entries.add(_SheetEntry.volume(volume));
        if (!_collapsedVolumeIds.contains(volume.id)) {
          for (final ChapterView chapter in active) {
            entries.add(_SheetEntry.chapter(chapter));
          }
        }
      }
    }
    final List<ChapterView> retired = detail.retiredChapters;
    if (retired.isNotEmpty) {
      entries.add(_SheetEntry.retired(retired.length));
      final List<ChapterView> retiredList =
          _ascending ? retired : retired.reversed.toList();
      for (final ChapterView chapter in retiredList) {
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
  const _VolumeHeader({
    required this.volume,
    required this.isCollapsed,
    required this.onToggle,
  });

  final VolumeView volume;
  final bool isCollapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
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
                style: text.labelLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              isCollapsed
                  ? Icons.expand_more_rounded
                  : Icons.expand_less_rounded,
              color: scheme.primary,
              size: 20,
            ),
          ],
        ),
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
    final bool missing = chapter.missing;
    final bool vip = chapter.isVip;

    final Widget titleWidget = Text(
      chapter.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.bodyMedium?.copyWith(
        color: current
            ? scheme.primary
            : missing
                ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
                : scheme.onSurface,
        fontWeight: current ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final Widget? trailing = missing
        ? Text(
            '缺失',
            style: text.labelSmall?.copyWith(
              color: scheme.error.withValues(alpha: 0.8),
            ),
          )
        : vip
            ? Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              )
            : null;

    return ListTile(
      dense: true,
      selected: current,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      leading: SizedBox(
        width: 32,
        child: Text(
          '${chapter.chapterIndex + 1}',
          style: text.labelSmall?.copyWith(
            color: current ? scheme.primary : scheme.onSurfaceVariant,
          ),
        ),
      ),
      title: titleWidget,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
