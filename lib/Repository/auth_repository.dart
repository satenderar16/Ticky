import 'dart:convert';
// import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
import 'package:quthon/Auth/http_manager.dart';
import 'package:quthon/Auth/user_model.dart';

ValueNotifier<DateTime?> globalauthRefreshNotifier = ValueNotifier(
  DateTime.now().toUtc(),
);

// route localhost/auth

class AuthRepository {
  static AuthRepository? instance; // singleton instance
  static const _refreshTokenKey = "refresh_token";
  static const _accessKey = "access_token";
  static const _accessExpiryKey = 'access_expiry';
  static const _refreshExpiryKey = 'refresh_expiry';
  static const _userKey = "userKey";
  static final _storage = HttpManager.storage;

  final String baseUrl = '${httpManager.apiBaseUrl}/auth'; // api url
  static final HttpManager httpManager =
      HttpManager(); // handle all auth related refresh internally :

  DateTime? accessTokenExpiry;
  DateTime? refreshTokenExpiry;
  User? user;

  //default contructor:
  AuthRepository({this.accessTokenExpiry, this.refreshTokenExpiry, this.user});

  AuthRepository._({
    this.accessTokenExpiry,
    this.refreshTokenExpiry,
    this.user,
  });

  static Future<AuthRepository> getInstance() async {
    if (instance != null) return instance!;

    try {
      // handling the case when bad_encrption errro found:
      final accessExpiryStr = await _storage.read(key: _accessExpiryKey);
      final refreshExpiryStr = await _storage.read(key: _refreshExpiryKey);
      final userStr = await _storage.read(key: _userKey);
      User? user = userStr == null ? null : User.fromJson(jsonDecode(userStr));
      globalauthRefreshNotifier.value =
          DateTime.tryParse(
            accessExpiryStr ?? '',
          )?.toUtc(); // assing the value to the global schedular notifier:
      instance = AuthRepository._(
        accessTokenExpiry: DateTime.tryParse(accessExpiryStr ?? '')?.toUtc(),
        refreshTokenExpiry: DateTime.tryParse(refreshExpiryStr ?? '')?.toUtc(),

        user: user,
      );
    } catch (e) {
      debugPrint('geting instance of repo catch');
      User? user;
      globalauthRefreshNotifier.value =
          DateTime.tryParse(
            '',
          )?.toUtc(); // assing the value to the global schedular notifier:
      instance = AuthRepository._(
        accessTokenExpiry: DateTime.tryParse('')?.toUtc(),
        refreshTokenExpiry: DateTime.tryParse('')?.toUtc(),

        user: user,
      );
    }

    return instance!;
  }

  // this help us in reading with bad_encryption:

  Future<String?> safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint("SecureStorage read failed for key '$key': $e");

      await _storage.delete(key: key);

      return null;
    }
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
    return await safeRead(_refreshTokenKey);
  }

  Future<DateTime?> getRefreshTokenExpiry() async {
    final exp = await safeRead(_refreshExpiryKey);
    return exp == null
        ? null
        : DateTime.parse(exp).toLocal(); // get data in local
  }

  Future<String?> getAccessToken() async {
    return await safeRead(_accessKey);
  }

  Future<DateTime?> getAccessTokenExpiry() async {
    final exp = await safeRead(_accessExpiryKey);
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
    final jsonString = await safeRead(_userKey);
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
        throw Exception('${HttpManager.httpFallback} : /auth/signup');
      }
    } on HttpException catch (e) {
      debugPrint('there is http error found:$e');
      throw e.message;
    } catch (e) {
      if (e.toString().contains(HttpManager.httpFallback)) {
        debugPrint(e.toString());
        throw 'Nework Error';
      }
      debugPrint(e.toString());
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
      debugPrint('hey there is sign');
      final requestBody = <String, String>{
        if (email?.isNotEmpty == true) "email": email!,
        if (username?.isNotEmpty == true) "username": username!,
        "password": password,
      };
      debugPrint(requestBody.toString());

      final response = await httpManager.post(
        Uri.parse('$baseUrl/signin'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: requestBody,
      );
      debugPrint('just return response body from htttpManger:');
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
        throw Exception('${HttpManager.httpFallback} : /auth/signin');
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

  // global refreshToken handler
  Future<DateTime?> refreshTokens({bool autoRefresh = false}) async {
    try {
      debugPrint('hey refreshToken called');

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

        // this call the session checker when value changes:
        globalauthRefreshNotifier.value = null;
        throw Exception('Session Expire'); //
      }
      // using same client but avoid recurrsion with httpManager instance : and usign name tcp connection:
      final response = await HttpManager.client.get(
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
        // globalauthRefreshNotifier.value = accessTokenExpiry;
        // returning new access expiry time:
        return accessTokenExpiry;
      }

      // considering server send the invalid response to the refresh Token:
      if (response.statusCode == 401) {
        // refresh token reponse 401 appling the re-signin:
        await deleteTokens();
        await deleteUser();

        globalauthRefreshNotifier.value =
            globalauthRefreshNotifier.value == null
                ? DateTime.now().toUtc()
                : null; // send schedular to refresh the auth state:

        throw Exception('Session Expire');
      }
    } on Exception {
      throw 'Session Expire';
    } catch (e) {
      rethrow;
    }
  }

  //TODO handle the refresh here: as we don't want user to signin:
  /// Sign Out user
  Future<void> signOut({bool refresh = false}) async {
    try {
      String? token = await getAccessToken();
      // special safety as we only apply the refresh auto to NON AUTH routes:
      if (token == null || accessTokenExpiry == null) {
        await refreshTokens();
        token = await getAccessToken();
      }
      final response = await httpManager.post(
        Uri.parse('$baseUrl/signout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // clear local token , user and repository instance.
        await deleteTokens();
        await deleteUser();

        return;
      }
      // avoid recurrsion:
      if (response.statusCode == 401 && !refresh) {
        await refreshTokens();
        await signOut(refresh: true);
      }

      throw Exception('${HttpManager.httpFallback} : /auth/signout');
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
