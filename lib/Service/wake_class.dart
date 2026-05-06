import 'package:flutter/services.dart';

// TODO when this serve for multiple plaform we replace this the multidevice functionality:

class WakeClass {
  static const MethodChannel _channel = MethodChannel(
    'com.environ.quthon/wake',
  );
  static bool _active = false;

  static Future<void> enable() async {
    if (!_active) {
      await _channel.invokeMethod('keepScreenOn');
      _active = true;
    }
  }

  static Future<void> disable() async {
    if (_active) {
      await _channel.invokeMethod('allowSleep');
      _active = false;
    }
  }
}
