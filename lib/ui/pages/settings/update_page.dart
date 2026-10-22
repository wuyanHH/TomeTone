import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/app_info.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/apk_download_providers.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/app/providers/update_providers.dart';
import 'package:tometone/app/update/release_selection.dart';
import 'package:tometone/app/update/semver.dart';
import 'package:tometone/contracts/update/apk_download_state.dart';
import 'package:tometone/contracts/update/update_models.dart';
import 'package:tometone/contracts/update/update_source.dart';
import 'package:tometone/contracts/update/update_state.dart';
import 'package:tometone/ui/pages/settings/update_history_page.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import 'package:tometone/ui/widgets/markdown_body.dart';
import 'package:url_launcher/url_launcher.dart';

/// 版本更新详情页面（《架构需求文档》§2.7）。
///
/// 展示版本详情、Markdown 更新说明、多架构 APK 资产列表、
/// 推荐 ABI 标记、复制校验值、内置下载/安装及吸底常驻操作栏等功能。
class UpdatePage extends ConsumerStatefulWidget {
  /// 创建版本更新详情页面。
  const UpdatePage({
    super.key,
    this.initialReleaseTag,
  });

  /// 初始目标版本标签（若由通知/弹窗传入）。
  final String? initialReleaseTag;

  /// 主操作按钮 key（下载/重新下载）。
  static const Key primaryActionKey = Key('update-primary-action');

  /// 立即安装按钮 key。
  static const Key installKey = Key('update-install-action');

  /// 取消下载按钮 key。
  static const Key cancelDownloadKey = Key('update-cancel-download');

  /// 浏览器下载按钮 key。
  static const Key browserDownloadKey = Key('update-browser-download');

  /// 更多选项按钮 key。
  static const Key moreOptionsKey = Key('update-more-options');

  /// 下载进度条 key。
  static const Key downloadProgressKey = Key('update-download-progress');

  /// 吸底常驻栏 key。
  static const Key stickyBottomBarKey = Key('update-sticky-bottom-bar');

  /// 下载按钮 key 生成器。
  static Key downloadKey(String name) => Key('update-download-$name');

  /// 打开 Release 页面按钮 key。
  static const Key releasePageKey = Key('update-release-page');

  /// 跳过此版本按钮 key。
  static const Key skipKey = Key('update-skip');

  /// 取消跳过按钮 key。
  static const Key unskipKey = Key('update-unskip');

  /// 重试按钮 key。
  static const Key retryKey = Key('update-retry');

  /// 更新历史入口 key。
  static const Key historyKey = Key('update-history');

  /// URL 唤起回调，便于测试插桩。
  static Future<bool> Function(Uri uri, {LaunchMode mode}) urlLauncher =
      launchUrl;

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> {
  late Future<List<String>> _abisFuture;

  @override
  void initState() {
    super.initState();
    _abisFuture = ref.read(deviceArchitectureProvider).supportedAbis();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final release = ref.read(updateControllerProvider).release;
      final tag = widget.initialReleaseTag ?? release?.tag;
      if (tag != null && tag.isNotEmpty) {
        ref.read(updateControllerProvider.notifier).acknowledge(tag);
      }
    });
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  bool _isSkipped(String? skippedVersion, String releaseTag) {
    if (skippedVersion == null) return false;
    final normalized = versionFromTag(releaseTag)?.toString() ?? releaseTag;
    return skippedVersion == normalized || skippedVersion == releaseTag;
  }

  String _failureMessage(UpdateFailureKind? kind) {
    return switch (kind) {
      UpdateFailureKind.network => '网络连接异常或超时，请检查网络后重试。',
      UpdateFailureKind.rateLimited => '请求频次超限，请稍候再试。',
      UpdateFailureKind.badResponse => '版本数据解析失败，请稍后重试。',
      UpdateFailureKind.notConfigured => '更新源未配置，暂无法检查更新。',
      null => '检查更新失败，请重试。',
    };
  }

