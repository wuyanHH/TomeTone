import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/cover_art.dart';
import 'package:tometone/app/policy/chapter_sequencer.dart';
import 'package:tometone/app/policy/playback_controller.dart';
import 'package:tometone/app/policy/sleep_timer.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/playback_providers.dart';
import 'package:tometone/contracts/playback/engine_event.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/book_cover.dart';

/// MiniPlayer 与播放大台共享的封面 Hero 标签。
///
/// 两端必须取同一个常量，否则 Container Transform 的替身会变成两张各自
/// 淡入淡出的封面（表现为"闪一下"）。
const String playerCoverHeroTag = 'tometone.player.cover';

/// 打开全屏播放大台。
///
/// 本轮不引入 `animations` 包，因此用「淡入 + 轻微放大 + Hero 封面飞行」
/// 近似 Material 3 的 Container Transform（交付说明中已注明这一偏离）。
Future<void> showPlayerPage(BuildContext context) {
  final Duration duration = AppMotion.resolve(
    context,
    AppDurations.containerTransform,
  );
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: 'player'),
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (BuildContext _, Animation<double> _, Animation<double> _) {
        return const PlayerPage();
      },
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final Animation<double> eased = animation.drive(
              CurveTween(curve: AppDurations.emphasizedCurve),
            );
            return FadeTransition(
              opacity: eased,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(eased),
                child: child,
              ),
            );
          },
    ),
  );
}

/// 全屏播放大台（《架构需求文档》§2.2）。
///
/// 信息层级（自上而下）：
/// 1. 返回 / 书名 / 章节目录 —— 导航与"我在哪本书"；
/// 2. 大封面 + 章标题 —— 当前正在听什么；
/// 3. 双层时间轴 —— 章节可拖动，全书只读；
/// 4. 倍速 / 睡眠 / 撤销回退 —— 低频设置；
/// 5. 五键下沉控制台 —— 拇指区，固定不随内容滚动。
///
/// 播放状态一律读 [PlaybackController]，页面不保存"是否在播放"的副本。
class PlayerPage extends ConsumerStatefulWidget {
  /// 创建播放大台。
  const PlayerPage({super.key});

  /// 上一曲。
  static const Key previousKey = Key('player-previous');

  /// 快退 15 秒。
  static const Key rewindKey = Key('player-rewind-15');

  /// 播放 / 暂停。
  static const Key playPauseKey = Key('player-play-pause');

  /// 快进 30 秒。
  static const Key forwardKey = Key('player-forward-30');

  /// 下一曲。
  static const Key nextKey = Key('player-next');

  /// 倍速入口。
  static const Key speedKey = Key('player-speed');

  /// 睡眠守夜入口。
  static const Key sleepKey = Key('player-sleep');

  /// 撤销微回退。
  static const Key undoRewindKey = Key('player-undo-rewind');

  /// 章节目录入口。
  static const Key chaptersKey = Key('player-chapters');

  /// 章节进度条。
  static const Key chapterSliderKey = Key('player-chapter-slider');

  /// 「这一章打不开」失败提示（切章加载失败的可见出口）。
  static const Key playbackErrorKey = Key('player-playback-error');

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  /// 拖动中的章节位置（毫秒）。只用于滑块的即时跟手，
  /// 松手后立即回到控制器位置，不构成第二份播放状态。
  double? _dragPositionMs;

  @override
  Widget build(BuildContext context) {
    final PlaybackController controller = ref.watch(playbackControllerProvider);
    final BookDetail? book = ref.watch(currentBookProvider);

    return ListenableBuilder(
      listenable: controller.listenable,
      builder: (BuildContext context, Widget? _) {
        final QueueChapter? chapter = controller.current;
        if (book == null && chapter == null) {
          return _buildEmpty(context);
        }

        final ColorScheme scheme = Theme.of(context).colorScheme;
        // OLED 形态（surface 为纯黑）保持纯黑底：只让封面光晕提供层次，
        // 不再铺渐变，避免把"纯黑省电"换成一层近黑。
        final bool oledBlack =
            scheme.brightness == Brightness.dark &&
            scheme.surface.computeLuminance() < 0.0001;
        final BoxDecoration backdrop = oledBlack
            ? BoxDecoration(color: scheme.surface)
            : BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Color.alphaBlend(
                      scheme.primary.withValues(alpha: 0.06),
                      scheme.surface,
                    ),
                    scheme.surface,
                  ],
                ),
              );

