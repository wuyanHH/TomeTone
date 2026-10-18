import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/cover_paths.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/player/player_page.dart';
import 'package:tometone/ui/theme/app_theme.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/book_cover.dart';

/// 底部吸附的 MiniPlayer（《架构需求文档》§3.2）。
///
/// 内容只有三件事：封面、章节标题（单行省略）、播放 / 暂停。
/// 整条可点，Hero 封面飞入全屏播放大台；没有任何播放状态副本 ——
/// 播放 / 暂停、进度、章节全部从 [PlaybackController] 读取。
///
/// 没有当前章节时返回 [SizedBox.shrink]，外壳不会为它留出空白。
class MiniPlayer extends ConsumerWidget {
  /// 创建 MiniPlayer。
  const MiniPlayer({super.key});

  /// 播放 / 暂停按钮。
  static const Key playPauseKey = Key('mini-player-play-pause');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PlaybackController controller = ref.watch(playbackControllerProvider);
    final BookDetail? book = ref.watch(currentBookProvider);
    final List<LibraryRootView> roots =
        ref.watch(libraryRootsProvider).value ?? const <LibraryRootView>[];

    return ListenableBuilder(
      listenable: controller.listenable,
      builder: (BuildContext context, Widget? _) {
        final QueueChapter? chapter = controller.current;
        if (chapter == null) {
          return const SizedBox.shrink();
        }

        final MiniPlayerTheme theme = MiniPlayerTheme.of(context);
        final TextTheme text = Theme.of(context).textTheme;
        final bool playing =
            controller.state == EnginePlaybackState.playing ||
            controller.state == EnginePlaybackState.buffering;
        final String? rootUri = _rootUriOf(roots, book);
        final String? coverPath = absoluteCoverPath(
          relativePath: book?.summary.coverPath,
          libraryRootUri: rootUri,
        );
        final Duration? end = controller.range.end ?? chapter.duration;
        final double? progress = end == null || end <= Duration.zero
            ? null
            : (controller.position.inMilliseconds / end.inMilliseconds)
                  .clamp(0.0, 1.0)
                  .toDouble();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Material(
            color: theme.background,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: theme.borderRadius,
              side: BorderSide(color: theme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: theme.height),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Semantics(
                            container: true,
                            button: true,
                            label:
                                '正在播放《${book?.summary.title ?? chapter.title}》'
                                '${chapter.title}，点击展开播放大台',
                            child: ExcludeSemantics(
                              child: InkWell(
                                onTap: () => unawaited(showPlayerPage(context)),
                                child: Row(
                                  children: <Widget>[
                                    Hero(
                                      tag: playerCoverHeroTag,
                                      child: BookCover(
                                        title:
                                            book?.summary.title ??
                                            chapter.title,
                                        size: AppSizes.coverMedium,
                                        coverPath: coverPath,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            chapter.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: text.titleSmall?.copyWith(
                                              color: theme.titleColor,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.xxs,
                                          ),
                                          Text(
                                            _subtitle(book, chapter),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: text.labelSmall?.copyWith(
                                              color: theme.subtitleColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        SizedBox.square(
                          dimension: AppSizes.minTouchTarget,
                          child: IconButton(
                            key: MiniPlayer.playPauseKey,
                            tooltip: playing ? '暂停' : '播放',
                            onPressed: () =>
                                unawaited(controller.togglePlayPause()),
                            color: theme.titleColor,
                            iconSize: 26,
                            icon: Icon(
                              playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 2,
                  child: progress == null
                      ? ColoredBox(color: theme.progressTrack)
                      : LinearProgressIndicator(
                          value: progress,
                          minHeight: 2,
                          color: theme.progressFill,
                          backgroundColor: theme.progressTrack,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _subtitle(BookDetail? book, QueueChapter chapter) {
    final String? title = book?.summary.title;
    if (title == null || title.trim().isEmpty) {
      return '正在播放';
    }
    final String? author = book?.summary.author;
    if (author == null || author.trim().isEmpty) {
      return title;
    }
    return '$title · ${author.trim()}';
  }

  static String? _rootUriOf(List<LibraryRootView> roots, BookDetail? book) {
    final String? id = book?.summary.libraryRootId;
    if (id == null) {
      return null;
    }
    for (final LibraryRootView root in roots) {
      if (root.id == id) {
        return root.uri;
      }
    }
    return null;
  }
}
