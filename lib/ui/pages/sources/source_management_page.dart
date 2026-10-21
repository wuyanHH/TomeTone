import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/source_engine_providers.dart';
import 'package:tometone/app/providers/source_providers.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/domain/sources/book_source.dart';
import 'package:tometone/domain/sources/discovery/source_failure.dart';
import 'package:tometone/domain/sources/discovery/source_models.dart';
import 'package:tometone/ui/pages/library/local_roots_section.dart';
import 'package:tometone/ui/pages/sources/source_edit_page.dart';
import 'package:tometone/ui/pages/sources/source_import_sheet.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书源管理页的稳定测试键。
abstract final class SourceManagementKeys {
  static const Key addButtonKey = Key('source-add');
  static const Key emptyStateKey = Key('source-empty');
  static const Key listKey = Key('source-list');
  static const Key loadingKey = Key('source-loading');
  static const Key errorStateKey = Key('source-error');
  static const Key deleteDialogKey = Key('source-delete-dialog');
  static const Key deleteBooksCheckboxKey = Key('source-delete-books');
  static const Key deleteConfirmKey = Key('source-delete-confirm');
  static const Key deleteCancelKey = Key('source-delete-cancel');
  static const Key testDialogKey = Key('source-test-dialog');
  static const Key testDialogCloseKey = Key('source-test-dialog-close');

  static Key menuKey(String id) => ValueKey<String>('source-menu-$id');

  static Key enabledSwitchKey(String id) =>
      ValueKey<String>('source-enabled-$id');

  static Key testActionKey(String id) => ValueKey<String>('source-test-$id');

  static Key httpBadgeKey(String id) => ValueKey<String>('source-http-$id');
}

/// 书源管理：列表、启用、编辑、删除与导入入口。
///
/// 列表永远来自重新查询，不做乐观更新；删除默认只软删除源记录，书目与
/// 进度保留，只有显式勾选才删除该源书目。
class SourceManagementPage extends ConsumerStatefulWidget {
  const SourceManagementPage({super.key});

  @override
  ConsumerState<SourceManagementPage> createState() =>
      _SourceManagementPageState();
}

class _SourceManagementPageState extends ConsumerState<SourceManagementPage> {
  late Future<List<BookSourceListItem>> _items;
  final Set<String> _updating = <String>{};

