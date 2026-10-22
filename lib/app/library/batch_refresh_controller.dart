import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/library/batch_refresh_state.dart';
import '../../domain/library/queries/online_library_queries.dart';
import '../providers/online_providers.dart';
import 'online_book_service.dart';

class BatchRefreshController extends Notifier<BatchRefreshState> {
  bool _cancelled = false;

  @override
  BatchRefreshState build() => const BatchRefreshState();

  Future<void> startRefresh({
    OnlineLibraryQueries? queries,
    OnlineBookService? service,
    void Function(int index)? onBookCompleted,
  }) async {
    final OnlineLibraryQueries effectiveQueries =
        queries ?? ref.read(onlineLibraryQueriesProvider);
    final OnlineBookService effectiveService =
        service ?? ref.read(onlineBookServiceProvider);

    final books = await effectiveQueries.getOnShelfOnlineBooks();
    if (books.isEmpty) {
      state = const BatchRefreshState(
        isRunning: false,
        total: 0,
        completed: 0,
        updatedCount: 0,
        message: '没有待刷新的在架在线书',
      );
      return;
    }

    _cancelled = false;
    state = BatchRefreshState(
      isRunning: true,
      total: books.length,
      completed: 0,
      updatedCount: 0,
      currentBookTitle: books.first.title,
    );

    int updatedCount = 0;
    int completed = 0;

    for (var i = 0; i < books.length; i++) {
      if (_cancelled) break;
      final book = books[i];

      state = state.copyWith(
        currentBookTitle: book.title,
      );

      try {
        final result = await effectiveService.refreshBookToc(book.id);
        if (result.newChaptersCount > 0) {
          updatedCount++;
        }
      } catch (_) {
        // 单本失败隔离，绝不中断全局批量刷新
      }

      completed++;
      state = state.copyWith(
        completed: completed,
        updatedCount: updatedCount,
      );

      onBookCompleted?.call(i);
    }

    final String finalMessage;
    if (_cancelled) {
      finalMessage = '刷新已取消';
    } else if (updatedCount > 0) {
      finalMessage = '已更新 $updatedCount 本书的最新章节';
    } else {
      finalMessage = '所有在线书已是最新目录';
    }

    state = state.copyWith(
      isRunning: false,
      currentBookTitle: null,
      message: finalMessage,
    );
  }

  void cancel() {
    _cancelled = true;
    if (state.isRunning) {
      state = state.copyWith(
        isRunning: false,
        message: '刷新已取消',
      );
    }
  }
}

final NotifierProvider<BatchRefreshController, BatchRefreshState>
    batchRefreshControllerProvider =
    NotifierProvider<BatchRefreshController, BatchRefreshState>(
  BatchRefreshController.new,
);
