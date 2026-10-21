import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_repository.dart';

/// Вход «как гость»: флаг в SharedPreferences. Аккаунтов здесь нет.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs);

  static const _key = 'signed_in';

  final SharedPreferences _prefs;
  final _changes = StreamController<AuthState>.broadcast();

  @override
  AuthState get current =>
      (_prefs.getBool(_key) ?? false) ? const Guest() : const SignedOut();

  @override
  Stream<AuthState> changes() => _changes.stream;

  @override
  Future<void> continueAsGuest() => _set(true);

  @override
  Future<void> signOut() => _set(false);

  @override
  Future<void> signInWithEmail(String email, String password) => _unsupported();

  @override
  Future<void> register(String email, String password) => _unsupported();

  @override
  Future<void> signInWithGoogle() => _unsupported();

  @override
  Future<void> resetPassword(String email) => _unsupported();

  Future<void> _unsupported() async =>
      throw const AuthException('Вход по email недоступен');

  Future<void> _set(bool guest) async {
    await _prefs.setBool(_key, guest);
    _changes.add(current);
  }
}
