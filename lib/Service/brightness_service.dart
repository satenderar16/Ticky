import 'package:flutter/services.dart';

class BrightnessService {
  static const MethodChannel _channel =
  MethodChannel('com.environ.quthon/brightness');


  /// Get system brightness (0.0 to 1.0)
 static Future<double> getSystemBrightness() async {
    final int raw = await _channel.invokeMethod('getSystemBrightness');
    return raw.clamp(0, 255) / 255.0;
  }

  /// Set app-level brightness , null implies to the system brightness
 static Future<void> setBrightness(double? value) async {
    await _channel.invokeMethod('setBrightness', {
      'value': value,
    });
  }



  /// Manually change brightness within app
 static Future<void> applyCustomBrightness(double value) async {
    await setBrightness(value);
  }

  /// Restore original system brightness (window-level only)
 static Future<void> restore() async {
      await setBrightness(null);

  }
}
