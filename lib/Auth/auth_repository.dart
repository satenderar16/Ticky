import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:quthon/Auth/auth_provider.dart';
import 'package:quthon/Auth/http_manager.dart';
import 'package:quthon/Auth/user_model.dart';

ValueNotifier<DateTime?> globalAccessExpiryNotifier = ValueNotifier(null);

// route localhost/auth

class AuthRepository {
  static AuthRepository? instance; // singleton instance
  static const _refreshTokenKey = "refresh_token";
  static const _accessKey = "access_token";
  static const _accessExpiryKey = 'access_expiry';
  static const _refreshExpiryKey = 'refresh_expiry';
  static const _userKey = "userKey";
  static final _storage = const FlutterSecureStorage();

  final String baseUrl = '${httpManager.apiBaseUrl}/auth'; // api url
  static final HttpManager httpManager =
      HttpManager(); // handle all auth related refresh internally :

  DateTime? accessTokenExpiry;
  DateTime? refreshTokenExpiry;
  User? user;

  /// Notifier to broadcast access token refresh

  //default contructor:
  AuthRepository({this.accessTokenExpiry, this.refreshTokenExpiry, this.user});

  // confirming value while app launches: private contuctor:

  AuthRepository._({
    this.accessTokenExpiry,
    this.refreshTokenExpiry,
    this.user,
  });

  static Future<AuthRepository> getInstance() async {
    if (instance != null) return instance!;
    final accessExpiryStr = await _storage.read(key: _accessExpiryKey);
    final refreshExpiryStr = await _storage.read(key: _refreshExpiryKey);
    final userStr = await _storage.read(key: _userKey);
    User? user = userStr == null ? null : User.fromJson(jsonDecode(userStr));
    globalAccessExpiryNotifier.value =
        DateTime.tryParse(accessExpiryStr ?? '')?.toUtc();
    instance = AuthRepository._(
      accessTokenExpiry: DateTime.tryParse(accessExpiryStr ?? '')?.toUtc(),
      refreshTokenExpiry: DateTime.tryParse(refreshExpiryStr ?? '')?.toUtc(),

      user: user,
    );

    return instance!;
  }

