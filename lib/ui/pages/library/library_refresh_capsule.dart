import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/library/batch_refresh_controller.dart';
import '../../../domain/library/batch_refresh_state.dart';

/// 书库顶部微胶囊呼吸刷新进度指示器。
class LibraryRefreshCapsule extends ConsumerStatefulWidget {
  const LibraryRefreshCapsule({super.key});

  @override
  ConsumerState<LibraryRefreshCapsule> createState() => _LibraryRefreshCapsuleState();
}

class _LibraryRefreshCapsuleState extends ConsumerState<LibraryRefreshCapsule> {
  String? _dismissedMessage;

  @override
  Widget build(BuildContext context) {
    final BatchRefreshState state = ref.watch(batchRefreshControllerProvider);

    // 未在运行且无完成消息，或者该完成消息已被用户手动关闭，则不展示
    if (!state.isRunning && (state.message == null || state.message == _dismissedMessage)) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state.isRunning) {
      // 正在刷新状态
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withAlpha(220),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withAlpha(80),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '正在检查 ${state.completed}/${state.total} 本在线书更新...',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              onTap: () {
                ref.read(batchRefreshControllerProvider.notifier).cancel();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colorScheme.onPrimaryContainer.withAlpha(180),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 完成汇报胶囊
    final message = state.message!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withAlpha(220),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withAlpha(80),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '✓ $message',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              setState(() {
                _dismissedMessage = message;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: colorScheme.onSecondaryContainer.withAlpha(180),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
