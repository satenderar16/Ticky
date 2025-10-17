// Riverpod StreamProvider
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:quthon/Service/Battery/battery_model.dart';
import 'package:quthon/Service/Battery/battery_service.dart';

final batteryProvider = StreamProvider.autoDispose<BatteryState>((ref) {
  final stream = BatteryService.batteryStream;
  return stream;
});
