import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';

/// Реализация задаётся в main() и в тестах.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('authRepositoryProvider не переопределён'),
);

/// Текущее состояние входа.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final repo = ref.watch(authRepositoryProvider);
    final subscription = repo.changes().listen((v) => state = v);
    ref.onDispose(subscription.cancel);
    return repo.current;
  }

  Future<void> continueAsGuest() => _repo.continueAsGuest();

  Future<void> signInWithEmail(String email, String password) =>
      _repo.signInWithEmail(email, password);

  Future<void> register(String email, String password) =>
      _repo.register(email, password);

  Future<void> signInWithGoogle() => _repo.signInWithGoogle();

  Future<void> resetPassword(String email) => _repo.resetPassword(email);

  Future<void> signOut() => _repo.signOut();
}
