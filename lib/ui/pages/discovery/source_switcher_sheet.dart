import 'package:flutter/material.dart';
import 'package:tometone/app/sources/book_source_service.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书源切换弹层的结果：选中某个源，或进入管理页。
class SourceSwitcherResult {
  const SourceSwitcherResult.select(this.sourceId) : manage = false;

  const SourceSwitcherResult.manage() : sourceId = null, manage = true;

  final String? sourceId;
  final bool manage;
}

/// 打开书源切换弹层。
Future<SourceSwitcherResult?> showSourceSwitcherSheet({
  required BuildContext context,
  required List<BookSourceListItem> sources,
  required String? selectedId,
}) {
  return showModalBottomSheet<SourceSwitcherResult>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return _SourceSwitcherSheet(sources: sources, selectedId: selectedId);
    },
  );
}

class _SourceSwitcherSheet extends StatelessWidget {
  const _SourceSwitcherSheet({required this.sources, required this.selectedId});

  final List<BookSourceListItem> sources;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    '切换书源',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sources.length,
              itemBuilder: (BuildContext context, int index) {
                final BookSourceListItem item = sources[index];
                final bool selected = item.source.id == selectedId;
                return ListTile(
                  key: SourceSwitcherKeys.itemKey(item.source.id),
                  selected: selected,
                  leading: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                  title: Text(
                    item.source.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle:
                      item.source.groupName == null ||
                          item.source.groupName!.trim().isEmpty
                      ? null
                      : Text(
                          item.source.groupName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  onTap: () =>
                      Navigator.of(context)
                          .pop(SourceSwitcherResult.select(item.source.id)),
                );
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            key: SourceSwitcherKeys.manageKey,
            leading: const Icon(Icons.tune_rounded),
            title: const Text('管理书源'),
            onTap: () =>
                Navigator.of(context).pop(const SourceSwitcherResult.manage()),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

/// 书源切换弹层的稳定测试键。
abstract final class SourceSwitcherKeys {
  static const Key manageKey = Key('source-switcher-manage');

  static Key itemKey(String id) => ValueKey<String>('source-switcher-$id');
}
