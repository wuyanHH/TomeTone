import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/scan/scan_report.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书库根区块的共享件（书库页使用）。
///
/// 方案 A：书库根从设置页拆到独立的第 4 个 tab。这些 widget、扫描编排与
/// 测试键整体从 `settings_page.dart` 迁出，逻辑原样复用、没有重写；
/// 设置页不再引用它们。

/// 单个书库根的一次扫描状态（瞬时 UI 状态，不落库）。
@immutable
class RootScanState {
  /// 创建扫描状态。
  const RootScanState({this.scanning = false, this.report, this.error});

  /// 是否正在扫描。
  final bool scanning;

  /// 最近一次扫描结果（成功时）。
  final ScanReport? report;

  /// 最近一次扫描的失败原因（失败时）。
  final String? error;
}

/// 书库根扫描编排（书库页专用）。
///
/// 扫描可能持续数十秒，且用户随时会切到书架看结果，所以扫描状态放在
/// provider 而不是页面 `State` 里：切走再回来，进度与摘要都还在；
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

/// 书库根区块的测试键（自设置页迁移，键名前缀改为 `library-`）。
abstract final class LibraryRootsKeys {
  /// 书库根列表。
  static const Key rootsListKey = Key('library-roots-list');

  /// 书库根加载态。
  static const Key rootsLoadingKey = Key('library-roots-loading');

  /// 书库根读取失败。
  static const Key rootsErrorKey = Key('library-roots-error');

  /// 书库根空态。
  static const Key rootsEmptyKey = Key('library-roots-empty');

  /// 手动添加书库根入口（空态与非空态各一个，互斥出现）。
  static const Key addRootKey = Key('library-add-root');

  /// 用系统目录选择器添加书库根（推荐路径，与 [addRootKey] 互斥出现）。
  static const Key safPickKey = Key('library-pick-saf');

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

  /// 添加成功后的就地提示。
  static const Key addedNoticeKey = Key('library-root-added');

  /// 某个书库根的扫描按钮。
  static Key scanKey(String rootId) => Key('library-scan-$rootId');

  /// 某个书库根的扫描摘要。
  static Key reportKey(String rootId) => Key('library-report-$rootId');

  /// 某个书库根的扫描失败提示。
  static Key scanErrorKey(String rootId) => Key('library-root-error-$rootId');
}

/// SAF 选择失败的就地提示：标题 + 说明。用户取消不是失败，不会用到它。
typedef SafPickFailure = ({String title, String message});

/// 推荐路径：移动端取应用私有目录，桌面端取用户主目录。
///
/// 不预填 `/sdcard`：Android 11+ 的分区存储会直接拒绝这种路径，
/// 预填一个必然失败的值只会制造一次无效报错。
String defaultRootPathSuggestion() {
  if (Platform.isAndroid || Platform.isIOS) {
    final Directory temp = Directory.systemTemp;
    final Directory privateDir = temp.parent;
    if (privateDir.path != temp.path && privateDir.existsSync()) {
      return privateDir.path;
    }
    return temp.path;
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

/// 空态：直接给出下一步，而不是只说「暂无数据」。
class LibraryRootsEmpty extends StatelessWidget {
  /// 创建空态面板。
  const LibraryRootsEmpty({
    required this.onAdd,
    required this.onPickSaf,
    required this.pickingSaf,
    this.error,
    super.key,
  });

  /// 打开「高级：手动输入路径」弹层。
  final VoidCallback onAdd;

  /// 打开系统目录选择器。
  final VoidCallback onPickSaf;

  /// 系统目录选择器是否正开着。
  final bool pickingSaf;

  /// SAF 选择失败的原因；用户取消时为 null。
  final SafPickFailure? error;

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
          LibraryRootActions(
            pickingSaf: pickingSaf,
            onPickSaf: onPickSaf,
            onAddManual: onAdd,
            error: error,
          ),
        ],
      ),
    );
  }
}

/// 书库根的两个添加入口：SAF 是推荐路径，手动输入路径是高级兜底。
class LibraryRootActions extends StatelessWidget {
  /// 创建添加入口。
  const LibraryRootActions({
    required this.pickingSaf,
    required this.onPickSaf,
    required this.onAddManual,
    this.error,
    super.key,
  });

