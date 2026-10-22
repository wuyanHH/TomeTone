import 'package:connectivity_plus/connectivity_plus.dart';
import '../../contracts/network/network_monitor.dart';

class NetworkMonitorImpl implements NetworkMonitor {
  final Connectivity _connectivity;

  NetworkMonitorImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  @override
  Stream<bool> get isWifiConnectedStream {
    return _connectivity.onConnectivityChanged.map(
      (results) => results.contains(ConnectivityResult.wifi),
    );
  }

  @override
  Future<bool> get isWifiConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }
}
