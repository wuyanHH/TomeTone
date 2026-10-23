import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/app/providers/online_providers.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/pages/library/preview_audio_player.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 换源候选源数据模型。
class SwitchSourceCandidate {
  final BookSource source;
  final String bookUrl;
  final String? latestChapter;
  final Duration? latency;
  final double matchScore;
  final String matchBadge;
  final String? sampleAudioUrl;

  const SwitchSourceCandidate({
    required this.source,
    required this.bookUrl,
    this.latestChapter,
    this.latency,
    this.matchScore = 1.0,
    required this.matchBadge,
    this.sampleAudioUrl,
  });
}

/// 沉浸式换源半屏抽屉 (SwitchSourceSheet)。
class SwitchSourceSheet extends ConsumerStatefulWidget {
  const SwitchSourceSheet({
    super.key,
    required this.bookId,
    required this.currentBookTitle,
    required this.currentSourceId,
    this.initialCandidates = const <SwitchSourceCandidate>[],
    this.onlineBookService,
    this.previewPlayer,
  });

  final String bookId;
  final String currentBookTitle;
  final String currentSourceId;
  final List<SwitchSourceCandidate> initialCandidates;
  final OnlineBookService? onlineBookService;
  final PreviewAudioPlayer? previewPlayer;

  @override
  ConsumerState<SwitchSourceSheet> createState() => _SwitchSourceSheetState();
}

class _SwitchSourceSheetState extends ConsumerState<SwitchSourceSheet> {
  late final PreviewAudioPlayer _player;
  late final bool _ownedPlayer;
  SwitchSourceCandidate? _selectedCandidate;
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    if (widget.previewPlayer != null) {
      _player = widget.previewPlayer!;
      _ownedPlayer = false;
    } else {
      _player = PreviewAudioPlayer();
      _ownedPlayer = true;
    }

    if (widget.initialCandidates.isNotEmpty) {
      // 默认选中除当前源外的第一个最佳候选
      _selectedCandidate = widget.initialCandidates.firstWhere(
        (c) => c.source.id != widget.currentSourceId,
        orElse: () => widget.initialCandidates.first,
      );
    }
  }

  @override
  void dispose() {
    if (_ownedPlayer) {
      _player.dispose();
    }
    super.dispose();
  }

  Future<void> _handleConfirmSwitch() async {
    final candidate = _selectedCandidate;
    if (candidate == null || _isSwitching) return;

    setState(() {
      _isSwitching = true;
    });

    await _player.stop();

    try {
      final OnlineBookService service =
          widget.onlineBookService ?? ref.read(onlineBookServiceProvider);
      final result = await service.switchSource(
        bookId: widget.bookId,
        targetSourceId: candidate.source.id,
        targetBookUrl: candidate.bookUrl,
        targetSource: candidate.source,
      );

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSwitching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('换源失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final candidates = widget.initialCandidates;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶端拖拽手柄
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: AppRadii.xs,
                ),
              ),
            ),

            // 头部标题与关闭按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '切换听书源',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '当前书目: ${widget.currentBookTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // 候选源列表
            Flexible(
              child: candidates.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          '未搜索到可用替换听书源',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: candidates.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        final isSelected = _selectedCandidate?.source.id == candidate.source.id;
                        final isCurrent = candidate.source.id == widget.currentSourceId;

                        return _CandidateCard(
                          candidate: candidate,
                          isSelected: isSelected,
                          isCurrent: isCurrent,
                          player: _player,
                          onTap: () {
                            setState(() {
                              _selectedCandidate = candidate;
                            });
                          },
                        );
                      },
                    ),
            ),

            // 底部确认动作栏
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: FilledButton(
                onPressed: _selectedCandidate == null || _isSwitching
                    ? null
                    : _handleConfirmSwitch,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.md,
                  ),
                ),
                child: _isSwitching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('确认换源'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.isSelected,
    required this.isCurrent,
    required this.player,
    required this.onTap,
  });

  final SwitchSourceCandidate candidate;
  final bool isSelected;
  final bool isCurrent;
  final PreviewAudioPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withAlpha(120);

    final backgroundColor = isSelected
        ? colorScheme.primaryContainer.withAlpha(40)
        : colorScheme.surface;

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.md,
        side: BorderSide(
          color: borderColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 选中指示器
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),

              // 候选书源信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            candidate.source.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: AppRadii.xs,
                            ),
                            child: Text(
                              '当前源',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // 最新章节
                    if (candidate.latestChapter != null)
                      Text(
                        candidate.latestChapter!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AppSpacing.xs),

                    // 徽标栏：延迟与匹配度
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        if (candidate.latency != null)
                          _Badge(
                            text: '${candidate.latency!.inMilliseconds}ms',
                            color: candidate.latency!.inMilliseconds < 400
                                ? Colors.green
                                : Colors.orange,
                          ),
                        _Badge(
                          text: candidate.matchBadge,
                          color: candidate.matchScore >= 0.8
                              ? colorScheme.primary
                              : Colors.amber.shade700,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 试听片头按钮
              if (candidate.sampleAudioUrl != null) ...[
                const SizedBox(width: AppSpacing.sm),
                ListenableBuilder(
                  listenable: player,
                  builder: (context, _) {
                    final isPlayingThis =
                        player.isPlaying && player.currentUrl == candidate.sampleAudioUrl;
                    return IconButton(
                      icon: Icon(
                        isPlayingThis
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline_rounded,
                        color: isPlayingThis ? colorScheme.error : colorScheme.primary,
                      ),
                      tooltip: isPlayingThis ? '停止试听' : '试听片头',
                      onPressed: () {
                        player.play(candidate.sampleAudioUrl!);
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        border: Border.all(color: color.withAlpha(100), width: 0.8),
        borderRadius: AppRadii.xs,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
