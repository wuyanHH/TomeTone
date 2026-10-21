import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/contracts/storage/directory_picker.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/scan/scan_report.dart';
import 'package:tometone/ui/pages/library/library_root_location.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/scroll_marquee_text.dart';

/// 书库根区块的共享件（书库页使用）。
///
/// 这里是「来源与扫描」的交互主场，不是设置项的搬家终点：
/// - 添加是一个入口（页首 `+`，空态是主按钮），弹层里再分两条路；
/// - 删除、重命名属于单个根的管理动作，收进卡片的 `⋮` 菜单；
/// - 点卡片本身进入只读目录浏览，扫描留在卡片上是这一页的主要动作。
///
/// 所有写操作都只动数据库登记：**不移动、不重命名、不删除用户的任何文件**
/// （《架构需求文档》§9.2）。

/// 单个书库根的一次扫描状态（瞬时 UI 状态，不落库）。
@immutable
class RootScanState {
  /// 创建扫描状态。
  const RootScanState({
    this.scanning = false,
    this.report,
    this.error,
    this.collapsed = false,
  });

  /// 是否正在扫描。
  final bool scanning;

  /// 最近一次扫描结果（成功时）。
  final ScanReport? report;

  /// 最近一次扫描的失败原因（失败时）。
  final String? error;

  /// 结果面板是否已被收起。
  ///
  /// 成功结果只短暂停留（到点自动收起），失败结果常驻到用户手动收起；
  /// 两者都靠这个标记让面板不再铺在卡片上；下次扫描会带上新的状态覆盖它。
  final bool collapsed;
}

/// 书库根扫描编排（书库页专用）。
///
/// 扫描可能持续数十秒，且用户随时会切到书架看结果，所以扫描状态放在
/// provider 而不是页面 `State` 里：切走再回来，进度还在；结果面板的
/// 「已收起」标记也一起留在这里，切 tab 回来不会让收起过的结果又冒出来。
/// 扫描成功后的 `invalidate` 也不会因为页面被销毁而漏掉。
///
/// 这里只做「调用服务 + 转成界面状态 + 失效缓存」，扫描规则本身在
/// `LibraryScanner`，不在这里重复。
class LibraryScanController extends Notifier<Map<String, RootScanState>> {
  @override
  Map<String, RootScanState> build() => const <String, RootScanState>{};

  /// 扫描指定书库根。
  Future<void> scan(String libraryRootId) async {
    if (state[libraryRootId]?.scanning ?? false) {
      return;
    }
    _put(libraryRootId, const RootScanState(scanning: true));
    try {
      final ScanReport report = await ref
          .read(libraryRootServiceProvider)
          .scan(libraryRootId);
      if (!ref.mounted) {
        return;
      }
      _put(libraryRootId, RootScanState(report: report));
      // 扫描成功后必须同时失效书架与根列表：书架读的是缓存过的
      // `booksProvider`，只刷新根列表会让用户以为「扫描没扫到书」。
      ref.invalidate(booksProvider);
      ref.invalidate(libraryRootsProvider);
    } on StateError catch (error) {
      if (!ref.mounted) {
        return;
      }
      _put(libraryRootId, RootScanState(error: error.message));
    } on FileSystemException catch (error) {
      if (!ref.mounted) {
        return;
      }
      final String reason = error.osError?.message ?? error.message;
      _put(
        libraryRootId,
        RootScanState(error: '读取目录失败：${error.path ?? libraryRootId}（$reason）'),
      );
    } on Object {
      if (!ref.mounted) {
        return;
      }
      _put(
        libraryRootId,
        const RootScanState(error: '扫描意外中断。请确认目录仍然存在、且有读取权限，然后再试一次。'),
      );
    }
  }

  /// 丢掉某个书库根的扫描状态（根被移除后，这一条再也不会被渲染）。
  void forget(String libraryRootId) {
    if (!state.containsKey(libraryRootId)) {
      return;
    }
    state = <String, RootScanState>{...state}..remove(libraryRootId);
  }

  /// 收起某个书库根的结果面板（成功面板到点自动收，失败面板由用户收）。
  ///
  /// 只标记收起，不丢结果：下次扫描会用新状态整体覆盖它，形态也就自然复位。
  void collapse(String libraryRootId) {
    final RootScanState? current = state[libraryRootId];
    if (current == null || current.collapsed) {
      return;
    }
    state = <String, RootScanState>{
      ...state,
      libraryRootId: RootScanState(
        scanning: current.scanning,
        report: current.report,
        error: current.error,
        collapsed: true,
      ),
    };
  }

  void _put(String libraryRootId, RootScanState value) {
    state = <String, RootScanState>{...state, libraryRootId: value};
  }
}

/// 书库根扫描状态。
final NotifierProvider<LibraryScanController, Map<String, RootScanState>>
libraryScanProvider =
    NotifierProvider<LibraryScanController, Map<String, RootScanState>>(
      LibraryScanController.new,
    );

/// 书库根区块的测试键。
abstract final class LibraryRootsKeys {
  /// 书库根列表。
  static const Key rootsListKey = Key('library-roots-list');

  /// 书库根加载态。
  static const Key rootsLoadingKey = Key('library-roots-loading');

  /// 书库根读取失败。
  static const Key rootsErrorKey = Key('library-roots-error');

