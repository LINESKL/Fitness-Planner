/// Вход пользователя. На неделе 8 реализация заменится на Firebase Authentication.
abstract interface class AuthRepository {
  bool get isSignedIn;
  Stream<bool> authStateChanges();
  Future<void> signIn();
  Future<void> signOut();
}
