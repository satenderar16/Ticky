import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Auth/user_model.dart';
import 'auth_repository.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';

// Container AuthNotifier and AuthState:

class AuthState {
  final User? user;
  final String? sessionExpired;

  const AuthState({this.user, this.sessionExpired});

  bool get isAuthenticated => user != null;

  /// logged out or fresh Start
  factory AuthState.unauthenticated() =>
      const AuthState(user: null, sessionExpired: null);

  // logged in
  factory AuthState.authenticated(User user) =>
      AuthState(user: user, sessionExpired: null);

  AuthState copyWith({User? user, String? sessionExpired}) {
    return AuthState(
      user: user ?? this.user,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  String toString() =>
      'AuthState(isAuthenticated: $isAuthenticated, user: ${user.toString()}, sessionExpired: $sessionExpired)';
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository repository;
  Timer? _timer;
  // directly initial contructor as on launch repo have instance with all values to make it wait on custom/native splash page while initial auth notifier:
  AuthNotifier.initial({User? user, required this.repository})
    : super(
        user != null
            ? AuthState.authenticated(user)
            : AuthState.unauthenticated(),
      ) {
    // Listen to access token changes after system calls update it :
    globalAccessExpiryNotifier.addListener(() {
      final newExpiry = globalAccessExpiryNotifier.value;
      if (newExpiry != null) {
        scheduleRefresh(accessTime: newExpiry);
      }
    });
  }

  Future<void> signIn({
    String? email,
    required String password,
    String? username,
  }) async {
    try {
      final user = await repository.signIn(
        email: email,
        password: password,
        username: username,
      );
      final accessTime = repository.accessTokenExpiry;
      if (accessTime == null) {
        throw Exception(
          "access token expiry found null after sign is complete",
        );
      }

      /// updating auth state so we can utilize schedule for access token refresh:
      state = AuthState.authenticated(user);

      // assigned a listener which listen the current asses token value:
      await scheduleRefresh(accessTime: accessTime);
    } catch (e) {}
  }

  /// todo :successfull signup lead to login page.
  Future<User?> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final user = await repository.signUp(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    return user;
  }

  Future<void> signOut() async {
    // we are throw error to UI function to show :already hanlde in repository

    await repository.signOut();
    state = AuthState.unauthenticated();
    _timer?.cancel();
  }

  // session expiry user update state:
  void sessionTimeOut() {
    state = AuthState.unauthenticated();
  }

  /// Schedule a refresh 30s before [accessTime]
  Future<void> scheduleRefresh({
    required DateTime accessTime,
    int retryInterval = 5,
  }) async {
    // Cancel existing timer if running
    _timer?.cancel();
    // when user signout in the middle of schedule Refresh and assign some data to storage :

    // might have this condition in one in million as

    if (state == AuthState.unauthenticated()) {
      debugPrint("unauthenticated schedule cancelling for future");
      await repository.deleteTokens();
      await repository.deleteUser();
      return;
    }
    final durationUntilExpiry = accessTime.difference(DateTime.now().toUtc());

    // Schedule 30s before expiry
    Duration refreshBefore = durationUntilExpiry - const Duration(seconds: 30);
    debugPrint("time to refresh is : $refreshBefore");
    if (refreshBefore.isNegative) {
      // this ensure the instant session expiry as user hit the limit:
      final refreshExpiry = repository.refreshTokenExpiry;

      if (refreshExpiry == null ||
          refreshExpiry.difference(DateTime.now().toUtc()).inSeconds < 30) {
        // or we can pop up session expiry pop for better ux:
        state = state.copyWith(sessionExpired: "Session Expired");
        await repository.deleteTokens();
        await repository.deleteUser();

        return;
      }
      try {
        final expiry = await repository.refreshTokens(
          autoRefresh: true,
        ); // api call return access token time:
        refreshBefore =
            expiry!.difference(DateTime.now().toUtc()) - Duration(seconds: 30);
      } catch (e) {
        if (e.toString().contains('Session Expiry')) {
          // token already delete in repositor refresToken then this Exception :
          state = state.copyWith(sessionExpired: 'Session Expiry');
        }
        debugPrint(
          "access token found to be negative tries fetch but got error: $e",
        );
        _timer = Timer(Duration(seconds: retryInterval), () async {
          await scheduleRefresh(
            accessTime: accessTime,
          ); // retry with same expiry
        });
        return;
      }
    }
    // this will not block the thread, event loop handle it:
    _timer = Timer(refreshBefore, () async {
      try {
        final expiry = await repository.refreshTokens(autoRefresh: true);
        await scheduleRefresh(accessTime: expiry!);
      } catch (e) {
        debugPrint("timer and scheduled refresh error: $e");
        _timer = Timer(Duration(seconds: retryInterval), () async {
          await scheduleRefresh(
            accessTime: accessTime,
          ); // retry with same expiry
        });
      }
    });
  }

  // when user resume app , it resycn schedule refresh with app state and if session expires refetch it:
  Future<void> reSyncScheduleRefresh({int interval = 5}) async {
    final accessExpiry = repository.accessTokenExpiry;
    if (accessExpiry == null) {
      return; // case when user pause the state while on login screen :
    }
    await scheduleRefresh(accessTime: accessExpiry, retryInterval: interval);
  }
}
