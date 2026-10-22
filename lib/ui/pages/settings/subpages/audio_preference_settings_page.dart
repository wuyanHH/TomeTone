import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 听书偏好二级页面。
class AudioPreferenceSettingsPage extends ConsumerWidget {
  const AudioPreferenceSettingsPage({super.key});

  static const List<double> _speedOptions = <double>[
    0.75,
    1.0,
    1.25,
    1.5,
    1.75,
    2.0,
  ];

  static const List<int> _skipOptions = <int>[
    0,
    15,
    30,
    45,
    60,
    90,
    120,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppPreferences prefs = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('听书偏好'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text('默认播放倍速', style: text.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '书籍初次播放时的默认倍速',
                      style: text.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _speedOptions.map((double speed) {
                        final bool isSelected =
                            (prefs.defaultPlaybackSpeed - speed).abs() < 0.01;
                        return ChoiceChip(
                          label: Text('${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 1 : 2)}x'),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              ref
                                  .read(preferencesProvider.notifier)
                                  .update((s) => s.copyWith(defaultPlaybackSpeed: speed));
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    Text('默认片头跳过', style: text.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '换章播放时自动跳过片头固定时长',
                      style: text.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _skipOptions.map((int seconds) {
                        final bool isSelected =
                            prefs.defaultSkipIntroSeconds == seconds;
                        return ChoiceChip(
                          label: Text(seconds == 0 ? '不跳过' : '$seconds秒'),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              ref
                                  .read(preferencesProvider.notifier)
                                  .update((s) => s.copyWith(defaultSkipIntroSeconds: seconds));
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    Text('默认片尾跳过', style: text.titleSmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '章节临近结束时提前切至下一章',
                      style: text.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _skipOptions.map((int seconds) {
                        final bool isSelected =
                            prefs.defaultSkipOutroSeconds == seconds;
                        return ChoiceChip(
                          label: Text(seconds == 0 ? '不跳过' : '$seconds秒'),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            if (selected) {
                              ref
                                  .read(preferencesProvider.notifier)
                                  .update((s) => s.copyWith(defaultSkipOutroSeconds: seconds));
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
