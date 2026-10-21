import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/network_cover.dart';

/// 在线书预览页的稳定测试键。
abstract final class OnlineBookPreviewKeys {
  static const Key loadingKey = Key('online-preview-loading');
  static const Key errorKey = Key('online-preview-error');
  static const Key retryKey = Key('online-preview-retry');
  static const Key titleKey = Key('online-preview-title');
  static const Key tocListKey = Key('online-preview-toc-list');
  static const Key partialTocKey = Key('online-preview-partial-toc');
  static const Key previewNoticeKey = Key('online-preview-notice');
  static const Key tocRetryKey = Key('online-preview-toc-retry');

  static Key chapterKey(int index) =>
      ValueKey<String>('online-preview-chapter-$index');
}

/// 在线书只读详情：加载书信息与目录，不写 `books` / `chapters` / 进度。
///
/// 加入书架与播放入口属于 M1-C；本页只显示信息、预览说明和只读目录。
class OnlineBookPreviewPage extends ConsumerStatefulWidget {
  /// 创建在线书预览页。
  const OnlineBookPreviewPage({
    super.key,
    required this.source,
    required this.item,
  });

  /// 当前书源。
  final BookSource source;

  /// 发现结果中的书目摘要，也是详情加载失败时的回退数据。
  final SourceBookSummary item;

  @override
  ConsumerState<OnlineBookPreviewPage> createState() =>
      _OnlineBookPreviewPageState();
}

class _OnlineBookPreviewPageState extends ConsumerState<OnlineBookPreviewPage> {
  SourceBookInfo? _info;
  SourceToc? _toc;
  SourceFailure? _infoFailure;
  SourceFailure? _tocFailure;
  bool _loading = true;
  bool _loadingToc = false;
  bool _introExpanded = false;
  int _generation = 0;

  SourceBookSummary get _display => _info ?? widget.item;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final int generation = ++_generation;
    if (mounted) {
      setState(() {
        _loading = true;
        _loadingToc = false;
        _info = null;
        _toc = null;
        _infoFailure = null;
        _tocFailure = null;
        _introExpanded = false;
      });
    }

