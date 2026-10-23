import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/domain/library/cover/cover_source.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/shelf/shelf_filter.dart';

void main() {
  const localBook = BookSummary(
    id: 'local_1',
    title: '凡人修仙传',
    libraryRootId: 'root_1',
    rootPath: 'fanren',
    coverSource: CoverSource.typography,
    totalChapters: 100,
    totalDurationMs: 3600000,
    missingChapters: 0,
    sourceType: 'local',
  );

  const onlineBook = BookSummary(
    id: 'online_1',
    title: '诡秘之主',
    libraryRootId: 'root_online',
    rootPath: '',
    coverSource: CoverSource.typography,
    totalChapters: 200,
    totalDurationMs: 7200000,
    missingChapters: 0,
    sourceType: 'online',
  );

  group('ShelfFilterState 来源过滤与默认状态', () {
    test('默认 source 为 all 且未激活', () {
      const state = ShelfFilterState();
      expect(state.source, ShelfSourceFilter.all);
      expect(state.isActive, isFalse);
    });

    test('当 source 设置为 local 或 online 时激活筛选', () {
      const localState = ShelfFilterState(source: ShelfSourceFilter.local);
      expect(localState.source, ShelfSourceFilter.local);
      expect(localState.isActive, isTrue);

      const onlineState = ShelfFilterState(source: ShelfSourceFilter.online);
      expect(onlineState.source, ShelfSourceFilter.online);
      expect(onlineState.isActive, isTrue);
    });

    test('copyWith 可以修改或保留 source 字段', () {
      const state = ShelfFilterState();
      final updated = state.copyWith(source: ShelfSourceFilter.local);
      expect(updated.source, ShelfSourceFilter.local);

      final unchanged = updated.copyWith(query: '凡人');
      expect(unchanged.source, ShelfSourceFilter.local);
      expect(unchanged.query, '凡人');
    });

    test('apply: ShelfSourceFilter.all 返回所有来源的书籍', () {
      const filter = ShelfFilterState(source: ShelfSourceFilter.all);
      final result = filter.apply([localBook, onlineBook]);
      expect(result, [localBook, onlineBook]);
    });

    test('apply: ShelfSourceFilter.local 只保留本地书籍', () {
      const filter = ShelfFilterState(source: ShelfSourceFilter.local);
      final result = filter.apply([localBook, onlineBook]);
      expect(result, [localBook]);
    });

    test('apply: ShelfSourceFilter.online 只保留在线书籍', () {
      const filter = ShelfFilterState(source: ShelfSourceFilter.online);
      final result = filter.apply([localBook, onlineBook]);
      expect(result, [onlineBook]);
    });

    test('apply: 结合来源与关键词联合过滤', () {
      const filter = ShelfFilterState(
        source: ShelfSourceFilter.online,
        query: '凡人',
      );
      // '凡人' 为本地书，在线筛选下应为空
      expect(filter.apply([localBook, onlineBook]), isEmpty);

      const matchFilter = ShelfFilterState(
        source: ShelfSourceFilter.online,
        query: '诡秘',
      );
      expect(matchFilter.apply([localBook, onlineBook]), [onlineBook]);
    });
  });
}
