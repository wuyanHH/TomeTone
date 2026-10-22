import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/app/library/batch_refresh_controller.dart';
import 'package:tometone/app/library/online_book_service.dart';
import 'package:tometone/domain/library/batch_refresh_state.dart';
import 'package:tometone/domain/library/queries/online_library_queries.dart';
import 'package:tometone/domain/sources/book_source.dart';

class _FakeOnlineQueries implements OnlineLibraryQueries {
  List<OnlineBookRecord> onShelfBooks = [];

  @override
  Future<List<OnlineBookRecord>> getOnShelfOnlineBooks() async {
    return onShelfBooks;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOnlineBookService implements OnlineBookService {
  final Map<String, TocRefreshResult> resultsByBookId = {};
  final List<String> refreshedBookIds = [];
  bool shouldThrowOn(String bookId) => false;

  @override
  Future<TocRefreshResult> refreshBookToc(String bookId, {BookSource? source}) async {
    refreshedBookIds.add(bookId);
    if (bookId == 'b_error') {
      throw Exception('网络连接中断');
    }
    return resultsByBookId[bookId] ??
        const TocRefreshResult(
          isComplete: true,
          newChaptersCount: 0,
          updatedChaptersCount: 0,
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late ProviderContainer container;
  late _FakeOnlineQueries fakeQueries;
  late _FakeOnlineBookService fakeService;

  const b1 = OnlineBookRecord(
    id: 'b1',
    sourceId: 'src1',
    bookUrl: 'http://test/1',
    title: '书目一',
    libraryRootId: 'root1',
  );
  const b2 = OnlineBookRecord(
    id: 'b2',
    sourceId: 'src1',
    bookUrl: 'http://test/2',
    title: '书目二',
    libraryRootId: 'root1',
  );
  const b3 = OnlineBookRecord(
    id: 'b3',
    sourceId: 'src1',
    bookUrl: 'http://test/3',
    title: '书目三',
    libraryRootId: 'root1',
  );

  setUp(() {
    fakeQueries = _FakeOnlineQueries();
    fakeService = _FakeOnlineBookService();
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('iterates through all on-shelf online books and emits progressive state', () async {
    fakeQueries.onShelfBooks = [b1, b2, b3];
    fakeService.resultsByBookId['b1'] = const TocRefreshResult(
      isComplete: true,
      newChaptersCount: 2,
      updatedChaptersCount: 0,
    );
    fakeService.resultsByBookId['b2'] = const TocRefreshResult(
      isComplete: true,
      newChaptersCount: 0,
      updatedChaptersCount: 1,
    );
    fakeService.resultsByBookId['b3'] = const TocRefreshResult(
      isComplete: true,
      newChaptersCount: 1,
      updatedChaptersCount: 0,
    );

    final controller = container.read(batchRefreshControllerProvider.notifier);

    final states = <BatchRefreshState>[];
    container.listen(batchRefreshControllerProvider, (_, next) {
      states.add(next);
    });

    await controller.startRefresh(
      queries: fakeQueries,
      service: fakeService,
    );

    final finalState = container.read(batchRefreshControllerProvider);
    expect(finalState.isRunning, isFalse);
    expect(finalState.total, 3);
    expect(finalState.completed, 3);
    expect(finalState.updatedCount, 2); // b1 and b3 have new chapters
    expect(fakeService.refreshedBookIds, ['b1', 'b2', 'b3']);

    // 检查曾进入 isRunning 状态并汇报过进度
    expect(states.any((s) => s.isRunning && s.completed == 1), isTrue);
    expect(states.any((s) => s.isRunning && s.completed == 2), isTrue);
  });

  test('partial or individual book error does NOT abort whole batch', () async {
    const bError = OnlineBookRecord(
      id: 'b_error',
      sourceId: 'src1',
      bookUrl: 'http://test/err',
      title: '故障书目',
      libraryRootId: 'root1',
    );
    fakeQueries.onShelfBooks = [b1, bError, b3];
    fakeService.resultsByBookId['b3'] = const TocRefreshResult(
      isComplete: true,
      newChaptersCount: 1,
      updatedChaptersCount: 0,
    );

    final controller = container.read(batchRefreshControllerProvider.notifier);

    await controller.startRefresh(
      queries: fakeQueries,
      service: fakeService,
    );

    final finalState = container.read(batchRefreshControllerProvider);
    expect(finalState.isRunning, isFalse);
    expect(finalState.total, 3);
    expect(finalState.completed, 3);
    expect(finalState.updatedCount, 1);
    // 即使 b_error 抛出异常，b3 依然得到执行！
    expect(fakeService.refreshedBookIds, ['b1', 'b_error', 'b3']);
  });

  test('cancel immediately stops further book refresh iterations', () async {
    fakeQueries.onShelfBooks = [b1, b2, b3];

    final controller = container.read(batchRefreshControllerProvider.notifier);

    // 启动刷新并在第一本完成后立即取消
    final future = controller.startRefresh(
      queries: fakeQueries,
      service: fakeService,
      onBookCompleted: (index) {
        if (index == 0) {
          controller.cancel();
        }
      },
    );

    await future;

    final finalState = container.read(batchRefreshControllerProvider);
    expect(finalState.isRunning, isFalse);
    expect(fakeService.refreshedBookIds, hasLength(1));
    expect(fakeService.refreshedBookIds, ['b1']);
  });
}