  /// 书库根空态。
  static const Key rootsEmptyKey = Key('library-roots-empty');

  /// 页首右上角的 `+`（有书库根时才出现）。
  static const Key addRootButtonKey = Key('library-add-button');
  static const Key addButtonKey = addRootButtonKey;

  /// 书源管理入口（在线书源，不混入本机根）。
  static const Key sourcesButtonKey = Key('library-sources-button');

  /// 空态里的主按钮（空态没有 `+` 可点，这里是唯一入口）。
  static const Key addRootKey = Key('library-add-root');

  /// 添加弹层里的「选择目录（SAF）」入口（推荐路径）。
  static const Key safPickKey = Key('library-pick-saf');

  /// 添加弹层里的「手动输入绝对路径」入口（高级兜底）。
  static const Key manualPathKey = Key('library-manual-path');

  /// 手动输入表单里返回入口列表。
  static const Key addSheetBackKey = Key('library-add-back');

  /// SAF 选择失败的就地提示（用户取消时不出现）。
  static const Key safErrorKey = Key('library-saf-error');

  /// 选中目录已在书库时的就地提示（没有写入任何东西）。
  static const Key duplicateNoticeKey = Key('library-root-duplicate');

  /// 添加弹层里的路径输入框。
  static const Key pathFieldKey = Key('library-root-path');

  /// 添加弹层里的显示名输入框。
  static const Key nameFieldKey = Key('library-root-name');

  /// 添加弹层里的提交按钮。
  static const Key submitRootKey = Key('library-root-submit');

  /// 页面上的一次性提示（添加成功 / 移除结果）。
  static const Key noticeKey = Key('library-root-notice');

  /// 某个书库根的扫描按钮。
  static Key scanKey(String rootId) => Key('library-scan-$rootId');

  /// 某个书库根的扫描摘要。
  static Key reportKey(String rootId) => Key('library-report-$rootId');

  /// 某个书库根的扫描失败提示。
  static Key scanErrorKey(String rootId) => Key('library-root-error-$rootId');

  /// 某个书库根结果面板右上角的收起按钮（成功/失败共用）。
  static Key dismissResultKey(String rootId) =>
      Key('library-dismiss-result-$rootId');

  /// 某个书库根的管理菜单（`⋮`）。
  static Key rootMenuKey(String rootId) => Key('library-root-menu-$rootId');

  /// 某个书库根卡片本身（点它进入只读目录浏览）。
  static Key rootCardKey(String rootId) => Key('library-root-card-$rootId');

  /// 管理菜单里的「重命名」。
  static Key renameRootKey(String rootId) => Key('library-root-rename-$rootId');

  /// 管理菜单里的「移除书库根」。
  static Key removeRootKey(String rootId) => Key('library-root-remove-$rootId');

  /// 重命名弹窗里的名字输入框。
  static const Key renameFieldKey = Key('library-rename-field');

  /// 重命名弹窗里的保存按钮。
  static const Key renameSubmitKey = Key('library-rename-submit');

  /// 移除确认弹窗。
  static const Key removeDialogKey = Key('library-remove-dialog');

  /// 移除确认弹窗里的确认按钮。
  static const Key removeConfirmKey = Key('library-remove-confirm');

  /// 移除确认弹窗里的取消按钮。
  static const Key removeCancelKey = Key('library-remove-cancel');
}

/// SAF 选择失败的就地提示：标题 + 说明。用户取消不是失败，不会用到它。
typedef SafPickFailure = ({String title, String message});

/// 手动输入时的预填路径。
///
/// 移动端返回空串（不预填）：在移动端能预填的只有应用私有目录，里面不会
/// 有音频，预填它只会制造一条扫不出东西的废根（用户反馈过）。手填入口本
/// 就只服务「确知完整路径」的特殊目录，推荐路径是系统选择器，所以这里留空
/// 并给出可读的示例提示。
///
/// 桌面端照旧预填用户主目录。
String defaultRootPathSuggestion() {
  if (Platform.isAndroid || Platform.isIOS) {
    return '';
  }
  final String? home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home != null && home.trim().isNotEmpty && Directory(home).existsSync()) {
    return home;
  }
  return Directory.current.path;
}

/// 写入前防重复：同一条来源重复添加只会产生重复书目。
///
/// 只做「同一字符串视为同一来源」的比对：本地路径与 SAF tree URI 都先
/// 去掉末尾分隔符再比较；不同写法指向同一目录的情况不在这一层猜。
bool hasLibraryRootWithUri(List<LibraryRootView> roots, String uri) {
  final String candidate = _normalizeRootUri(uri);
  if (candidate.isEmpty) {
    return false;
  }
  return roots.any((LibraryRootView root) {
    return _normalizeRootUri(root.uri) == candidate;
  });
}

String _normalizeRootUri(String uri) {
  final String trimmed = uri.trim();
  if (trimmed.length <= 1) {
    return trimmed;
  }
  return trimmed.replaceFirst(RegExp(r'[/\\]+$'), '');
}

/// 提示条的语气：成功、说明、失败。
enum LibraryNoticeTone {
  /// 成功（添加完成、移除完成）。
  success,

  /// 说明（例如「这个目录已经在书库里」）。
  info,

  /// 失败（写入没成功）。
  error,
}