        return Scaffold(
          body: DecoratedBox(
            decoration: backdrop,
            child: SafeArea(
              child: Column(
                children: <Widget>[
                  _buildTopBar(context, book, chapter),
                  Expanded(
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.only(
                                left: AppSpacing.lg,
                                right: AppSpacing.lg,
                                bottom: AppSpacing.md,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: math.max(
                                    0,
                                    constraints.maxHeight - AppSpacing.md,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    _buildCover(context, book, chapter),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildChapterHeading(
                                      context,
                                      controller,
                                      book,
                                      chapter,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    _buildTimeline(
                                      context,
                                      controller,
                                      book,
                                      chapter,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    _buildSecondaryRow(context, controller),
                                  ],
                                ),
                              ),
                            );
                          },
                    ),
                  ),
                  _buildConsole(context, controller, chapter),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '返回',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('播放大台'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.graphic_eq_rounded,
                size: 44,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('还没有正在播放的内容', style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '从书架里点开一本书，播放台就会亮起来。',
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    BookDetail? book,
    QueueChapter? chapter,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String title = book?.summary.title ?? chapter?.title ?? '播放大台';

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: '返回',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: text.titleMedium,
                ),
                Text(
                  '正在播放',
                  style: text.labelSmall?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: PlayerPage.chaptersKey,
            tooltip: '章节目录',
            onPressed: () => unawaited(_openChapterSheet()),
            icon: const Icon(Icons.queue_music_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(
    BuildContext context,
    BookDetail? book,
    QueueChapter? chapter,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.sizeOf(context).width;
    final double size = math.min(width - AppSpacing.xxxl * 2, 300);
    final CoverArt? coverArt = book == null
        ? null
        : ref
              .watch(
                coverArtProvider(
                  CoverArtKey(
                    rootId: book.summary.libraryRootId,
                    coverPath: book.summary.coverPath,
                  ),
                ),
              )
              .value;
    final String title = book?.summary.title ?? chapter?.title ?? '听卷';

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadii.lg,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.12),
              blurRadius: 48,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Hero(
          tag: playerCoverHeroTag,
          child: BookCover(
            title: title,
            size: size,
            coverPath: coverArt is CoverArtFile ? coverArt.absolutePath : null,
            coverImage: coverArt is CoverArtBytes
                ? MemoryImage(coverArt.bytes)
                : null,
            borderRadius: AppRadii.lg,
          ),
        ),
      ),
    );
  }

  Widget _buildChapterHeading(
    BuildContext context,
    PlaybackController controller,
    BookDetail? book,
    QueueChapter? chapter,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String? volumeTitle = _volumeTitleOf(book, chapter?.volumeId);
    final String? author = book?.summary.author;
    final String meta = <String>[
      ?volumeTitle,
      if (author != null && author.trim().isNotEmpty) author.trim(),
    ].join(' · ');
    // 切章加载失败时给出可见出口，不静默卡住（见 PlaybackController 的切章加固）。
    final bool loadFailed = controller.lastError != null;

    return Column(
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            chapter?.title ?? '未选择章节',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge,
          ),
        ),
        if (meta.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            meta,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (loadFailed) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            '这一章打不开：文件可能已移动，或这个书库根的授权已失效',
            key: PlayerPage.playbackErrorKey,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    PlaybackController controller,
    BookDetail? book,
    QueueChapter? chapter,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final ({Duration start, Duration? end}) range = controller.range;
    final Duration? end = range.end ?? chapter?.duration;
    final bool known = end != null && end > range.start;
    final double minMs = range.start.inMilliseconds.toDouble();
    final double maxMs = known ? end.inMilliseconds.toDouble() : minMs + 1;
    final double positionMs =
        (_dragPositionMs ?? controller.position.inMilliseconds.toDouble())
            .clamp(minMs, maxMs)
            .toDouble();
    final Duration shown = Duration(milliseconds: positionMs.round());
    final Duration total = known ? end : shown;
    final String totalLabel = known ? _formatClock(total) : '--:--';

    final List<ChapterView> chapters = book?.chapters ?? const <ChapterView>[];
    final int index = chapter == null
        ? -1
        : chapters.indexWhere(
            (ChapterView item) => item.id == chapter.chapterId,
          );
    final int totalChapters = chapters.length;
    final double bookFraction = totalChapters == 0 || index < 0
        ? 0
        : (index + 1) / totalChapters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '${_formatClock(shown)} / $totalLabel',
              style: text.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            Text(
              totalChapters == 0
                  ? '章节识别中'
                  : '第 ${index < 0 ? '—' : index + 1} / $totalChapters 章',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            activeTrackColor: scheme.primary,
            inactiveTrackColor: scheme.surfaceContainerHighest,
            thumbColor: scheme.primary,
            overlayColor: scheme.primary.withValues(alpha: 0.14),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
          ),
          child: Semantics(
            label: known ? '章节进度' : '章节时长识别中',
            child: Slider(
              key: PlayerPage.chapterSliderKey,
              value: positionMs,
              min: minMs,
              max: maxMs,
              label: _formatClock(shown),
              onChanged: known
                  ? (double value) => setState(() => _dragPositionMs = value)
                  : null,
              onChangeEnd: known
                  ? (double value) {
                      setState(() => _dragPositionMs = null);
                      unawaited(
                        controller.seek(Duration(milliseconds: value.round())),
                      );
                    }
                  : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            Text(
              '全书',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadii.pill,
                child: LinearProgressIndicator(
                  value: bookFraction,
                  minHeight: 3,
                  color: scheme.secondary,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${(bookFraction * 100).round()}%',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondaryRow(
    BuildContext context,
    PlaybackController controller,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        _PillButton(
          key: PlayerPage.speedKey,
          icon: Icons.speed_rounded,
          label: '${_formatSpeed(controller.preferences.speed)}×',
          onPressed: () => unawaited(_openSpeedSheet(controller)),
        ),
        _PillButton(
          key: PlayerPage.sleepKey,
          icon: Icons.bedtime_outlined,
          label: _sleepLabel(controller.sleep),
          active: controller.sleep.isActive,
          onPressed: () => unawaited(_openSleepSheet(controller)),
        ),
        if (controller.canUndoRewind)
          _PillButton(
            key: PlayerPage.undoRewindKey,
            icon: Icons.undo_rounded,
            label: '撤销回退',
            onPressed: () => unawaited(_undoRewind(controller)),
          ),
      ],
    );
  }

  Widget _buildConsole(
    BuildContext context,
    PlaybackController controller,
    QueueChapter? chapter,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool playing =
        controller.state == EnginePlaybackState.playing ||
        controller.state == EnginePlaybackState.buffering;
    final bool enabled = chapter != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: AppRadii.xl,
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // 320dp 级窄屏：侧键收 48、中央键收 64，仍满足 ≥48dp 触控门禁。
              final bool compact = constraints.maxWidth < 296;
              final double sideSize = compact ? 48 : 56;
              final double centerSize = compact ? 64 : 72;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _ConsoleButton(
                    key: PlayerPage.previousKey,
                    icon: Icons.skip_previous_rounded,
                    label: '上一章',
                    size: sideSize,
                    onPressed: enabled ? controller.skipToPrevious : null,
                  ),
                  _ConsoleButton(
                    key: PlayerPage.rewindKey,
                    icon: Icons.fast_rewind_rounded,
                    label: '快退 15 秒',
                    size: sideSize,
                    onPressed: enabled
                        ? () => unawaited(
                            controller.seek(
                              controller.position - const Duration(seconds: 15),
                            ),
                          )
                        : null,
                  ),
                  SizedBox.square(
                    key: PlayerPage.playPauseKey,
                    dimension: centerSize,
                    child: Tooltip(
                      message: playing ? '暂停' : '播放',
                      child: FilledButton(
                        onPressed: enabled
                            ? () => unawaited(controller.togglePlayPause())
                            : null,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.square(centerSize),
                          shape: const CircleBorder(),
                        ),
                        child: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: centerSize / 2,
                        ),
                      ),
                    ),
                  ),
                  _ConsoleButton(
                    key: PlayerPage.forwardKey,
                    icon: Icons.fast_forward_rounded,
                    label: '快进 30 秒',
                    size: sideSize,
                    onPressed: enabled
                        ? () => unawaited(
                            controller.seek(
                              controller.position + const Duration(seconds: 30),
                            ),
                          )
                        : null,
                  ),
                  _ConsoleButton(
                    key: PlayerPage.nextKey,
                    icon: Icons.skip_next_rounded,
                    label: '下一章',
                    size: sideSize,
                    onPressed: enabled ? controller.skipToNext : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _undoRewind(PlaybackController controller) async {
    await controller.undoRewind();
    if (mounted) {
      setState(() {});
    }
  }

  /// 底部面板同样跟随系统「减弱动效」。
  AnimationStyle _sheetAnimation(BuildContext context) {
    return AnimationStyle(
      duration: AppMotion.resolve(context, AppDurations.standard),
      reverseDuration: AppMotion.resolve(context, AppDurations.fast),
    );
  }

  Future<void> _openSpeedSheet(PlaybackController controller) async {
    double draft = controller.preferences.speed;
    await showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: _sheetAnimation(context),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final ColorScheme scheme = Theme.of(context).colorScheme;
            final TextTheme text = Theme.of(context).textTheme;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('播放速度', style: text.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${_formatSpeed(draft)}×',
                    style: text.displaySmall?.copyWith(color: scheme.primary),
                  ),
                  Slider(
                    value: draft.clamp(0.5, 3.0).toDouble(),
                    min: 0.5,
                    max: 3.0,
                    divisions: 50,
                    label: '${_formatSpeed(draft)}×',
                    onChanged: (double value) {
                      final double next = (value * 20).round() / 20;
                      setSheetState(() => draft = next);
                      unawaited(controller.setSpeed(next));
                    },
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final double preset in const <double>[
                        0.75,
                        1,
                        1.25,
                        1.5,
                        1.75,
                        2,
                        2.5,
                        3,
                      ])
                        ChoiceChip(
                          label: Text('${_formatSpeed(preset)}×'),
                          selected: (draft - preset).abs() < 0.001,
                          onSelected: (_) {
                            setSheetState(() => draft = preset);
                            unawaited(controller.setSpeed(preset));
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () {
                          setSheetState(() => draft = 1);
                          unawaited(controller.setSpeed(1));
                        },
                        child: const Text('恢复 1×'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('完成'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openSleepSheet(PlaybackController controller) async {
    int customMinutes = 20;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: _sheetAnimation(context),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final ColorScheme scheme = Theme.of(context).colorScheme;
            final TextTheme text = Theme.of(context).textTheme;
            final SleepTimer sleep = controller.sleep;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    '睡眠守夜',
                    textAlign: TextAlign.center,
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    sleep.isActive ? _sleepLabel(sleep) : '未启用',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(
                      color: sleep.isActive
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('倒计时', style: text.titleSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      for (final int minutes in const <int>[15, 30, 45, 60])
                        ActionChip(
                          avatar: const Icon(
                            Icons.hourglass_bottom_rounded,
                            size: 16,
                          ),
                          label: Text('$minutes 分钟'),
                          onPressed: () {
                            controller.sleep.startCountdown(
                              Duration(minutes: minutes),
                            );
                            Navigator.of(sheetContext).pop();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: <Widget>[
                      Text('自定义 · $customMinutes 分钟', style: text.bodySmall),
                      const Spacer(),
                      Text(
                        '5–120',
                        style: text.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: customMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '$customMinutes 分钟',
                    onChanged: (double value) {
                      setSheetState(() => customMinutes = value.round());
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () {
                        controller.sleep.startCountdown(
                          Duration(minutes: customMinutes),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('开始倒计时'),
                    ),
                  ),
                  const Divider(height: AppSpacing.xl),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.menu_book_rounded),
                    title: const Text('播完本章即停'),
                    subtitle: const Text('本章结束后暂停，不改变整本书的进度'),
                    onTap: () {
                      controller.sleep.stopAtChapterEnd();
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                  if (sleep.isActive)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bedtime_off_outlined),
                      title: const Text('关闭睡眠守夜'),
                      onTap: () {
                        controller.sleep.cancel();
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openChapterSheet() async {
    final BookDetail? book = ref.read(currentBookProvider);
    final PlaybackController controller = ref.read(playbackControllerProvider);
    if (book == null) {
      return;
    }
    final String? currentId = controller.current?.chapterId;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: _sheetAnimation(context),
      builder: (BuildContext sheetContext) {
        final ColorScheme scheme = Theme.of(sheetContext).colorScheme;
        final TextTheme text = Theme.of(sheetContext).textTheme;
        return SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.sm,
                  AppSpacing.xl,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('章节目录', style: text.titleLarge),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '共 ${book.chapters.length} 章',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: CustomScrollView(
                  slivers: <Widget>[
                    for (final VolumeView volume in book.volumes) ...<Widget>[
                      SliverToBoxAdapter(
                        child: _VolumeHeader(
                          volume: volume,
                          count: volume.chapters.length,
                        ),
                      ),
                      SliverList.builder(
                        itemCount: volume.chapters.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ChapterView chapter = volume.chapters[index];
                          final bool current = chapter.id == currentId;
                          return _ChapterTile(
                            chapter: chapter,
                            current: current,
                            onTap: chapter.missing
                                ? null
                                : () {
                                    Navigator.of(sheetContext).pop();
                                    if (!current) {
                                      unawaited(
                                        controller.seekToChapter(chapter.id),
                                      );
                                    }
                                  },
                          );
                        },
                      ),
                    ],
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSpacing.xl),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String? _volumeTitleOf(BookDetail? book, String? volumeId) {
    if (book == null || volumeId == null) {
      return null;
    }
    for (final VolumeView volume in book.volumes) {
      if (volume.id == volumeId) {
        return volume.title;
      }
    }
    return null;
  }
}

/// 倍速 / 睡眠 / 撤销共用的小胶囊按钮。
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.active = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color foreground = active
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: foreground),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: foreground),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          backgroundColor: active
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          side: BorderSide(
            color: active ? scheme.primary : scheme.outlineVariant,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
        ),
      ),
    );
  }
}

/// 五键控制台的侧键（除中央播放键外的四个）。
class _ConsoleButton extends StatelessWidget {
  const _ConsoleButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 56,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        iconSize: size / 2,
        icon: Icon(icon),
      ),
    );
  }
}

class _VolumeHeader extends StatelessWidget {
  const _VolumeHeader({required this.volume, required this.count});

  final VolumeView volume;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xs,
      ),
      child: Row(
        children: <Widget>[
          Container(width: 3, height: 14, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              volume.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall,
            ),
          ),
          Text(
            '$count 章',
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
    return ListTile(
      enabled: !chapter.missing,
      selected: current,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.32),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      leading: Icon(
        current
            ? Icons.graphic_eq_rounded
            : chapter.missing
            ? Icons.link_off_rounded
            : Icons.article_outlined,
        size: 20,
        color: current ? scheme.primary : null,
      ),
      title: Text(
        chapter.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodyMedium?.copyWith(
          fontWeight: current ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: chapter.missing
          ? Text(
              '文件缺失，暂不可播放',
              style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            )
          : null,
      trailing: current
          ? Text(
              '正在播放',
              style: text.labelSmall?.copyWith(color: scheme.primary),
            )
          : null,
      onTap: onTap,
    );
  }
}

String _formatClock(Duration duration) {
  final Duration safe = duration.isNegative ? Duration.zero : duration;
  final int hours = safe.inHours;
  final String minutes = safe.inMinutes
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  final String seconds = safe.inSeconds
      .remainder(60)
      .toString()
      .padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _formatSpeed(double speed) {
  final String text = speed.toStringAsFixed(2);
  return text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String _sleepLabel(SleepTimer sleep) {
  return switch (sleep.mode) {
    SleepMode.off => '睡眠',
    SleepMode.endOfChapter => '本章后停',
    SleepMode.countdown => switch (sleep.remaining) {
      null => '倒计时',
      final Duration remaining => '剩余 ${_formatClock(remaining)}',
    },
  };
}
