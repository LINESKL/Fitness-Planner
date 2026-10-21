/// Состояние входа: не вошёл, гость (только локально) или аккаунт.
sealed class AuthState {
  const AuthState();
}

final class SignedOut extends AuthState {
  const SignedOut();
}

final class Guest extends AuthState {
  const Guest();
}

final class SignedIn extends AuthState {
  const SignedIn({required this.uid, this.email});

  final String uid;
  final String? email;

  // Firebase повторно отдаёт того же пользователя — это не смена состояния.
  @override
  bool operator ==(Object other) =>
      other is SignedIn && other.uid == uid && other.email == email;

  @override
  int get hashCode => Object.hash(uid, email);
}

/// Ошибка входа с текстом, готовым для показа пользователю.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Вход пользователя. Локальная реализация — гость; Firebase — аккаунт.
abstract interface class AuthRepository {
  AuthState get current;
  Stream<AuthState> changes();
  Future<void> continueAsGuest();
  Future<void> signInWithEmail(String email, String password);
  Future<void> register(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> resetPassword(String email);
  Future<void> signOut();
}
