import 'package:flutter/services.dart';

enum CustomDeviceOrientation {
  portraitUp,
  portraitDown,
  landscapeLeft,
  landscapeRight,
}

class AutoRotate {
  static const MethodChannel _channel = MethodChannel(
    "com.environ.quthon/autorotate",
  );

  static Future<void> enableSensor() => _channel.invokeMethod("enableSensor");

  static Future<void> unlock() => _channel.invokeMethod("unlock");

  static Future<CustomDeviceOrientation> lockCurrent() async {
    final int orientationInt = await _channel.invokeMethod("lockCurrent");
    return _mapAndroidOrientation(orientationInt);
  }

  static CustomDeviceOrientation _mapAndroidOrientation(int value) {
    switch (value) {
      case 1:
        return CustomDeviceOrientation.portraitUp;

      case 8:
        return CustomDeviceOrientation.portraitDown;

      case 0:
        return CustomDeviceOrientation.landscapeLeft;

      case 9:
        return CustomDeviceOrientation.landscapeRight;

      default:
        return CustomDeviceOrientation.portraitUp;
    }
  }
}
