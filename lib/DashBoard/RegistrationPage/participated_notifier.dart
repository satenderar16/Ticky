import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/Models/leaderboard_model.dart';
import 'package:quthon/Models/participate_model.dart';
import 'package:quthon/Models/register_models.dart';
import 'package:quthon/Repository/contest_repository.dart';

final participateProvider =
    StateNotifierProvider<ParticipatedNotifier, ParticipateState>(
      (ref) => ParticipatedNotifier(ref: ref),
    );

class ParticipatedNotifier extends StateNotifier<ParticipateState> {
  final Ref ref;

  Map<String?, int?> participateIdMap = {null: null};
  // to track already fetch details
  Set<String> contestId = {};
  ParticipatedNotifier({required this.ref})
    : super(const ParticipateState(participates: <ParticipateDetailModel>[]));

  void setSelectedParticipate({required String id}) {
    final idx = participateIdMap[id];
    if (idx == null) {
      return;
    }
    state = state.copyWith(selectedParticipated: state.participates[idx]);
  }

  // get current index of selected contest:
  int getSelectParticipateIndex() {
    final id = state.selectedParticipated?.contest.id;
    final idx = participateIdMap[id];
    if (id == null || idx == null) {
      debugPrint('selectedcontest/idx is null while getting contest idx');
      throw Exception('null operation used on null value:');
    }

    return idx;
  }

  void updateParticipate({
    int? index,
    required ParticipateDetailModel participate,
  }) {
    if (index != null) {
      state = state.copyWith(
        participates: ([...state.participates]..[index] = participate),
        selectedParticipated: participate,
      );

      return;
    }

    final idx = participateIdMap[participate.contest.id];
    if (idx == null) {
      debugPrint('participate not found return without updating the state');
      return;
    }

    state = state.copyWith(
      participates: ([...state.participates]..[idx] = participate),
      selectedParticipated: participate,
    );
  }

  //update participates list or insert new element if there is not such id:
  void upsertParticipate({
    required String id,
    required ContestDetailModel contest,
  }) {
    final idx = participateIdMap[id];
    if (idx == null) {
      // make sure to update the idx in participatedMap to avoid any inconsistency in ui

      state = state.copyWith(
        participates: ([
          ...state.participates,
          ParticipateDetailModel(contest: contest),
        ]),
      );

      //we can directly assign the in case of single update:
      final newMap = {contest.id: state.participates.length - 1};

      participateIdMap = {...participateIdMap, ...newMap};
      // optional: not updating contestId of already fetched details , just trying to let sync with server and only upating the list of participate intensionly:
      return;
    }

    final updateParticipate = state.participates[idx].copyWith(
      contest: contest,
    );

    final updateSelectedParticipate =
        (state.selectedParticipated != null &&
                state.selectedParticipated!.contest.id == contest.id)
            ? updateParticipate
            : null;

    state = state.copyWith(
      participates: ([...state.participates]..[idx] = updateParticipate),
      selectedParticipated: updateSelectedParticipate,
    );
  }