/// 一次性提示条：书库页里所有「刚才发生了什么」都用同一种版式。
class LibraryRootNotice extends StatelessWidget {
  /// 创建提示条。
  const LibraryRootNotice({
    required this.message,
    required this.tone,
    super.key,
  });

  /// 提示内容。
  final String message;

  /// 语气（决定底色与图标）。
  final LibraryNoticeTone tone;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (Color background, Color foreground, IconData icon) = switch (tone) {
      LibraryNoticeTone.success => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.check_rounded,
      ),
      LibraryNoticeTone.info => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.info_outline_rounded,
      ),
      LibraryNoticeTone.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_outline_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(color: background, borderRadius: AppRadii.sm),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// 读列表时的行内加载提示。
class LibraryRootsLoading extends StatelessWidget {
  /// 创建加载提示。
  const LibraryRootsLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      key: LibraryRootsKeys.rootsLoadingKey,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '正在读取书库根…',
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 书库根读取失败：说明 + 重试。
class LibraryRootsError extends StatelessWidget {
  /// 创建失败面板。
  const LibraryRootsError({required this.onRetry, super.key});

  /// 重试回调（重新查询书库根列表）。
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      key: LibraryRootsKeys.rootsErrorKey,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadii.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.folder_off_outlined,
                size: 20,
                color: scheme.onErrorContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '书库根读取失败',
                  style: text.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '数据库暂时读不出书库根。已有书目不会丢失，重试即可。',
            style: text.bodySmall?.copyWith(color: scheme.onErrorContainer),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onErrorContainer,
                side: BorderSide(
                  color: scheme.onErrorContainer.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 空态：没有根的时候没有 `+` 可点，所以这里直接给一个主按钮。
class LibraryRootsEmpty extends StatelessWidget {
  /// 创建空态面板。
  const LibraryRootsEmpty({required this.onAdd, super.key});

  /// 打开「添加书库根」弹层。
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      key: LibraryRootsKeys.rootsEmptyKey,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.lg,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: AppRadii.lg,
              ),
              child: SizedBox.square(
                dimension: 56,
                child: Icon(
                  Icons.folder_special_outlined,
                  size: 26,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '还没有书库根',
            textAlign: TextAlign.center,
            style: text.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '先把一个装有音频的目录加进来。支持 mp3 / m4a / m4b / aac / '
            'flac / wav / ogg / opus；添加后点「扫描」建立书目。',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: LibraryRootsKeys.addRootKey,
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('添加书库根'),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '点开后可以选系统目录（推荐），也可以手动填绝对路径。',
            textAlign: TextAlign.center,
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// 一个书库根：名字与可读位置在上，扫描与菜单在下，进度与结果按需出现。
///
/// 路径用 [ScrollMarqueeText] 单行滚动：多层目录能完整展开，又不会换行把卡片
/// 撑高。点卡片本身进入只读浏览；扫描与 `⋮` 是独立手势，不会误触发进入。
class LibraryRootCard extends StatefulWidget {
  /// 创建根卡片。
  const LibraryRootCard({
    required this.root,
    required this.scan,
    required this.onScan,
    required this.onOpen,
    required this.onRename,
    required this.onRemove,
    required this.onDismissResult,
    super.key,
  });

  /// 这条根的数据。
  final LibraryRootView root;

  /// 这条根的扫描状态。
  final RootScanState scan;

  /// 触发扫描（一等操作，带进度与禁用状态）。
  final VoidCallback onScan;

  /// 进入这个根的只读目录浏览。
  final VoidCallback onOpen;

  /// 打开重命名弹窗。
  final VoidCallback onRename;

  /// 打开移除确认弹窗。
  final VoidCallback onRemove;

  /// 收起扫描结果面板（成功面板到点自动收，失败面板由用户收起）。
  final VoidCallback onDismissResult;

  @override
  State<LibraryRootCard> createState() => _LibraryRootCardState();
}

class _LibraryRootCardState extends State<LibraryRootCard> {
  /// 成功结果停留多久后自动收起。
  ///
  /// 失败结果不设时限：它常驻在卡片上，直到用户收起或下一次扫描
  /// —— 出错原因需要一直看得见，成功只是一次「刚才发生了什么」。
  static const Duration _successLinger = Duration(seconds: 6);

  static const double _badgeSize = 44;

  Timer? _autoDismiss;

  /// 已经排过自动收起的那一份成功结果（同一份不重复排）。
  ScanReport? _scheduledReport;

  @override
  void initState() {
    super.initState();
    _scheduleAutoDismiss();
  }

  @override
  void didUpdateWidget(LibraryRootCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleAutoDismiss();
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  /// 成功结果可见时排一次自动收起；扫描中 / 失败 / 已收起都会取消排队。
  void _scheduleAutoDismiss() {
    final ScanReport? report = widget.scan.report;
    final bool visible = report != null && !widget.scan.collapsed;
    if (!visible) {
      _cancelAutoDismiss();
      return;
    }
    if (identical(_scheduledReport, report)) {
      return;
    }
    _scheduledReport = report;
    _autoDismiss?.cancel();
    _autoDismiss = Timer(_successLinger, _dismissResult);
  }

  void _cancelAutoDismiss() {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    _scheduledReport = null;
  }

  void _dismissResult() {
    _cancelAutoDismiss();
    widget.onDismissResult();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final LibraryRootView root = widget.root;
    final RootScanState scan = widget.scan;
    final String location = readableLibraryRootLocation(root);
    final String lastScan = root.lastScanAt == null
        ? '从未扫描'
        : '上次扫描 · ${_formatTimestamp(root.lastScanAt!)}';
    final Color muted = scheme.onSurfaceVariant;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.lg,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        key: LibraryRootsKeys.rootCardKey(root.id),
        onTap: widget.onOpen,
        // 卡片整体可点，但读屏只把「上半张」当作一个入口；扫描、菜单
        // 仍是各自独立的按钮，避免被外层合成一个说不清的巨型按钮。
        excludeFromSemantics: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                button: true,
                label: '打开书库根「${root.displayName}」，位置 $location',
                onTap: widget.onOpen,
                child: ExcludeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: AppRadii.md,
                        ),
                        child: SizedBox.square(
                          dimension: _badgeSize,
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: 22,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              root.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Row(
                              children: <Widget>[
                                Icon(
                                  Icons.place_outlined,
                                  size: 12,
                                  color: muted,
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Expanded(
                                  child: ScrollMarqueeText(
                                    text: location,
                                    style: text.labelSmall?.copyWith(
                                      color: muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: muted.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Icon(Icons.schedule_rounded, size: 12, color: muted),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      lastScan,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: muted),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ScanButton(
                    root: root,
                    scanning: scan.scanning,
                    onScan: widget.onScan,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  _RootMenuButton(
                    root: root,
                    onRename: widget.onRename,
                    onRemove: widget.onRemove,
                  ),
                ],
              ),
              if (scan.scanning) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                const ClipRRect(
                  borderRadius: AppRadii.pill,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '正在扫描…大书库可能需要几十秒。',
                  style: text.labelSmall?.copyWith(color: muted),
                ),
              ],
              AnimatedSize(
                duration: AppMotion.resolve(context, AppDurations.standard),
                curve: AppDurations.standardCurve,
                alignment: Alignment.topCenter,
                child: _buildResult(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 结果面板：扫描中或已收起时不留空位，否则成功 / 失败各渲染一块。
  Widget _buildResult() {
    final RootScanState scan = widget.scan;
    if (scan.scanning || scan.collapsed) {
      return const SizedBox(width: double.infinity);
    }
    final String? error = scan.error;
    if (error != null) {
      return _resultPanel(
        _ScanErrorPanel(
          key: LibraryRootsKeys.scanErrorKey(widget.root.id),
          rootId: widget.root.id,
          message: error,
          onDismiss: _dismissResult,
        ),
      );
    }
    final ScanReport? report = scan.report;
    if (report != null) {
      return _resultPanel(
        _ScanReportPanel(
          key: LibraryRootsKeys.reportKey(widget.root.id),
          rootId: widget.root.id,
          report: report,
          onDismiss: _dismissResult,
        ),
      );
    }
    return const SizedBox(width: double.infinity);
  }

  Widget _resultPanel(Widget panel) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: panel,
    );
  }
}

/// 单个根的管理动作。
enum _RootMenuAction {
  /// 重命名（只改展示名）。
  rename,

  /// 移除登记（不动文件）。
  remove,
}

/// 根卡片上的 `⋮`：管理动作收在这里，卡片上只留扫描。
class _RootMenuButton extends StatelessWidget {
  const _RootMenuButton({
    required this.root,
    required this.onRename,
    required this.onRemove,
  });

  final LibraryRootView root;
  final VoidCallback onRename;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_RootMenuAction>(
      key: LibraryRootsKeys.rootMenuKey(root.id),
      tooltip: '「${root.displayName}」的管理',
      icon: const Icon(Icons.more_vert_rounded),
      onSelected: (_RootMenuAction action) {
        switch (action) {
          case _RootMenuAction.rename:
            onRename();
          case _RootMenuAction.remove:
            onRemove();
        }
      },
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<_RootMenuAction>>[
          PopupMenuItem<_RootMenuAction>(
            key: LibraryRootsKeys.renameRootKey(root.id),
            value: _RootMenuAction.rename,
            child: const _MenuRow(icon: Icons.edit_outlined, label: '重命名'),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<_RootMenuAction>(
            key: LibraryRootsKeys.removeRootKey(root.id),
            value: _RootMenuAction.remove,
            child: _MenuRow(
              icon: Icons.delete_outline_rounded,
              label: '移除书库根',
              color: scheme.error,
            ),
          ),
        ];
      },
    );
  }
}

/// 菜单项内容：图标 + 文字（比 ListTile 更紧凑，且颜色可控）。
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effective = color ?? Theme.of(context).colorScheme.onSurface;
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: effective),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: effective),
        ),
      ],
    );
  }
}

/// 扫描按钮：扫描中禁用，并把「正在进行」交给进度条与本行文案一起表达。
class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.root,
    required this.scanning,
    required this.onScan,
  });

  final LibraryRootView root;
  final bool scanning;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: !scanning,
      label: scanning
          ? '正在扫描书库根「${root.displayName}」'
          : '扫描书库根「${root.displayName}」',
      child: ExcludeSemantics(
        child: OutlinedButton(
          key: LibraryRootsKeys.scanKey(root.id),
          onPressed: scanning ? null : onScan,
          style: OutlinedButton.styleFrom(
            foregroundColor: scheme.primary,
            minimumSize: const Size(0, AppSizes.minTouchTarget),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            side: BorderSide(color: scheme.primary.withValues(alpha: 0.45)),
          ),
          child: scanning
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text('扫描中'),
                  ],
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.radar_rounded, size: 18),
                    SizedBox(width: AppSpacing.xs),
                    Text('扫描'),
                  ],
                ),
        ),
      ),
    );
  }
}

