import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/DashBoard/RegistrationPage/participated_notifier.dart';
import 'package:quthon/Repository/contest_repository.dart';
import 'contest_model.dart';

/// LiveContest Provider
final contestProvider = StateNotifierProvider<ContestNotifier, LiveContest>((
  ref,
) {
  return ContestNotifier(ref: ref);
});

class ContestNotifier extends StateNotifier<LiveContest> {
  final Ref ref;
  ContestNotifier({required this.ref}) : super(const LiveContest());

  Map<String?, int?> contestIdsMap = {null: null};

  //track the detailed fetched with ids:

  Set<String> contestfetched = {};

  void setSelectedContest({required String id}) {
    final index = contestIdsMap[id];
    if (index == null) {
      return;
    }
    state = state.copyWith(selectedContest: state.contests[contestIdsMap[id]!]);
  }

  void updateContest({int? index, required ContestDetailModel contest}) {
    if (index != null) {
      state = state.copyWith(
        contests: ([...state.contests]..[index] = contest),
        selectedContest: contest,
      );
      return;
    }
    final idx = contestIdsMap[contest.id];
    if (idx == null) {
      debugPrint('idx exception found while updating the value of contest:');
      return;
    }
    state = state.copyWith(
      contests: ([...state.contests]..[idx] = contest),
      selectedContest: contest,
    );
  }

  //----------------------------------------------------------------------------------------------------->

  Future<({bool hasNext, List<ContestDetailModel> contests})> getContestList({
    required int offset,
    int limit = 30,
    bool refresh = false,
  }) async {
    // on refresh we are also calling the notifier invalidator which deleted contestFetch set:
    try {
      // offset is zero when user refresh it
      if (refresh) {
        offset = 0;
      }
      final responseBody = await ContestRepository.getContestList(
        offset: offset,
        limit: limit,
      );
      if (responseBody == null) {
        throw Exception('contest list response exception ');
      }
      final response = await jsonDecode(responseBody);
      final List<dynamic> data = response['data'];
      final bool hasNext = response['has_next'] ?? false;
      final newContests =
          data.map((d) => ContestDetailModel.fromJson(d)).toList();

      final newMap = {
        for (final entry in newContests.asMap().entries)
          entry.value.id: offset + entry.key,
      };
      // update with new list :
      if (refresh) {
        state = state.copyWith(contests: newContests, hasNext: hasNext);
        contestIdsMap = newMap;
      } else {
        state = state.copyWith(
          contests: [...state.contests, ...newContests],
          hasNext: hasNext,
        );

        contestIdsMap = {...contestIdsMap, ...newMap};
      }

      return (hasNext: hasNext, contests: newContests);
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  Future<ContestDetailModel> getContestDetail({bool refresh = false}) async {
    try {
      // await Future.delayed(Duration(seconds: 10));
      final contestId = state.selectedContest?.id;
      final idx = contestIdsMap[contestId];
      if (contestId == null || idx == null) {
        throw Exception('contest details fetching exception');
      }
      if (contestfetched.contains(contestId) && !refresh) {
        return state.contests[idx];
      }
      final responseBody = await Future.wait([
        ContestRepository.getContestDetail(id: contestId),
        Future.delayed(
          Duration(milliseconds: 500),
        ), // to make sure animation or any bouncing effect got updated based on it:
      ]);

      final data = await jsonDecode(responseBody[0]);
      final updated = ContestDetailModel.fromJson(data);
      contestfetched.add(updated.id);

      // this will only update the contest but not the contestId -> already have details:
      updateContest(contest: updated);
      return updated;
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  Future<String> postContestParticipate() async {
    try {
      final id = state.selectedContest?.id;
      final idx = contestIdsMap[id];
      if (id == null || idx == null) {
        throw Exception('post ContestParticipated exception:');
      }
      final responseBody = await ContestRepository.postParticipate(id: id);
      final response = await jsonDecode(responseBody);
      final currContest = state.contests[idx];

      final updatedContest = currContest.copyWith(
        // trying to parsing the time should be not null:
        participateAt: DateTime.parse(response['participated_at']).toLocal(),
      );
      updateContest(contest: updatedContest);

      ref
          .read(participateProvider.notifier)
          .upsertParticipate(id: id, contest: updatedContest);

      // update the state:
      return response['detail'] ?? 'Successfull';
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  Future<String> joinContest() async {
    try {
      final id = state.selectedContest?.id;
      final idx = contestIdsMap[id];
      if (id == null || idx == null) {
        throw Exception('joining exception found');
      }
      final reponseBody = await ContestRepository.patchJoinContest(id: id);

      final response = await jsonDecode(reponseBody);

      //update state:

      final currentContest = state.contests[idx];
      final updatedContest = currentContest.copyWith(
        joinedAt: DateTime.parse(response['joined_at']).toLocal(),
      );
      updateContest(contest: updatedContest);

      ref
          .read(participateProvider.notifier)
          .upsertParticipate(id: id, contest: updatedContest);
      return response['detail'] ?? 'Successfull';
    } on Exception {
      // debugPrint(e)
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  // update contest for more details. with index"
  void updateContestsList({
    required String id,
    required ContestDetailModel update,
  }) {
    final index = contestIdsMap[id]!;
    state.contests[index] =
        update; // this only work as went this happends it mututate the entire list as first child instead of nested:

    state = state.copyWith(selectedContest: update);
  }

  /// load more will expand the available contests:
}

///  LiveContest State Class
class LiveContest {
  final List<ContestDetailModel> contests;
  final ContestDetailModel? selectedContest;
  final bool
  hasNext; // never gonna use as it is the first page always build from the scratch:
  const LiveContest({
    this.contests = const [],
    this.selectedContest,
    this.hasNext = false,
  });

  LiveContest copyWith({
    List<ContestDetailModel>? contests,
    ContestDetailModel? selectedContest,
    bool? hasNext,
    // Map<String, ContestDetailModel>? contestMap,
  }) {
    return LiveContest(
      contests: contests ?? this.contests,
      selectedContest: selectedContest ?? this.selectedContest,
      hasNext: hasNext ?? this.hasNext,
      // contestMap: contestM/p ?? this.contestMap,
      // selectedContest: selectedContest ?? this.selectedContest,
    );
  }
}
