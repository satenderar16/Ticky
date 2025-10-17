import 'dart:async';
import 'package:flutter/services.dart';

/// Matches Android's NotificationManager interruption filters
enum DndFilter {
  unknown,   // 0 - INTERRUPTION_FILTER_UNKNOWN
  all,       // 1 - INTERRUPTION_FILTER_ALL
  priority,  // 2 - INTERRUPTION_FILTER_PRIORITY
  none,      // 3 - INTERRUPTION_FILTER_NONE - implies that whole notification is off
  alarms     // 4 - INTERRUPTION_FILTER_ALARMS
}

class DndService {
  static const MethodChannel _channel = MethodChannel('com.environ.quthon/dnd_method');
  static const EventChannel _event = EventChannel('com.environ.quthon/dnd_stream');

  /// Tracks whether DND was enabled by this app
  static bool enableByApp = false;

  /// Stores the DND filter value at app startup or initialization
  static DndFilter? initialFilter;

  /// Enables Do Not Disturb (DND) with INTERRUPTION_FILTER_NONE (no interruptions)
  static Future<void> enableDnd() async {
    await _channel.invokeMethod('enableDnd');
  }

  /// Disables Do Not Disturb (sets INTERRUPTION_FILTER_ALL)
  static Future<void> disableDnd() async {
    await _channel.invokeMethod('disableDnd');
  }

  /// Requests DND permission by opening the system settings screen
  static Future<void> requestPermission() async {
    await _channel.invokeMethod('requestPermission');
  }

  /// Returns true if the app has DND access permission
  static Future<bool> isPermissionGranted() async {
    final result = await _channel.invokeMethod('isPermissionGranted');
    return result == true;
  }

  /// Returns true if the system's DND filter is set to NONE (fully silenced)
  static Future<bool> isDndCurrentlyEnabled() async {
    final result = await _channel.invokeMethod('isDndCurrentlyEnabled');
    return result == true;
  }

  /// Gets the current raw DND filter as an enum
  static Future<DndFilter> getCurrentFilter() async {
    final code = await _channel.invokeMethod('getDndStatus');
    final parsed = parseFilter(code);
    return parsed;
  }

  /// Call this during app init to fetch and store the initial DND filter
  static Future<void> initializeDndFilter() async {
    final code = await _channel.invokeMethod('getDndStatus');
    initialFilter = parseFilter(code);
  }

  /// Listens to real-time changes in the DND filter
  static Stream<DndFilter> get dndFilterStream =>
      _event.receiveBroadcastStream().map(parseFilter);

  /// Maps raw Android values to [DndFilter] enum
  static DndFilter parseFilter(dynamic code) {
    switch (int.tryParse(code.toString())) {
      case 1:
        return DndFilter.all;
      case 2:
        return DndFilter.priority;
      case 3:
        return DndFilter.none;
      case 4:
        return DndFilter.alarms;
      default:
        return DndFilter.unknown;
    }
  }

  /// Optional helper for user-friendly labels
  static String label(DndFilter filter) {
    switch (filter) {
      case DndFilter.all:
        return "DND OFF";
      case DndFilter.priority:
        return "PRIORITY ONLY";
      case DndFilter.none:
        return "DND: ON";
      case DndFilter.alarms:
        return "ALARMS ONLY";
      case DndFilter.unknown:
        return "UNKNOWN";
    }
  }
}

