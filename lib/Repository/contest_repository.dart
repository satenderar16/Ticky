import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quthon/Auth/http_manager.dart';
import 'package:quthon/Models/register_models.dart';
import 'package:http/http.dart' as http;

import 'auth_repository.dart';

//ContestRepository is globally access to all with and instance: restFull

class ContestRepository {
  static final _storage = HttpManager.storage;

  static final baseUrl = "${httpManager.apiBaseUrl}/contests"; // api/contests:
  static final HttpManager httpManager = HttpManager(
    refreshFunction: () async {
      try {
        final res = await AuthRepository.instance!.refreshTokens.call();
        return res;
      } catch (e) {
        rethrow;
      } // when user arrive first needed to sign in hence must have a instance for non logining part with deal with it later:
    },
  );

  // id is contest_id as we only persist answer and remove them as soon as user submit them:
  static Future<void> persistAnswers({
    required String answer,
    required String id,
  }) async {
    try {
      await _storage.write(key: id, value: answer);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // when sending to server is complete remove any stored answer related with contest:
  static Future<void> removePersistAnswers({required String id}) async {
    try {
      await _storage.delete(key: id);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  static Future<String?> getPersistedAnswer({required String id}) async {
    try {
      final answer = await _storage.read(key: id);
      debugPrint(answer.toString());
      return answer;
    } catch (e) {
      return null;
    }
  }

  static bool test = false;

  // contest public contest list:
  static Future<String?> getContestList({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final response = await httpManager.get(
        Uri.parse(baseUrl).replace(
          queryParameters: {
            'limit': limit.toString(),
            'offset': offset.toString(),
          },
        ),
      );
      // out api specific in this case:
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          '${HttpManager.httpFallback} : /contest/getContestList',
        );
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      debugPrint(e.toString());
      throw 'Something went wrong';
    }
  }
  //post contests with question and options list:// this will only available for admin or creator

  //get contest details "contests/{contest_id}/" :

  static Future<String> getContestDetail({required String id}) async {
    try {
      final response = await httpManager.get(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        // debugPrint(data.toString());
        return response.body;
      } else {
        throw Exception(
          '${HttpManager.httpFallback} : /contest/getContestDetail',
        );
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      rethrow;
    }
  }

  //get contests question "contests/{contest_id}/questions"

  static Future<String> getContestQuestions({required String id}) async {
    try {
      final response = await httpManager.get(
        Uri.parse('$baseUrl/$id/questions'),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          '${HttpManager.httpFallback} : /contest/getContestQuestions',
        );
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      rethrow;
    }
  }

  //post participate in question "more like joining the contests" ."contests/{contest_Id}/participate": // this help to get single entry once enter cannot leave without submit or quitting:

  static Future<String> postParticipate({required String id}) async {
    try {
      final response = await httpManager.post(
        Uri.parse('$baseUrl/$id/participate'),
      );

      if (response.statusCode == 201) {
        debugPrint('${response.statusCode}->${response.body}');
        return response.body;
      } else {
        throw Exception(
          '${HttpManager.httpFallback} : /contest/postParticipate',
        );
      }
    } on HttpException catch (e) {
      debugPrint('hey htttp found');
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      rethrow;
    }
  }

  // post contests/{id}/join to joining the contest:

  static Future<String> patchJoinContest({required String id}) async {
    try {
      final response = await httpManager.patch(Uri.parse('$baseUrl/$id/join'));

      if (response.statusCode == 200) {
        // debugPrint(response.body.toString());
        return response.body;
      } else {
        throw Exception('${HttpManager.httpFallback} : /contest/join');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      rethrow;
    }
  }

  //post. submit answered questions when contests it over and still have submit window after contest (end_at), "contests/{contest_id}/submit":
  static Future<String> postContestSubmit({required String id}) async {
    try {
      final answers = await getPersistedAnswer(id: id); // get persist answser:
      debugPrint(' submitted ansse json : $answers');
      if (answers == null) throw 'Answers are not persisted';
      final response = await httpManager.post(
        Uri.parse('$baseUrl/$id/submit'),

        body: answers,
      );

      if (response.statusCode == 201) {
        // submission is done for future:
        await removePersistAnswers(id: id); // remove persist answers:
        return response.body;
      } else {
        throw Exception(
          '${HttpManager.httpFallback} : /contest/postContestSubmit',
        );
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      debugPrint(e.toString());
      throw 'Something went wrong';
    }
  }

  // route /contests/:id/participated-list to get the of user participate(aka registered contests):
  static Future<String> getParticipateContestList({
    int offset = 0,
    int limit = 30,
  }) async {
    try {
      final response = await httpManager.get(
        Uri.parse('$baseUrl/participated-list').replace(
          queryParameters: {
            'limit': limit.toString(),
            'offset': offset.toString(),
          },
        ),
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          '${HttpManager.httpFallback} : /contest/id/getRegisteredContests:',
        );
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      debugPrint(e.toString());
      throw 'Something went wrong';
    }
  }

  /// if user joined and submit he/she able to fetch there results:

  //  get result for the user: /contests/id/results:

  static Future<String> getContestResult({
    required String id,
    required String userId,
  }) async {
    try {
      final response = await httpManager.get(
        Uri.parse('$baseUrl/$id/result/$userId'),
      );
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('${HttpManager.httpFallback} :getContestResult');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }

      debugPrint(e.toString());
      throw 'Something went wrong';
    }
  }

  /// if user only participated he/she get the rank in leader board to confirm the no. of participation:
  // get leaderboard after the submit_before time elaped limit.
  // TODO make sure to call the api :
  static Future<String> getContestLeaderboard({
    required String id,
    int offset = 0,
    int limit = 30,
  }) async {
    try {
      final response = await httpManager.get(
        Uri.parse('$baseUrl/$id/leaderboard').replace(
          queryParameters: {
            'limit': limit.toString(),
            'offset': offset.toString(),
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
          '${HttpManager.httpFallback} : /contest/id/leaderboard get',
        );
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      rethrow;
    }
  }
}
