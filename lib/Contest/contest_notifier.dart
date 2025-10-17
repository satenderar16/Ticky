import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Auth/auth_provider.dart';
import 'package:quthon/Contest/contest_repository.dart';

import 'contest_model.dart';

/// LiveContest Provider
final contestProvider = StateNotifierProvider<ContestNotifier, LiveContest>((
  ref,
) {
  return ContestNotifier(ref: ref);
});

///  LiveContest State Class
class LiveContest {
  final bool isLoading;
  final String? onError;
  final List<ContestDetailModel> contests;
  final ContestDetailModel? selectedContest;
  const LiveContest({
    this.isLoading = false,
    this.onError,
    this.contests = const [],
    this.selectedContest,
  });

  LiveContest copyWith({
    bool? isLoading,
    String? onError,
    List<ContestDetailModel>? contests,
    ContestDetailModel? selectedContest,
    // Map<String, ContestDetailModel>? contestMap,
  }) {
    return LiveContest(
      isLoading: isLoading ?? this.isLoading,
      onError: onError,
      contests: contests ?? this.contests,
      selectedContest: selectedContest ?? this.selectedContest,
      // contestMap: contestM/p ?? this.contestMap,
      // selectedContest: selectedContest ?? this.selectedContest,
    );
  }
}

class ContestNotifier extends StateNotifier<LiveContest> {
  final Ref ref;
  ContestNotifier({required this.ref}) : super(const LiveContest()) {
    _loadContests(
      // indicating  schedule refresh:
      refreshFlag: true,
    );
  }

  /// Regular loading with isLoading = true
  Future<void> _loadContests({bool refreshFlag = false}) async {
    state = state.copyWith(isLoading: true, onError: null);
    try {
      // // fetch or start the schedule refresh first
      // if (refreshFlag) {
      //   final accessTime =
      //       ref
      //           .read(authNotifierProvider.notifier)
      //           .repository
      //           .accessTokenExpiry;

      //   await ref
      //       .read(authNotifierProvider.notifier)
      //       .scheduleRefresh(accessTime: accessTime ?? DateTime.now());
      // }

      final contests = await ContestRepository.getContestList();

      state = state.copyWith(isLoading: false, contests: contests);
    } catch (e) {
      state = state.copyWith(isLoading: false, onError: e.toString());
    }
  }

  ///  Refresh with loading indicator
  Future<void> refreshContests() async {
    await _loadContests();
  }

  /// Refresh silently without triggering loading indicator
  Future<void> silentRefreshContests() async {
    try {
      final contests = await ContestRepository.getContestList();
      state = state.copyWith(
        contests: contests,
        onError: null,
        // keep isLoading as is
      );
    } catch (e) {
      state = state.copyWith(onError: e.toString());
      debugPrint(e.toString());
    }
  }

  // update contest for more details. with index"
  void updateContestsList({
    required String id,
    required ContestDetailModel update,
  }) {
    // use index for void linear update:
    final contests = [
      for (final c in state.contests)
        if (c.id == update.id) update else c,
    ];

    state = state.copyWith(contests: contests, selectedContest: update);
  }

  void setSelectedContest(ContestDetailModel contest) {
    state = state.copyWith(selectedContest: contest);
  }

  /// load more will expand the available contests:
}
