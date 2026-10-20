/// 在线书源的领域模型。
///
/// 只描述导入/管理所需字段；Legado 规则原文保存在 [rawJson]，由 M1-B 的规则
/// 引擎按需解析，避免领域层提前耦合具体选择器语法。
class BookSource {
  const BookSource({
    required this.id,
    required this.libraryRootId,
    required this.name,
    required this.sourceUrl,
    required this.sourceType,
    required this.rawJson,
    required this.header,
    required this.enabled,
    required this.enabledExplore,
    required this.customOrder,
    required this.createdAt,
    required this.updatedAt,
    this.groupName,
    this.exploreUrl,
    this.searchUrl,
    this.jsLib,
    this.concurrentRate,
    this.deletedAt,
    this.lastTestAt,
    this.lastTestOk,
    this.lastError,
    this.consecutiveFailures = 0,
  });

  final String id;
  final String libraryRootId;
  final String name;
  final String sourceUrl;
  final int sourceType;
  final String rawJson;
  final Map<String, String> header;
  final bool enabled;
  final bool enabledExplore;
  final int customOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? groupName;
  final String? exploreUrl;
  final String? searchUrl;
  final String? jsLib;
  final int? concurrentRate;
  final DateTime? deletedAt;
  final DateTime? lastTestAt;
  final bool? lastTestOk;
  final String? lastError;
  final int consecutiveFailures;

  bool get isDeleted => deletedAt != null;
  bool get isAvailable => !isDeleted && enabled;

  /// 用完整草稿覆盖可编辑字段；`null` 会真正清空分组/规则/并发限制。
  /// `id`、`libraryRootId`、`createdAt`、健康字段与 `deletedAt` 保持不变。
  /// 清空 `deletedAt` 仍走查询端口的 `revive`。
  BookSource applyDraft(BookSourceDraft draft, {required DateTime updatedAt}) {
    return BookSource(
      id: id,
      libraryRootId: libraryRootId,
      name: draft.name,
      sourceUrl: draft.sourceUrl,
      sourceType: draft.sourceType,
      rawJson: draft.rawJson,
      header: draft.header,
      groupName: draft.groupName,
      exploreUrl: draft.exploreUrl,
      searchUrl: draft.searchUrl,
      jsLib: draft.jsLib,
      enabled: draft.enabled,
      enabledExplore: draft.enabledExplore,
      customOrder: draft.customOrder,
      concurrentRate: draft.concurrentRate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      lastTestAt: lastTestAt,
      lastTestOk: lastTestOk,
      lastError: lastError,
      consecutiveFailures: consecutiveFailures,
    );
  }
}

class BookSourceDraft {
  const BookSourceDraft({
    required this.name,
    required this.sourceUrl,
    required this.sourceType,
    required this.rawJson,
    required this.header,
    this.groupName,
    this.exploreUrl,
    this.searchUrl,
    this.jsLib,
    this.enabled = true,
    this.enabledExplore = true,
    this.customOrder = 0,
    this.concurrentRate,
  });

  final String name;
  final String sourceUrl;
  final int sourceType;
  final String rawJson;
  final Map<String, String> header;
  final String? groupName;
  final String? exploreUrl;
  final String? searchUrl;
  final String? jsLib;
  final bool enabled;
  final bool enabledExplore;
  final int customOrder;
  final int? concurrentRate;
}
