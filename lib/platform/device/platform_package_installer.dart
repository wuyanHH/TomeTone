import 'package:flutter/services.dart';
import 'package:tometone/contracts/update/package_installer.dart';

/// 平台安装包安装器实现（通过 `tometone/device` 通道触发系统安装）。
class PlatformPackageInstaller implements PackageInstaller {
  /// 创建平台安装包安装器。
  const PlatformPackageInstaller();

  static const MethodChannel _channel = MethodChannel('tometone/device');

  @override
  Future<bool> installApk(String filePath) async {
    try {
      final bool? ok = await _channel.invokeMethod<bool>(
        'installApk',
        <String, Object?>{'filePath': filePath},
      );
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
