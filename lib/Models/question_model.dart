import 'option_model.dart';

class ContestQuestion {
  final String id;
  final String text;
  final double marks;
  final negativeMarks; // TODO
  final List<Option> options;

  final Duration? timeAllocated;

  ContestQuestion({
    required this.id,
    required this.text,
    required this.marks,
    required this.negativeMarks,
    required this.options,
    required this.timeAllocated,
  });

  factory ContestQuestion.fromJson(Map<String, dynamic> json) {
    return ContestQuestion(
      id: json['id'] as String,
      text: json['question'] as String,
      marks:
          (json['marks'] as num)
              .toDouble(), // could return error in case of int:
      negativeMarks: json['negative_marks_percentage'],
      options:
          (json['options'] as List<dynamic>)
              .map((e) => Option.fromSubmitJson(e as Map<String, dynamic>))
              .toList(),
      timeAllocated:
          json['time_allocation'] == null
              ? Duration(seconds: 10)
              : Duration(
                seconds: json['time_allocation'] as int,
              ), // update this as it could be null when contest is free.
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': text,
      'options': options.map((o) => o.toResultJson()).toList(),
      'time_allocation':
          timeAllocated?.inSeconds ??
          Duration(seconds: 10), // to do remove in case of null
    };
  }
}
