import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/ui/theme/app_color_palette.dart';
import 'package:tometone/ui/theme/app_theme.dart';

/// WCAG 2.x 相对亮度对比度公式。
double contrastRatio(Color foreground, Color background) {
  final double a = foreground.computeLuminance();
  final double b = background.computeLuminance();
  final double lighter = math.max(a, b);
  final double darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}

/// 参与门禁的语义文字/底色组合。
const List<(String, String)> _pairs = <(String, String)>[
  ('onSurface/surface', '正文'),
  ('onPrimary/primary', '主色按钮文字'),
  ('onSurfaceVariant/surface', '次级文字'),
  ('onPrimaryContainer/primaryContainer', '选中态/封面字标'),
  ('onSecondaryContainer/secondaryContainer', '导航指示器'),
  ('onError/error', '错误按钮文字'),
  ('onErrorContainer/errorContainer', '错误容器文字'),
];

/// 取一对语义色的实际颜色。
Color _colorOf(AppPaletteColors colors, String pair, bool foreground) {
  final String key = pair.split('/')[foreground ? 0 : 1];
  return switch (key) {
    'onSurface' => colors.onSurface,
    'onPrimary' => colors.onPrimary,
    'onSurfaceVariant' => colors.onSurfaceVariant,
    'onPrimaryContainer' => colors.onPrimaryContainer,
    'onSecondaryContainer' => colors.onSecondaryContainer,
    'onError' => colors.onError,
    'onErrorContainer' => colors.onErrorContainer,
    'surface' => colors.surface,
    'primary' => colors.primary,
    'primaryContainer' => colors.primaryContainer,
    'secondaryContainer' => colors.secondaryContainer,
    'error' => colors.error,
    'errorContainer' => colors.errorContainer,
    _ => throw ArgumentError.value(key, 'pair', '未知语义色'),
  };
}

void main() {
  group('五套色盘 × 明/暗 × OLED 对比度均达 WCAG AA', () {
    for (final AppPalette palette in AppColorPalettes.all) {
      for (final Brightness brightness in Brightness.values) {
        // 四种组合全测：oled 只改变深色形态，浅色形态重复覆盖以证明该开关
        // 不会破坏浅色下的可读性（见下方"浅色形态不受 OLED 开关影响"）。
        for (final bool oled in const <bool>[false, true]) {
          final AppPaletteColors colors = palette.colorsFor(
            brightness,
            oled: oled,
          );
          final String tag =
              '${palette.label} · ${brightness == Brightness.light ? '浅色' : '深色'}'
              '${oled ? ' · OLED' : ''}';

          test(tag, () {
            for (final (String pair, String label) in _pairs) {
              final double ratio = contrastRatio(
                _colorOf(colors, pair, true),
                _colorOf(colors, pair, false),
              );
              expect(
                ratio,
                greaterThanOrEqualTo(4.5),
                reason:
                    '$tag · $label（$pair）对比度 ${ratio.toStringAsFixed(2)}:1 未达 AA',
              );
            }
          });
        }
      }
    }
  });

  group('暗夜 OLED 约束', () {
    test('OLED 背景为纯黑，中间色阶被压暗，不产生灰雾', () {
      for (final AppPalette palette in AppColorPalettes.all) {
        final AppPaletteColors oled = palette.colorsFor(
          Brightness.dark,
          oled: true,
        );
        expect(oled.surface, const Color(0xFF000000), reason: palette.label);
        expect(
          oled.surfaceContainerLowest,
          const Color(0xFF000000),
          reason: palette.label,
        );
        expect(
          oled.surfaceContainerHighest.computeLuminance(),
          lessThan(0.02),
          reason: '${palette.label} 最高容器层过亮，OLED 上会发灰',
        );
      }
    });

    test('OLED 强调色亮度与饱和度均低于普通深色，避免发光刺眼', () {
      for (final AppPalette palette in AppColorPalettes.all) {
        final AppPaletteColors dark = palette.colorsFor(Brightness.dark);
        final AppPaletteColors oled = palette.colorsFor(
          Brightness.dark,
          oled: true,
        );
        expect(
          oled.primary.computeLuminance(),
          lessThan(dark.primary.computeLuminance()),
          reason: palette.label,
        );
        expect(
          HSVColor.fromColor(oled.primary).saturation,
          lessThanOrEqualTo(HSVColor.fromColor(dark.primary).saturation),
          reason: palette.label,
        );
      }
    });

    test('浅色形态不受 OLED 开关影响', () {
      for (final AppPalette palette in AppColorPalettes.all) {
        expect(
          palette.colorsFor(Brightness.light, oled: true),
          same(palette.light),
          reason: palette.label,
        );
      }
    });
  });

  group('ThemeData 工厂', () {
    test('五套色盘 × 明暗 × OLED 均可构建，且语义色映射正确', () {
      for (final AppPalette palette in AppColorPalettes.all) {
        for (final Brightness brightness in Brightness.values) {
          final List<bool> oledModes = brightness == Brightness.dark
              ? const <bool>[false, true]
              : const <bool>[false];
          for (final bool oled in oledModes) {
            final AppPaletteColors colors = palette.colorsFor(
              brightness,
              oled: oled,
            );
            final ThemeData theme = AppTheme.build(
              palette: palette,
              brightness: brightness,
              oled: oled,
            );
            expect(theme.useMaterial3, isTrue);
            expect(theme.colorScheme.surface, colors.surface);
            expect(theme.colorScheme.onSurface, colors.onSurface);
            expect(theme.colorScheme.primary, colors.primary);
            expect(theme.scaffoldBackgroundColor, colors.surface);
            expect(theme.extension<MiniPlayerTheme>(), isNotNull);
            expect(
              theme.textTheme.bodyMedium?.height,
              greaterThanOrEqualTo(1.6),
              reason: '中文正文行高应偏宽松',
            );
          }
        }
      }
    });
  });

  group('色盘集合完整性', () {
    test('五套色盘标识、名称唯一且可反查', () {
      expect(AppColorPalettes.all, hasLength(5));
      expect(
        AppColorPalettes.all.map((AppPalette p) => p.id).toSet(),
        hasLength(5),
      );
      expect(
        AppColorPalettes.all.map((AppPalette p) => p.label).toSet(),
        hasLength(5),
      );
      for (final AppPalette palette in AppColorPalettes.all) {
        expect(AppColorPalettes.byId(palette.id), same(palette));
      }
    });
  });
}
