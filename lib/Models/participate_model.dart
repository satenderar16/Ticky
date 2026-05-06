import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Contest/contest_model.dart';
import 'package:quthon/Models/leaderboard_model.dart';
import 'package:quthon/Models/option_model.dart';

// none is for the live contests:
// enum ContestStage { none, participated, joined, submitted }

class ParticipateDetailModel {
  ContestDetailModel contest;

  // directly used to manage state to call leaderboard or result with it.

  // for managing state effortlessly:
  final List<LeaderboardModel>?
  leaderboard; //n as only when user fetch leaderboard from the api avoiding multiple fetches:
  final bool leaderboardHasNext;

  // NOW: we are only saving the result of logged in user not of any other user , we gonna fetch the result if user request other users result:

  final ResultModel? resultModel; // only for the logged in user:

  ParticipateDetailModel({
    required this.contest,

    // have separate api calls
    this.leaderboard,
    this.leaderboardHasNext = false,
    this.resultModel,
  });
  // using the contests for now :
  factory ParticipateDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      return ParticipateDetailModel(contest: ContestDetailModel.fromJson(json));
    } catch (e) {
      debugPrint('Register model parsing error');
      throw 'Something went wrong';
    }
  }

  ParticipateDetailModel copyWith({
    ContestDetailModel? contest,
    List<LeaderboardModel>? leaderboard,
    bool? leaderboardHasNext,
    ResultModel? resultModel,
  }) {
    return ParticipateDetailModel(
      contest: contest ?? this.contest,
      leaderboard: leaderboard ?? this.leaderboard,
      leaderboardHasNext: leaderboardHasNext ?? this.leaderboardHasNext,
      resultModel: resultModel ?? this.resultModel,
    );
  }

  Map<String, dynamic> toJson() {
    final c = contest; // shorthand alias for readability

    return {
      'id': c.id,
      'name': c.name,
      'description': c.description,
      if (c.instruction != null) 'instruction': c.instruction,

      'scheduled_at': c.scheduleAt.toIso8601String(),
      'starts_at': c.startAt.toIso8601String(),
      'ends_at': c.endAt.toIso8601String(),
      'time_distribution': c.timeDistribution.toString().split('.').last,
      'total_questions': c.questionCount,
      'participated_at': c.participatedAt?.toIso8601String(),
      if (c.joinedAt != null)
        'contest_joined_at': c.joinedAt!.toIso8601String(),
      'status': c.status.toString().split('.').last,
      'total_participate': c.participantCount,
      'total_joined': c.joinedCount,
      'total_submission': c.submissionCount,
    };
  }
}

class ResultModel {
  final double score; // nn
  final int rank; // nn
  final List<ResultQuestionModel> questions; // nn

  ResultModel({
    required this.score,
    required this.rank,
    required this.questions,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    try {
      return ResultModel(
        score: (json['score'] as num).toDouble(),
        rank: json['rank'] ?? -1,
        questions:
            (json['questions'] as List)
                .map((e) => ResultQuestionModel.fromJson(e))
                .toList(),
      );
    } catch (e) {
      debugPrint('Result model parsing error');
      throw 'Something went wrong';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'rank': rank,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

class ResultQuestionModel {
  // as result model is going to be used in both contests type uniform and free.
  final String id; // nn
  final String text; // nn
  final int? index; // n when user didn't select the option:
  final String?
  selectedOptionId; // n as might the case when user didn't answered the question:
  final DateTime? startAt;
  final DateTime? endAt;
  final double? timeTaken; // nn
  final List<Option> options; // nn

  ResultQuestionModel({
    required this.id,
    required this.text,
    required this.index,
    this.selectedOptionId,
    this.startAt,
    this.endAt,
    this.timeTaken,
    required this.options,
  });

  factory ResultQuestionModel.fromJson(Map<String, dynamic> json) {
    try {
      return ResultQuestionModel(
        id: json['question_id'] as String,
        text: json['question'] as String,
        index: json['attempt_index'] as int?, // could be null
        selectedOptionId: json['attempt_option_id'] as String?,
        startAt: DateTime.tryParse(
          json['attempt_started_at'] ?? '',
        ), // try parsing for now:
        endAt: DateTime.tryParse(json['attempt_finished_at'] ?? ''),
        timeTaken: (json['attempt_duration_in_seconds'] as num?)?.toDouble(),
        options:
            (json['options']
                    as List) // option is define in models as it shared with the contestOption:s
                .map((e) => Option.fromResultJson(e))
                .toList(),
      );
    } catch (e) {
      debugPrint('Result Question parsing errror found: $e');
      throw 'Something went wrong';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'attempt_option_id': selectedOptionId,
      'attempt_duration_in_seconds': timeTaken,
      'options': options.map((e) => e.toResultJson()).toList(),
    };
  }
}
