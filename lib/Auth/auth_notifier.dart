import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Auth/user_model.dart';
import 'package:quthon/Repository/auth_repository.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';

//enum for session:
enum AuthSession { expired, signedIn, none }

// Container AuthNotifier and AuthState:

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repo = AuthRepository.instance!;
  return AuthNotifier.initial(repository: repo, user: repo.user);
});

class AuthState {
  final User? user;
  final AuthSession sessionExpired;

  const AuthState({this.user, required this.sessionExpired});

  bool get isAuthenticated => user != null;

  /// logged out or fresh Start
  factory AuthState.unauthenticated() =>
      const AuthState(user: null, sessionExpired: AuthSession.none);

  // logged in
  factory AuthState.authenticated(User user) =>
      AuthState(user: user, sessionExpired: AuthSession.signedIn);

  AuthState copyWith({User? user, AuthSession? sessionExpired}) {
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
    globalauthRefreshNotifier.addListener(() {
      debugPrint('yes global acessExpiry also called');
      sessionChecker();
    });
  }

  void updateUser({required User user}) {
    state = state.copyWith(user: user);
  }

  Future<User> signIn({
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
      debugPrint('just received the data for repo to notifier');
      final token = repository.refreshTokenExpiry;
      if (token == null) {
        debugPrint('helo there is you');
        throw Exception(" token expiry found null after sign is complete");
      }

      /// updating auth state so we can utilize schedule for access token refresh:
      state = AuthState.authenticated(user);
      return user;
      // assigned a listener which listen the current asses token value:
      // await scheduleRefresh();
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final user = await repository.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      if (user == null) {
        throw Exception('signUp user exception ');
      }
      return user;
    } on Exception {
      throw 'Something went wrong';
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    // we are throw error to UI function to show :already hanlde in repository
    try {
      await repository.signOut();
      state = AuthState.unauthenticated();
      _timer?.cancel();
    } catch (e) {
      rethrow;
    }
  }

  // session expiry user update state:
  void sessionTimeOut() {
    state = AuthState.unauthenticated();
  }

  /// sessionChecker
  ///
  void sessionChecker() async {
    if (state == AuthState.unauthenticated()) {
      debugPrint("unauthenticated schedule cancelling for future");
      await repository.deleteTokens();
      await repository.deleteUser();

      return;
    }

    final now = DateTime.now().toUtc();

    final accessTime = repository.accessTokenExpiry ?? now;
    final durationUntilExpiry = accessTime.difference(now);

    Duration refreshBefore = durationUntilExpiry - const Duration(seconds: 30);

    /// look for the refresh token:
    if (refreshBefore.isNegative) {
      final refreshExpiry = repository.refreshTokenExpiry;

      if (refreshExpiry == null ||
          refreshExpiry.difference(now).inSeconds < 30) {
        // or we can pop up session expiry pop for better ux:
        // this pop up the re-login dialog:
        state = state.copyWith(sessionExpired: AuthSession.expired);

        // none of this gonna reflect changes on auth_notifier state:

        await repository.deleteTokens();
        await repository.deleteUser();

        return;
      }
    }
  }

  // /// Schedule a refresh 30s before [accessTime]
  // Future<void> scheduleRefresh({
  //   // required DateTime accessTime,
  //   int retryInterval = 5,
  // }) async {
  //   // Cancel existing timer if running
  //   _timer?.cancel();
  //   // when user signout in the middle of schedule Refresh and assign some data to storage :

  //   // might have this condition in one in million as

  //   if (state == AuthState.unauthenticated()) {
  //     debugPrint("unauthenticated schedule cancelling for future");
  //     await repository.deleteTokens();
  //     await repository.deleteUser();
  //     _timer?.cancel();
  //     return;
  //   }
  //   final now = DateTime.now().toUtc();

  //   final accessTime = repository.accessTokenExpiry ?? now;
  //   final durationUntilExpiry = accessTime.difference(now);

  //   // Schedule 30s before expiry
  //   Duration refreshBefore = durationUntilExpiry - const Duration(seconds: 30);
  //   debugPrint("time to refresh is : $refreshBefore");
  //   if (refreshBefore.isNegative) {
  //     // this ensure the instant session expiry as user hit the limit:
  //     final refreshExpiry = repository.refreshTokenExpiry;

  //     if (refreshExpiry == null ||
  //         refreshExpiry.difference(now).inSeconds < 30) {
  //       // or we can pop up session expiry pop for better ux:
  //       state = state.copyWith(sessionExpired: AuthSession.expired);
  //       await repository.deleteTokens();
  //       await repository.deleteUser();

  //       return;
  //     }
  //     try {
  //       final expiry = await repository.refreshTokens(
  //         autoRefresh: true,
  //       ); // api call return access token time:
  //       refreshBefore =
  //           expiry!.difference(DateTime.now().toUtc()) - Duration(seconds: 30);
  //     } catch (e) {
  //       if (e.toString().contains('Session')) {
  //         // token already delete in repositor refresToken then this Exception :
  //         state = state.copyWith(sessionExpired: AuthSession.expired);
  //         _timer?.cancel();
  //       }
  //       debugPrint(
  //         "access token found to be negative tries fetch but got error: $e",
  //       );
  //       _timer = Timer(Duration(seconds: retryInterval), () async {
  //         await scheduleRefresh(); // retry with same expiry
  //       });
  //       return;
  //     }
  //   }
  //   // this will not block the thread, event loop handle it:
  //   _timer = Timer(refreshBefore, () async {
  //     try {
  //       await repository.refreshTokens(autoRefresh: true);
  //       await scheduleRefresh();
  //     } catch (e) {
  //       debugPrint("timer and scheduled refresh error: $e");
  //       _timer = Timer(Duration(seconds: retryInterval), () async {
  //         await scheduleRefresh(); // retry with same expiry
  //       });
  //     }
  //   });
  // }

  // // when user resume app , it resycn schedule refresh with app state and if session expires refetch it:
  // Future<void> reSyncScheduleRefresh({int interval = 5}) async {
  //   final accessExpiry = repository.accessTokenExpiry;
  //   if (accessExpiry == null) {
  //     return; // case when user pause the state while on login screen :
  //   }
  //   await scheduleRefresh(retryInterval: interval);
  // }
}
