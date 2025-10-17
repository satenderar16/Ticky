import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quthon/Auth/auth_notifier.dart';
import 'auth_repository.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final repo = AuthRepository.instance ?? AuthRepository();
  return AuthNotifier.initial(repository: repo, user: repo.user);
});
