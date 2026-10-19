import 'package:flutter_test/flutter_test.dart';

import '../../tool/ci/brand_asset_rules.dart';

void main() {
  group('pngSize / pngColorType', () {
    test('读 IHDR 的宽、高与颜色类型', () {
      // PNG 签名 + IHDR 长度/类型 + 宽 48 / 高 72 / 位深 8 / 颜色类型 6
      final bytes = <int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0, 0, 0, 13, 0x49, 0x48, 0x44, 0x52,
        0, 0, 0, 48,
        0, 0, 0, 72,
        8, 6, 0, 0, 0,
      ];
      expect(pngSize(bytes), (48, 72));
      expect(pngColorType(bytes), 6);
    });

    test('不是 PNG 时返回 null', () {
      expect(pngSize(<int>[1, 2, 3]), isNull);
      expect(pngColorType(<int>[1, 2, 3]), isNull);
    });
  });

  group('maxVertexDistance', () {
    test('取相对画布中心的最远顶点', () {
      // 中心 (54,54)；(66,66) 距离 = sqrt(144+144) ≈ 16.97
      expect(maxVertexDistance(<double>[54, 54, 66, 66]), closeTo(16.97, 0.01));
    });

    test('空输入返回 0', () {
      expect(maxVertexDistance(<double>[]), 0);
    });
  });

  group('maxStrokeWidth', () {
    test('取最大笔宽', () {
      expect(
        maxStrokeWidth('<path android:strokeWidth="3"/><path android:strokeWidth="3.4"/>'),
        3.4,
      );
    });

    test('没有笔宽时为 0', () {
      expect(maxStrokeWidth('<path android:fillColor="#00000000"/>'), 0);
    });
  });

  group('contrastRatio', () {
    test('纸白对墨蓝符合文档实测值', () {
      // 《tometone_brand_icon_splash.md》§2：13.37:1
      expect(contrastRatio('#FFF2F4E9', '#FF0E2A3B'), closeTo(13.37, 0.01));
    });

    test('同色为 1:1', () {
      expect(contrastRatio('#FF0E2A3B', '#FF0E2A3B'), closeTo(1.0, 0.001));
    });

    test('接受 #RRGGBB 简写', () {
      expect(contrastRatio('#F2F4E9', '#0E2A3B'), closeTo(13.37, 0.01));
    });
  });

  group('pathDataOf', () {
    test('取出所有 pathData 与 d 属性', () {
      const xml = '<path android:pathData="M1,2 L3,4"/><path d="M5,6"/>';
      expect(pathDataOf(xml), <String>['M1,2 L3,4', 'M5,6']);
    });
  });
}