/// 结果面板右上角的收起按钮：图标按钮保持 48dp 触控目标，tooltip 给语义名。
class _DismissButton extends StatelessWidget {
  const _DismissButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final Key buttonKey;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: buttonKey,
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: 18,
      color: color,
      icon: const Icon(Icons.close_rounded),
    );
  }
}

/// 扫描摘要：默认只给结论，只有「用户此刻会困惑」的诊断才补一句。
///
/// 取舍（对齐用户反馈）：
/// - 有变化才带数字（`新增 1 册 · 2 章`），没变化就一句「没有发现新增或变更」；
/// - 去掉「用时 N 毫秒」——用户不关心，且每次都不一样，只是噪音；
/// - 「忽略 N 个非音频文件」「目录内共 N 册」这类诊断默认不铺：只有
///   `booksSeen == 0`（一个音频都没扫到，往往是把书加错了目录，例如把根
///   指向了应用私有目录）时，用户才正需要知道「为什么什么都没发生」，
///   这时才补一句解释。
(String, List<String>) _summarizeScan(ScanReport report) {
  if (report.booksSeen == 0) {
    return (
      '目录内没有音频文件',
      <String>[if (report.ignoredFiles > 0) '已忽略 ${report.ignoredFiles} 个其它文件'],
    );
  }

  final List<String> added = <String>[
    if (report.booksAdded > 0) '${report.booksAdded} 册',
    if (report.volumesAdded > 0) '${report.volumesAdded} 卷',
    if (report.chaptersAdded > 0) '${report.chaptersAdded} 章',
  ];
  final List<String> updates = <String>[
    if (report.booksUpdated > 0) '更新 ${report.booksUpdated} 册',
    if (report.chaptersUpdated > 0) '更新 ${report.chaptersUpdated} 章',
  ];
  final List<String> upkeep = <String>[
    if (report.chaptersMarkedMissing > 0)
      '标记缺失 ${report.chaptersMarkedMissing} 章',
    if (report.chaptersRestored > 0) '恢复 ${report.chaptersRestored} 章',
  ];
  final String headline = added.isNotEmpty
      ? '新增 ${added.join(' · ')}'
      : report.hasChanges
      ? '书目结构已更新'
      : '没有发现新增或变更';
  return (
    headline,
    <String>[
      if (updates.isNotEmpty) updates.join(' · '),
      if (upkeep.isNotEmpty) upkeep.join(' · '),
    ],
  );
}

