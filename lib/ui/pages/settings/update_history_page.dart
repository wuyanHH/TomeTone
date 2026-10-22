import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/update/changelog_parser.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/markdown_body.dart';

/// 更新历史离线查看页面（《架构需求文档》§2.7）。
///
/// 读取离线打包的 `assets/changelog/CHANGELOG.md` 快照，
/// 展示逐版本的详细发布记录与 Markdown 内容。
class UpdateHistoryPage extends StatefulWidget {
  /// 创建更新历史页面。
  const UpdateHistoryPage({super.key});

  /// 资源加载器，供测试用例替换为内存字符串。
  static Future<String> Function() loader = () =>
      rootBundle.loadString('assets/changelog/CHANGELOG.md');

  /// 版本条目卡片 key。
  static Key entryKey(String version) => Key('changelog-entry-$version');

  /// 当前版本徽标 key。
  static const Key currentVersionKey = Key('changelog-current-badge');

  /// 重试按钮 key。
  static const Key retryButtonKey = Key('changelog-retry-button');

  @override
  State<UpdateHistoryPage> createState() => _UpdateHistoryPageState();
}

class _UpdateHistoryPageState extends State<UpdateHistoryPage> {
  late Future<List<ChangelogEntry>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = UpdateHistoryPage.loader().then(parseChangelog);
  }

  void _retry() {
    setState(_load);
  }

  bool _isCurrentVersion(String entryVersion) {
    final cleanEntry =
        entryVersion.startsWith('v') || entryVersion.startsWith('V')
            ? entryVersion.substring(1)
            : entryVersion;
    final cleanApp =
        AppInfo.version.startsWith('v') || AppInfo.version.startsWith('V')
            ? AppInfo.version.substring(1)
            : AppInfo.version;
    return cleanEntry == cleanApp;
  }

  String? _extractSubtitle(ChangelogEntry entry) {
    if (entry.releaseDate != null) {
      return entry.releaseDate;
    }
    final bracketIndex = entry.title.indexOf(']');
    if (bracketIndex >= 0 && bracketIndex + 1 < entry.title.length) {
      final suffix = entry.title.substring(bracketIndex + 1).trim();
      if (suffix.startsWith('-')) {
        final text = suffix.substring(1).trim();
        if (text.isNotEmpty) return text;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更新历史'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
          child: FutureBuilder<List<ChangelogEntry>>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<List<ChangelogEntry>> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _buildLoading(context);
              }
              if (snapshot.hasError) {
                return _buildFailure(context, snapshot.error);
              }

              final entries = snapshot.data ?? const <ChangelogEntry>[];
              if (entries.isEmpty) {
                return _buildEmpty(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int index) {
                  return _buildEntryCard(context, entries[index]);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
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
              '正在加载更新历史…',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailure(BuildContext context, Object? error) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
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
                Icons.history_toggle_off_rounded,
                size: 28,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '更新历史读取失败',
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error?.toString() ?? '无法读取本地更新历史资源文件，请稍后重试。',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              key: UpdateHistoryPage.retryButtonKey,
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无更新记录',
              style: text.titleMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, ChangelogEntry entry) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final isCurrent = _isCurrentVersion(entry.version);
    final displayTitle = entry.version == '未发布'
        ? '未发布'
        : (entry.version.startsWith('v') || entry.version.startsWith('V')
            ? entry.version
            : 'v${entry.version}');
    final subtitle = _extractSubtitle(entry);

    return Card(
      key: UpdateHistoryPage.entryKey(entry.version),
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.lg,
        side: BorderSide(
          color: isCurrent
              ? scheme.primary.withValues(alpha: 0.6)
              : scheme.outlineVariant.withValues(alpha: 0.45),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: isCurrent,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                displayTitle,
                style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isCurrent) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              const _CurrentBadge(key: UpdateHistoryPage.currentVersionKey),
            ],
          ],
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  subtitle,
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            : null,
        children: <Widget>[
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          MarkdownBodyView(data: entry.body),
        ],
      ),
    );
  }
}

/// 当前版本徽标。
class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: AppRadii.pill,
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        '当前',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
