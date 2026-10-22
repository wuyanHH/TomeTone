/// 设备架构契约（《架构需求文档》2.7 与更新基础设施）。
///
/// 纯 Dart 类，严禁依赖 Flutter。
library;

/// 设备硬件架构接口。
abstract interface class DeviceArchitecture {
  /// 获取设备支持的 ABI 列表（按优先级降序排列，例如 `['arm64-v8a', 'armeabi-v7a']`）。
  Future<List<String>> supportedAbis();
}
