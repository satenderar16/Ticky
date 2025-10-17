import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Service/Battery/battery_model.dart';
import 'package:quthon/Service/Battery/battery_service.dart';

final batteryProvider = StreamProvider.autoDispose<BatteryState>((ref) async* {
  await for (final data in BatteryService.batteryStream) {
    final parts = data.split(' ');
    final isCharging = parts.length == 2 && parts[0] == 'charging';
    final level = int.tryParse(isCharging ? parts[1] : parts[0]) ?? 0;

    yield BatteryState(level: level, isCharging: isCharging);
  }
});