  /// 系统目录选择器是否正开着。
  final bool pickingSaf;

  /// 打开系统目录选择器。
  final VoidCallback onPickSaf;

  /// 打开「高级：手动输入路径」弹层。
  final VoidCallback onAddManual;

  /// SAF 选择失败的原因；用户取消时为 null。
  final SafPickFailure? error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool enabled = !pickingSaf;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (error != null) ...<Widget>[
          _SafErrorPanel(title: error!.title, message: error!.message),
          const SizedBox(height: AppSpacing.md),
        ],
        FilledButton.icon(
          key: LibraryRootsKeys.safPickKey,
          onPressed: enabled ? onPickSaf : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          ),
          icon: pickingSaf
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.folder_shared_outlined, size: 18),
          label: Text(pickingSaf ? '正在打开系统选择器…' : '选择目录（SAF）'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: LibraryRootsKeys.addRootKey,
          onPressed: enabled ? onAddManual : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppSizes.minTouchTarget),
          ),
          icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
          label: const Text('高级：手动输入路径'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '系统选择器会授予长期读取权限。SAF 目录无法在添加时校验是否还能访问，'
          '真正读不到会在扫描摘要里列为「目录读取失败」。',
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
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

/// 添加成功后的就地提示：新增的根还没有书目，需要再点一次扫描。
class LibraryRootAddedNotice extends StatelessWidget {
  /// 创建添加成功提示。
  const LibraryRootAddedNotice({required this.name, super.key});

  /// 新增书库根的显示名。
  final String name;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: LibraryRootsKeys.addedNoticeKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.check_rounded, size: 16, color: scheme.onPrimaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '已添加「$name」。点这一行的「扫描」开始建立书目。',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// 重复添加同一目录时的就地提示：没有写入任何东西，指回已有那条根。
class LibraryRootDuplicateNotice extends StatelessWidget {
  /// 创建重复提示。
  const LibraryRootDuplicateNotice({required this.name, super.key});

  /// 被重复选择的那条根的显示名。
  final String name;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      key: LibraryRootsKeys.duplicateNoticeKey,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '这个目录已经在书库里：「$name」，没有重复添加。',
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// 一个书库根：名称与操作在上，路径与扫描时间在下，摘要再往下展开。
class LibraryRootCard extends StatelessWidget {
  /// 创建根卡片。
  const LibraryRootCard({
    required this.root,
    required this.scan,
    required this.onScan,
    super.key,
  });

  /// 这条根的数据。
  final LibraryRootView root;

  /// 这条根的扫描状态。
  final RootScanState scan;

  /// 触发扫描。
  final VoidCallback onScan;

  static const double _badgeSize = 44;
  static const double _detailIndent = _badgeSize + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final String lastScan = root.lastScanAt == null
        ? '从未扫描'
        : '上次扫描 · ${_formatTimestamp(root.lastScanAt!)}';

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.lg,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
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
              Row(
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
                        Text(
                          root.type == 'local' ? '本地目录' : root.type,
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _ScanButton(
                    root: root,
                    scanning: scan.scanning,
                    onScan: onScan,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(
                  left: _detailIndent,
                  right: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _SingleLinePath(
                      path: root.uri,
                      style: text.labelSmall?.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            lastScan,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              AnimatedSize(
                duration: AppMotion.resolve(context, AppDurations.standard),
                curve: AppDurations.standardCurve,
                alignment: Alignment.topCenter,
                child: _buildResult(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    if (scan.report != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: _ScanReportPanel(
          key: LibraryRootsKeys.reportKey(root.id),
          report: scan.report!,
        ),
      );
    }
    if (scan.error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: _ScanErrorPanel(
          key: LibraryRootsKeys.scanErrorKey(root.id),
          message: scan.error!,
        ),
      );
    }
    return const SizedBox(width: double.infinity);
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
            minimumSize: const Size(0, AppSizes.minTouchTarget),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
              : const Text('扫描'),
        ),
      ),
    );
  }
}

/// 单行路径：中间省略，保证末尾目录名始终可读，并把完整路径放进 tooltip。
class _SingleLinePath extends StatelessWidget {
  const _SingleLinePath({required this.path, this.style});

  final String path;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final TextStyle? effective = style;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final String shown = effective == null || !constraints.hasBoundedWidth
            ? path
            : _middleEllipsis(
                source: path,
                maxWidth: constraints.maxWidth,
                style: effective,
                scaler: scaler,
              );
        return Tooltip(
          message: path,
          child: Text(
            shown,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: style,
          ),
        );
      },
    );
  }
}

/// 扫描摘要：一次写入的实际增量 + 耗时 + 异常目录。
class _ScanReportPanel extends StatelessWidget {
  const _ScanReportPanel({required this.report, super.key});

  final ScanReport report;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final List<String> changes = <String>[
      if (report.booksAdded > 0) '${report.booksAdded} 册',
      if (report.volumesAdded > 0) '${report.volumesAdded} 卷',
      if (report.chaptersAdded > 0) '${report.chaptersAdded} 章',
    ];
    // 拆成「更新」与「维护」两行：400dp 下挤在一行会把最后一个词挤成孤行。
    final List<String> updates = <String>[
      if (report.booksUpdated > 0) '更新 ${report.booksUpdated} 册',
      if (report.chaptersUpdated > 0) '更新 ${report.chaptersUpdated} 章',
    ];
    final List<String> upkeep = <String>[
      if (report.chaptersMarkedMissing > 0)
        '标记缺失 ${report.chaptersMarkedMissing} 章',
      if (report.chaptersRestored > 0) '恢复 ${report.chaptersRestored} 章',
      if (report.ignoredFiles > 0) '忽略 ${report.ignoredFiles} 个非音频文件',
    ];
    final bool changed = report.hasChanges;
    final String headline = changes.isNotEmpty
        ? '新增 ${changes.join(' · ')}'
        : changed
        ? '书目结构已更新'
        : '没有发现新增或变更';
    if (!changed && updates.isEmpty && upkeep.isEmpty) {
      upkeep.add('目录内共 ${report.booksSeen} 册 · ${report.chaptersSeen} 章');
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
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
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Icon(
              changed
                  ? Icons.check_circle_outline_rounded
                  : Icons.task_alt_rounded,
              size: 16,
              color: scheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '扫描完成 · 用时 ${_formatElapsed(report.elapsed)}',
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  headline,
                  style: text.titleSmall?.copyWith(color: scheme.onSurface),
                ),
                if (updates.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    updates.join(' · '),
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (upkeep.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    upkeep.join(' · '),
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
        ],
      ),
    );
  }
}

