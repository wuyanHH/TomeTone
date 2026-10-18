import 'media_format.dart';
import 'natural_order.dart';

/// 扫描期的一个条目（文件或目录），路径**相对书库根**。
class ScanNode {
  /// 创建条目。
  const ScanNode({
    required this.path,
    this.isDirectory = false,
    this.sizeBytes,
    this.modifiedAt,
  });

  /// 相对书库根的 NFC 规范化路径，`/` 分隔，无前导 `/`。
  final String path;

  /// 是否目录。
  final bool isDirectory;

  /// 字节数（目录或未知为 `null`）。
  final int? sizeBytes;

  /// 修改时间（未知为 `null`）。
  final DateTime? modifiedAt;

  /// 最后一段（文件名 / 目录名）。
  String get name {
    final slash = path.lastIndexOf('/');
    return slash < 0 ? path : path.substring(slash + 1);
  }

  /// 路径分段（丢弃空段）。
  List<String> get segments =>
      path.split('/').where((String segment) => segment.isNotEmpty).toList();

  @override
  String toString() => 'ScanNode($path, dir: $isDirectory)';
}

/// 章拓扑（相对书库根的绑定路径 + 全书序号）。
class ChapterTopology {
  /// 创建章拓扑。
  const ChapterTopology({
    required this.filePath,
    required this.title,
    required this.chapterIndex,
    this.sizeBytes,
    this.modifiedAt,
  });

  /// 绑定路径：相对书库根（NFC）。
  final String filePath;

  /// 显示标题（文件名去扩展名）。
  final String title;

  /// **全书内连续序号**（0 起）。卷内顺序即本节内升序。
  final int chapterIndex;

  /// 字节数。
  final int? sizeBytes;

  /// 修改时间。
  final DateTime? modifiedAt;

  @override
  String toString() => 'ChapterTopology($chapterIndex, $title)';
}

/// 卷拓扑。
class VolumeTopology {
  /// 创建卷拓扑。
  const VolumeTopology({
    required this.path,
    required this.title,
    required this.volumeIndex,
    required this.chapters,
  });

  /// 相对书根的卷路径；**根卷为空串**（单卷平铺）。
  final String path;

  /// 显示标题。
  final String title;

  /// 卷序号（0 起，根卷恒为 0）。
  final int volumeIndex;

  /// 章列表（已按自然顺序排序）。
  final List<ChapterTopology> chapters;

  @override
  String toString() =>
      'VolumeTopology($volumeIndex, $title, ${chapters.length})';
}

/// 书拓扑。
class BookTopology {
  /// 创建书拓扑。
  const BookTopology({
    required this.rootPath,
    required this.title,
    required this.volumes,
  });

  /// 相对书库根的书路径。
  final String rootPath;

  /// 显示标题（书目录名）。
  final String title;

  /// 卷列表（已排序）。
  final List<VolumeTopology> volumes;

  /// 章总数。
  int get totalChapters => volumes.fold(
    0,
    (int sum, VolumeTopology volume) => sum + volume.chapters.length,
  );

  @override
  String toString() => 'BookTopology($title, ${volumes.length} 卷)';
}

/// 拓扑推导（《架构需求文档》§2.1「扫描与建库」）。
///
/// ## 结构假设（显式声明，避免"猜"）
///
/// 书库根下按固定深度切分：
///
/// ```
/// 书库根/<书>/<章>.mp3              → 书 + 单个根卷        （单卷平铺）
/// 书库根/<书>/<卷>/<章>.mp3         → 书 + 多卷            （多卷嵌套）
/// ```
///
/// 即 [bookDepth] 层目录为书，书目录下第 1 层子目录为卷；卷内可继续嵌套，
/// 章顺序按**卷内相对路径**做自然排序。
///
/// 这个假设的代价：`书库根/作者/书名/` 这类两层组织会把"作者"当成书。
/// 需要时用 [bookDepth] 调整，或等 M2 引入可配置的书根识别 —— 现在**不猜**。
abstract final class TopologyBuilder {
  /// 允许的最大嵌套深度（防御异常目录结构导致的无限递归 / 巨量路径）。
  static const int maxDepth = 8;

