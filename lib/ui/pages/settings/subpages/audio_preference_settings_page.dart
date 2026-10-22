import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/ui/pages/settings/widgets/settings_shared_widgets.dart';
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
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPreferences prefs = ref.watch(preferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('听书偏好'),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.readingMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // 1. 默认播放倍速
                SettingsSectionCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    SettingsSectionHeader(
                      title: '默认播放倍速',
                      subtitle: '书籍初次播放时的默认倍速',
                      icon: Icons.speed_rounded,
                      iconColor: scheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _speedOptions.map((double speed) {
                        final bool isSelected =
                            (prefs.defaultPlaybackSpeed - speed).abs() < 0.01;
                        return ChoiceChip(
                          label: Text(
                            '${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 1 : 2)}x',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.md,
                            side: BorderSide(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
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
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. 默认片头跳过
                SettingsSectionCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    SettingsSectionHeader(
                      title: '默认片头跳过',
                      subtitle: '换章播放时自动跳过片头固定时长',
                      icon: Icons.skip_next_rounded,
                      iconColor: scheme.tertiary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _skipOptions.map((int seconds) {
                        final bool isSelected =
                            prefs.defaultSkipIntroSeconds == seconds;
                        return ChoiceChip(
                          label: Text(
                            seconds == 0 ? '不跳过' : '$seconds秒',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.md,
                            side: BorderSide(
                              color: isSelected
                                  ? scheme.tertiary
                                  : scheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
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
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. 默认片尾跳过
                SettingsSectionCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    SettingsSectionHeader(
                      title: '默认片尾跳过',
                      subtitle: '章节临近结束时提前切至下一章',
                      icon: Icons.fast_forward_rounded,
                      iconColor: scheme.secondary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _skipOptions.map((int seconds) {
                        final bool isSelected =
                            prefs.defaultSkipOutroSeconds == seconds;
                        return ChoiceChip(
                          label: Text(
                            seconds == 0 ? '不跳过' : '$seconds秒',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          showCheckmark: false,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadii.md,
                            side: BorderSide(
                              color: isSelected
                                  ? scheme.secondary
                                  : scheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