  String _releasePageUrl(ReleaseInfo? release) {
    if (release != null && release.htmlUrl.isNotEmpty) {
      return release.htmlUrl;
    }
    if (AppInfo.hasUpdateSource) {
      return 'https://github.com/${AppInfo.githubOwner}/${AppInfo.githubRepo}/releases';
    }
    return 'https://github.com';
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await UpdatePage.urlLauncher(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        // 外部唤起异常容错
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateControllerProvider);
    final prefs = ref.watch(preferencesProvider);
    final release = updateState.release;

    final bool isSkipped = _isSkipped(prefs.skippedVersion, release?.tag ?? '');
    final displayStatus = isSkipped ? UpdateStatus.skipped : updateState.status;

    final apkAssets = release?.assets
            .where((a) => a.name.toLowerCase().endsWith('.apk'))
            .toList(growable: false) ??
        const <ReleaseAsset>[];
    final bool showBottomBar = release != null &&
        apkAssets.isNotEmpty &&
        (displayStatus == UpdateStatus.available ||
            displayStatus == UpdateStatus.skipped);

    return Scaffold(
      appBar: AppBar(
        title: const Text('版本更新'),
        actions: <Widget>[
          IconButton(
            key: UpdatePage.historyKey,
            tooltip: '更新历史',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const UpdateHistoryPage(),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
          child: _buildBody(
            context,
            updateState,
            prefs,
            release,
            displayStatus,
          ),
        ),
      ),
      bottomNavigationBar: showBottomBar
          ? _buildStickyBottomBar(context, release, isSkipped, _abisFuture)
          : null,
    );
  }

  Widget _buildStickyBottomBar(
    BuildContext context,
    ReleaseInfo release,
    bool isSkipped,
    Future<List<String>> abisFuture,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final downloadState = ref.watch(apkDownloadProvider);

    final apkAssets = release.assets
        .where((a) => a.name.toLowerCase().endsWith('.apk'))
        .toList(growable: false);

    return Material(
      color: colorScheme.surface,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1.0,
          child: Container(
            key: UpdatePage.stickyBottomBarKey,
            constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: FutureBuilder<List<String>>(
              future: abisFuture,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<String>> snapshot,
              ) {
                final abis = snapshot.data ?? const <String>[];
                final recommendedName = recommendedAbiAsset(abis, apkAssets);
                final targetAsset = apkAssets.firstWhere(
                  (a) => a.name == recommendedName,
                  orElse: () => apkAssets.first,
                );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (downloadState.status ==
                        ApkDownloadStatus.downloading) ...<Widget>[
                      LinearProgressIndicator(
                        key: UpdatePage.downloadProgressKey,
                        value: downloadState.progress,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '${_formatSize(downloadState.receivedBytes)} / ${_formatSize(downloadState.totalBytes)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${(downloadState.progress * 100).toStringAsFixed(0)}%',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ] else if (downloadState.status ==
                        ApkDownloadStatus.completed) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          '下载完成（已校验 SHA-256），准备安装',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ] else if (downloadState.status ==
                        ApkDownloadStatus.failed) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Text(
                          downloadState.error ?? '下载失败，请重试',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    Row(
                      children: <Widget>[
                        if (isSkipped)
                          OutlinedButton(
                            key: UpdatePage.unskipKey,
                            onPressed: () => ref
                                .read(updateControllerProvider.notifier)
                                .clearSkip(),
                            child: const Text('取消跳过'),
                          )
                        else
                          OutlinedButton(
                            key: UpdatePage.skipKey,
                            onPressed: () => ref
                                .read(updateControllerProvider.notifier)
                                .skipVersion(release.tag),
                            child: const Text('跳过此版本'),
                          ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          key: UpdatePage.releasePageKey,
                          tooltip: 'Release 页面',
                          icon: const Icon(Icons.open_in_new_rounded),
                          onPressed: () =>
                              _openExternal(_releasePageUrl(release)),
                        ),
                        const Spacer(),
                        Flexible(
                          child: _buildPrimaryActionButton(
                            context,
                            downloadState,
                            targetAsset,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActionButton(
    BuildContext context,
    ApkDownloadState downloadState,
    ReleaseAsset targetAsset,
  ) {
    return switch (downloadState.status) {
      ApkDownloadStatus.idle || ApkDownloadStatus.cancelled => FilledButton.icon(
          key: UpdatePage.primaryActionKey,
          icon: const Icon(Icons.download_rounded),
          label: Text('下载更新 (${_formatSize(targetAsset.sizeBytes)})'),
          onPressed: () => ref
              .read(apkDownloadProvider.notifier)
              .startDownload(targetAsset),
        ),
      ApkDownloadStatus.downloading => OutlinedButton.icon(
          key: UpdatePage.cancelDownloadKey,
          icon: const Icon(Icons.close_rounded),
          label: const Text('取消下载'),
          onPressed: () => ref.read(apkDownloadProvider.notifier).cancel(),
        ),
      ApkDownloadStatus.completed => FilledButton.icon(
          key: UpdatePage.installKey,
          icon: const Icon(Icons.system_update_rounded),
          label: const Text('立即安装'),
          onPressed: () =>
              ref.read(apkDownloadProvider.notifier).installCurrent(),
        ),
      ApkDownloadStatus.failed => FilledButton.icon(
          key: UpdatePage.primaryActionKey,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('重新下载'),
          onPressed: () => ref
              .read(apkDownloadProvider.notifier)
              .startDownload(targetAsset),
        ),
    };
  }

  Widget _buildBody(
    BuildContext context,
    UpdateState updateState,
    AppPreferences prefs,
    ReleaseInfo? release,
    UpdateStatus displayStatus,
  ) {
    if (updateState.status == UpdateStatus.checking && release == null) {
      return _buildCheckingView(context);
    }

    if (updateState.status == UpdateStatus.failure && release == null) {
      return _buildFailureView(context, updateState.failure);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildVersionHeaderCard(context, displayStatus, release),
          if (updateState.status == UpdateStatus.failure &&
              release != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            _buildNoticeBanner(
              context,
              '检查失败，显示上次结果',
              isWarning: true,
              trailing: TextButton(
                key: UpdatePage.retryKey,
                onPressed: () => ref
                    .read(updateControllerProvider.notifier)
                    .check(manual: true),
                child: const Text('重试'),
              ),
            ),
          ],
          if (release != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            _buildReleaseContent(context, release),
          ] else ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            _buildNoReleaseCard(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckingView(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox.square(
              dimension: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '正在检查更新…',
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureView(BuildContext context, UpdateFailureKind? failure) {
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
                Icons.error_outline_rounded,
                size: 28,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '检查更新失败',
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _failureMessage(failure),
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonalIcon(
              key: UpdatePage.retryKey,
              onPressed: () => ref
                  .read(updateControllerProvider.notifier)
                  .check(manual: true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              key: UpdatePage.releasePageKey,
              onPressed: () => _openExternal(_releasePageUrl(null)),
              child: const Text('打开 GitHub Release 页'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeBanner(
    BuildContext context,
    String message, {
    bool isWarning = false,
    Widget? trailing,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isWarning
            ? scheme.errorContainer.withValues(alpha: 0.6)
            : scheme.secondaryContainer.withValues(alpha: 0.6),
        borderRadius: AppRadii.sm,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isWarning ? Icons.info_outline_rounded : Icons.check_circle_outline,
            size: 18,
            color: isWarning
                ? scheme.onErrorContainer
                : scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: text.bodySmall?.copyWith(
                color: isWarning
                    ? scheme.onErrorContainer
                    : scheme.onSecondaryContainer,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildVersionHeaderCard(
    BuildContext context,
    UpdateStatus status,
    ReleaseInfo? release,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '当前版本：${AppInfo.version}',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (release != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '最新版本：${release.tag}',
                          style: text.bodyMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '发布时间：${_formatDate(release.publishedAt)}',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(context, status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, UpdateStatus status) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (String label, Color bg, Color fg) = switch (status) {
      UpdateStatus.checking => (
          '检查中',
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      UpdateStatus.available => (
          '可更新',
          scheme.primaryContainer,
          scheme.onPrimaryContainer
        ),
      UpdateStatus.upToDate => (
          '最新',
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant
        ),
      UpdateStatus.skipped => (
          '已跳过',
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      UpdateStatus.failure => (
          '检查失败',
          scheme.errorContainer,
          scheme.onErrorContainer
        ),
      UpdateStatus.noRelease => (
          '暂无',
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant
        ),
      UpdateStatus.idle => (
          '最新',
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.pill,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildReleaseContent(
    BuildContext context,
    ReleaseInfo release,
  ) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '更新说明',
                  style: text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                MarkdownBodyView(data: release.body),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildAssetsSection(context, release),
        const SizedBox(height: AppSpacing.md),
        Text(
          '请在系统设置中允许安装未知来源应用。当前版本为 Debug/Pre-release 签名。',
          textAlign: TextAlign.center,
          style: text.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildAssetsSection(BuildContext context, ReleaseInfo release) {
    final TextTheme text = Theme.of(context).textTheme;
    final apkAssets = release.assets
        .where((a) => a.name.toLowerCase().endsWith('.apk'))
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '安装包列表',
              style: text.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (apkAssets.isEmpty)
              Text(
                '暂无可用 APK 安装包',
                style: text.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              FutureBuilder<List<String>>(
                future: _abisFuture,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<String>> snapshot,
                ) {
                  final abis = snapshot.data ?? const <String>[];
                  final recommendedName = recommendedAbiAsset(abis, apkAssets);

                  return Column(
                    children: <Widget>[
                      for (int i = 0; i < apkAssets.length; i++) ...<Widget>[
                        if (i > 0) const Divider(height: AppSpacing.lg),
                        _buildAssetRow(
                          context,
                          apkAssets[i],
                          isRecommended: apkAssets[i].name == recommendedName,
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetRow(
    BuildContext context,
    ReleaseAsset asset, {
    required bool isRecommended,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final downloadState = ref.watch(apkDownloadProvider);

    final bool isCurrentAsset = downloadState.assetName == asset.name;
    final bool isCompleted =
        isCurrentAsset && downloadState.status == ApkDownloadStatus.completed;
    final bool isDownloading =
        isCurrentAsset && downloadState.status == ApkDownloadStatus.downloading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                asset.name,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isRecommended) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadii.xs,
                ),
                child: Text(
                  '推荐架构',
                  style: text.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              _formatSize(asset.sizeBytes),
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  key: UpdatePage.browserDownloadKey,
                  tooltip: '在浏览器中下载',
                  icon: const Icon(Icons.public_rounded),
                  onPressed: () => _openExternal(asset.downloadUrl),
                ),
                const SizedBox(width: AppSpacing.xs),
                FilledButton.tonalIcon(
                  key: UpdatePage.downloadKey(asset.name),
                  onPressed: () {
                    if (isCompleted) {
                      ref.read(apkDownloadProvider.notifier).installCurrent();
                    } else {
                      ref
                          .read(apkDownloadProvider.notifier)
                          .startDownload(asset);
                    }
                  },
                  icon: Icon(
                    isCompleted
                        ? Icons.system_update_rounded
                        : (isDownloading
                            ? Icons.downloading_rounded
                            : Icons.download_rounded),
                    size: 16,
                  ),
                  label: Text(
                    isCompleted
                        ? '安装'
                        : (isDownloading ? '下载中' : '下载'),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (asset.digest != null && asset.digest!.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            borderRadius: AppRadii.xs,
            onTap: () {
              Clipboard.setData(ClipboardData(text: asset.digest!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('校验值已复制'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.copy_rounded,
                    size: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      asset.digest!,
                      style: text.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoReleaseCard(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: <Widget>[
            Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: scheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '当前已是最新版本',
              style: text.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '暂无更高版本的安装包发布。',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
