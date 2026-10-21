import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_repository.dart';

/// Текст ошибки Firebase Auth по её коду.
String authMessage(String code) => switch (code) {
  'invalid-credential' ||
  'wrong-password' ||
  'user-not-found' => 'Неверный email или пароль',
  'email-already-in-use' => 'Этот email уже зарегистрирован',
  'weak-password' => 'Пароль — минимум 6 символов',
  'invalid-email' => 'Неверный email',
  'network-request-failed' => 'Нет подключения к интернету',
  _ => 'Не удалось войти',
};

/// Вход через Firebase Auth. Гость — флаг в SharedPreferences, как раньше.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._auth,
    this._prefs, {
    Future<String?> Function()? googleIdToken,
  }) : _googleIdToken = googleIdToken ?? _googleSignInIdToken;

  static const _key = 'signed_in';
  // Web-клиент из google-services.json (client_type 3) — нужен Google-входу.
  static const _serverClientId =
      '742800135927-k31v5lqp04aikop1avev49d0r0kqe5vi.apps.googleusercontent.com';
  static var _googleReady = false;

  final FirebaseAuth _auth;
  final SharedPreferences _prefs;
  final Future<String?> Function() _googleIdToken;
  late final StreamController<AuthState> _changes =
      StreamController<AuthState>.broadcast(
        onListen: () => _sub = _auth.authStateChanges().listen(
          (user) => _changes.add(_stateFor(user)),
        ),
        onCancel: () => _sub?.cancel(),
      );
  StreamSubscription<User?>? _sub;

  AuthState _stateFor(User? user) {
    if (user != null) return SignedIn(uid: user.uid, email: user.email);
    return (_prefs.getBool(_key) ?? false) ? const Guest() : const SignedOut();
  }

  @override
  AuthState get current => _stateFor(_auth.currentUser);

  @override
  Stream<AuthState> changes() => _changes.stream;

  @override
  Future<void> continueAsGuest() async {
    await _prefs.setBool(_key, true);
    _changes.add(current);
  }

  @override
  Future<void> signInWithEmail(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<void> register(String email, String password) => _guard(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final idToken = await _googleIdToken();
    // Окно выбора закрыли — не ошибка.
    if (idToken == null) return;
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  });

  @override
  Future<void> resetPassword(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    await _prefs.setBool(_key, false);
    await _auth.signOut();
    _changes.add(current);
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(authMessage(e.code));
    }
  }

  static Future<String?> _googleSignInIdToken() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(serverClientId: _serverClientId);
      _googleReady = true;
    }
    try {
      final account = await google.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}
