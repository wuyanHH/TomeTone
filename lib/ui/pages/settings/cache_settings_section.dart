import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/ui/pages/settings/widgets/settings_shared_widgets.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';
import '../../../app/providers/online_providers.dart';
import '../../../contracts/audio/audio_cache_repository.dart';

/// 设置页音频缓存与预下载控制组件 (CacheSettingsSection)。
class CacheSettingsSection extends ConsumerStatefulWidget {
  const CacheSettingsSection({
    super.key,
    this.cacheRepository,
    this.initialWifiOnly = true,
    this.initialPreloadChapters = 3,
    this.onWifiOnlyChanged,
    this.onPreloadChaptersChanged,
  });

  final AudioCacheRepository? cacheRepository;
  final bool initialWifiOnly;
  final int initialPreloadChapters;
  final ValueChanged<bool>? onWifiOnlyChanged;
  final ValueChanged<int>? onPreloadChaptersChanged;

  @override
  ConsumerState<CacheSettingsSection> createState() => _CacheSettingsSectionState();
}

class _CacheSettingsSectionState extends ConsumerState<CacheSettingsSection> {
  late bool _wifiOnly;
  late int _preloadChapters;
  int? _cacheSizeBytes;
  bool _isLoadingSize = true;

  @override
  void initState() {
    super.initState();
    _wifiOnly = widget.initialWifiOnly;
    _preloadChapters = widget.initialPreloadChapters;
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    try {
      final repo = widget.cacheRepository ?? tryReadRepo(ref);
      if (repo == null) {
        if (mounted) {
          setState(() {
            _cacheSizeBytes = 0;
            _isLoadingSize = false;
          });
        }
        return;
      }
      final size = await repo.getTotalCacheSize();
      if (mounted) {
        setState(() {
          _cacheSizeBytes = size;
          _isLoadingSize = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheSizeBytes = 0;
          _isLoadingSize = false;
        });
      }
    }
  }

  Future<void> _handleClearCache() async {
    try {
      final repo = widget.cacheRepository ?? tryReadRepo(ref);
      if (repo == null) return;
      await repo.clearAllCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已清空本地音频缓存')),
        );
        await _loadCacheSize();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清理缓存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const maxBytes = 2 * 1024 * 1024 * 1024; // 默认 2.0 GB 上限

    final currentBytes = _cacheSizeBytes ?? 0;
    final currentMb = (currentBytes / (1024 * 1024)).toStringAsFixed(1);
    final maxGb = (maxBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final usageFraction = (currentBytes / maxBytes).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // 1. 预下载与网络策略卡片
        SettingsSectionCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Text(
              '音频缓存与预下载',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '在线播放时静默预载后续章节，提升连续收听体验并节省流量',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // 仅在 Wi-Fi 下预下载
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('仅在 Wi-Fi 下预下载'),
              subtitle: const Text('移动网络下暂停后台静默下载，防止消耗蜂窝流量'),
              value: _wifiOnly,
              onChanged: (val) {
                setState(() {
                  _wifiOnly = val;
                });
                widget.onWifiOnlyChanged?.call(val);
              },
            ),

            const SettingsDivider(indent: 0, endIndent: 0),
            const SizedBox(height: AppSpacing.sm),

            // 预下载未来章节数滑块
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '预下载未来章节数: $_preloadChapters 章',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: _preloadChapters.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '$_preloadChapters 章',
                    onChanged: (val) {
                      final intVal = val.round();
                      setState(() {
                        _preloadChapters = intVal;
                      });
                      widget.onPreloadChaptersChanged?.call(intVal);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. 缓存池占用与清理卡片
        SettingsSectionCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Text(
              '缓存占用与清理',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: AppRadii.md,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.storage_rounded,
                        size: 20,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _isLoadingSize
                              ? '正在计算缓存占用...'
                              : '已占用 $currentMb MB / 上限 $maxGb GB',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: AppRadii.pill,
                    child: LinearProgressIndicator(
                      value: _isLoadingSize ? null : usageFraction,
                      minHeight: 5,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '超过上限时自动淘汰最久未听的音频文件',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _handleClearCache,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('清空音频缓存'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static AudioCacheRepository? tryReadRepo(WidgetRef ref) {
    try {
      return ref.read(audioCacheRepositoryProvider);
    } catch (_) {
      return null;
    }
  }
}
