import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书库（独立的第 4 个 tab，方案 A）。
///
/// 职责边界：书架只负责「看与听」，书库只负责「来源与扫描」。
///
/// 这一页在拆出来后重排过一次交互，不再是设置页分组的搬移：
/// - 添加收成一个入口 —— 页首右上角的 `+`（空态是面板里的主按钮），
///   点开是底部弹层，里面再分「系统选择器（推荐）」与「手动填路径」两条路；
/// - 管理属于单个根 —— 重命名、移除在卡片的 `⋮` 菜单里，扫描留在卡片上；
/// - 移除只说清楚后果再动手：弹层里先给出「会影响多少册 / 多少章」，
///   并写明不会删除文件（§9.2 数据安全铁律）。
///
/// 列表永远以 [libraryRootsProvider] 的查询结果为准，不做乐观更新：
/// 添加、移除、重命名都重新查询，界面只渲染服务端结果。
class LibraryPage extends ConsumerStatefulWidget {
  /// 创建书库页。
  const LibraryPage({super.key, this.suggestedRootPath});

  /// 添加书库根时预填的路径。
  ///
  /// 为 null 时由 [defaultRootPathSuggestion] 推导（移动端不预填、桌面端预填
  /// 主目录）；显式传空串表示「明确不预填」，只用于测试与特殊端形态注入。
  final String? suggestedRootPath;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  /// 统计影响范围时的查询上限：够大，碰到它只说明这家书库不正常。
  static const int _impactQueryLimit = 2000;

