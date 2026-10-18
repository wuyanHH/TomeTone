import 'package:drift/drift.dart';

/// 封面来源档位（《架构需求文档》§2.1「封面五级继承」）。
///
/// 枚举顺序即优先级；文档的第 N 级对应 `rank == N - 1`：
///
/// | 文档级 | 枚举 | 含义 |
/// | :--- | :--- | :--- |
/// | 1 | `volumeDirectory` | 卷目录图片（`cover.jpg` / `folder.png` …） |
/// | 2 | `bookRoot` | 书根目录图片 |
/// | 3 | `firstVolumeFeedback` | 首卷封面反哺 |
/// | 4 | `firstChapterEmbedded` | 首章内嵌封面（ID3v2 APIC / MP4 covr） |
/// | 5 | `typography` | 几何字标兜底（国风主题色，无图片） |
enum CoverSource {
  /// 一级：卷目录图片。
  volumeDirectory(0),

  /// 二级：书根目录图片。
  bookRoot(1),

  /// 三级：首卷封面反哺。
  firstVolumeFeedback(2),

  /// 四级：首章内嵌封面。
  firstChapterEmbedded(3),

  /// 五级：几何字标兜底。
  typography(4);

  const CoverSource(this.rank);

  /// 持久化序号。**数值已落库，禁止重排**。
  final int rank;

  /// 字标兜底的序号 —— 供 Drift 列默认值使用（必须是编译期常量）。
  static const int typographyRank = 4;

  /// 是否表示"没有封面图片，由 UI 绘制字标"。
  bool get isTypography => this == CoverSource.typography;

  /// 是否需要读取音频内嵌封面（Phase 2 才可能拿到字节）。
  bool get needsEmbeddedArtwork => this == CoverSource.firstChapterEmbedded;

  /// 从持久化序号恢复。
  ///
  /// 未知序号回退到字标：旧版本读到新版本写入的档位时不崩溃，
  /// 只降级为"无封面"（§8.3 读旧写新 / 前向兼容）。
  static CoverSource fromRank(int rank) {
    for (final value in values) {
      if (value.rank == rank) {
        return value;
      }
    }
    return CoverSource.typography;
  }
}

/// Drift 类型转换器：`CoverSource ↔ int`。
class CoverSourceConverter extends TypeConverter<CoverSource, int> {
  /// 创建转换器。
  const CoverSourceConverter();

  @override
  CoverSource fromSql(int fromDb) => CoverSource.fromRank(fromDb);

  @override
  int toSql(CoverSource value) => value.rank;
}
