import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';

/// Реализация задаётся в main() и в тестах.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => throw UnimplementedError('authRepositoryProvider не переопределён'),
);

/// Вошёл ли пользователь.
final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(authRepositoryProvider);
    final subscription = repo.authStateChanges().listen((v) => state = v);
    ref.onDispose(subscription.cancel);
    return repo.isSignedIn;
  }

  Future<void> signIn() => ref.read(authRepositoryProvider).signIn();

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}
