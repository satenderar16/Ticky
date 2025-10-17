import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:quthon/Auth/auth_repository.dart';
import 'package:quthon/Auth/http_manager.dart';
import 'package:quthon/Contest/contest_model.dart';
// import 'package:quthon/Models/option_model.dart';
import 'package:quthon/Models/question_model.dart';

class ContestRepository {
  static const _accessKey = "access_token";

  static const _storage = FlutterSecureStorage();

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

  // get contests list with upper limit 10 by default:
  static Future<List<ContestDetailModel>> getContestList({
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final accessToken = await _storage.read(key: _accessKey);
      // check for the access expiry time:

      final response = await httpManager.get(
        Uri.parse(baseUrl).replace(
          queryParameters: {
            'limit': limit.toString(),
            'offset': offset.toString(),
          },
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      // out api specific in this case:
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> listData = data['data'];
        // debugPrint(listData.toString());
        // debugPrint(data.toString());
        final contests =
            listData
                .map(
                  (e) => ContestDetailModel.fromJson(e as Map<String, dynamic>),
                )
                .toList();

        return contests;
      } else {
        throw Exception('Wrong http status code:get /contests/');
      }
    } on HttpException catch (e) {
      debugPrint('http is calling $e');
      throw e.message;
    } catch (e) {
      debugPrint('catch is calling $e');
      throw 'Something Went Wrong';
    }
  }
  //post contests with question and options list:// this will only available for admin or creator

  //get contest details "contests/{contest_id}/" :

  static Future<ContestDetailModel> getContestDetail({
    required String id,
  }) async {
    try {
      final token = await _storage.read(key: _accessKey);
      final response = await httpManager.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // debugPrint(data.toString());
        return ContestDetailModel.fromJson(data as Map<String, dynamic>);
      } else {
        throw Exception('Wrong http status code: get /contests/{id}');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      debugPrint(e.toString());
      throw 'Something Went Wrong';
    }
  }

  //get contests question "contests/{contest_id}/questions"

  static Future<List<Question>> getContestQuestions({
    required String id,
  }) async {
    try {
      final token = await _storage.read(key: _accessKey);
      final response = await httpManager.get(
        Uri.parse('$baseUrl/$id/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint(data.toString());

        final questions = data.map((q) => Question.fromJson(q)).toList();
        return questions;
      } else {
        throw Exception('Wrong http status code: /contest/{id}/questions');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      debugPrint(e.toString());
      throw 'Something Went Wrong';
    }
  }

  //post participate in question "more like joining the contests" ."contests/{contest_Id}/participate": // this help to get single entry once enter cannot leave without submit or quitting:
  static Future<String?> postParticipate({required String id}) async {
    try {
      final token = await _storage.read(key: _accessKey); // get access token
      final response = await httpManager.post(
        Uri.parse('$baseUrl/$id/participate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        debugPrint('${response.statusCode}->${response.body}');
        return jsonDecode(response.body)['detail'];
      } else {
        throw Exception('Wrong http status code: /contest/participation');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      debugPrint(e.toString());
      throw 'Something Went Wrong';
    }
  }

  // post contests/{id}/join to joining the contest:

  static Future<String?> postJoinContest({required String id}) async {
    try {
      final token = await _storage.read(key: _accessKey); // get access token
      final response = await httpManager.post(
        Uri.parse('$baseUrl/$id/join'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('${response.statusCode}->${response.body}');
        return jsonDecode(response.body)['contest_joined_at'];
      } else {
        throw Exception('Wrong http status code: /contest/{id}/joincontest');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      debugPrint(e.toString());
      throw 'Something Went Wrong';
    }
  }

  //post. submit answered questions when contests it over and still have submit window after contest (end_at), "contests/{contest_id}/submit":
  static Future<void> postContestSubmit({required String id}) async {
    try {
      final token = await _storage.read(key: _accessKey); // get access token
      final answers = await _storage.read(key: id); // get persist answser:
      // debugPrint("persisted answers : $answers");
      if (answers == null) throw 'Answers are not persisted';
      final response = await httpManager
          .post(
            Uri.parse('$baseUrl/$id/submit'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: answers,
          )
          .timeout(
            const Duration(seconds: 6),
            onTimeout: () {
              throw 'Request Time out. Try again';
            },
          );
      ;
      debugPrint('${response.statusCode}->${response.body}');

      if (response.statusCode == 201) {
        // submission is done for future:
        await removePersistAnswers(id: id); // remove persist answers:
        debugPrint('${response.statusCode}->${response.body}');
      } else {
        throw "Something Went Wrong. Pleaes try again";
      }
    } on SocketException {
      throw 'No internet connection. Please check your network.';
    } on TimeoutException {
      throw 'Request timed out. Try again later.';
    } on HttpException catch (e) {
      // _showError(context, 'Server error: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  // get leaderboard after the submit_before time stamp limit.
}
