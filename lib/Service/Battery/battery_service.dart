import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

class BatteryState {
  final int level;
  final bool isCharging;
  final String health;

  BatteryState({
    required this.level,
    required this.isCharging,
    required this.health,
  });

  factory BatteryState.fromJson(String jsonStr) {
    final map = json.decode(jsonStr) as Map<String, dynamic>;
    return BatteryState(
      level: map['level'] ?? 0,
      isCharging: map['charging'] ?? false,
      health: map['health'] ?? 'Unknown',
    );
  }
}

class BatteryService {
  static const _channel = EventChannel('com.environ.quthon/battery');

  static Stream<BatteryState> get batteryStream =>
      _channel.receiveBroadcastStream().cast<String>().map((event) {
        return BatteryState.fromJson(event);
      });
}
