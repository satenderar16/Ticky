import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod/riverpod.dart';

// Riverpod StreamProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod provider
final batteryProvider = StreamProvider.autoDispose<BatteryState>((ref) {
  return BatteryService.batteryStream;
});

class BatteryService {
  static const _channel = EventChannel('com.environ.quthon/battery');

  // Lazy stream — nothing listens until someone subscribes
  static Stream<BatteryState> get batteryStream =>
      _channel.receiveBroadcastStream().cast<String>().map((event) {
        return BatteryState.fromJson(event);
      });
}

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
