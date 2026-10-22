import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tometone/app/preferences/app_preferences.dart';
import 'package:tometone/app/providers/preferences_providers.dart';
import 'package:tometone/ui/pages/settings/settings_page.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/theme_tokens.dart';

/// 外观设置二级页面。
class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme text = Theme.of(context).textTheme;
    final AppPreferences prefs = ref.watch(preferencesProvider);
    final AppPaletteId currentPaletteId = paletteIdFromName(prefs.paletteId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('外观'),
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
                    Text('明暗外观', style: text.titleSmall),
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
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.lg),
                    Text('国风色盘', style: text.titleSmall),
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
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.xs),
                    SwitchListTile(
                      key: SettingsPage.oledSwitchKey,
                      contentPadding: EdgeInsets.zero,
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
              ),
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
        borderRadius: AppRadii.sm,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.minTouchTarget,
            minHeight: AppSizes.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: lightColors.primaryContainer,
                    border: Border.all(
                      color: isSelected ? scheme.primary : lightColors.primary,
                      width: isSelected ? 2.5 : 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: lightColors.onPrimaryContainer,
                        )
                      : null,
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
      ),
    );
  }
}
