import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/providers/library_root_providers.dart';
import 'package:tometone/contracts/storage/storage_entry.dart';
import 'package:tometone/contracts/storage/storage_error.dart';
import 'package:tometone/contracts/storage/storage_provider.dart';
import 'package:tometone/domain/library/queries/library_views.dart';
import 'package:tometone/domain/library/scan/media_format.dart';
import 'package:tometone/ui/pages/library/library_root_location.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 只读书库根浏览页的测试键。
abstract final class LibraryBrowserKeys {
  /// 页面根节点。
  static const Key pageKey = Key('library-browser-page');

  /// 当前目录的条目列表。
  static const Key listKey = Key('library-browser-list');

  /// 读取中的状态。
  static const Key loadingKey = Key('library-browser-loading');

  /// 空目录状态。
  static const Key emptyKey = Key('library-browser-empty');

  /// 读取失败状态。
  static const Key errorKey = Key('library-browser-error');

  /// 失败状态里的重试按钮。
  static const Key retryKey = Key('library-browser-retry');

  /// AppBar 里的刷新按钮。
  static const Key refreshKey = Key('library-browser-refresh');

  /// 可横向滚动的面包屑。
  static const Key breadcrumbKey = Key('library-browser-breadcrumb');

  /// 某个条目（文件夹 / 文件）。
  static Key entryKey(String name) => Key('library-browser-entry-$name');
}

/// 从一个书库根进入的**只读**目录浏览。
///
/// 这里不是第二个书架：只按存储契约列目录，不解析书目、不接播放队列，
/// 也没有重命名 / 删除 / 新建。它的作用是回答问题 ——「这个根目录里到底有什么」，
/// 以及让用户顺着文件夹确认扫描指向的位置是否正确。
class LibraryBrowserPage extends ConsumerStatefulWidget {
  /// 创建浏览页。
  const LibraryBrowserPage({required this.root, super.key});

  /// 要浏览的书库根。
  final LibraryRootView root;

  @override
  ConsumerState<LibraryBrowserPage> createState() => _LibraryBrowserPageState();
}

class _LibraryBrowserPageState extends ConsumerState<LibraryBrowserPage> {
  /// 页面自己持有一个 provider；退出时释放，避免远程实现的连接池留在原地。
  StorageProvider? _provider;

  List<StorageEntry> _entries = const <StorageEntry>[];
  String _relativePath = '';
  bool _loading = true;
  _BrowserFailure? _failure;

  /// 快速连点文件夹时，只接受最后一次读取的结果。
  int _loadGeneration = 0;

  static const _BrowserFailure _providerFailure = _BrowserFailure(
    '这个位置暂时打不开',
    '当前来源没有提供可用的文件浏览。回到书库后可以重试扫描，或移除这个来源再重新添加。',
  );

  @override
  void initState() {
    super.initState();
    if (_createProvider()) {
      unawaited(_load(''));
    } else {
      _loading = false;
      _failure = _providerFailure;
    }
  }

  @override
  void dispose() {
    final StorageProvider? provider = _provider;
    _provider = null;
    if (provider != null) {
      unawaited(_disposeProvider(provider));
    }
    super.dispose();
  }

  bool _createProvider() {
    try {
      _provider = ref.read(storageProviderFactoryProvider)(widget.root.uri);
      return true;
    } on Object {
      _provider = null;
      return false;
    }
  }

  Future<void> _disposeProvider(StorageProvider provider) async {
    try {
      await provider.dispose();
    } on Object {
      // 释放失败没有补救动作；provider 的 dispose 本身约定为幂等。
    }
  }

  Future<void> _load(String path) async {
    final StorageProvider? provider = _provider;
    if (provider == null) {
      setState(() {
        _loading = false;
        _failure = _providerFailure;
      });
      return;
    }

    final int generation = ++_loadGeneration;
    setState(() {
      _relativePath = path;
      _loading = true;
      _failure = null;
    });

    try {
      final List<StorageEntry> entries = await provider.list(path);
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      final List<StorageEntry> sorted = List<StorageEntry>.of(entries)
        ..sort(_compareEntries);
      setState(() {
        _entries = List<StorageEntry>.unmodifiable(sorted);
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _entries = const <StorageEntry>[];
        _loading = false;
        _failure = _failureFor(error);
      });
    }
  }

  void _retry() {
    if (_provider == null && !_createProvider()) {
      setState(() {
        _loading = false;
        _failure = _providerFailure;
      });
      return;
    }
    unawaited(_load(_relativePath));
  }

  void _openEntry(StorageEntry entry) {
    if (entry.isDirectory) {
      unawaited(_load(entry.path));
      return;
    }
    if (MediaFormat.isSupported(entry.name)) {
      _showReadOnlyHint();
    }
  }

