import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final currentMb = ((_cacheSizeBytes ?? 0) / (1024 * 1024)).toStringAsFixed(1);
    final maxGb = (maxBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '音频缓存与预下载',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '在线播放时静默预载后续章节，提升连续收听体验并节省流量',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // 1. 仅在 Wi-Fi 下预下载
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

        // 2. 预下载未来章节数滑块
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

        // 3. 缓存池占用与清理
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(80),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withAlpha(100),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.storage_rounded,
                size: 22,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingSize
                          ? '正在计算缓存占用...'
                          : '已占用 $currentMb MB / 上限 $maxGb GB',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '超过上限时自动淘汰最久未听的音频文件',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _handleClearCache,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('清空音频缓存'),
              ),
            ],
          ),
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
