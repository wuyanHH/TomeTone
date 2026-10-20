import 'package:drift/drift.dart';

import '../cover/cover_source.dart';

// 数据模型对应《架构需求文档》§8.1 / §8.2。
//
// 约定：
// - 所有业务主键为**不可变 ULID 文本**（§8.2「章节身份与重链」）：ID 一经生成即不变，
//   文件重新绑定只更新 `filePath`，不重写 ID —— 保障进度与统计归属连续。
// - 文件绑定键 = `libraryRootId + 规范化（NFC）相对路径`；`chapters` 冗余存储
//   `libraryRootId` 以便对绑定键建唯一索引（丢文件重链需要 O(log n) 定位）。
// - 时间列：drift 默认按 **UTC epoch 秒** 存储，读回为**本地 `DateTime`** —— 两者指向
//   同一瞬时，因此比较必须用 `.toUtc()`；毫秒精度会被截断（心跳 30s / 进度 10s 节流
//   均不依赖亚秒精度）。按"本地日期"聚合（365 天热力图）必须在查询侧转换，
//   不能假设库里存的是本地日期。
// - 所有外键开启 `PRAGMA foreign_keys`，删除父行前必须先决策（§9.2 不静默删数据）。

/// 书库根（§2.1「多书库根」/ §8.2）。
@TableIndex(name: 'library_roots_type', columns: {#type})
class LibraryRoots extends Table {
  /// ULID。
  TextColumn get id => text()();

  /// `local` / `saf` / `webdav` / `smb`。
  TextColumn get type => text()();

  /// 根 URI（本地绝对路径或 provider 句柄）。
  TextColumn get uri => text()();

  /// 展示名。
  TextColumn get displayName => text()();

  /// 最近一次扫描完成时间。
  DateTimeColumn get lastScanAt => dateTime().nullable()();

  /// 加入时间。
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 书（§2.1 拓扑推导：多卷嵌套 → 书 → 卷 → 章）。
@TableIndex(
  name: 'books_root_path_unique',
  columns: {#libraryRootId, #rootPath},
  unique: true,
)
@TableIndex(name: 'books_series', columns: {#seriesName, #seriesIndex})
class Books extends Table {
  /// ULID，不可变。
  TextColumn get id => text()();

  /// 所属书库根。
  TextColumn get libraryRootId =>
      text().references(LibraryRoots, #id, onDelete: KeyAction.cascade)();

  /// 书名（可被元数据覆盖层覆盖）。
  TextColumn get title => text()();

  /// 作者。
  TextColumn get author => text().nullable()();

  /// 演播者。
  TextColumn get narrator => text().nullable()();

  /// 系列名。
  TextColumn get seriesName => text().nullable()();

  /// 系列序号。
  IntColumn get seriesIndex => integer().nullable()();

  /// 书根相对路径（NFC 规范化，相对 `library_roots.uri`）。
  TextColumn get rootPath => text()();

  /// 封面路径（**相对书库根**，与 `chapters.file_path` 同语义）；
  /// 为空时由 UI 走几何字标兜底。
  TextColumn get coverPath => text().nullable()();

  /// 封面来源档位（§2.1 五级继承）。枚举顺序即优先级，见 [CoverSource]。
  ///
  /// SQL 默认 4 = `CoverSource.typography.rank`（字标兜底）。
  /// 静态类型是 `IntColumn`（DSL 的 `map` 只做标记），生成器会把 Dart 侧类型
  /// 提升为 `CoverSource`。
  IntColumn get coverSourceType => integer()
      .withDefault(const Constant(CoverSource.typographyRank))
      .map(const CoverSourceConverter())();

  /// `local` / `saf` / `webdav`。
  TextColumn get sourceType => text()();

  /// provider 侧源地址；本地源为空。
  TextColumn get sourceUri => text().nullable()();

  /// 章节总数（冗余，供书库列表直接展示）。
  IntColumn get totalChapters => integer().withDefault(const Constant(0))();

  /// 总时长毫秒（冗余，第二阶段异步回填）。
  IntColumn get totalDurationMs => integer().withDefault(const Constant(0))();

  /// 加入时间。
  DateTimeColumn get createdAt => dateTime()();

  /// 最近更新时间。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 卷（单卷平铺时也建一个逻辑卷，保证结构统一）。
@TableIndex(
  name: 'volumes_book_path_unique',
  columns: {#bookId, #path},
  unique: true,
)
class Volumes extends Table {
  /// ULID，不可变。
  TextColumn get id => text()();

  /// 所属书。
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();

  /// 卷名。
  TextColumn get title => text()();

  /// 卷序号（自然排序后的位置）。
  IntColumn get volumeIndex => integer()();

  /// 卷相对路径（相对书根；单卷平铺时为空串）。
  TextColumn get path => text()();

  /// 卷封面路径。
  TextColumn get coverPath => text().nullable()();

  /// 最近更新时间。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 章（§2.1 / §8.2）。
///
/// `missing = true` 表示文件消失：**保留记录与进度**，只标记缺失（§9.2）。
@TableIndex(
  name: 'chapters_binding_unique',
  columns: {#libraryRootId, #filePath},
  unique: true,
)
@TableIndex(name: 'chapters_book_index', columns: {#bookId, #chapterIndex})
@TableIndex(name: 'chapters_volume_index', columns: {#volumeId, #chapterIndex})
class Chapters extends Table {
  /// ULID，不可变。
  TextColumn get id => text()();

  /// 所属书。
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();

  /// 所属卷。
  TextColumn get volumeId =>
      text().references(Volumes, #id, onDelete: KeyAction.cascade)();

  /// 冗余书库根，用于对绑定键建唯一索引。
  TextColumn get libraryRootId =>
      text().references(LibraryRoots, #id, onDelete: KeyAction.cascade)();

  /// 章名。
  TextColumn get title => text()();

  /// 章序号（自然排序后的位置）。
  IntColumn get chapterIndex => integer()();

  /// 绑定键：相对书库根的 NFC 规范化路径。
  TextColumn get filePath => text()();

  /// provider 侧源地址；本地源为空。
  TextColumn get sourceUri => text().nullable()();

  /// 时长毫秒（第二阶段异步回填）。
  IntColumn get durationMs => integer().nullable()();

  /// 文件字节数（重链特征匹配用，§8.2）。
  IntColumn get sizeBytes => integer().nullable()();

  /// 文件是否缺失。缺失章节保留占位并高亮。
  BoolColumn get missing => boolean().withDefault(const Constant(false))();

  /// 元信息回填尝试次数（Phase 2 内部记账）。
  ///
  /// 为什么需要：回填队列是 `duration_ms IS NULL` + 排序 + 限量。若某章永久读不出
  /// 时长（坏文件 / 编码异常），它会一直留在队首，**饿死**后面所有章节。
  /// 连续失败达到上限后跳过它，保证队列整体推进。
  IntColumn get metadataAttempts => integer().withDefault(const Constant(0))();

  /// 最近更新时间。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 元数据覆盖层（§2.1 / §8.2）：独立存储，**不被重扫描覆盖**。
class BookMetadataOverrides extends Table {
  /// 对应书。
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();

  /// 覆盖书名。
  TextColumn get title => text().nullable()();

  /// 覆盖作者。
  TextColumn get author => text().nullable()();

  /// 覆盖演播者。
  TextColumn get narrator => text().nullable()();

  /// 覆盖系列名。
  TextColumn get seriesName => text().nullable()();

  /// 覆盖系列序号。
  IntColumn get seriesIndex => integer().nullable()();

  /// 覆盖简介。
  TextColumn get description => text().nullable()();

  /// 最近一次手动编辑时间（区分"扫描自动写入"与"用户手改"，用于不覆盖用户编辑）。
  DateTimeColumn get manualEditedAt => dateTime().nullable()();

  /// 最近更新时间。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{bookId};
}

/// 书标签（§2.1 书架元数据）：多值标签，一标签一行。
///
/// 主键 `(bookId, tag)` 天然去重：同书同标签只会有一行。
/// 文本在写入前经 `normalizeTags` 归一化（去空、去首尾空格、大小写不敏感去重）。
@TableIndex(name: 'book_tags_tag', columns: {#tag})
class BookTags extends Table {
  /// 对应书。
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();

  /// 标签文本（已归一化）。
  TextColumn get tag => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{bookId, tag};
}

/// 播放进度（§2.2「进度写入可靠性」）：每书一条，WAL + 关键事件立即写。
@TableIndex(name: 'playback_progress_updated', columns: {#updatedAt})
class PlaybackProgress extends Table {
  /// 对应书。
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();

  /// 当前章。
  TextColumn get chapterId =>
      text().references(Chapters, #id, onDelete: KeyAction.cascade)();

  /// 章内位置（毫秒）。
  IntColumn get positionMs => integer()();

  /// 最近更新时间 —— 书库"最近收听"排序依据。
  DateTimeColumn get updatedAt => dateTime()();

  /// 听完（finished）时间；`null` 表示尚未听完。
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{bookId};
}

/// 每书播放偏好（§2.2「每书播放偏好」）。
class PerBookPrefs extends Table {
  /// 对应书。
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();

  /// 倍速记忆（0.5–3.0）。
  RealColumn get speed => real().withDefault(const Constant(1.0))();

  /// 片头跳过秒数。
  IntColumn get skipIntroSec => integer().withDefault(const Constant(0))();

  /// 片尾跳过秒数。
  IntColumn get skipOutroSec => integer().withDefault(const Constant(0))();

  /// 回退阶梯覆盖（JSON；`null` 表示沿用全局阶梯）。
  TextColumn get rewindOverride => text().nullable()();

  /// 最近更新时间。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{bookId};
}

/// 聆听纪年心跳切片（§2.3）：**仅真实播放态**采计，30 秒一片。
@TableIndex(name: 'listening_records_started', columns: {#startedAt})
@TableIndex(name: 'listening_records_book', columns: {#bookId, #startedAt})
class ListeningRecords extends Table {
  /// ULID。
  TextColumn get id => text()();

  /// 对应书。
  TextColumn get bookId =>
      text().references(Books, #id, onDelete: KeyAction.cascade)();

  /// 对应章（可能为空：切章瞬间的切片归属不清）。
  TextColumn get chapterId => text().nullable().references(
    Chapters,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// 切片起始时间（UTC）。热力图按本地日期聚合。
  DateTimeColumn get startedAt => dateTime()();

  /// 切片时长（毫秒）。单条不超过 30_000 + 容差。
  IntColumn get durationMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 网盘 / 存储账户（§2.6 / §8.2）。
///
/// **凭据本体不在数据库**：只存安全存储中的引用 `credentialRef` 与刷新语义元数据。
@TableIndex(name: 'storage_accounts_default', columns: {#isDefault})
class StorageAccounts extends Table {
  /// ULID。
  TextColumn get id => text()();

  /// `webdav` / `smb` / `saf`。
  TextColumn get providerType => text()();

  /// 服务地址。
  TextColumn get baseUrl => text()();

  /// 平台安全存储中的凭据引用（不是凭据本身）。
  TextColumn get credentialRef => text()();

  /// 刷新语义元数据（JSON：认证类型 / 客户端类型等）。
  TextColumn get refreshMeta => text()();

  /// 是否为默认账户。
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  /// 最近更新时间。
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