  /// Persist JWT securely
  Future<void> _persistToken({
    String? accesToken,
    String? accessExpiry,
    String? refreshToken,
    String? refreshExpiry,
  }) async {
    //access Token expiry persistence current intance:
    await _storage.write(key: _accessKey, value: accesToken);
    await _storage.write(key: _accessExpiryKey, value: accessExpiry);
    accessTokenExpiry = DateTime.parse(accessExpiry!).toUtc();

    //refresh Token  expiry persistence current intance:
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _refreshExpiryKey, value: refreshExpiry);
    refreshTokenExpiry = DateTime.parse(refreshExpiry!).toUtc();
  }

  /// Get stored JWT
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<DateTime?> getRefreshTokenExpiry() async {
    final exp = await _storage.read(key: _refreshExpiryKey);
    return exp == null
        ? null
        : DateTime.parse(exp).toLocal(); // get data in local
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessKey);
  }

  Future<DateTime?> getAccessTokenExpiry() async {
    final exp = await _storage.read(key: _accessExpiryKey);
    return exp == null ? null : DateTime.parse(exp).toLocal();
  }

  /// Delete stored JWT
  Future<void> deleteTokens() async {
    //access Token delete current intance:
    await _storage.delete(key: _accessExpiryKey);
    await _storage.delete(key: _accessKey);
    accessTokenExpiry = null;

    //refresh Token delete current intance:
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _refreshExpiryKey);
    refreshTokenExpiry = null;

    debugPrint("token has been deleted:");
  }

  Future<void> saveUser(User user) async {
    final jsonString = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: jsonString);
    user = user;
  }

  /// Get user object
  Future<User?> getUser() async {
    final jsonString = await _storage.read(key: _userKey);
    if (jsonString == null) return null;

    final Map<String, dynamic> data = jsonDecode(jsonString);
    return User.fromJson(data);
  }

  /// Delete user
  Future<void> deleteUser() async {
    await _storage.delete(key: _userKey);
    debugPrint("user has been removed from the secure storage:");
  }

  /// Todo need to update as after api is not reponses with access token or refresh token.
  //----------------------------------------------------------------------------------------------------------API----------------------------------------------->----------------------------------------------------------------------------------------------------------API----------------------------------------------->----------------------------------------------------------------------------------------------------------API----------------------------------------------->----------------------------------------------------------------------------------------------------------API----------------------------------------------->----------------------------------------------------------------------------------------------------------API----------------------------------------------->----------------------------------------------------------------------------------------------------------API----------------------------------------------->
  Future<User?> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await httpManager.post(
        Uri.parse('$baseUrl/signup'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "first_name": firstName,
          "last_name": lastName,
          "email": email,
          "password": password,
        }),
      );

      debugPrint("Signup Response: ${response.statusCode}");
      debugPrint("Body: ${response.body}");

      if (response.statusCode == 200) {
        // Success
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data["user"] != null) {
          return User.fromJson(data["user"]);
        } else {
          // Some APIs return user fields directly instead of a nested object
          return User.fromJson(data);
        }
      } else {
        throw HttpException('Wrong handle Statuscode: auth/signup');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign In user
  Future<User> signIn({
    String? email,
    String? username,
    required String password,
  }) async {
    try {
      final requestBody = <String, String>{
        if (email?.isNotEmpty == true) "email": email!,
        if (username?.isNotEmpty == true) "username": username!,
        "password": password,
      };

      final response = await httpManager.post(
        Uri.parse('$baseUrl/signin'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: requestBody,
      );

      // debugPrint('${response.statusCode} -> ${jsonDecode(response.body)}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final User user = User.fromJson(data['account']);
        // might call an error:
        await _persistToken(
          accesToken: data['access_token'] as String,
          accessExpiry: data['access_token_expires_at'] as String,
          refreshToken: data['refresh_token'] as String,
          refreshExpiry: data['refresh_token_expires_at'] as String,
        );

        // NOTE: manually starts the timer when user signed it , or else -> unauthenicated trigger and token wipe out just after changing the accessexpiryNOtifier:

        // globalAccessExpiryNotifier.value =
        //     DateTime.tryParse(data['access_token_expires_at'] ?? '')?.toLocal();
        await saveUser(user);
        return user;
      } else {
        throw HttpException('Wrong handle Statuscode: auth/signin');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  // indicating only used by auth repo: schedular for general refresh we can use httpManager:
  /// new expiry :
  Future<DateTime?> refreshTokens({bool autoRefresh = false}) async {
    try {
      debugPrint(
        'refresh token called schedular which is not started yet $autoRefresh',
      );

      // using refreshtoken for refreshing:
      final token = await getRefreshToken();
      // using DateTime.now when is at blink of refrshtoken exipiry :
      if (refreshTokenExpiry == null ||
          DateTime.now()
              .toUtc()
              .subtract(Duration(seconds: 30))
              .isAfter(refreshTokenExpiry!) ||
          token == null) {
        // refresh token is null implies =>user need re- singin:
        await deleteTokens();
        await deleteUser();
        // if non schedular try to refresh and got null or about condition need to run this:
        // as schedular need to make sure the refreshtoken can't have null value:
        if (!autoRefresh) {
          globalAccessExpiryNotifier.value = null;
        }

        throw Exception('Session Expiry');
      }

      final response = await httpManager.get(
        Uri.parse("$baseUrl/token/refresh"),
        headers: {'accept': 'application/json', "x-refresh-token": token},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // storing new token:
        await _persistToken(
          accesToken: data['access_token']['token'],
          accessExpiry: data['access_token']['expires_at'],
          refreshToken: data['refresh_token']['token'],
          refreshExpiry: data['refresh_token']["expires_at"],
        );

        if (!autoRefresh) {
          globalAccessExpiryNotifier.value = accessTokenExpiry;
        }

        // returning new access expiry time:
        return accessTokenExpiry;
      } else {
        throw HttpException('Wrong handle Statuscode: auth/refreshToken');
      }
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign Out user
  Future<void> signOut() async {
    try {
      final token = await getAccessToken();

      if (token == null || accessTokenExpiry == null) {
        await refreshTokens();
      }
      final response = await httpManager.post(
        Uri.parse('$baseUrl/signout'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        // clear local token , user and repository instance.
        await deleteTokens();
        await deleteUser();
        return;
      }

      throw HttpException('Wrong handle Statuscode: auth/singout');
    } on HttpException catch (e) {
      throw e.message;
    } catch (e) {
      rethrow;
    }
  }
}
