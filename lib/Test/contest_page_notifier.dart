import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Contest/contest_notifier.dart';
// import 'package:quthon/Contest/contest_notifier.dart';
import 'package:quthon/Contest/contest_repository.dart';

final contestPageProvider =
    StateNotifierProvider<ContestPageNotifier, ContestPageState>((ref) {
      return ContestPageNotifier(ref: ref);
    });

class ContestPageNotifier extends StateNotifier<ContestPageState> {
  final Ref ref;
  final List<String> contestID = [];

  ContestPageNotifier({required this.ref}) : super(ContestPageState.initial());

  Future<void> getContestDetail({bool refresh = false}) async {
    try {
      final id = ref.read(contestProvider).selectedContest!.id;
      state = state.loading();

      if (contestID.contains(id) && !refresh) {
        state = state.data(); // no change, but ensure not stuck in loading
        return;
      }
      // TODO check for the status and mode for detailed fetched:
      final contest = await ContestRepository.getContestDetail(id: id);

      // if (contest == null) throw Exception("Contest details null");

      contestID.add(contest.id);

      // Update state (data state)
      state = state.data(ids: List.from(contestID));

      // Update contest list provider
      ref
          .read(contestProvider.notifier)
          .updateContestsList(id: id, update: contest);
    } catch (e) {
      state = state.error(e.toString());
    }
  }

  Future<void> refreshContestDetail() async {
    await getContestDetail(
      refresh: true,
    ); // function handle all catch and update up:
  }

  Future<String?> participateContest() async {
    try {
      final contest = ref.read(contestProvider).selectedContest!;
      final success = await ContestRepository.postParticipate(id: contest.id);

      final updatedContest = contest.copyWith(
        participate: DateTime.now().toLocal(),
      );

      // Update contest list provider
      ref
          .read(contestProvider.notifier)
          .updateContestsList(id: contest.id, update: updatedContest);
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> joinContest() async {
    try {
      final contest = ref.read(contestProvider).selectedContest!;
      await ContestRepository.postJoinContest(id: contest.id);
    } catch (e) {
      rethrow;
    }
  }
}

@immutable
class ContestPageState {
  final List<String> contestsIds;
  final bool isLoading;
  final String? errorMessage;

  const ContestPageState({
    required this.contestsIds,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state
  factory ContestPageState.initial() {
    return const ContestPageState(contestsIds: []);
  }

  /// Loading state
  ContestPageState loading() {
    return ContestPageState(contestsIds: contestsIds, isLoading: true);
  }

  /// Error state
  ContestPageState error(String message) {
    return ContestPageState(contestsIds: contestsIds, errorMessage: message);
  }

  /// Success/data state
  ContestPageState data({List<String>? ids}) {
    return ContestPageState(contestsIds: ids ?? contestsIds);
  }

  ContestPageState copyWith({
    List<String>? contestsIds,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ContestPageState(
      contestsIds: contestsIds ?? this.contestsIds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  bool get hasError => errorMessage != null && errorMessage!.isNotEmpty;
}
