import 'package:flutter/cupertino.dart';
import 'package:quthon/Models/register_models.dart';

class LeaderboardModel {
  final String id; // [nn]
  final String firstName; // [nn]
  final String lastName; //nn
  final String userName;

  ///nn
  final int rank; // [nn]
  final double score; // [nn]
  final ContestStage contestStage; // [nn]

  LeaderboardModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.rank,
    required this.score,
    required this.contestStage,
  });

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    ///Expected API responses:
    // "participant_id": "string",
    // "first_name": "string",
    // "last_name": "string",
    // "username": "string",
    // "score": 0,
    // "rank": 0,
    // "current_stage": "participated"
    try {
      return LeaderboardModel(
        id: json['participant_id'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        userName: json['username'],
        rank:
            json['rank'] as int? ??
            -1, //TODO update this when rank is available:
        score: (json['score'] ?? 0 as num).toDouble(),
        contestStage: ContestStage.values.firstWhere(
          (e) => e.name == json['current_stage'],
          orElse:
              () =>
                  throw 'contestStage parsing error', // fallback when there is no widget:
        ),
      );
    } catch (e) {
      debugPrint('leaderboardModel parsing error: $e');
      throw 'Something went wrong';
    }
  }

  /// Model → JSON
  Map<String, dynamic> toJson() {
    return {
      'participant_id': id,
      'first_name': firstName,
      'last_name': lastName,
      'username': userName,
      'rank': rank,
      'score': score,
      'current_stage': contestStage.name,
    };
  }
}