  Future<({bool hasNext, List<ParticipateDetailModel> participates})>
  getParticipateList({
    bool refresh = false,
    required int offset,
    int limit = 30,
  }) async {
    try {
      if (refresh) {
        offset = 0;
      }

      final responseBody = await ContestRepository.getParticipateContestList(
        offset: offset,
        limit: limit,
      );
      final response = await jsonDecode(responseBody);
      final List<dynamic> data = response['data'];
      final newParticipate =
          data
              .map(
                (e) =>
                    ParticipateDetailModel.fromJson(e as Map<String, dynamic>),
              )
              .toList();

      final hasNext = response['has_next'] as bool?;
      if (hasNext == null) {
        throw Exception('hasNext Exception found');
      }
      final newMap = {
        for (final entry in newParticipate.asMap().entries)
          entry.value.contest.id: offset + entry.key,
      };
      if (refresh) {
        state = state.copyWith(participates: newParticipate, hasNext: hasNext);
        participateIdMap = {...participateIdMap, ...newMap};
        contestId = {};
        debugPrint('contest id set is : ${contestId.toString()}');
      } else {
        state = state.copyWith(
          participates: [...state.participates, ...newParticipate],
          hasNext: hasNext,
        );
        participateIdMap = {...participateIdMap, ...newMap};
      }

      return (hasNext: hasNext, participates: newParticipate);
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  // get details if not available:
  Future<ParticipateDetailModel> getContestDetail({
    bool refresh = false,
  }) async {
    try {
      // await Future.delayed()
      final id = state.selectedParticipated?.contest.id;
      final idx = participateIdMap[id];
      if (id == null || idx == null) {
        throw Exception('ContestDetail exception found');
      }
      if (contestId.contains(id) && !refresh) {
        return state.participates[idx];
      }

      // get new details
      final responseBody = await ContestRepository.getContestDetail(id: id);
      final response = await jsonDecode(responseBody);
      final updatedParticipate = ParticipateDetailModel.fromJson(
        response,
      ); // or you can simply update the store copywith to maintain non chnage as they are;
      updateParticipate(participate: updatedParticipate);
      contestId.add(id);
      return state.participates[idx];
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  Future<String> joinContest() async {
    try {
      final id = state.selectedParticipated?.contest.id;
      final idx = participateIdMap[id];
      if (id == null || idx == null) {
        throw Exception('join contest Exception ');
      }

      final responseBody = await ContestRepository.patchJoinContest(id: id);
      final response = await jsonDecode(responseBody);
      final joinedAt =
          DateTime.parse(
            response['joined_at'],
          ).toLocal(); // use try catch to avoid any parsing errror:
      // update state
      final currentparticipated = state.participates[idx];
      final updateParticipated = currentparticipated.copyWith(
        contest: currentparticipated.contest.copyWith(
          joinedAt: joinedAt,
          currentStage: ContestStage.joined,
        ),
      );

      // also update in contestLive page as currentStage could be utilize there:

      updateParticipate(participate: updateParticipated);

      return response['detail'] ?? 'Successfull';
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  Future<String> submitContest() async {
    try {
      final id = state.selectedParticipated?.contest.id;
      final idx = participateIdMap[id];
      if (id == null || idx == null) {
        throw Exception(
          'contest submission exception: visit participation_notifier->submitContest',
        );
      }
      final responseBody = await ContestRepository.postContestSubmit(id: id);
      final response = await jsonDecode(responseBody);
      // update the state of contest:
      final submittedAt = DateTime.parse(response['submitted_at']).toLocal();
      final updatedParticipate = state.participates[idx].copyWith(
        contest: state.participates[idx].contest.copyWith(
          currentStage: ContestStage.submitted,
          schedulateAt: submittedAt,
        ),
      );
      // no need to update in contestLive as contest only going to be remove.

      // update in ui
      updateParticipate(participate: updatedParticipate);
      return response['detail'] ?? 'Contest Submission Successful';
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  Future<ResultModel> getResult({
    required String userId,
    bool refresh = false,
  }) async {
    try {
      // await Future.delayed(Duration(seconds: 2));
      // await Future.error('oops something fook liye');
      final participate = state.selectedParticipated;
      final id = participate?.contest.id;
      final idx = participateIdMap[id];
      if (participate == null || idx == null || id == null) {
        throw Exception('result exception found');
      }
      // if there and not refresh:
      if (participate.resultModel != null && !refresh) {
        return state.participates[idx].resultModel!;
      }
      // get the result from the server :

      final responseBody = await ContestRepository.getContestResult(
        id: id,
        userId: userId,
      );
      final response = await jsonDecode(responseBody);
      // parse the result, update state and return :
      final result = ResultModel.fromJson(response as Map<String, dynamic>);

      //update ui:
      final updated = state.participates[idx].copyWith(resultModel: result);

      updateParticipate(participate: updated);

      final updateResult = state.participates[idx].resultModel;

      if (updateResult == null) {
        throw Exception(
          'result exception found: state is not updated with result',
        );
      }

      return updateResult;
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  // get leaderboard info with hasNext value:
  Future<({List<LeaderboardModel> leaderboard, bool hasNext})>
  getLeaderboardList({
    required int offset,
    int limit = 30,
    bool refresh = false,
  }) async {
    try {
      final participate = state.selectedParticipated;
      final id = participate?.contest.id;
      final idx = participateIdMap[participate?.contest.id];
      if (participate == null || id == null || idx == null) {
        throw Exception('leaderborad exception found');
      }
      if (participate.leaderboard != null && !refresh) {
        return (
          leaderboard: state.participates[idx].leaderboard!,
          hasNext: state.participates[idx].leaderboardHasNext,
        );
      }
      // get the list of leaderboard:

      final responseBody = await ContestRepository.getContestLeaderboard(
        id: id,
      );
      final response = await jsonDecode(responseBody);

      final bool hasNext = (response['has_next'] ?? false);
      final List<dynamic> data = response['data'];
      final leaderboard =
          data
              .map((e) => LeaderboardModel.fromJson(e as Map<String, dynamic>))
              .toList();
      final updatedPar = state.participates[idx].copyWith(
        leaderboard: leaderboard,
        leaderboardHasNext: hasNext,
      );
      updateParticipate(participate: updatedPar);

      return (hasNext: hasNext, leaderboard: leaderboard);
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }
}

class ParticipateState {
  // list of participated
  final List<ParticipateDetailModel> participates;
  final bool hasNext; // to get list is fetched or not:
  final ParticipateDetailModel? selectedParticipated;

  const ParticipateState({
    required this.participates,
    this.hasNext = false,
    this.selectedParticipated,
  });

  ParticipateState copyWith({
    // null represent data is not fetch if empty means there is no data avilable
    List<ParticipateDetailModel>? participates,
    bool? hasNext,
    ParticipateDetailModel? selectedParticipated,
  }) {
    return ParticipateState(
      participates: participates ?? this.participates,
      selectedParticipated: selectedParticipated ?? this.selectedParticipated,
    );
  }
}