  @override
  void initState() {
    super.initState();
    _items = ref.read(bookSourceServiceProvider).listSources();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书源'),
        actions: <Widget>[
          IconButton(
            key: SourceManagementKeys.addButtonKey,
            tooltip: '导入书源',
            onPressed: _openImport,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<BookSourceListItem>>(
        future: _items,
        builder:
            (
              BuildContext context,
              AsyncSnapshot<List<BookSourceListItem>> snapshot,
            ) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  key: SourceManagementKeys.loadingKey,
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return _SourceError(onRetry: _reload);
              }
              final items = snapshot.data ?? const <BookSourceListItem>[];

              return ListView(
                key: SourceManagementKeys.listKey,
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: <Widget>[
                  if (items.isEmpty)
                    _SourceEmpty(onImport: _openImport)
                  else ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        '网络书源',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: <Widget>[
                          for (int i = 0; i < items.length; i++) ...<Widget>[
                            if (i > 0) const SizedBox(height: AppSpacing.md),
                            _SourceCard(
                              item: items[i],
                              busy: _updating.contains(items[i].source.id),
                              onToggle: (bool value) =>
                                  unawaited(_toggle(items[i], value)),
                              onTest: () => unawaited(_test(items[i])),
                              onEdit: () => unawaited(_edit(items[i])),
                              onDelete: () => unawaited(_delete(items[i])),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: AppSpacing.xxl),
                  const LocalRootsSection(),
                ],
              );
            },
      ),
    );
  }

  void _reload() {
    setState(() {
      _items = ref.read(bookSourceServiceProvider).listSources();
    });
  }

  Future<void> _openImport() async {
    final changed = await showSourceImportSheet(context);
    // 下滑关闭时返回 null；只要不是明确的全失败/取消，就重新查询兜底。
    if (!mounted || changed == false) {
      return;
    }
    _reload();
  }

  Future<void> _toggle(BookSourceListItem item, bool value) async {
    final id = item.source.id;
    if (_updating.contains(id)) {
      return;
    }
    setState(() => _updating.add(id));
    try {
      await ref.read(bookSourceServiceProvider).setEnabled(id, value);
      if (!mounted) {
        return;
      }
      _reload();
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('启用状态没有更新成功，请稍后再试。')));
    } finally {
      if (mounted) {
        setState(() => _updating.remove(id));
      }
    }
  }

  Future<void> _test(BookSourceListItem item) async {
    final id = item.source.id;
    if (_updating.contains(id)) {
      return;
    }
    setState(() => _updating.add(id));

    String message;
    try {
      final report = await ref.read(sourceDiscoveryProvider).test(item.source);
      message = _testSuccessMessage(report);
    } on SourceFailure catch (failure) {
      message = '失败 · ${failure.message}';
    } on Object {
      message = '失败 · 书源测试失败，请稍后重试。';
    } finally {
      if (mounted) {
        setState(() => _updating.remove(id));
      }
    }
    if (!mounted) {
      return;
    }

    _reload();
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          key: SourceManagementKeys.testDialogKey,
          title: const Text('测试书源'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              key: SourceManagementKeys.testDialogCloseKey,
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  String _testSuccessMessage(SourceTestReport report) {
    final parts = <String>[
      '成功',
      '${report.resultCount} 条',
      '${report.latency.inMilliseconds} ms',
    ];
    final sample = report.sampleTitle?.trim();
    if (sample != null && sample.isNotEmpty) {
      parts.add('示例《$sample》');
    }
    return parts.join(' · ');
  }

  Future<void> _edit(BookSourceListItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SourceEditPage(source: item.source),
      ),
    );
    if (!mounted || changed != true) {
      return;
    }
    _reload();
  }

  Future<void> _delete(BookSourceListItem item) async {
    final service = ref.read(bookSourceServiceProvider);
    final int bookCount;
    try {
      bookCount = await service.countBooks(item.source.id);
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('暂时无法统计该书源的书目，请稍后再试。')));
      return;
    }
    if (!mounted) {
      return;
    }

    final choice = await showDialog<_DeleteChoice>(
      context: context,
      builder: (BuildContext dialogContext) {
        var deleteBooks = false;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              key: SourceManagementKeys.deleteDialogKey,
              title: const Text('删除书源'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('确定删除「${item.source.name}」？'),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '默认只删除书源登记。已加入书架/书库的书目与进度会保留，'
                      '并标记为来源不可用。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (bookCount > 0) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      CheckboxListTile(
                        key: SourceManagementKeys.deleteBooksCheckboxKey,
                        value: deleteBooks,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool? value) {
                          setDialogState(() => deleteBooks = value ?? false);
                        },
                        title: const Text('同时删除该源的已存书目'),
                        subtitle: Text(
                          deleteBooks
                              ? '将删除 $bookCount 本书及其章节与进度，此操作不可撤销。'
                              : '这些书会保留，但会标记为来源不可用。',
                        ),
                      ),
                    ] else ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '该源下没有已存书目。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  key: SourceManagementKeys.deleteCancelKey,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  key: SourceManagementKeys.deleteConfirmKey,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () =>
                      Navigator.of(dialogContext)
                          .pop(_DeleteChoice(deleteBooks: deleteBooks)),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted || choice == null) {
      return;
    }

    try {
      await service.deleteSource(
        item.source.id,
        deleteBooks: choice.deleteBooks,
      );
    } on Object {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('书源没有删除成功，请稍后再试。')));
      return;
    }
    if (!mounted) {
      return;
    }
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          choice.deleteBooks
              ? '已删除书源「${item.source.name}」及相关书目。'
              : '已删除书源「${item.source.name}」，书目与进度已保留。',
        ),
      ),
    );
  }
}

class _DeleteChoice {
  const _DeleteChoice({required this.deleteBooks});

  final bool deleteBooks;
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.item,
    required this.busy,
    required this.onToggle,
    required this.onTest,
    required this.onEdit,
    required this.onDelete,
  });

  final BookSourceListItem item;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTest;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final BookSource source = item.source;
    final group = source.groupName?.trim();
    final health = switch (source.lastTestOk) {
      null => '未测试',
      true => '上次测试成功',
      false => '连续失败 ${source.consecutiveFailures} 次',
    };

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        source.name,
                        style: text.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        group == null || group.isEmpty ? '未分组' : group,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Switch(
                  key: SourceManagementKeys.enabledSwitchKey(source.id),
                  value: source.enabled,
                  onChanged: busy ? null : onToggle,
                ),
                PopupMenuButton<String>(
                  key: SourceManagementKeys.menuKey(source.id),
                  tooltip: '更多操作',
                  enabled: !busy,
                  onSelected: (String value) {
                    if (value == 'test') {
                      onTest();
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (_) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      key: SourceManagementKeys.testActionKey(source.id),
                      value: 'test',
                      child: const Text('测试'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('编辑'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('删除'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _MetaLabel(text: '书 ${item.bookCount}'),
                _MetaLabel(text: health),
                if (source.sourceUrl.startsWith('http://'))
                  _MetaLabel(
                    key: SourceManagementKeys.httpBadgeKey(source.id),
                    text: 'HTTP 明文',
                  ),
                if (!source.enabled) const _MetaLabel(text: '已停用'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaLabel extends StatelessWidget {
  const _MetaLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

class _SourceEmpty extends StatelessWidget {
  const _SourceEmpty({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Center(
      key: SourceManagementKeys.emptyStateKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.rss_feed, size: 48, color: scheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text('还没有书源', style: text.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '导入 Legado 听书源 JSON，开始发现和收听。',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.add_rounded),
              label: const Text('导入书源'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceError extends StatelessWidget {
  const _SourceError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: SourceManagementKeys.errorStateKey,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: AppSpacing.md),
            const Text('书源读取失败'),
            const SizedBox(height: AppSpacing.md),
            FilledButton.tonal(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