  /// 由扁平条目列表推导书 / 卷 / 章拓扑。
  ///
  /// - 非音频、隐藏文件、目录条目、深度超过 [maxDepth] 的条目全部忽略；
  /// - 返回结果按书路径自然排序，保证输出稳定。
  static List<BookTopology> build(List<ScanNode> nodes, {int bookDepth = 1}) {
    if (bookDepth < 1) {
      throw ArgumentError.value(bookDepth, 'bookDepth', '必须 >= 1');
    }

    final byBook = <String, List<ScanNode>>{};
    for (final node in nodes) {
      if (node.isDirectory || !MediaFormat.isSupported(node.path)) {
        continue;
      }
      final segments = node.segments;
      if (segments.length <= bookDepth || segments.length > maxDepth) {
        continue;
      }
      final bookPath = segments.take(bookDepth).join('/');
      byBook.putIfAbsent(bookPath, () => <ScanNode>[]).add(node);
    }

    final books = <BookTopology>[
      for (final entry in byBook.entries)
        _buildBook(entry.key, entry.value, bookDepth),
    ];

    final order = NaturalOrder.sortedIndices(_bookTitles(books));
    return <BookTopology>[for (final index in order) books[index]];
  }

  static List<String> _bookTitles(List<BookTopology> books) => <String>[
    for (final book in books) book.rootPath,
  ];

  static BookTopology _buildBook(
    String bookPath,
    List<ScanNode> files,
    int bookDepth,
  ) {
    final bookTitle = bookPath.split('/').last;
    final prefix = '$bookPath/';

    // 卷路径（相对书根，根卷为 ''）→ 卷内条目。
    final byVolume = <String, List<({ScanNode node, String relativePath})>>{};
    for (final node in files) {
      if (!node.path.startsWith(prefix)) {
        continue;
      }
      final relativeToBook = node.path.substring(prefix.length);
      final slash = relativeToBook.indexOf('/');
      final volumePath = slash < 0 ? '' : relativeToBook.substring(0, slash);
      final relativeToVolume = slash < 0
          ? relativeToBook
          : relativeToBook.substring(slash + 1);
      byVolume
          .putIfAbsent(
            volumePath,
            () => <({ScanNode node, String relativePath})>[],
          )
          .add((node: node, relativePath: relativeToVolume));
    }

    // 卷顺序：根卷优先，其余按卷路径自然排序。
    final nestedVolumePaths = byVolume.keys
        .where((String path) => path.isNotEmpty)
        .toList();
    final nestedOrder = NaturalOrder.sortedIndices(nestedVolumePaths);
    final orderedVolumePaths = <String>[
      if (byVolume.containsKey('')) '',
      for (final index in nestedOrder) nestedVolumePaths[index],
    ];

    var chapterCursor = 0;
    final volumes = <VolumeTopology>[];
    for (
      var volumeIndex = 0;
      volumeIndex < orderedVolumePaths.length;
      volumeIndex++
    ) {
      final volumePath = orderedVolumePaths[volumeIndex];
      final entries = byVolume[volumePath]!;

      final order = NaturalOrder.sortedIndices(<String>[
        for (final entry in entries) entry.relativePath,
      ]);

      final chapters = <ChapterTopology>[];
      for (final index in order) {
        final entry = entries[index];
        chapters.add(
          ChapterTopology(
            filePath: entry.node.path,
            title: MediaFormat.titleOf(entry.node.name),
            chapterIndex: chapterCursor++,
            sizeBytes: entry.node.sizeBytes,
            modifiedAt: entry.node.modifiedAt,
          ),
        );
      }

      volumes.add(
        VolumeTopology(
          path: volumePath,
          // 根卷没有自己的目录名，用书名占位，保证列表视图永远有可读标题。
          title: volumePath.isEmpty ? bookTitle : volumePath,
          volumeIndex: volumeIndex,
          chapters: chapters,
        ),
      );
    }

    return BookTopology(rootPath: bookPath, title: bookTitle, volumes: volumes);
  }
}