  /// 页面级一次性提示（添加成功 / 移除成功 / 移除失败），同一时刻只留一条。
  ({String message, LibraryNoticeTone tone})? _notice;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LibraryRootView>> rootsAsync = ref.watch(
      libraryRootsProvider,
    );
    final Map<String, RootScanState> scans = ref.watch(libraryScanProvider);
    final List<LibraryRootView> roots =
        rootsAsync.value ?? const <LibraryRootView>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _LibraryHeader(
                countLabel: _countLabel(rootsAsync),
                // 空态由空态自己的主按钮负责引导，`+` 只在有根时出现。
                onAddRoot: rootsAsync.hasValue && roots.isNotEmpty
                    ? () => unawaited(_openAddRootSheet())
                    : null,
              ),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildRootsSection(rootsAsync, roots, scans),
                    if (_notice != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),
                      LibraryRootNotice(
                        key: LibraryRootsKeys.noticeKey,
                        message: _notice!.message,
                        tone: _notice!.tone,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _countLabel(AsyncValue<List<LibraryRootView>> rootsAsync) {
    if (rootsAsync.hasError) {
      return '读取失败';
    }
    if (!rootsAsync.hasValue) {
      return '正在读取…';
    }
    return '${rootsAsync.value!.length} 个';
  }

  Widget _buildRootsSection(
    AsyncValue<List<LibraryRootView>> rootsAsync,
    List<LibraryRootView> roots,
    Map<String, RootScanState> scans,
  ) {
    if (rootsAsync.hasError) {
      return LibraryRootsError(
        onRetry: () {
          ref.invalidate(libraryRootsProvider);
        },
      );
    }
    if (!rootsAsync.hasValue) {
      return const LibraryRootsLoading();
    }
    if (roots.isEmpty) {
      return LibraryRootsEmpty(onAdd: () => unawaited(_openAddRootSheet()));
    }
    return Column(
      key: LibraryRootsKeys.rootsListKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final LibraryRootView root in roots)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: LibraryRootCard(
              root: root,
              scan: scans[root.id] ?? const RootScanState(),
              onScan: () => _scan(root),
              onRename: () => unawaited(_renameRoot(root)),
              onRemove: () => unawaited(_removeRoot(root)),
              onDismissResult: () =>
                  ref.read(libraryScanProvider.notifier).collapse(root.id),
            ),
          ),
      ],
    );
  }

  /// 打开「添加书库根」弹层：两个入口都在里面，成功后重新查询列表。
  Future<void> _openAddRootSheet() async {
    _clearNotice();
    final String suggested =
        widget.suggestedRootPath ?? defaultRootPathSuggestion();
    final String? addedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.resolve(context, AppDurations.standard),
        reverseDuration: AppMotion.resolve(context, AppDurations.fast),
      ),
      builder: (_) => LibraryAddRootSheet(suggestedPath: suggested),
    );
    if (!mounted || addedName == null) {
      return;
    }
    _showNotice('已添加「$addedName」。点这一行的「扫描」开始建立书目。');
    // 列表以重新查询为准：不复用弹层里输入的路径拼一条假记录。
    ref.invalidate(libraryRootsProvider);
  }

  /// 重命名：只改展示名，目录与书目都不动。
  Future<void> _renameRoot(LibraryRootView root) async {
    _clearNotice();
    final String? name = await showRenameRootDialog(context, root: root);
    if (!mounted || name == null || name == root.displayName) {
      return;
    }
    try {
      await ref.read(libraryRootServiceProvider).renameRoot(root.id, name);
    } on Object {
      _showNotice('重命名没有成功，请稍后再试。', tone: LibraryNoticeTone.error);
      return;
    }
    if (!mounted) {
      return;
    }
    ref.invalidate(libraryRootsProvider);
  }

  /// 移除登记：先问清楚，再动手。
  ///
  /// 统计与确认都在删除之前完成；数据库侧 `onDelete: cascade` 会连带清掉
  /// 这个根下的书 / 卷 / 章（以及它们的进度），但**不会碰用户的文件**。
  Future<void> _removeRoot(LibraryRootView root) async {
    _clearNotice();
    final LibraryRemovalImpact? impact = await _loadRemovalImpact(root.id);
    if (!mounted) {
      return;
    }
    final bool confirmed = await showRemoveRootDialog(
      context,
      root: root,
      impact: impact,
    );
    if (!mounted || !confirmed) {
      return;
    }
    try {
      await ref.read(libraryRootServiceProvider).removeRoot(root.id);
    } on Object {
      _showNotice(
        '「${root.displayName}」没有移除成功，请稍后再试。',
        tone: LibraryNoticeTone.error,
      );
      return;
    }
    if (!mounted) {
      return;
    }
    // 这根已经不存在了，它的扫描状态没有意义。
    ref.read(libraryScanProvider.notifier).forget(root.id);
    ref.invalidate(libraryRootsProvider);
    // 书架读的是同一批书：不失效的话会留下点不动的条目。
    ref.invalidate(booksProvider);
    _showNotice('已移除「${root.displayName}」。目录里的文件没有任何改动。');
  }

  /// 统计一个书库根下将被级联清掉的书目范围。
  ///
  /// 用一次针对该根的查询，而不是书架那页缓存：书架只取前 50 条，
  /// 用户却会拿弹窗里的数字去对照。查不到就退回书架缓存，
  /// 再不行如实说「统计不出来」，绝不编一个数字。
  Future<LibraryRemovalImpact?> _loadRemovalImpact(String rootId) async {
    try {
      final List<BookSummary> books = await ref
          .read(libraryQueriesProvider)
          .listBooks(libraryRootId: rootId, limit: _impactQueryLimit);
      return _summarizeImpact(books, capped: books.length >= _impactQueryLimit);
    } on Object {
      try {
        final List<BookSummary> cached = await ref.read(booksProvider.future);
        return _summarizeImpact(<BookSummary>[
          for (final BookSummary book in cached)
            if (book.libraryRootId == rootId) book,
        ], capped: false);
      } on Object {
        return null;
      }
    }
  }

  LibraryRemovalImpact _summarizeImpact(
    List<BookSummary> books, {
    required bool capped,
  }) {
    int chapters = 0;
    for (final BookSummary book in books) {
      chapters += book.totalChapters;
    }
    return LibraryRemovalImpact(
      books: books.length,
      chapters: chapters,
      capped: capped,
    );
  }

  void _scan(LibraryRootView root) {
    if (ref.read(libraryScanProvider)[root.id]?.scanning ?? false) {
      return;
    }
    _clearNotice();
    // 扫描不阻塞点击回调，也不在 build 里启动。
    unawaited(ref.read(libraryScanProvider.notifier).scan(root.id));
  }

  void _showNotice(
    String message, {
    LibraryNoticeTone tone = LibraryNoticeTone.success,
  }) {
    if (!mounted) {
      return;
    }
    setState(() => _notice = (message: message, tone: tone));
  }

  void _clearNotice() {
    if (_notice == null) {
      return;
    }
    setState(() => _notice = null);
  }
}

/// 页首题头：眉题 + 标题 + 根数量 + 一个添加入口（版式与书架一致）。
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.countLabel, this.onAddRoot});

  final String countLabel;

  /// 打开添加弹层；为空时不渲染 `+`（空态/加载态/失败态都交给正文自己说）。
  final VoidCallback? onAddRoot;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '书库 · LIBRARY',
            style: text.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('书库根', style: text.headlineMedium),
                ),
              ),
              Text(
                countLabel,
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (onAddRoot != null) ...<Widget>[
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  key: LibraryRootsKeys.addRootButtonKey,
                  onPressed: onAddRoot,
                  tooltip: '添加书库根',
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    iconSize: 24,
                  ),
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '每个根目录独立扫描。听卷只读取其中的音频文件，不会移动、重命名或删除任何内容。',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
