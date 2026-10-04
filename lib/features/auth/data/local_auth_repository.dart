import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/auth_repository.dart';

/// Вход «как гость»: флаг в SharedPreferences.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs);

  static const _key = 'signed_in';

  final SharedPreferences _prefs;
  final _changes = StreamController<bool>.broadcast();

  @override
  bool get isSignedIn => _prefs.getBool(_key) ?? false;

  @override
  Stream<bool> authStateChanges() => _changes.stream;

  @override
  Future<void> signIn() => _set(true);

  @override
  Future<void> signOut() => _set(false);

  Future<void> _set(bool signedIn) async {
    await _prefs.setBool(_key, signedIn);
    _changes.add(signedIn);
  }
}
