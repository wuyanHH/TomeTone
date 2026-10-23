import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/library/batch_refresh_controller.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/ui/app_tabs.dart';
import 'package:tometone/ui/pages/library/library_refresh_capsule.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/pages/library/local_roots_section.dart';
import 'package:tometone/ui/pages/sources/source_import_sheet.dart';
import 'package:tometone/ui/pages/sources/source_management_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书库页稳定测试定位键。
abstract final class LibraryKeys {
  /// 历史搜索框定位键（书库已不再渲染书籍搜索框，保留供测试断言已移除）。
  static const Key searchFieldKey = Key('library-search-field');

  /// 来源管理入口（复用 [LibraryRootsKeys.sourcesButtonKey]）。
  static const Key sourcesButtonKey = LibraryRootsKeys.sourcesButtonKey;

  /// 检查在线更新刷新按钮。
  static const Key refreshButtonKey = Key('library-refresh-button');

  /// 无来源友好指引空态。
  static const Key emptyKey = Key('library-empty');

  /// 导入书源入口。
  static const Key importSourceKey = Key('library-import-source');

  /// 添加本地目录入口。
  static const Key addLocalRootKey = Key('library-add-local-root');

  /// 跳转发现页找书入口。
  static const Key goToDiscoveryKey = Key('library-go-to-discovery');

  /// 管理书源按钮。
  static const Key manageSourcesKey = Key('library-manage-sources');

  /// 在线书源管理卡片。
  static const Key onlineSourcesCardKey = Key('library-online-sources-card');

  /// 资产统计汇总。
  static const Key statisticsKey = Key('library-statistics');

  /// 历史过滤 Chip 定位键（书库已不再渲染书籍列表过滤 Chip，保留供测试断言已移除）。
  static const Key sourceFilterAll = Key('library-filter-all');
  static const Key sourceFilterLocal = Key('library-filter-local');
  static const Key sourceFilterOnline = Key('library-filter-online');
  static const Key statusDropdownKey = Key('library-status-dropdown');
  static const Key tagDropdownKey = Key('library-tag-dropdown');
  static Key bookRowKey(String id) => ValueKey<String>('library-book-$id');
}

/// 书库来源与资产管理面板：专注于本机目录与在线书源的资产管理与同步。
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key, this.suggestedRootPath});

  final String? suggestedRootPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BookSummary>> booksAsync = ref.watch(booksProvider);
    final List<BookSummary> books = booksAsync.value ?? const <BookSummary>[];

    final AsyncValue<List<LibraryRootView>> rootsAsync = ref.watch(
      libraryRootsProvider,
    );
    final AsyncValue<List<BookSource>> sourcesAsync = ref.watch(
      bookSourcesProvider,
    );

    final List<LibraryRootView> roots =
        rootsAsync.value ?? const <LibraryRootView>[];
    final List<BookSource> sources =
        sourcesAsync.value ?? const <BookSource>[];
    final bool hasSources = roots.isNotEmpty || sources.isNotEmpty;

    final int localCount = books.where((BookSummary b) => !b.isOnline).length;
    final int onlineCount = books.where((BookSummary b) => b.isOnline).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('我的书库'),
            Text(
              '共 ${books.length} 册 · 本地 $localCount · 在线 $onlineCount',
              key: LibraryKeys.statisticsKey,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            key: LibraryKeys.refreshButtonKey,
            tooltip: '检查在线更新',
            onPressed: () async {
              await ref
                  .read(batchRefreshControllerProvider.notifier)
                  .startRefresh();
              ref.invalidate(booksProvider);
            },
            icon: const Icon(Icons.sync_rounded),
          ),
          IconButton(
            key: LibraryKeys.sourcesButtonKey,
            tooltip: '来源管理',
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const SourceManagementPage(),
                ),
              );
            },
            icon: const Icon(Icons.source_outlined),
          ),
        ],
      ),
      body: _buildBody(context, ref, hasSources, sources, rootsAsync, sourcesAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    bool hasSources,
    List<BookSource> sources,
    AsyncValue<List<LibraryRootView>> rootsAsync,
    AsyncValue<List<BookSource>> sourcesAsync,
  ) {
    if (rootsAsync.isLoading && sourcesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasSources) {
      return _buildEmptyState(context, ref);
    }

    return ListView(
      children: <Widget>[
        const LibraryRefreshCapsule(),
        LocalRootsSection(suggestedRootPath: suggestedRootPath),
        _buildOnlineSourcesSection(context, ref, sources),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  Widget _buildOnlineSourcesSection(
    BuildContext context,
    WidgetRef ref,
    List<BookSource> sources,
  ) {
    final int enabledCount =
        sources.where((BookSource s) => s.enabled).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '在线书源',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                key: LibraryKeys.manageSourcesKey,
                onPressed: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const SourceManagementPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('管理书源'),
              ),
            ],
          ),
        ),
        Padding(
          padding: AppSpacing.pagePadding,
          child: Card(
            key: LibraryKeys.onlineSourcesCardKey,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.lg,
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: AppRadii.md,
                        ),
                        child: Icon(
                          Icons.language_rounded,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '网络书源',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              sources.isEmpty
                                  ? '未添加任何在线书源'
                                  : '共 ${sources.length} 个书源 · $enabledCount 个已启用',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '管理并订阅公开网络书源，提供搜索检索、在线试听与章节批量更新。',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      OutlinedButton.icon(
                        key: LibraryKeys.importSourceKey,
                        onPressed: () {
                          unawaited(
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (_) => const SourceImportSheet(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('导入书源'),
                      ),
                      FilledButton.tonalIcon(
                        key: LibraryKeys.goToDiscoveryKey,
                        onPressed: () {
                          ref
                              .read(appTabProvider.notifier)
                              .select(AppTab.discovery);
                        },
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text('去发现找书'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      key: LibraryKeys.emptyKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.menu_book_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text('还没有书', style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '书库包含本机扫描与在线缓存的全部书目。导入网络书源或添加本机听书目录后开始建立书库。',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton.icon(
                  key: LibraryKeys.importSourceKey,
                  onPressed: () {
                    unawaited(
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => const SourceImportSheet(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('导入书源'),
                ),
                OutlinedButton.icon(
                  key: LibraryKeys.addLocalRootKey,
                  onPressed: () {
                    final String suggested =
                        suggestedRootPath ?? defaultRootPathSuggestion();
                    unawaited(
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) =>
                            LibraryAddRootSheet(suggestedPath: suggested),
                      ),
                    );
                  },
                  icon: const Icon(Icons.folder_open_outlined),
                  label: const Text('添加本机目录'),
                ),
                TextButton.icon(
                  key: LibraryKeys.goToDiscoveryKey,
                  onPressed: () {
                    ref.read(appTabProvider.notifier).select(AppTab.discovery);
                  },
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('去发现找书'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
