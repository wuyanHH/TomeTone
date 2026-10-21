import '../../domain/sources/book_source.dart';
import '../../domain/sources/discovery/explore_category.dart';
import '../../domain/sources/discovery/source_models.dart';

/// 在线书源的只读引擎：发现、搜索、详情、目录、源测试。
abstract interface class SourceEngine {
  Future<SourcePage<SourceBookSummary>> explore(
    BookSource source,
    ExploreCategory category,
    int page,
  );

  Future<SourcePage<SourceBookSummary>> search(
    BookSource source,
    String keyword,
    int page,
  );

  Future<SourceBookInfo> bookInfo(BookSource source, String bookUrl);

  Future<SourceToc> toc(BookSource source, SourceBookInfo info);

  Future<ResolvedAudio> resolveAudio(BookSource source, SourceChapter chapter);

  Future<SourceTestReport> test(BookSource source);
}
