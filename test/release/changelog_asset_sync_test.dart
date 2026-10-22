import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assets/changelog/CHANGELOG.md 与仓库根 CHANGELOG.md 完全一致', () {
    final root = File('CHANGELOG.md').readAsStringSync();
    final copy = File('assets/changelog/CHANGELOG.md').readAsStringSync();
    expect(
      copy,
      root,
      reason: '更新历史打包的是根 CHANGELOG 的快照，发版时必须同步',
    );
  });
}