    SourceBookInfo info;
    try {
      info = await ref
          .read(sourceDiscoveryProvider)
          .bookInfo(widget.source, widget.item.bookUrl);
    } on SourceFailure catch (failure) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loading = false;
        _infoFailure = failure;
      });
      return;
    } on Object {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loading = false;
        _infoFailure = const SourceFailure(
          kind: SourceFailureKind.rule,
          stage: SourceStage.bookInfo,
          message: '书源规则无法解析',
        );
      });
      return;
    }

    if (!mounted || generation != _generation) {
      return;
    }
    setState(() {
      _info = info;
    });

    try {
      final SourceToc toc = await ref
          .read(sourceDiscoveryProvider)
          .toc(widget.source, info);
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _toc = toc;
        _loading = false;
      });
    } on SourceFailure catch (failure) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loading = false;
        _tocFailure = failure;
      });
    } on Object {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loading = false;
        _tocFailure = const SourceFailure(
          kind: SourceFailureKind.rule,
          stage: SourceStage.toc,
          message: '书源规则无法解析',
        );
      });
    }
  }

  Future<void> _retryToc() async {
    final SourceBookInfo? info = _info;
    if (info == null) {
      await _load();
      return;
    }
    final int generation = ++_generation;
    setState(() {
      _loadingToc = true;
      _tocFailure = null;
    });

    try {
      final SourceToc toc = await ref
          .read(sourceDiscoveryProvider)
          .toc(widget.source, info);
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _toc = toc;
        _loadingToc = false;
      });
    } on SourceFailure catch (failure) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _tocFailure = failure;
        _loadingToc = false;
      });
    } on Object {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _tocFailure = const SourceFailure(
          kind: SourceFailureKind.rule,
          stage: SourceStage.toc,
          message: '书源规则无法解析',
        );
        _loadingToc = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '在线预览 · ${widget.source.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(
              key: OnlineBookPreviewKeys.loadingKey,
              child: CircularProgressIndicator(),
            )
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final SourceBookSummary display = _display;
    final SourceToc? toc = _toc;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _PreviewNotice(),
                if (_infoFailure != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _FailureBanner(
                    message: _infoFailure!.message,
                    onRetry: _load,
                  ),
                ],
                if (_tocFailure != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _TocFailure(
                    message: _tocFailure!.message,
                    loading: _loadingToc,
                    onRetry: _retryToc,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _BookHeader(
                  display: display,
                  titleKey: OnlineBookPreviewKeys.titleKey,
                ),
                if (_metaLine(display).isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _metaLine(display),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                if (display.intro != null && display.intro!.trim().isNotEmpty)
                  _IntroSection(
                    intro: display.intro!.trim(),
                    expanded: _introExpanded,
                    onToggle: () {
                      setState(() => _introExpanded = !_introExpanded);
                    },
                  ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  toc == null ? '目录暂不可用' : '目录 · ${toc.chapters.length} 章',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (toc != null && !toc.complete) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    key: OnlineBookPreviewKeys.partialTocKey,
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.xsValue),
                    ),
                    child: Text(
                      '目录未完整抓取，共 ${toc.chapters.length} 章',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (toc != null)
          SliverList(
            key: OnlineBookPreviewKeys.tocListKey,
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final SourceChapter chapter = toc.chapters[index];
              return ListTile(
                key: OnlineBookPreviewKeys.chapterKey(chapter.index),
                dense: true,
                leading: Text('${index + 1}'),
                title: Text(
                  chapter.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: chapter.isVip
                    ? Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      )
                    : null,
              );
            }, childCount: toc.chapters.length),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
      ],
    );
  }

  static String _metaLine(SourceBookSummary display) {
    final List<String> parts = <String>[];
    if (display.author != null && display.author!.trim().isNotEmpty) {
      parts.add('作者：${display.author!.trim()}');
    }
    if (display.narrator != null && display.narrator!.trim().isNotEmpty) {
      parts.add('演播：${display.narrator!.trim()}');
    }
    if (display.kind != null && display.kind!.trim().isNotEmpty) {
      parts.add(display.kind!.trim());
    }
    if (display.wordCount != null && display.wordCount!.trim().isNotEmpty) {
      parts.add(display.wordCount!.trim());
    }
    if (display.status != null && display.status!.trim().isNotEmpty) {
      parts.add(display.status!.trim());
    }
    return parts.join(' · ');
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: OnlineBookPreviewKeys.previewNoticeKey,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.xsValue),
      ),
      child: Text(
        '预览模式 · 不会写入书库',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: scheme.onPrimaryContainer),
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: OnlineBookPreviewKeys.errorKey,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadii.xsValue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onErrorContainer),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: OnlineBookPreviewKeys.retryKey,
              onPressed: () => unawaited(onRetry()),
              child: const Text('重试'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TocFailure extends StatelessWidget {
  const _TocFailure({
    required this.message,
    required this.loading,
    required this.onRetry,
  });

  final String message;
  final bool loading;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.xsValue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '目录暂不可用 · $message',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: OnlineBookPreviewKeys.tocRetryKey,
              onPressed: loading ? null : () => unawaited(onRetry()),
              child: loading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('重试目录'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.display, required this.titleKey});

  final SourceBookSummary display;
  final Key titleKey;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        NetworkCover(coverUrl: display.coverUrl, size: 96),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                display.title,
                key: titleKey,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (display.lastChapter != null &&
                  display.lastChapter!.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '最新：${display.lastChapter!.trim()}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _IntroSection extends StatelessWidget {
  const _IntroSection({
    required this.intro,
    required this.expanded,
    required this.onToggle,
  });

  final String intro;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final bool canExpand = intro.length > 80;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '简介',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            intro,
            maxLines: expanded ? null : 4,
            overflow: expanded ? null : TextOverflow.ellipsis,
          ),
          if (canExpand)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onToggle,
                child: Text(expanded ? '收起' : '展开'),
              ),
            ),
        ],
      ),
    );
  }
}
