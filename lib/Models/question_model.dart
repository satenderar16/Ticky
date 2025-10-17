import 'option_model.dart';

class Question {
  final String id;
  final String text;
    final double marks;
    final negativeMarks;
  final List<Option> options;

  final Duration? timeAllocated;

  Question({
    required this.id,
    required this.text,
    required this.marks,
    required this.negativeMarks,
    required this.options,
    required this.timeAllocated,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['question'] as String,
      marks: (json['marks'] as num).toDouble(),// could return error in case of int:
      negativeMarks: json['negative_marks_percentage'],
      options:
          (json['options'] as List<dynamic>)
              .map((e) => Option.fromJson(e as Map<String, dynamic>))
              .toList(),
      timeAllocated:json['time_allocation']==null?Duration(seconds: 10): Duration(seconds: json['time_allocation'] as int),// update this as it could be null when contest is free. 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': text,
      'options': options.map((o) => o.toJson()).toList(),
      'time_allocation': timeAllocated?.inSeconds ?? Duration(seconds: 10),// to do remove in case of null
    };
  }
}
