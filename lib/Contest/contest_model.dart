/// contests List:
enum TimeDistribution { free, uniform }
//status is changing with time to reduce rebuiling with constant with time depends avoid showing it on list views.
// we can achieve such functionality with .familiy notifier for time based rebuilding.
// class ContestListModel {
//   final String id;
//   final String name;
//   // final String description;
//   final DateTime schedulateAt;
//   final DateTime startAt;
//   final DateTime endAt;///to get the exact time of ending the contest instead of Duration:
//   final TimeDistribution timeDistribution;/// this helps in find test if time bound for each question or not. each contest have a specific time.
//   final int numberOfQuestions;// for now we just let it here due to highly coupling with contestEntry class.
//   final Duration timeDuration; /// get the actually time duration to start and end the contest
//   // final String subject;// for v0 this string are later need to change it:
//   final bool participate;// either already joined or not:
// // status is not needed in listing it is based on startAt and endAt.
//   ContestListModel({
//     required this.id,
//     required this.name,
//     // required this.description,
//     required this.schedulateAt,
//     required this.startAt,
//     required this.endAt,
//     required this.timeDistribution,
//     required this.numberOfQuestions,
//     required this.timeDuration,
//     // required this.subject,
//     required this.participate
//   });

//   factory ContestListModel.fromJson(Map<String, dynamic> json) {
//     return ContestListModel(
//       id: json['id'] as String,
//       name: json['name'] as String,
//       // description: json['description'] as String,
//       schedulateAt: DateTime.parse(json['scheduled_at'] as String),
//       startAt: DateTime.parse(json['start_at'] as String).toLocal(),
//       endAt: DateTime.parse(json['end_at'] as String).toLocal(),
//       timeDistribution:TimeDistribution.values.byName( json['time_distribution'] as String),
//       numberOfQuestions: json['numberOfQuestions'] as int? ?? 10,
//       timeDuration: DateTime.parse(json['end_at'] as String).difference(DateTime.parse( json['start_at'] as String)),// #TODO update with api value, in upcoming version.
//       // subject: json['subject'] ==null?"":json['subject'] as String,
//       participate: json['participate'] as bool? ?? false
//     );
//   }

//   /// Convert to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'name': name,
//       // 'description': description,
//       'start_at': startAt.toUtc().toIso8601String(),
//       'end_at': endAt.toUtc().toIso8601String(),
//       'time_distribution': timeDistribution,
//       'numberOfQuestions': numberOfQuestions,
//       'timeDuration': timeDuration.inSeconds, // store as seconds
//       // 'subject': subject,
//     };
//   }

//   /// Copy with updated values
//   ContestListModel copyWith({
//     String? id,
//     String? name,
//     String? description,
//     DateTime? startAt,
//     DateTime? endAt,
//     TimeDistribution? timeDistribution,
//     int? numberOfQuestions,
//     Duration? timeDuration,
//     String? subject,
//     bool? participate,
//     DateTime? schedulateAt
//   }) {
//     return ContestListModel(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       // description: description ?? this.description,
//       schedulateAt: schedulateAt ?? this.schedulateAt,
//       startAt: startAt ?? this.startAt,
//       endAt: endAt ?? this.endAt,
//       timeDistribution: timeDistribution ?? this.timeDistribution,
//       numberOfQuestions: numberOfQuestions ?? this.numberOfQuestions,
//       timeDuration: timeDuration ?? this.timeDuration,
//       // subject: subject ?? this.subject,
//       participate:participate?? this.participate
//     );
//   }
// }

/// Contest Detailed Model:
///

enum ContestStatus { open, started, ongoing, closed, cancelled }
// open- before entry, started - entyr allow, ongoing- contest begin, closed - contest ended, cancelled(contest cancelled):

class ContestDetailModel {
  final String id; //-
  final String name; //-
  final String?
  description; //-(api could send null) // detailed description of contest
  final DateTime schedulateAt; //- // when it was scheduled
  final DateTime startAt; //-
  final DateTime endAt; //-
  // exact ending time
  ///may be we required the submit_at to let user submit in interval just like entry widnow it is submit window.
  final TimeDistribution timeDistribution; //-
  final int numberOfQuestions; //-
  final Duration timeDuration; //-
  final String? subject;
  final DateTime? participate; //- // whether user joined or not
  final ContestStatus? status;
  final String? instruction;
  // total participants for upcoming version.

  ContestDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.schedulateAt,
    required this.startAt,
    required this.endAt,
    required this.timeDistribution,
    required this.numberOfQuestions,
    required this.timeDuration,
    required this.subject,
    required this.participate,
    required this.status,
    required this.instruction,
  });

  factory ContestDetailModel.fromJson(Map<String, dynamic> json) {
    return ContestDetailModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? "",
      schedulateAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      startAt: DateTime.parse(json['starts_at'] as String).toLocal(),
      endAt: DateTime.parse(json['ends_at'] as String).toLocal(),
      timeDistribution: TimeDistribution.values.byName(
        json['time_distribution'] as String,
      ),
      numberOfQuestions:
          json['numberOfQuestions'] == null
              ? 10
              : json['numberOfQuestions'] as int,
      timeDuration: DateTime.parse(
        json['ends_at'] as String,
      ).difference(DateTime.parse(json['starts_at'] as String)),
      subject: json['subject'] ?? "",
      participate: DateTime.tryParse(json['participated_at'] ?? '')?.toLocal(),
      status:
          json['status'] == null
              ? null
              : ContestStatus.values.byName(json['status'] as String),
      instruction: json['instruction'] ?? "", // when details arrives:
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scheduled_at': schedulateAt.toUtc().toIso8601String(),
      'scheduleStartAt': startAt.toUtc().toIso8601String(),
      'scheduleEndAt': endAt.toUtc().toIso8601String(),
      'time_distribution': timeDistribution.name,
      'numberOfQuestions': numberOfQuestions,
      'timeDuration': timeDuration.inSeconds, // store as seconds
      'subject': subject,
      'participate': participate,
      'status': status?.name,
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
    int? numberOfQuestions,
    Duration? timeDuration,
    String? subject,
    DateTime? participate,
    ContestStatus? status,
    String? instruction,
  }) {
    return ContestDetailModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      schedulateAt: schedulateAt ?? this.schedulateAt,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      timeDistribution: timeDistribution ?? this.timeDistribution,
      numberOfQuestions: numberOfQuestions ?? this.numberOfQuestions,
      timeDuration: timeDuration ?? this.timeDuration,
      subject: subject ?? this.subject,
      participate: participate ?? this.participate,
      status: status ?? this.status,
      instruction: instruction ?? this.instruction ?? "",
    );
  }
}
