import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:tometone/contracts/network/network_monitor.dart';

class TestNetworkMonitor implements NetworkMonitor {
  final _controller = StreamController<bool>.broadcast();
  bool _current = true;

  @override
  Stream<bool> get isWifiConnectedStream => _controller.stream;

  @override
  Future<bool> get isWifiConnected async => _current;

  void emit(bool isWifi) {
    _current = isWifi;
    _controller.add(isWifi);
  }

  void dispose() => _controller.close();
}

void main() {
  test('NetworkMonitor mock reports wifi state and emits changes', () async {
    final monitor = TestNetworkMonitor();
    expect(await monitor.isWifiConnected, isTrue);

    final emitted = <bool>[];
    final sub = monitor.isWifiConnectedStream.listen(emitted.add);

    monitor.emit(false);
    monitor.emit(true);
    await pumpEventQueue();

    expect(emitted, [false, true]);
    expect(await monitor.isWifiConnected, isTrue);
    await sub.cancel();
    monitor.dispose();
  });
}
