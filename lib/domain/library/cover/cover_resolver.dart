import '../scan/natural_order.dart';
import 'cover_source.dart';

/// 一次封面解析结果。
class CoverResolution {
  /// 创建解析结果。
  const CoverResolution({required this.source, this.relativePath});

  /// 命中的档位。
  final CoverSource source;

  /// 封面图片相对**书库根**的路径。
  ///
  /// 为 `null` 的两种情形：
  /// - `typography`：本来就没有图片，UI 绘制字标；
  /// - `firstChapterEmbedded`：档位已判定，但内嵌图尚未抽取落盘（Phase 2 负责）。
  final String? relativePath;

  /// 是否有可直接展示的图片文件。
  bool get hasImage => relativePath != null;

  @override
  String toString() => 'CoverResolution(${source.name}, $relativePath)';
}

/// 封面五级继承的**纯解析逻辑**（《架构需求文档》§2.1）。
///
/// 只做"哪一级胜出"的判定，不碰文件系统、不碰数据库 —— 因此可以穷举测试，
/// 也保证 UI 与扫描器对"判级"的理解不会分叉。
abstract final class CoverResolver {
  /// 封面文件名优先级（不含扩展名，按小写比较）。
  ///
  /// 顺序即优先级：`cover.jpg` 胜过 `folder.png`。
  /// 不在列表中的图片名排到最后（仍可作为候选，避免漏掉 `001.jpg` 这类命名）。
  static const List<String> preferredFileNames = <String>[
    'cover',
    'folder',
    'front',
    'poster',
    'album',
    'artwork',
    '封面',
    '专辑封面',
  ];

  /// 视为封面的图片扩展名。
  static const Set<String> imageExtensions = <String>{
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  /// 解析**书**的封面：书根图 → 首卷反哺 → 首章内嵌 → 字标。
  ///
  /// [rootImages] / [firstVolumeImages] 均为相对书库根的完整路径。
  static CoverResolution resolveBook({
    required List<String> rootImages,
    required List<String> firstVolumeImages,
    bool firstChapterHasEmbeddedCover = false,
  }) {
    final root = pickPreferred(rootImages);
    if (root != null) {
      return CoverResolution(source: CoverSource.bookRoot, relativePath: root);
    }

    final volume = pickPreferred(firstVolumeImages);
    if (volume != null) {
      return CoverResolution(
        source: CoverSource.firstVolumeFeedback,
        relativePath: volume,
      );
    }

    if (firstChapterHasEmbeddedCover) {
      // 档位已定，但字节要等 Phase 2 抽取落盘。
      return const CoverResolution(source: CoverSource.firstChapterEmbedded);
    }

    return const CoverResolution(source: CoverSource.typography);
  }

  /// 解析**卷**的封面：卷目录图 → 书根图 → 字标。
  static CoverResolution resolveVolume({
    required List<String> volumeImages,
    required List<String> rootImages,
  }) {
    final own = pickPreferred(volumeImages);
    if (own != null) {
      return CoverResolution(
        source: CoverSource.volumeDirectory,
        relativePath: own,
      );
    }

    final root = pickPreferred(rootImages);
    if (root != null) {
      return CoverResolution(source: CoverSource.bookRoot, relativePath: root);
    }

    return const CoverResolution(source: CoverSource.typography);
  }

  /// 从候选里挑一张：先按文件名优先级，再按自然顺序（保证结果确定）。
  static String? pickPreferred(List<String> images) {
    final candidates = images.where(isCoverImage).toList(growable: false);
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.reduce((String best, String candidate) {
      final byPriority = priorityOf(candidate).compareTo(priorityOf(best));
      if (byPriority != 0) {
        return byPriority < 0 ? candidate : best;
      }
      return NaturalOrder.compare(candidate, best) < 0 ? candidate : best;
    });
  }

  /// 是否是可作为封面的图片。
  static bool isCoverImage(String path) {
    final name = _baseName(path);
    if (name.isEmpty || name.startsWith('.')) {
      return false;
    }
    final dot = name.lastIndexOf('.');
    if (dot <= 0 || dot == name.length - 1) {
      return false;
    }
    return imageExtensions.contains(name.substring(dot + 1).toLowerCase());
  }

  /// 名称优先级：越小越优先；未登记的名字统一为 [unranked]。
  static int priorityOf(String path) {
    final name = _baseName(path);
    final dot = name.lastIndexOf('.');
    final stem = (dot <= 0 ? name : name.substring(0, dot)).toLowerCase();
    final index = preferredFileNames.indexOf(stem);
    return index < 0 ? unranked : index;
  }

  /// 未登记名称的优先级（排在所有登记名称之后）。
  static const int unranked = 1 << 20;

  static String _baseName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash < 0 ? normalized : normalized.substring(slash + 1);
  }
}
