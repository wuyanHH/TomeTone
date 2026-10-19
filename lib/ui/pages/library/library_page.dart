import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/app_providers.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/contracts/storage/directory_picker.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/ui/pages/library/library_roots.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 书库（独立的第 4 个 tab，方案 A）。
///
/// 职责边界：书架只负责「看与听」，书库只负责「来源与扫描」。
/// 本页整块搬走了设置页原有的「书库根」分组：根列表、扫描、添加都在
/// [library_roots.dart] 的共享件里原样复用，没有重写一份。
///
/// 列表永远以 [libraryRootsProvider] 的查询结果为准，不做乐观更新：
/// 添加后重新查询，扫描成功后失效书架与根列表，界面只渲染服务端结果。
class LibraryPage extends ConsumerStatefulWidget {
  /// 创建书库页。
  const LibraryPage({super.key, this.suggestedRootPath});

  /// 添加书库根时预填的路径；为空时由 [defaultRootPathSuggestion] 推导。
  ///
  /// 只用于测试与特殊端形态注入，正常运行时无需传值。
  final String? suggestedRootPath;

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  /// 添加成功后的一次性提示；扫描、再次添加或命中重复时消失。
  String? _addedNotice;

  /// 选中目录已在书库时的一次性提示（没有写入任何东西）。
  String? _duplicateNotice;

  /// 系统目录选择器是否正开着（避免连点弹出两次）。
  bool _pickingSaf = false;

  /// SAF 选择失败的原因，已转成给用户看的标题与说明；用户取消时为 null。
  SafPickFailure? _safError;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<LibraryRootView>> rootsAsync = ref.watch(
      libraryRootsProvider,
    );
    final Map<String, RootScanState> scans = ref.watch(libraryScanProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _LibraryHeader(countLabel: _countLabel(rootsAsync)),
              Padding(
                padding: AppSpacing.pagePadding,
                child: _buildRootsSection(context, rootsAsync, scans),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _countLabel(AsyncValue<List<LibraryRootView>> rootsAsync) {
    if (rootsAsync.hasError) {
      return '读取失败';
    }
    if (!rootsAsync.hasValue) {
      return '正在读取…';
    }
    return '${rootsAsync.value!.length} 个';
  }

  Widget _buildRootsSection(
    BuildContext context,
    AsyncValue<List<LibraryRootView>> rootsAsync,
    Map<String, RootScanState> scans,
  ) {
    final List<LibraryRootView> roots =
        rootsAsync.value ?? const <LibraryRootView>[];
    final bool failed = rootsAsync.hasError;

    if (failed) {
      return LibraryRootsError(
        onRetry: () {
          ref.invalidate(libraryRootsProvider);
        },
      );
    }
    if (!rootsAsync.hasValue) {
      return const LibraryRootsLoading();
    }
    if (roots.isEmpty) {
      return LibraryRootsEmpty(
        onAdd: () => unawaited(_openAddRootSheet()),
        onPickSaf: () => unawaited(_pickSafRoot()),
        pickingSaf: _pickingSaf,
        error: _safError,
      );
    }
    return Column(
      key: LibraryRootsKeys.rootsListKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final LibraryRootView root in roots)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: LibraryRootCard(
              root: root,
              scan: scans[root.id] ?? const RootScanState(),
              onScan: () => _scan(root),
            ),
          ),
        if (_duplicateNotice != null) ...<Widget>[
          LibraryRootDuplicateNotice(name: _duplicateNotice!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_addedNotice != null) ...<Widget>[
          LibraryRootAddedNotice(name: _addedNotice!),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xs),
        LibraryRootActions(
          pickingSaf: _pickingSaf,
          onPickSaf: () => unawaited(_pickSafRoot()),
          onAddManual: () => unawaited(_openAddRootSheet()),
          error: _safError,
        ),
      ],
    );
  }

  /// 系统目录选择器 → 落库 → 重新查询（Android 11+ 唯一可行的选目录方式）。
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
      _addedNotice = null;
      _duplicateNotice = null;
    });

    try {
      final PickedDirectory? picked = await ref
          .read(directoryPickerProvider)
          .pickDirectory();
      if (picked == null) {
        // 用户取消：不提示、不写入、不刷新列表。
        if (mounted) {
          setState(() => _pickingSaf = false);
        }
        return;
      }
      final String name = picked.name.trim().isEmpty ? picked.uri : picked.name;
      final List<LibraryRootView> known =
          ref.read(libraryRootsProvider).value ?? const <LibraryRootView>[];
      if (hasLibraryRootWithUri(known, picked.uri)) {
        if (!mounted) {
          return;
        }
        setState(() {
          _pickingSaf = false;
          _duplicateNotice = name;
        });
        return;
      }
      await ref
          .read(libraryRootServiceProvider)
          .addSafRoot(treeUri: picked.uri, displayName: picked.name);
      if (!mounted) {
        return;
      }
      setState(() {
        _pickingSaf = false;
        _addedNotice = name;
      });
      // 与手动添加一致：列表以重新查询为准，不拼一条假记录。
      ref.invalidate(libraryRootsProvider);
    } on MissingPluginException {
      _failSafPick(
        '这里没有系统目录选择器',
        '当前平台没有接入目录选择，或应用不在 Android 上运行。请改用「高级：手动输入路径」。',
      );
    } on PlatformException catch (error) {
      if (error.code == 'busy') {
        _failSafPick('目录选择器正在使用', '已经有一个目录选择在进行，先完成那一次选择，再回来添加。');
      } else {
        _failSafPick('目录选择器没有打开', '系统没有返回选中的目录。稍后再试，或用「高级：手动输入路径」。');
      }
    } on Object {
      _failSafPick('书库根没有添加成功', '目录已经选中，但没有保存下来。请再选一次，或改用「高级：手动输入路径」。');
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

  void _scan(LibraryRootView root) {
    if (ref.read(libraryScanProvider)[root.id]?.scanning ?? false) {
      return;
    }
    if (_addedNotice != null || _duplicateNotice != null) {
      setState(() {
        _addedNotice = null;
        _duplicateNotice = null;
      });
    }
    // 扫描不阻塞点击回调，也不在 build 里启动。
    unawaited(ref.read(libraryScanProvider.notifier).scan(root.id));
  }

  Future<void> _openAddRootSheet() async {
    if (_safError != null || _duplicateNotice != null) {
      setState(() {
        _safError = null;
        _duplicateNotice = null;
      });
    }
    final String suggested =
        (widget.suggestedRootPath != null &&
            widget.suggestedRootPath!.trim().isNotEmpty)
        ? widget.suggestedRootPath!.trim()
        : defaultRootPathSuggestion();
    final String? addedName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: AppMotion.resolve(context, AppDurations.standard),
        reverseDuration: AppMotion.resolve(context, AppDurations.fast),
      ),
      builder: (_) => LibraryAddRootSheet(suggestedPath: suggested),
    );
    if (!mounted || addedName == null) {
      return;
    }
    setState(() => _addedNotice = addedName);
    // 列表以重新查询为准：不复用弹层里输入的路径拼一条假记录。
    ref.invalidate(libraryRootsProvider);
  }
}

/// 页首题头：眉题 + 标题 + 根数量 + 一句说明（版式与书架一致）。
class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.countLabel});

  final String countLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '书库 · LIBRARY',
            style: text.labelSmall?.copyWith(
              color: scheme.primary,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('书库根', style: text.headlineMedium),
                ),
              ),
              Text(
                countLabel,
                style: text.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '每个根目录独立扫描。听卷只读取其中的音频文件，不会移动、重命名或删除任何内容。',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
