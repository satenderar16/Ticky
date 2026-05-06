import 'package:flutter/material.dart';
import 'package:quthon/Models/register_models.dart';

/// contests List:
enum TimeDistribution { free, uniform }

enum ContestStatus { open, started, ongoing, closed, cancelled }
// open- before entry, started - entyr allow, ongoing- contest begin, closed - contest ended, cancelled(contest cancelled):

// "contest_joined_at": "2019-08-24T14:15:22Z",
// "total_joined": 0,
// "total_submissions": 0,
// "current_stage": "not participated"

class ContestDetailModel {
  final String id; //nn
  final String name; //nn
  final String description; //nn
  final DateTime scheduleAt; //nn
  final DateTime startAt; //nn
  final DateTime endAt; //nn
  // exact ending time
  ///may be we required the submit_at to let user submit in interval just like entry widnow it is submit window.
  final TimeDistribution timeDistribution; //nn
  final bool isPublic; //nn
  final DateTime createdAt; //nn
  final DateTime updateAt; //nn
  final int questionCount; //nn
  final Duration timeDuration; //nn
  final String? subject; //n
  final DateTime? participatedAt; //n when user isn't participated:
  final int participantCount; // nn (deafult is 0)
  final int marks; //nn
  final ContestStatus status; //nn
  // SHOULD WE NEED TO CALL THIS HERE as this only required in detail of register(participated) contest page: other than instruction: satisfy the case when already joined the user but user didn't refresh the contest and registration close and joining started:
  // simple contest status changes but user didn't refresh the contestList:instead he just fetch the contestDetails :
  // details fetched varible:
  final String? instruction;
  final DateTime? joinedAt;
  final int? joinedCount;
  final int? submissionCount;
  final ContestStage currentStage; // this can be null not required to be

  ContestDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.scheduleAt,
    required this.startAt,
    required this.endAt,
    required this.timeDistribution,
    required this.isPublic,
    required this.createdAt,
    required this.updateAt,

    required this.questionCount,
    required this.timeDuration,
    required this.subject,
    required this.participatedAt,
    required this.participantCount,
    required this.marks,
    required this.status,

    // this are detailed varibles:
    required this.instruction,
    required this.joinedAt,
    required this.joinedCount,
    required this.submissionCount,
    required this.currentStage,
  });

  factory ContestDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      return ContestDetailModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? "",
        scheduleAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
        startAt: DateTime.parse(json['starts_at'] as String).toLocal(),
        endAt: DateTime.parse(json['ends_at'] as String).toLocal(),
        timeDistribution: TimeDistribution.values.byName(
          json['time_distribution'] as String,
        ),
        isPublic: json['is_public'],
        createdAt:
            DateTime.tryParse(json['created_at'] ?? '')?.toLocal() ??
            DateTime.now().toLocal(),
        updateAt:
            DateTime.tryParse(json['updated_at'] ?? '')?.toLocal() ??
            DateTime.now().toLocal(),
        questionCount: json['total_questions'] as int,
        timeDuration: DateTime.parse(
          json['ends_at'] as String,
        ).difference(DateTime.parse(json['starts_at'] as String)),
        subject: json['subject'] ?? "",
        participatedAt:
            DateTime.tryParse(json['participated_at'] ?? '')?.toLocal(),
        participantCount: json['total_participants'] ?? 0,
        marks: json['total_marks'],
        status: ContestStatus.values.byName(json['status'] ?? 'open'),

        // this are detailed variables:
        instruction: json['instruction'],
        joinedAt: DateTime.tryParse(json['contest_joined_at'] ?? '')?.toLocal(),
        joinedCount: json['total_joined'],
        submissionCount: json['total_submissions'],
        currentStage: ContestStage.values.byName(
          json['current_stage'] == 'not_participated'
              ? 'none'
              : json['current_stage'] ?? 'none',
        ), // assuming none defualt:
      );
    } catch (e) {
      debugPrint('ContestDetailed Model parsing error: $e');
      throw 'Something went wrong';
    }
  }
  // TODO update this when creator section is open for the public or UI is ready to be used for devs:
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scheduled_at': scheduleAt.toUtc().toIso8601String(),
      'scheduleStartAt': startAt.toUtc().toIso8601String(),
      'scheduleEndAt': endAt.toUtc().toIso8601String(),
      'time_distribution': timeDistribution.name,
      'numberOfQuestions': questionCount,
      'timeDuration': timeDuration.inSeconds, // store as seconds
      'subject': subject,
      'participate': participatedAt,
      'status': status.name,
      'instruction': instruction ?? "",
    };
  }

  ContestDetailModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? schedulateAt,
    DateTime? startAt,
    DateTime? endAt,
    TimeDistribution? timeDistribution,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updateAt,
    int? questionCount,
    Duration? timeDuration,
    String? subject,
    DateTime? participateAt,
    int? participantCount,
    int? marks,
    ContestStatus? status,
    String? instruction,
    DateTime? joinedAt,
    int? joinedCount,
    int? submissionCount,
    ContestStage? currentStage,
  }) {
    return ContestDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      scheduleAt: schedulateAt ?? this.scheduleAt,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      timeDistribution: timeDistribution ?? this.timeDistribution,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updateAt: updateAt ?? this.updateAt,
      questionCount: questionCount ?? this.questionCount,
      timeDuration: timeDuration ?? this.timeDuration,
      subject: subject ?? this.subject,
      participatedAt: participateAt ?? this.participatedAt,
      participantCount: participantCount ?? this.participantCount,
      marks: marks ?? this.marks,
      status: status ?? this.status,
      instruction: instruction ?? this.instruction ?? "",
      joinedAt: joinedAt ?? this.joinedAt,
      joinedCount: joinedCount ?? this.joinedCount,
      submissionCount: submissionCount ?? this.submissionCount,
      currentStage: currentStage ?? this.currentStage,
    );
  }
}
