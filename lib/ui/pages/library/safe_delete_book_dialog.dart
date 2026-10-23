import 'package:flutter/material.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 安全删除动作分类。
enum SafeDeleteAction {
  /// 在线书：仅移出书架（保留收听历史与退役章节）
  removeFromShelf,

  /// 从书库记录彻底删除（不删物理文件）
  deleteRecord,

  /// 本地书：删除记录并物理删除本地音频目录（高危）
  deleteRecordAndFiles,
}

/// 安全删除结果。
class SafeDeleteResult {
  const SafeDeleteResult({
    required this.action,
    this.deleteLocalFiles = false,
  });

  final SafeDeleteAction action;
  final bool deleteLocalFiles;
}

/// 弹出分级安全删除弹窗。
Future<SafeDeleteResult?> showSafeDeleteBookDialog(
  BuildContext context, {
  required BookSummary book,
  required bool isLocal,
  bool isSafRoot = false,
}) {
  return showDialog<SafeDeleteResult>(
    context: context,
    builder: (context) => _SafeDeleteDialog(
      book: book,
      isLocal: isLocal,
      isSafRoot: isSafRoot,
    ),
  );
}

class _SafeDeleteDialog extends StatefulWidget {
  const _SafeDeleteDialog({
    required this.book,
    required this.isLocal,
    required this.isSafRoot,
  });

  final BookSummary book;
  final bool isLocal;
  final bool isSafRoot;

  @override
  State<_SafeDeleteDialog> createState() => _SafeDeleteDialogState();
}

class _SafeDeleteDialogState extends State<_SafeDeleteDialog> {
  bool _deleteLocalFiles = false;

  bool get _isRestrictedRoot {
    final path = widget.book.rootPath.trim();
    return widget.isSafRoot || path.isEmpty || path == '/' || path == '.';
  }

  Future<void> _handleConfirmLocal() async {
    if (_deleteLocalFiles) {
      // 触发高危物理删除二次确认弹窗
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 36),
          title: const Text('不可撤销警告'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '您正在尝试物理删除本地音频文件及所属目录：\n\n${widget.book.rootPath}\n\n此操作将直接清空该磁盘目录，且无法撤销！',
                style: const TextStyle(height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('彻底物理删除'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        Navigator.of(context).pop(
          const SafeDeleteResult(
            action: SafeDeleteAction.deleteRecordAndFiles,
            deleteLocalFiles: true,
          ),
        );
      }
    } else {
      Navigator.of(context).pop(
        const SafeDeleteResult(
          action: SafeDeleteAction.deleteRecord,
          deleteLocalFiles: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!widget.isLocal) {
      // 在线书籍删除分级
      return AlertDialog(
        title: const Text('删除在线书目'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '请选择对《${widget.book.title}》的删除方式：',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Material(
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: AppRadii.sm,
              child: ListTile(
                title: const Text('仅移出书架', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('保留收听进度与历史记录，可在发现页或搜索重新入库'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).pop(
                    const SafeDeleteResult(
                      action: SafeDeleteAction.removeFromShelf,
                      deleteLocalFiles: false,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Material(
              color: colorScheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: AppRadii.sm,
              child: ListTile(
                title: Text(
                  '彻底删除',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: const Text('清空该书的所有已下载缓存、章节与收听进度记录'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).pop(
                    const SafeDeleteResult(
                      action: SafeDeleteAction.deleteRecord,
                      deleteLocalFiles: false,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('取消'),
          ),
        ],
      );
    }

    // 本地书籍删除分级与 SAF 护栏
    final isRestricted = _isRestrictedRoot;

    return AlertDialog(
      title: const Text('删除本地书目'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确认从书库中移除《${widget.book.title}》？'),
            const SizedBox(height: AppSpacing.md),
            Text(
              '从书库移除记录',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '书目将从书库列表中移除，收听进度将被清理。',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),

            // 物理删除复选框
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '同时删除本地音频目录',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                isRestricted
                    ? '当前书目挂载在书库根目录，已禁用文件清理以防误伤书库'
                    : '勾选后将永久删除磁盘上的音频文件（高危）',
                style: TextStyle(
                  fontSize: 12,
                  color: isRestricted ? Colors.orange.shade800 : colorScheme.error,
                ),
              ),
              value: isRestricted ? false : _deleteLocalFiles,
              onChanged: isRestricted
                  ? null
                  : (val) {
                      setState(() {
                        _deleteLocalFiles = val ?? false;
                      });
                    },
            ),

            if (isRestricted) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  borderRadius: AppRadii.xs,
                  border: Border.all(color: Colors.amber.shade700, width: 0.8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade800),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        '安全护栏：根目录与 SAF 保护已生效，禁止物理删除。',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        FilledButton(
          style: _deleteLocalFiles
              ? FilledButton.styleFrom(backgroundColor: colorScheme.error)
              : null,
          onPressed: _handleConfirmLocal,
          child: Text(_deleteLocalFiles ? '确认删除' : '确认移除'),
        ),
      ],
    );
  }
}
