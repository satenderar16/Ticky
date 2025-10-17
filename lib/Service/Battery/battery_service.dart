import 'dart:async';
import 'package:flutter/services.dart';

class BatteryService {
  static const _channel = EventChannel('com.environ.quthon/battery');

  static Stream<String> get batteryStream =>
      _channel.receiveBroadcastStream().cast<String>();
}