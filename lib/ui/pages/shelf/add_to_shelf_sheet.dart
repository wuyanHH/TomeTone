import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 加入书架分类弹层的稳定测试键。
abstract final class AddToShelfKeys {
  static const Key searchKey = Key('add-shelf-search');
  static const Key newTagKey = Key('add-shelf-new-tag');
  static const Key addTagKey = Key('add-shelf-add-tag');
  static const Key saveKey = Key('add-shelf-save');
  static Key tagKey(String tag) => ValueKey<String>('add-shelf-tag-$tag');
}

/// 打开「加入书架」分类弹层。
///
/// 返回 `null` 表示取消；空集合表示未分类；否则为选中标签。
Future<Set<String>?> showAddToShelfSheet(
  BuildContext context, {
  required String bookTitle,
  Set<String> initialTags = const <String>{},
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) {
      return _AddToShelfSheet(bookTitle: bookTitle, initialTags: initialTags);
    },
  );
}

class _AddToShelfSheet extends ConsumerStatefulWidget {
  const _AddToShelfSheet({required this.bookTitle, required this.initialTags});

  final String bookTitle;
  final Set<String> initialTags;

  @override
  ConsumerState<_AddToShelfSheet> createState() => _AddToShelfSheetState();
}

class _AddToShelfSheetState extends ConsumerState<_AddToShelfSheet> {
  final TextEditingController _search = TextEditingController();
  final TextEditingController _newTag = TextEditingController();
  late final Set<String> _selected = <String>{...widget.initialTags};
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _newTag.dispose();
    super.dispose();
  }

  void _addNewTag() {
    final String tag = _newTag.text.trim();
    if (tag.isEmpty) {
      return;
    }
    final String folded = tag.toLowerCase();
    final bool exists = _selected.any((value) => value.toLowerCase() == folded);
    if (!exists) {
      setState(() => _selected.add(tag));
    }
    _newTag.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AsyncValue<List<String>> tagsAsync = ref.watch(bookTagsProvider);
    final List<String> tags = tagsAsync.value ?? const <String>[];
    final String query = _query.trim().toLowerCase();
    final List<String> visible = <String>[
      for (final String tag in tags)
        if (query.isEmpty || tag.toLowerCase().contains(query)) tag,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('加入书架', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '《${widget.bookTitle}》',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    key: AddToShelfKeys.searchKey,
                    controller: _search,
                    onChanged: (String value) => setState(() => _query = value),
                    decoration: const InputDecoration(
                      hintText: '搜索分类',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: tagsAsync.hasError
                    ? Text(
                        '分类读取失败，仍可直接保存',
                        style: TextStyle(color: scheme.error),
                      )
                    : tagsAsync.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : visible.isEmpty
                    ? Text(
                        tags.isEmpty ? '还没有分类，可以新建一个' : '没有匹配的分类',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      )
                    : Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: <Widget>[
                          for (final String tag in visible)
                            FilterChip(
                              key: AddToShelfKeys.tagKey(tag),
                              label: Text(tag),
                              selected: _selected.contains(tag),
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selected.add(tag);
                                  } else {
                                    _selected.remove(tag);
                                  }
                                });
                              },
                            ),
                          for (final String tag in _selected)
                            if (!tags.contains(tag))
                              FilterChip(
                                key: AddToShelfKeys.tagKey(tag),
                                label: Text(tag),
                                selected: true,
                                onSelected: (_) =>
                                    setState(() => _selected.remove(tag)),
                              ),
                        ],
                      ),
              ),
            ),
            Padding(
              padding: AppSpacing.pagePadding,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: AddToShelfKeys.newTagKey,
                      controller: _newTag,
                      onSubmitted: (_) => _addNewTag(),
                      decoration: const InputDecoration(
                        hintText: '新建分类',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    key: AddToShelfKeys.addTagKey,
                    tooltip: '添加分类',
                    onPressed: _addNewTag,
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: AddToShelfKeys.saveKey,
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: const Text('保存'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