/// 扫描摘要面板：成功后短暂停留，可手动收起；异常目录照样列出来。
class _ScanReportPanel extends StatelessWidget {
  const _ScanReportPanel({
    required this.rootId,
    required this.report,
    required this.onDismiss,
    super.key,
  });

  final String rootId;
  final ScanReport report;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final (String headline, List<String> details) = _summarizeScan(report);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: AppRadii.sm,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Icon(
              report.hasChanges
                  ? Icons.check_circle_outline_rounded
                  : Icons.task_alt_rounded,
              size: 16,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '扫描完成',
                    style: text.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    headline,
                    style: text.titleSmall?.copyWith(color: scheme.onSurface),
                  ),
                  for (final String detail in details) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      detail,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (report.failedPaths.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _failedPathsLabel(report.failedPaths),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: scheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _DismissButton(
            buttonKey: LibraryRootsKeys.dismissResultKey(rootId),
            tooltip: '收起扫描结果',
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// 扫描失败：具体原因常驻在卡片上（出错原因要一直看得见），可手动收起。
class _ScanErrorPanel extends StatelessWidget {
  const _ScanErrorPanel({
    required this.rootId,
    required this.message,
    required this.onDismiss,
    super.key,
  });

  final String rootId;
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '扫描没有完成',
                  style: text.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '确认目录仍然存在、且有读取权限后再试。',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          _DismissButton(
            buttonKey: LibraryRootsKeys.dismissResultKey(rootId),
            tooltip: '收起',
            color: scheme.onErrorContainer,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

/// SAF 选择失败：说明能做什么，不把原始异常直接摊给用户。
class _SafErrorPanel extends StatelessWidget {
  const _SafErrorPanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      key: LibraryRootsKeys.safErrorKey,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: scheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: text.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 移除一个书库根会连带清掉的书目范围（`onDelete: cascade` 的后果）。
@immutable
class LibraryRemovalImpact {
  /// 创建影响范围。
  const LibraryRemovalImpact({
    required this.books,
    required this.chapters,
    this.capped = false,
  });

  /// 该书库根下的书目数。
  final int books;

  /// 这些书目下的章节总数。
  final int chapters;

  /// 统计是否已经碰到查询上限（碰上了就只报「以上」）。
  final bool capped;

  /// 是否还没有任何书目。
  bool get isEmpty => books == 0;

  /// 界面文案：`3 册 · 12 章`。
  String get label {
    final String booksLabel = capped ? '$books 册以上' : '$books 册';
    final String chaptersLabel = capped ? '$chapters 章以上' : '$chapters 章';
    return '$booksLabel · $chaptersLabel';
  }
}

/// 移除书库根前的确认弹窗。
///
/// 两件事必须写在按钮上面：**影响多少册 / 多少章**，以及
/// **不会删除文件**（《架构需求文档》§9.2：不静默删数据）。
/// 返回 true 表示用户确认。
Future<bool> showRemoveRootDialog(
  BuildContext context, {
  required LibraryRootView root,
  LibraryRemovalImpact? impact,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final ColorScheme scheme = Theme.of(context).colorScheme;
      final TextTheme text = Theme.of(context).textTheme;
      final String impactLine = switch (impact) {
        null => '这本书库根下的书目数量暂时统计不出来；移除后，已经扫描出的书也会从书架一起消失。',
        LibraryRemovalImpact(isEmpty: true) => '这里还没有扫描出书目，移除只会清掉这条来源登记。',
        LibraryRemovalImpact() => '将移除 ${impact.label}的书目记录，这些书也会从书架消失。',
      };

      return AlertDialog(
        key: LibraryRootsKeys.removeDialogKey,
        title: const Text('移除书库根？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('「${root.displayName}」', style: text.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            // 弹窗要算固有宽度，这里用两行截断展示可读位置；目录再深，
            // 也不必在确认弹窗里铺一整串授权 URI。
            Text(
              readableLibraryRootLocation(root),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(impactLine, style: text.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: AppRadii.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.shield_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      '只会从听卷里移除这个来源：不会删除文件，也不会改动目录里的任何内容。',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            // 两种根的差别只在这里体现：系统授权目录被移除后授权也一起放弃。
            if (root.type == 'saf') ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '这个来源是系统授权目录：移除会一并放弃对它的系统授权，下次要重新选择并授权。',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              '重新添加同一个目录再扫描，书目可以重建；但已有的收听进度会一起清掉。',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            key: LibraryRootsKeys.removeCancelKey,
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: LibraryRootsKeys.removeConfirmKey,
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('移除'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// 重命名书库根的弹窗：只改展示名。保存返回新名字，取消返回 null。
Future<String?> showRenameRootDialog(
  BuildContext context, {
  required LibraryRootView root,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => _RenameRootDialog(root: root),
  );
}

class _RenameRootDialog extends StatefulWidget {
  const _RenameRootDialog({required this.root});

  final LibraryRootView root;

  @override
  State<_RenameRootDialog> createState() => _RenameRootDialogState();
}

class _RenameRootDialogState extends State<_RenameRootDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.root.displayName,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '名字不能为空');
      return;
    }
    Navigator.of(context).pop<String>(name);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('重命名书库根'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            key: LibraryRootsKeys.renameFieldKey,
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            onChanged: _error == null
                ? null
                : (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: '显示名',
              hintText: '例如：本机书库',
              errorText: _error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '只改这里显示的名字：目录、书目和收听进度都不变。',
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          key: LibraryRootsKeys.renameSubmitKey,
          onPressed: _submit,
          child: const Text('保存'),
        ),
      ],
    );
  }
}

/// 添加书库根的底部弹层。
///
/// 两个入口（推荐用系统选择器、手动填路径是高级兜底）都从 [LibraryRootsKeys.addRootButtonKey]
/// 或空态主按钮进来；SAF 的失败与重复提示留在弹层里，用户不用来回切换页面。
/// 添加成功时 `pop` 出显示名，由页面负责重新查询列表。
class LibraryAddRootSheet extends ConsumerStatefulWidget {
  /// 创建添加弹层。
  const LibraryAddRootSheet({required this.suggestedPath, super.key});

  /// 手动输入时预填的绝对路径。
  final String suggestedPath;

  @override
  ConsumerState<LibraryAddRootSheet> createState() =>
      _LibraryAddRootSheetState();
}

/// 弹层内的两步：先选方式，再按方式展开。
enum _AddRootStep {
  /// 两个入口。
  entries,

  /// 手动输入绝对路径。
  manualPath,
}

class _LibraryAddRootSheetState extends ConsumerState<LibraryAddRootSheet> {
  _AddRootStep _step = _AddRootStep.entries;

  /// 系统目录选择器是否正开着（避免连点弹出两次）。
  bool _pickingSaf = false;

  /// SAF 选择失败的原因，已转成给用户看的标题与说明；用户取消时为 null。
  SafPickFailure? _safError;

  /// 选中目录已在书库时的提示；没有写入任何东西。
  String? _duplicateName;

  late final TextEditingController _pathController = TextEditingController(
    text: widget.suggestedPath,
  );
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  bool _validateOnChange = false;
  String? _submitError;

  @override
  void dispose() {
    _pathController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// 系统目录选择器 → 落库 → 关掉弹层（页面负责重新查询）。
  ///
  /// 用户取消是正常操作，静默返回；失败只就地说明，不弹原始异常。
  /// 选中目录已在书库时不写入，只就地提示，避免同一目录产生重复书目。
  Future<void> _pickSafRoot() async {
    if (_pickingSaf) {
      return;
    }
    setState(() {
      _pickingSaf = true;
      _safError = null;
      _duplicateName = null;
    });

    try {
      final PickedDirectory? picked = await ref
          .read(directoryPickerProvider)
          .pickDirectory();
      if (!mounted) {
        return;
      }
      if (picked == null) {
        // 用户取消：不提示、不写入、不刷新列表，直接回到两个入口。
        setState(() => _pickingSaf = false);
        return;
      }
      final String name = picked.name.trim().isEmpty ? picked.uri : picked.name;
      final List<LibraryRootView> known =
          ref.read(libraryRootsProvider).value ?? const <LibraryRootView>[];
      if (hasLibraryRootWithUri(known, picked.uri)) {
        setState(() {
          _pickingSaf = false;
          _duplicateName = name;
        });
        return;
      }
      await ref
          .read(libraryRootServiceProvider)
          .addSafRoot(treeUri: picked.uri, displayName: picked.name);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop<String>(name);
    } on MissingPluginException {
      _failSafPick(
        '这里没有系统目录选择器',
        '当前平台没有接入目录选择，或应用不在 Android 上运行。请改用「手动输入绝对路径」。',
      );
    } on PlatformException catch (error) {
      if (error.code == 'busy') {
        _failSafPick('目录选择器正在使用', '已经有一个目录选择在进行，先完成那一次选择，再回来添加。');
      } else {
        _failSafPick('目录选择器没有打开', '系统没有返回选中的目录。稍后再试，或用「手动输入绝对路径」。');
      }
    } on Object {
      _failSafPick('书库根没有添加成功', '目录已经选中，但没有保存下来。请再选一次，或改用「手动输入绝对路径」。');
    }
  }

  void _failSafPick(String title, String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _pickingSaf = false;
      _safError = (title: title, message: message);
    });
  }

  String? _validatePath(String? value) {
    final String path = (value ?? '').trim();
    if (path.isEmpty) {
      return '请输入书库根的绝对路径';
    }
    if (!_isAbsolutePath(path)) {
      final String example = Platform.isWindows
          ? r'D:\Books'
          : '/storage/emulated/0/Books';
      return '请填写绝对路径，例如 $example';
    }
    if (!Directory(path).existsSync()) {
      return '目录不存在：$path';
    }
    return null;
  }

  Future<void> _submitManualPath() async {
    if (_submitting) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _submitError = null;
      _validateOnChange = true;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String path = _pathController.text.trim();
    final String name = _nameController.text.trim();
    // 写入前防重复：同一条来源重复添加只会产生重复书目。
    final List<LibraryRootView> known =
        ref.read(libraryRootsProvider).value ?? const <LibraryRootView>[];
    if (hasLibraryRootWithUri(known, path)) {
      setState(() {
        _submitError = '这个目录已经在书库里，不用重复添加。';
      });
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(libraryRootServiceProvider)
          .addLocalRoot(
            absolutePath: path,
            displayName: name.isEmpty ? null : name,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context)
          .pop<String>(name.isEmpty ? _lastPathSegment(path) : name);
    } on StateError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = error.message;
      });
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = '路径不可用：${error.message ?? path}';
      });
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _submitError = '书库根没有添加成功，请换一个目录再试。';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 写入 / 选目录进行中不允许下滑关闭：否则页面收不到结果，
    // 用户会以为没添加上。
    final bool busy = _submitting || _pickingSaf;

    return PopScope(
      canPop: !busy && _step == _AddRootStep.entries,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop || busy || _step == _AddRootStep.entries) {
          return;
        }
        // 手动输入时按返回：退回两个入口，而不是直接关掉弹层。
        setState(() => _validateOnChange = false);
        setState(() => _step = _AddRootStep.entries);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: AnimatedSize(
            duration: AppMotion.resolve(context, AppDurations.standard),
            curve: AppDurations.standardCurve,
            alignment: Alignment.topCenter,
            child: _step == _AddRootStep.entries
                ? _buildEntries(context)
                : _buildManualForm(context),
          ),
        ),
      ),
    );
  }

