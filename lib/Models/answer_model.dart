import 'package:flutter/foundation.dart';

class Answer {
  final String questionID;
  final String? optionID;
  final int questionIN;
  final int? optionIN;
  final bool review;
  final DateTime? startAt;
  final DateTime? endAt;

  Answer({
    required this.questionID,
    required this.questionIN,
    this.optionID,
    this.optionIN,
    this.review = false,
    required this.startAt,
    required this.endAt,
  });

  /// CopyWith
  Answer copyWith({
    String? questionID,
    String? optionID,
    int? questionIN,
    int? optionIN,
    bool? review,
    DateTime? startAt,
    DateTime? endAt,
  }) {
    return Answer(
      questionID: questionID ?? this.questionID,
      optionID:
          optionID, //wher user marked and then unmarked it copy with might assign previous value of option id when have null optional value . same goes for optionIN:
      questionIN: questionIN ?? this.questionIN,
      optionIN: optionIN,
      review: review ?? this.review,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'question_id': questionID,
      'option_id': optionID,
      'index': questionIN + 1, // should be > 0: to ensure the server validation
      // 'optionIN': optionIN ?? null.toString(),// ask for option_Index as well
      'started_at': startAt?.toIso8601String(),
      'finished_at': endAt?.toIso8601String(),
      // 'review':review.toString()// review optional:
    };
  }

  /// From JSON
  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      questionID: json['questionID'] as String,
      optionID: json['optionID'] as String?,
      questionIN: json['questionIN'] as int,
      optionIN: json['optionIN'] as int?,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: DateTime.parse(json['endAt'] as String),
    );
  }
}