/// 扫描失败：具体原因就地展示，可再次扫描。
class _ScanErrorPanel extends StatelessWidget {
  const _ScanErrorPanel({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
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
        ],
      ),
    );
  }
}

/// 添加书库根的底部弹层。
class LibraryAddRootSheet extends ConsumerStatefulWidget {
  /// 创建添加弹层。
  const LibraryAddRootSheet({required this.suggestedPath, super.key});

  /// 预填的绝对路径。
  final String suggestedPath;

  @override
  ConsumerState<LibraryAddRootSheet> createState() =>
      _LibraryAddRootSheetState();
}

class _LibraryAddRootSheetState extends ConsumerState<LibraryAddRootSheet> {
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

  Future<void> _submit() async {
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool isWindows = Platform.isWindows;

    return PopScope(
      // 写入过程中不允许下滑关闭：否则 page 收不到成功结果，
      // 也不会触发列表重新查询，用户会以为没添加上。
      canPop: !_submitting,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
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
                  '高级：手动输入绝对路径。扫描只读取其中的音频文件，不会改动任何内容。',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
                    hintText: isWindows
                        ? r'D:\Books'
                        : '/storage/emulated/0/Books',
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
                  onFieldSubmitted: (_) => unawaited(_submit()),
                  decoration: const InputDecoration(
                    labelText: '显示名（可选）',
                    hintText: '例如：本机书库',
                    prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
                  ),
                ),
                if (_submitError != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Container(
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
                          child: Text(
                            _submitError!,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Text(
                  '提示：应用私有目录会随卸载一起删除；长期书架建议选一个独立目录。',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
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
                            : () => unawaited(_submit()),
                        child: _submitting
                            // 大字号下按钮会变窄，只留转圈；「正在添加」交给语义标签。
                            ? Semantics(
                                label: '正在添加书库根',
                                child: const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const Text('添加'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

/// 扫描耗时：不足 1 秒看毫秒，分钟级也保持短句。
String _formatElapsed(Duration elapsed) {
  if (elapsed.inMilliseconds < 1000) {
    return '${elapsed.inMilliseconds} 毫秒';
  }
  if (elapsed.inSeconds < 60) {
    return '${(elapsed.inMilliseconds / 1000).toStringAsFixed(1)} 秒';
  }
  final int minutes = elapsed.inMinutes;
  final int seconds = elapsed.inSeconds.remainder(60);
  return seconds == 0 ? '$minutes 分钟' : '$minutes 分 $seconds 秒';
}

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

/// 测量单行文本宽度。
double _measureText(String value, TextStyle style, TextScaler scaler) {
  final TextPainter painter = TextPainter(
    text: TextSpan(text: value, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    textScaler: scaler,
  )..layout();
  final double width = painter.width;
  painter.dispose();
  return width;
}

/// 路径中间省略：保留开头与最后一级目录，中间用一个 `…` 折叠。
///
/// Flutter 只提供尾部省略，长路径会把最有信息量的目录名切掉；
/// 这里用二分查找逐步缩短开头，控制测量次数。
String _middleEllipsis({
  required String source,
  required double maxWidth,
  required TextStyle style,
  required TextScaler scaler,
}) {
  final String path = source.trim();
  if (path.isEmpty) {
    return path;
  }
  if (_measureText(path, style, scaler) <= maxWidth) {
    return path;
  }

  final String separator = path.contains('\\') ? '\\' : '/';
  final int lastSeparator = path.lastIndexOf(RegExp(r'[/\\]'));
  String head = lastSeparator > 0 ? path.substring(0, lastSeparator) : '';
  head = head.replaceFirst(RegExp(r'[/\\]+$'), '');
  String tail = lastSeparator >= 0 && lastSeparator < path.length - 1
      ? path.substring(lastSeparator + 1)
      : path;
  if (tail.length > 28) {
    tail = tail.substring(tail.length - 28);
  }

  String compose(String keptHead, String keptTail) {
    return keptHead.isEmpty
        ? '…$separator$keptTail'
        : '$keptHead$separator…$separator$keptTail';
  }

  bool fits(String candidate) =>
      _measureText(candidate, style, scaler) <= maxWidth;

  // 1) 完整开头 + 尾目录。
  if (fits(compose(head, tail))) {
    return compose(head, tail);
  }

  // 2) 二分缩短开头（宽度随保留字符数单调增长）。
  int best = -1;
  int low = 0;
  int high = head.length;
  while (low <= high) {
    final int mid = (low + high) ~/ 2;
    if (fits(compose(head.substring(0, mid), tail))) {
      best = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  if (best >= 0) {
    int keep = best;
    if (keep > 0 && keep < head.length) {
      // 尽量切在分隔符上，避免留下半个目录名；切不到就整体省略开头。
      final int cut = head.lastIndexOf(RegExp(r'[/\\]'), keep - 1);
      if (cut >= 0) {
        keep = cut;
      }
    }
    return compose(head.substring(0, keep), tail);
  }

  // 3) 开头全部省略仍太宽：缩短尾目录，至少保留一个字符。
  int bestTail = -1;
  low = 1;
  high = tail.length;
  while (low <= high) {
    final int mid = (low + high) ~/ 2;
    if (fits('…$separator${tail.substring(tail.length - mid)}')) {
      bestTail = mid;
      low = mid + 1;
    } else {
      high = mid - 1;
    }
  }
  if (bestTail >= 0) {
    return '…$separator${tail.substring(tail.length - bestTail)}';
  }
  return '…';
}