  /// 第一步：两条路摆明，推荐的那条在上。
  Widget _buildEntries(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool enabled = !_pickingSaf;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            '添加书库根',
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '扫描只读取目录里的音频文件，不会移动、重命名或删除任何内容。',
          textAlign: TextAlign.center,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        _AddEntryTile(
          key: LibraryRootsKeys.safPickKey,
          icon: Icons.folder_shared_outlined,
          title: '选择目录（SAF）',
          subtitle: '用系统文件选择器挑一个目录，并授予长期读取权限。',
          badge: '推荐',
          prominent: true,
          busy: _pickingSaf,
          busyLabel: '正在打开系统选择器…',
          onTap: enabled ? () => unawaited(_pickSafRoot()) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        _AddEntryTile(
          key: LibraryRootsKeys.manualPathKey,
          icon: Icons.keyboard_alt_outlined,
          title: '手动输入绝对路径',
          subtitle: Platform.isWindows
              ? r'手边有完整路径时用这个，例如 D:\Books。'
              : '只在你确知目录的完整路径时才用；一般目录请用上面的系统选择器。',
          onTap: enabled
              ? () => setState(() => _step = _AddRootStep.manualPath)
              : null,
        ),
        if (_duplicateName != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          LibraryRootNotice(
            key: LibraryRootsKeys.duplicateNoticeKey,
            tone: LibraryNoticeTone.info,
            message: '这个目录已经在书库里：「$_duplicateName」，没有重复添加。',
          ),
        ],
        if (_safError != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          _SafErrorPanel(title: _safError!.title, message: _safError!.message),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text(
          '系统选择器会授予长期读取权限。SAF 目录无法在添加时校验是否还能访问，'
          '真正读不到会在扫描摘要里列为「目录读取失败」。',
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  /// 第二步：手动输入绝对路径（原来的表单，入口从通栏按钮换成弹层里的第二个选项）。
  Widget _buildManualForm(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool isWindows = Platform.isWindows;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                key: LibraryRootsKeys.addSheetBackKey,
                onPressed: _submitting
                    ? null
                    : () => setState(() => _step = _AddRootStep.entries),
                tooltip: '返回上一步',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('手动输入绝对路径', style: text.titleLarge),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '填一个你现在就能读取的完整路径；一般目录请返回上一步，用系统选择器'
            '（推荐）。扫描只读取其中的音频文件，不会改动任何内容。',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            key: LibraryRootsKeys.pathFieldKey,
            controller: _pathController,
            enabled: !_submitting,
            autofocus: false,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autovalidateMode: _validateOnChange
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            validator: _validatePath,
            decoration: InputDecoration(
              labelText: '绝对路径',
              hintText: isWindows ? r'D:\Books' : '/storage/emulated/0/Books',
              prefixIcon: const Icon(Icons.folder_open_rounded, size: 20),
              errorMaxLines: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: LibraryRootsKeys.nameFieldKey,
            controller: _nameController,
            enabled: !_submitting,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => unawaited(_submitManualPath()),
            decoration: const InputDecoration(
              labelText: '显示名（可选）',
              hintText: '例如：本机书库',
              prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
            ),
          ),
          if (_submitError != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            LibraryRootNotice(
              tone: LibraryNoticeTone.error,
              message: _submitError!,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            '提示：这里要填一个你能读取的完整路径。不确定填什么就返回上一步，'
            '用系统选择器（推荐）。',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  key: LibraryRootsKeys.submitRootKey,
                  onPressed: _submitting
                      ? null
                      : () => unawaited(_submitManualPath()),
                  child: _submitting
                      // 大字号下按钮会变窄，只留转圈；「正在添加」交给语义标签。
                      ? Semantics(
                          label: '正在添加书库根',
                          child: const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Text('添加'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 添加弹层里的一个入口：图标 + 标题 + 说明，可选「推荐」角标。
class _AddEntryTile extends StatelessWidget {
  const _AddEntryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.prominent = false,
    this.busy = false,
    this.busyLabel,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final String? badge;

  /// 推荐路径：用主色容器打底，视觉上压过兜底入口。
  final bool prominent;
  final bool busy;
  final String? busyLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color background = prominent
        ? scheme.primaryContainer
        : scheme.surfaceContainerHigh;
    final Color foreground = prominent
        ? scheme.onPrimaryContainer
        : scheme.onSurface;
    final Color muted = prominent
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final Color border = prominent
        ? scheme.primary.withValues(alpha: 0.35)
        : scheme.outlineVariant.withValues(alpha: 0.7);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: busy ? '$title，正在进行' : '$title：$subtitle',
      child: ExcludeSemantics(
        child: Material(
          color: background,
          borderRadius: AppRadii.md,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(
                minHeight: AppSizes.minTouchTarget,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: AppRadii.md,
                border: Border.all(color: border),
              ),
              child: Row(
                children: <Widget>[
                  Icon(icon, size: 22, color: foreground),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium?.copyWith(
                                  color: foreground,
                                ),
                              ),
                            ),
                            if (badge != null) ...<Widget>[
                              const SizedBox(width: AppSpacing.sm),
                              _Badge(label: badge!, color: foreground),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          busy ? (busyLabel ?? subtitle) : subtitle,
                          style: text.bodySmall?.copyWith(color: muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (busy)
                    SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    )
                  else
                    Icon(Icons.chevron_right_rounded, color: muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 小角标（「推荐」）。
class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadii.pill,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// 时间戳：本地时区，精确到分钟，避免「3 天前」这类需要当前时间的表述。
String _formatTimestamp(DateTime value) {
  final DateTime local = value.toLocal();
  return '${local.year}-${_pad2(local.month)}-${_pad2(local.day)} '
      '${_pad2(local.hour)}:${_pad2(local.minute)}';
}

String _pad2(int value) => value.toString().padLeft(2, '0');

/// 读取失败的目录：给出具体路径，超出两条时说明还有几处。
String _failedPathsLabel(List<String> paths) {
  final String shown = paths.take(2).join('、');
  final String more = paths.length > 2 ? '（另有 ${paths.length - 2} 处）' : '';
  return '${paths.length} 处目录读取失败：$shown$more';
}

/// 绝对路径判定：POSIX / Android 根、UNC、Windows 盘符。
bool _isAbsolutePath(String path) {
  if (path.startsWith('/') || path.startsWith(r'\\')) {
    return true;
  }
  return RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
}

String _lastPathSegment(String path) {
  final String trimmed = path.replaceFirst(RegExp(r'[/\\]+$'), '');
  final int slash = trimmed.lastIndexOf(RegExp(r'[/\\]'));
  final String name = slash < 0 ? trimmed : trimmed.substring(slash + 1);
  return name.trim().isEmpty ? path : name.trim();
}
