import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/ui/pages/settings/settings_page.dart';
import 'package:tometone/ui/pages/settings/widgets/settings_shared_widgets.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 外观设置二级页面。
class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPreferences prefs = ref.watch(preferencesProvider);
    final AppPaletteId currentPaletteId = paletteIdFromName(prefs.paletteId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('外观'),
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
                // 1. 明暗外观
                SettingsSectionCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    const SettingsSectionHeader(
                      title: '明暗外观',
                      subtitle: '跟随系统或固定浅色/深色主题',
                      icon: Icons.brightness_6_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<BrightnessPreference>(
                        showSelectedIcon: false,
                        segments: <ButtonSegment<BrightnessPreference>>[
                          ButtonSegment<BrightnessPreference>(
                            value: BrightnessPreference.system,
                            label: Text(
                              '跟随系统',
                              key: SettingsPage.brightnessKey(
                                BrightnessPreference.system,
                              ),
                            ),
                            icon: const Icon(Icons.brightness_auto_rounded),
                          ),
                          ButtonSegment<BrightnessPreference>(
                            value: BrightnessPreference.light,
                            label: Text(
                              '浅色',
                              key: SettingsPage.brightnessKey(
                                BrightnessPreference.light,
                              ),
                            ),
                            icon: const Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment<BrightnessPreference>(
                            value: BrightnessPreference.dark,
                            label: Text(
                              '深色',
                              key: SettingsPage.brightnessKey(
                                BrightnessPreference.dark,
                              ),
                            ),
                            icon: const Icon(Icons.dark_mode_rounded),
                          ),
                        ],
                        selected: <BrightnessPreference>{prefs.brightness},
                        onSelectionChanged: (Set<BrightnessPreference> selection) {
                          ref
                              .read(preferencesProvider.notifier)
                              .update((s) => s.copyWith(brightness: selection.first));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 2. 国风色盘
                SettingsSectionCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: <Widget>[
                    const SettingsSectionHeader(
                      title: '国风色盘',
                      subtitle: '融汇传统东方雅色，点染素雅听书意境',
                      icon: Icons.palette_rounded,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.spaceAround,
                      children: AppColorPalettes.all.map((AppPalette palette) {
                        final bool isSelected = palette.id == currentPaletteId;
                        return _PaletteOption(
                          palette: palette,
                          isSelected: isSelected,
                          onTap: () {
                            ref
                                .read(preferencesProvider.notifier)
                                .update((s) => s.copyWith(paletteId: palette.id.name));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. 显示与功耗
                SettingsSectionCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  children: <Widget>[
                    SwitchListTile(
                      key: SettingsPage.oledSwitchKey,
                      contentPadding: EdgeInsets.zero,
                      secondary: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: (prefs.oledDark &&
                                  prefs.brightness != BrightnessPreference.light)
                              ? scheme.primary.withValues(alpha: 0.12)
                              : scheme.surfaceContainerHighest,
                          borderRadius: AppRadii.md,
                        ),
                        child: Icon(
                          Icons.nightlight_round,
                          size: 20,
                          color: (prefs.oledDark &&
                                  prefs.brightness != BrightnessPreference.light)
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      title: const Text('暗夜 OLED 纯黑'),
                      subtitle: const Text('仅深色模式生效，背景降为纯黑节省功耗'),
                      value: prefs.oledDark,
                      onChanged: prefs.brightness == BrightnessPreference.light
                          ? null
                          : (bool val) {
                              ref
                                  .read(preferencesProvider.notifier)
                                  .update((s) => s.copyWith(oledDark: val));
                            },
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

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.palette,
    required this.isSelected,
    required this.onTap,
  });

  final AppPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final AppPaletteColors lightColors = palette.light;

    return Semantics(
      selected: isSelected,
      label: palette.label,
      button: true,
      child: InkWell(
        key: SettingsPage.appearancePaletteKey(palette.id),
        borderRadius: AppRadii.md,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: AppDurations.standardCurve,
          constraints: const BoxConstraints(
            minWidth: 80,
            minHeight: AppSizes.minTouchTarget,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: AppRadii.md,
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // 双色环 preview
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          lightColors.primary,
                          lightColors.primaryContainer,
                        ],
                      ),
                      boxShadow: isSelected
                          ? <BoxShadow>[
                              BoxShadow(
                                color: lightColors.primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: lightColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                palette.label,
                style: text.labelMedium?.copyWith(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
