import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
///countdownProvider is help in getting the count of test reverse count down in ConestLive Card uses this for long lists:
final countdownProvider = StateNotifierProvider.family<CountdownController, CountdownState, DateTime>(
      (ref, targetTime) {
    return CountdownController(
      targetTime: targetTime,
      initialNow: DateTime.now(),
    );
  },
);


class CountdownState {
  final Duration remaining;
  final String displayText;

  const CountdownState({
    required this.remaining,
    required this.displayText,
  });

  bool get isStarted => remaining.inSeconds <= 0;
  bool get isLessThan10Minutes => remaining.inMinutes < 10 && remaining.inSeconds > 0;
}

class CountdownController extends StateNotifier<CountdownState> {
  final DateTime targetTime;
  final DateTime initialNow;

  late Duration _remaining;
  Timer? _timer;

  CountdownController({
    required this.targetTime,
    required this.initialNow,
  }) : super(const CountdownState(remaining: Duration.zero, displayText: '')) {
    _remaining = targetTime.difference(initialNow);
    _updateState();
    _scheduleTick();
  }

  void _scheduleTick() {
    if (_remaining.inSeconds <= 0) {
      _updateState();
      return;
    }

    final nextInterval = _nextTickInterval(_remaining);

    _timer = Timer(nextInterval, () {
      _remaining -= nextInterval;
      _updateState();
      _scheduleTick(); // keep ticking
    });
  }

  void _updateState() {
    final newState = CountdownState(
      remaining: _remaining,
      displayText: _format(_remaining),
    );

    if (newState.displayText != state.displayText) {
      state = newState;
    }
  }

  Duration _nextTickInterval(Duration remaining) {
    ///just update the update from zero to window of entry permitted. even set free permit implies no time restriction on entry
    ///so according to which we set Duration of tick after scheduled time of contest
    if (remaining.inSeconds <= 0) return Duration.zero;

    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = midnight.difference(now);

    if (remaining.inHours >= 24) {
      return timeUntilMidnight < const Duration(hours: 1)
          ? timeUntilMidnight
          : const Duration(hours: 1);
    }
    if (remaining.inMinutes > 2) {
      return const Duration(minutes: 1);
    }



    return const Duration(seconds: 1);
  }

  String _format(Duration diff) {
    ///update here as well what you want to send to widget
    if (diff.inSeconds <= 0) return 'Closed';

    if(diff.inMinutes <1)return '${diff.inSeconds}s';
    if (diff.inMinutes < 2) return '${diff.inMinutes}m ${diff.inSeconds % 60}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
