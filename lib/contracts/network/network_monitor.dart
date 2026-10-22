/// 网络状态监控接口（纯 Dart 契约，不直接依赖平台通道）
abstract class NetworkMonitor {
  /// 是否处于 Wi-Fi 连接状态流
  Stream<bool> get isWifiConnectedStream;

  /// 当前是否处于 Wi-Fi 连接状态
  Future<bool> get isWifiConnected;
}
