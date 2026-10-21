import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_planner/features/auth/data/firebase_auth_repository.dart';
import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth auth;
  late MockUser user;
  late SharedPreferences prefs;

  setUpAll(() => registerFallbackValue(FakeAuthCredential()));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('a@b.kz');
    when(() => auth.currentUser).thenReturn(null);
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  FirebaseAuthRepository repo({Future<String?> Function()? token}) =>
      FirebaseAuthRepository(auth, prefs, googleIdToken: token);

  group('current', () {
    test('есть пользователь Firebase — SignedIn', () {
      when(() => auth.currentUser).thenReturn(user);

      expect(repo().current, const SignedIn(uid: 'u1', email: 'a@b.kz'));
    });

    test('нет пользователя, флаг гостя — Guest', () async {
      await prefs.setBool('signed_in', true);

      expect(repo().current, isA<Guest>());
    });

    test('нет ни пользователя, ни флага — SignedOut', () {
      expect(repo().current, isA<SignedOut>());
    });
  });

  test('signInWithEmail обрезает пробелы в email', () async {
    when(
      () => auth.signInWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => MockUserCredential());

    await repo().signInWithEmail('  a@b.kz ', 'secret1');

    verify(
      () =>
          auth.signInWithEmailAndPassword(email: 'a@b.kz', password: 'secret1'),
    ).called(1);
  });

  group('коды ошибок', () {
    const cases = {
      'invalid-credential': 'Неверный email или пароль',
      'wrong-password': 'Неверный email или пароль',
      'user-not-found': 'Неверный email или пароль',
      'email-already-in-use': 'Этот email уже зарегистрирован',
      'weak-password': 'Пароль — минимум 6 символов',
      'invalid-email': 'Неверный email',
      'network-request-failed': 'Нет подключения к интернету',
      'что-то': 'Не удалось войти',
    };
    for (final MapEntry(key: code, value: message) in cases.entries) {
      test('$code → $message', () {
        expect(authMessage(code), message);
      });
    }

    test('FirebaseAuthException превращается в AuthException', () {
      when(
        () => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      expect(
        repo().signInWithEmail('a@b.kz', 'x'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Нет подключения к интернету',
          ),
        ),
      );
    });
  });

  group('Google', () {
    test('окно закрыто (токен null) — ничего не происходит', () async {
      await repo(token: () async => null).signInWithGoogle();

      verifyNever(() => auth.signInWithCredential(any()));
    });

    test('сбой получения токена — AuthException «Не удалось войти»', () {
      expect(
        repo(token: () async => throw StateError('boom')).signInWithGoogle(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Не удалось войти',
          ),
        ),
      );
    });

    test('токен есть — signInWithCredential вызван один раз', () async {
      when(() => auth.signInWithCredential(any()))
          .thenAnswer((_) async => MockUserCredential());

      await repo(token: () async => 'tok').signInWithGoogle();

      verify(() => auth.signInWithCredential(any())).called(1);
    });
  });

  test('signOut сбрасывает флаг гостя и выходит из Firebase', () async {
    await prefs.setBool('signed_in', true);

    await repo().signOut();

    expect(prefs.getBool('signed_in'), false);
    verify(() => auth.signOut()).called(1);
  });

  group('changes', () {
    test('пользователь Firebase → SignedIn, null → по флагу гостя', () async {
      final controller = StreamController<User?>();
      when(() => auth.authStateChanges()).thenAnswer((_) => controller.stream);
      await prefs.setBool('signed_in', true);
      final events = <AuthState>[];
      final sub = repo().changes().listen(events.add);

      controller.add(user);
      controller.add(null);
      await Future<void>.delayed(Duration.zero);
      await prefs.setBool('signed_in', false);
      controller.add(null);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, [
        const SignedIn(uid: 'u1', email: 'a@b.kz'),
        const Guest(),
        const SignedOut(),
      ]);
    });

    test('continueAsGuest публикует Guest', () async {
      when(() => auth.authStateChanges())
          .thenAnswer((_) => const Stream<User?>.empty());
      final r = repo();
      final events = <AuthState>[];
      final sub = r.changes().listen(events.add);

      await r.continueAsGuest();
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, [const Guest()]);
    });
  });
}
