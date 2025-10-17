import 'package:flutter/services.dart';

enum PinState { pinned, unpinned, violation }

class PinService {
  static const _method = MethodChannel('com.environ.quthon/pin_method');
  static const _event = EventChannel('com.environ.quthon/pin_events');

  static Future<void> startPin() async =>
      await _method.invokeMethod('startPin');

  static Future<void> stopPin() async => await _method.invokeMethod('stopPin');

  static Future<int> getStatus() async =>
      await _method.invokeMethod('getStatus');

  static Future<void> setMonitorState(bool monitor) async {
    await _method.invokeMethod('setMonitorState', {'monitor': monitor});
  }

  static Stream<PinState> get pinEvents =>
      _event.receiveBroadcastStream().map(parsePinState);

  ///helper function to only get the fixed enum states, to avoid string handling via stream:
  static PinState parsePinState(dynamic value) {
    switch (value.toString().toLowerCase()) {
      case 'unpinned':
        return PinState.unpinned;
      case 'violation':
        return PinState.violation;
      case 'pinned':
      default:
        return PinState.pinned;
    }
  }
  // only works for some oems:

  ///  Check if screen pinning is enabled on the device
  static Future<bool> checkPermission() async {
    return await _method.invokeMethod("checkPermission");
  }

  ///  Open Android's settings screen to enable screen pinning manually
  static Future<void> requestPermission() async {
    await _method.invokeMethod("requestPermission");
  }
}