  void _showReadOnlyHint() {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('这里只读浏览，不能播放；听书请回到书架。')));
  }

  void _goUp() {
    if (_relativePath.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    final List<String> segments = _segmentsOf(_relativePath);
    if (segments.isEmpty) {
      unawaited(_load(''));
      return;
    }
    unawaited(_load(segments.sublist(0, segments.length - 1).join('/')));
  }

  void _handleBack() {
    if (_relativePath.isEmpty) {
      Navigator.of(context).maybePop();
    } else {
      _goUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool atRoot = _relativePath.isEmpty;

    return PopScope(
      canPop: atRoot,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _goUp();
      },
      child: Scaffold(
        key: LibraryBrowserKeys.pageKey,
        appBar: AppBar(
          leading: IconButton(
            tooltip: atRoot ? '返回书库' : '返回上一级',
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(
            widget.root.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: <Widget>[
            IconButton(
              key: LibraryBrowserKeys.refreshKey,
              tooltip: '刷新目录',
              onPressed: _loading ? null : _retry,
              icon: const Icon(Icons.refresh_rounded),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: _BreadcrumbBar(
              root: widget.root,
              relativePath: _relativePath,
              onNavigate: (String path) => unawaited(_load(path)),
            ),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.readingMaxWidth,
            ),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return _buildLoading();
    }
    final _BrowserFailure? failure = _failure;
    if (failure != null) {
      return _buildFailure(failure);
    }
    if (_entries.isEmpty) {
      return _buildEmpty();
    }
    return ListView.separated(
      key: LibraryBrowserKeys.listKey,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: _entries.length,
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: AppSpacing.xxs),
      itemBuilder: (BuildContext context, int index) {
        return _buildEntry(context, _entries[index]);
      },
    );
  }

  Widget _buildLoading() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      key: LibraryBrowserKeys.loadingKey,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '正在读取目录…',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool atRoot = _relativePath.isEmpty;

    return Center(
      key: LibraryBrowserKeys.emptyKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: AppRadii.lg,
              ),
              child: Icon(
                Icons.folder_off_outlined,
                size: 26,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              atRoot ? '这个书库根里没有可浏览的内容' : '这个文件夹是空的',
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              atRoot
                  ? '目录里没有列出文件夹或文件。回到书库点「扫描」，或检查这个根是否指错了目录。'
                  : '返回上一级，或换一个文件夹看看。',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (!atRoot) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: _goUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                label: const Text('返回上一级'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFailure(_BrowserFailure failure) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      key: LibraryBrowserKeys.errorKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: scheme.errorContainer,
                borderRadius: AppRadii.lg,
              ),
              child: Icon(
                Icons.folder_off_outlined,
                size: 26,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              failure.title,
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              key: LibraryBrowserKeys.retryKey,
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntry(BuildContext context, StorageEntry entry) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final bool audio =
        !entry.isDirectory && MediaFormat.isSupported(entry.name);

    final (
      IconData icon,
      Color background,
      Color foreground,
    ) = entry.isDirectory
        ? (
            Icons.folder_rounded,
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
          )
        : audio
        ? (
            Icons.audiotrack_rounded,
            scheme.secondaryContainer,
            scheme.onSecondaryContainer,
          )
        : (
            Icons.insert_drive_file_outlined,
            scheme.surfaceContainerHighest,
            scheme.onSurfaceVariant,
          );

    return Material(
      color: Colors.transparent,
      child: ListTile(
        key: LibraryBrowserKeys.entryKey(entry.name),
        onTap: entry.isDirectory
            ? () => _openEntry(entry)
            : (audio ? _showReadOnlyHint : null),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.md),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadii.sm,
          ),
          child: Icon(icon, size: 20, color: foreground),
        ),
        title: Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium?.copyWith(
            fontWeight: entry.isDirectory ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _entrySubtitle(entry),
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: entry.isDirectory
            ? Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
    );
  }
}

/// 面包屑：根位置固定在最左，进入深层后追加路径段；点任意一段都能跳回去。
class _BreadcrumbBar extends StatefulWidget {
  const _BreadcrumbBar({
    required this.root,
    required this.relativePath,
    required this.onNavigate,
  });

  final LibraryRootView root;
  final String relativePath;
  final ValueChanged<String> onNavigate;

  @override
  State<_BreadcrumbBar> createState() => _BreadcrumbBarState();
}

class _BreadcrumbBarState extends State<_BreadcrumbBar> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _revealCurrentSegment();
  }

  @override
  void didUpdateWidget(_BreadcrumbBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.relativePath != widget.relativePath) {
      _revealCurrentSegment();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 目录一层层变深时，把当前段滚进视野；减弱动效时直接跳过去。
  void _revealCurrentSegment() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final double target = _controller.position.maxScrollExtent;
      if (AppMotion.reduced(context)) {
        _controller.jumpTo(target);
      } else {
        unawaited(
          _controller.animateTo(
            target,
            duration: AppDurations.standard,
            curve: AppDurations.standardCurve,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final List<String> segments = _segmentsOf(widget.relativePath);
    final List<({String label, String path})> crumbs =
        <({String label, String path})>[
          (label: readableLibraryRootLocation(widget.root), path: ''),
          for (int index = 0; index < segments.length; index++)
            (label: segments[index], path: segments.take(index + 1).join('/')),
        ];

    return Material(
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: <Widget>[
            Icon(Icons.place_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SingleChildScrollView(
                key: LibraryBrowserKeys.breadcrumbKey,
                controller: _controller,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < crumbs.length;
                      index++
                    ) ...<Widget>[
                      if (index > 0)
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: scheme.outline,
                        ),
                      _BreadcrumbSegment(
                        label: crumbs[index].label,
                        current: index == crumbs.length - 1,
                        onTap: index == crumbs.length - 1
                            ? null
                            : () => widget.onNavigate(crumbs[index].path),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: '只读浏览，不会修改任何内容',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: AppRadii.pill,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Text(
                      '只读',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbSegment extends StatelessWidget {
  const _BreadcrumbSegment({
    required this.label,
    required this.current,
    required this.onTap,
  });

  final String label;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Semantics(
      button: !current,
      selected: current,
      label: current ? '$label，当前位置' : '前往 $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: text.labelMedium?.copyWith(
                  color: current ? scheme.onSurface : scheme.onSurfaceVariant,
                  fontWeight: current ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 列表排序：文件夹在前，文件在后；同类按名称不区分大小写。
int _compareEntries(StorageEntry a, StorageEntry b) {
  if (a.isDirectory != b.isDirectory) {
    return a.isDirectory ? -1 : 1;
  }
  final int folded = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  if (folded != 0) {
    return folded;
  }
  // 同名只差大小写时保持稳定顺序，避免每次刷新跳来跳去。
  return a.name.compareTo(b.name);
}

List<String> _segmentsOf(String path) {
  return <String>[
    for (final String segment in path.replaceAll('\\', '/').split('/'))
      if (segment.isNotEmpty && segment != '.') segment,
  ];
}

String _entrySubtitle(StorageEntry entry) {
  if (entry.isDirectory) {
    return '文件夹';
  }
  final String kind = MediaFormat.isSupported(entry.name) ? '音频' : '文件';
  final int? bytes = entry.sizeBytes;
  if (bytes == null || bytes < 0) {
    return kind;
  }
  return '$kind · ${_formatBytes(bytes)}';
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  const List<String> units = <String>['KB', 'MB', 'GB', 'TB'];
  double value = bytes / 1024;
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final String digits = value >= 100
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$digits ${units[unit]}';
}

_BrowserFailure _failureFor(Object error) {
  if (error is StorageError) {
    return switch (error.code) {
      StorageErrorCode.notFound => const _BrowserFailure(
        '这个文件夹找不到了',
        '它可能被移动、重命名或删除。返回上一级，或回到书库重新扫描。',
      ),
      StorageErrorCode.permission => const _BrowserFailure(
        '没有读取这个文件夹的权限',
        '系统没有授予读取权限。回到书库移除这个来源，再重新添加并确认授权。',
      ),
      StorageErrorCode.io => const _BrowserFailure(
        '读取目录时出错',
        '存储暂时读不出来。确认目录仍然存在、且设备可以访问，然后再试。',
      ),
      StorageErrorCode.invalidPath => const _BrowserFailure(
        '这个位置无法读取',
        '路径包含当前存储不接受的字符。返回上一级再试。',
      ),
      StorageErrorCode.unsupportedOperation => const _BrowserFailure(
        '这个来源暂时不能浏览',
        '当前存储没有提供目录列表能力。',
      ),
      StorageErrorCode.serverUnsupported => const _BrowserFailure(
        '这个来源不支持浏览目录',
        '当前存储只支持扫描，无法列出文件夹。',
      ),
      StorageErrorCode.network => const _BrowserFailure(
        '网络位置暂时连不上',
        '检查网络后再试；离线时请换用本地目录。',
      ),
      StorageErrorCode.authentication => const _BrowserFailure(
        '这个位置需要重新授权',
        '登录状态可能已经过期。回到书库移除这个来源，再重新添加。',
      ),
      StorageErrorCode.quotaExceeded => const _BrowserFailure(
        '存储空间不足',
        '设备空间已满，暂时无法读取目录。',
      ),
      StorageErrorCode.conflict => const _BrowserFailure(
        '目录状态发生了变化',
        '这个位置同时被其它程序修改。稍后再试。',
      ),
      StorageErrorCode.unknown => const _BrowserFailure(
        '目录没有读出来',
        '暂时读不出这个文件夹。稍后再试。',
      ),
    };
  }
  return const _BrowserFailure('目录没有读出来', '存储暂时没有响应。确认目录仍然存在、设备空间正常后再试。');
}

@immutable
class _BrowserFailure {
  const _BrowserFailure(this.title, this.message);

  final String title;
  final String message;
}
