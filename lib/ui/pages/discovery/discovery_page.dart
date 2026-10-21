import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/explore_category.dart';
import 'package:tometone/ui/pages/discovery/discovery_source_card.dart';
import 'package:tometone/ui/pages/discovery/source_switcher_sheet.dart';
import 'package:tometone/ui/pages/sources/source_management_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 发现页的稳定测试键。
abstract final class DiscoveryPageKeys {
  static const Key emptyKey = Key('discovery-empty');
  static const Key importKey = Key('discovery-import');
  static const Key sourceCardKey = Key('discovery-source-card');
  static const Key switchKey = Key('discovery-switch-source');
  static const Key manageKey = Key('discovery-manage-sources');
  static const Key retryKey = Key('discovery-retry');
  static const Key loadingKey = Key('discovery-loading');
  static const Key errorKey = Key('discovery-error');

  static Key categoryKey(String name) =>
      ValueKey<String>('discovery-category-$name');
}

/// 发现页壳：加载启用的听书源，显示当前源与分类。
///
/// 本任务只负责书源与分类，不请求发现结果；搜索、分页与结果列表在任务 12
/// 接入。发现页不写 `books` / `chapters`，所有在线书操作仍由后续链路负责。
class DiscoveryPage extends ConsumerStatefulWidget {
  /// 创建发现页。
  const DiscoveryPage({super.key});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  List<BookSourceListItem> _sources = const <BookSourceListItem>[];
  BookSource? _source;
  List<ExploreCategory> _categories = const <ExploreCategory>[];
  ExploreCategory? _category;
  bool _loadingSources = true;
  bool _loadingPage = false;
  String? _failure;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSources());
  }

  Future<void> _loadSources() async {
    final int generation = ++_generation;
    if (mounted) {
      setState(() {
        _loadingSources = true;
        _failure = null;
      });
    }

    try {
      final List<BookSourceListItem> all = await ref
          .read(bookSourceServiceProvider)
          .listSources();
      final List<BookSourceListItem> enabled = all
          .where(
            (BookSourceListItem item) =>
                !item.source.isDeleted && item.source.enabled,
          )
          .toList(growable: false);
      if (!mounted || generation != _generation) {
        return;
      }

      final String? selectedId = ref.read(selectedSourceIdProvider);
      BookSourceListItem? selected;
      for (final BookSourceListItem item in enabled) {
        if (item.source.id == selectedId) {
          selected = item;
          break;
        }
      }
      selected ??= enabled.isEmpty ? null : enabled.first;

      final List<ExploreCategory> categories = selected == null
          ? const <ExploreCategory>[]
          : parseExploreCategories(
              exploreUrl: selected.source.exploreUrl,
              enabledExplore: selected.source.enabledExplore,
            );

      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _sources = enabled;
        _source = selected?.source;
        _categories = categories;
        _category = categories.isEmpty ? null : categories.first;
        _loadingSources = false;
        _loadingPage = false;
      });
      if (selected != null && selected.source.id != selectedId) {
        ref.read(selectedSourceIdProvider.notifier).state = selected.source.id;
      }
    } on Object {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _loadingSources = false;
        _failure = '书源读取失败，请稍后重试。';
      });
    }
  }

  Future<void> _openManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SourceManagementPage(),
      ),
    );
    if (mounted) {
      await _loadSources();
    }
  }

  Future<void> _openSwitcher() async {
    final SourceSwitcherResult? result = await showSourceSwitcherSheet(
      context: context,
      sources: _sources,
      selectedId: _source?.id,
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.manage) {
      await _openManagement();
      return;
    }
    final String? id = result.sourceId;
    if (id != null) {
      _selectSource(id);
    }
  }

  void _selectSource(String id) {
    BookSourceListItem? selected;
    for (final BookSourceListItem item in _sources) {
      if (item.source.id == id) {
        selected = item;
        break;
      }
    }
    if (selected == null || selected.source.id == _source?.id) {
      return;
    }

    _generation++;
    final List<ExploreCategory> categories = parseExploreCategories(
      exploreUrl: selected.source.exploreUrl,
      enabledExplore: selected.source.enabledExplore,
    );
    ref.read(selectedSourceIdProvider.notifier).state = id;
    setState(() {
      _source = selected!.source;
      _categories = categories;
      _category = categories.isEmpty ? null : categories.first;
      _loadingPage = false;
      _failure = null;
    });
  }

  void _selectCategory(ExploreCategory category) {
    if (_category?.name == category.name &&
        _category?.urlTemplate == category.urlTemplate) {
      return;
    }
    _generation++;
    setState(() {
      _category = category;
      _loadingPage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
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
                '发现 · DISCOVER',
                style: text.labelSmall?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '发现',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_source != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                DiscoverySourceCard(
                  key: DiscoveryPageKeys.sourceCardKey,
                  source: _source!,
                  switchKey: DiscoveryPageKeys.switchKey,
                  manageKey: DiscoveryPageKeys.manageKey,
                  onSwitch: () => unawaited(_openSwitcher()),
                  onManage: () => unawaited(_openManagement()),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loadingSources) {
      return const Center(
        key: DiscoveryPageKeys.loadingKey,
        child: CircularProgressIndicator(),
      );
    }
    if (_failure != null) {
      return _ErrorState(message: _failure!, onRetry: _loadSources);
    }
    if (_source == null) {
      return _EmptyState(onImport: _openManagement);
    }
    return _buildSourceBody();
  }

  Widget _buildSourceBody() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (_loadingPage) ...<Widget>[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_categories.isEmpty)
            Text(
              '该源没有发现分类，试试搜索',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final ExploreCategory category in _categories)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        key: DiscoveryPageKeys.categoryKey(category.name),
                        label: Text(category.name),
                        selected: _category?.name == category.name,
                        onSelected: (_) => _selectCategory(category),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onImport});

  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      child: Column(
        key: DiscoveryPageKeys.emptyKey,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.travel_explore_rounded, size: 56, color: scheme.primary),
          const SizedBox(height: AppSpacing.lg),
          Text('还没有书源', style: text.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '支持 Legado 听书源 JSON',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: DiscoveryPageKeys.importKey,
            onPressed: () => unawaited(onImport()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('导入书源'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      key: DiscoveryPageKeys.errorKey,
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off_rounded, size: 48, color: scheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: DiscoveryPageKeys.retryKey,
              onPressed: () => unawaited(onRetry()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
