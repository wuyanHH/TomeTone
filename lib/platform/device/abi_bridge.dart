import 'package:flutter/services.dart';
import 'package:tometone/contracts/update/device_architecture.dart';

/// 硬件架构平台桥（Android Build.SUPPORTED_ABIS）。
class AbiBridge implements DeviceArchitecture {
  /// 创建 ABI 桥。
  const AbiBridge();

  static const MethodChannel _channel = MethodChannel('tometone/device');

  @override
  Future<List<String>> supportedAbis() async {
    try {
      final List<dynamic>? abis =
          await _channel.invokeMethod<List<dynamic>>('getSupportedAbis');
      return abis?.map((e) => e.toString()).toList() ?? const <String>[];
    } catch (_) {
      return const <String>[];
    }
  }
}
