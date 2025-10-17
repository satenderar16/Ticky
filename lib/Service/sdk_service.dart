
import 'package:flutter/services.dart';

class PlatformSdk {
  static const MethodChannel _channel = MethodChannel('com.environ.quthon/sdk');

  static Future<int> getAndroidSdkVersion() async {

      return await _channel.invokeMethod('getSdkVersion');

  }
}
