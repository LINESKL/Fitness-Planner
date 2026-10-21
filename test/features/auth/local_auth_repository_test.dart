import 'package:fitness_planner/features/auth/data/local_auth_repository.dart';
import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('по умолчанию не вошёл', () async {
    final repo = LocalAuthRepository(await SharedPreferences.getInstance());

    expect(repo.current, isA<SignedOut>());
  });

  test('гость сохраняется и сообщается подписчикам', () async {
    final repo = LocalAuthRepository(await SharedPreferences.getInstance());
    final events = <AuthState>[];
    repo.changes().listen(events.add);

    await repo.continueAsGuest();
    expect(repo.current, isA<Guest>());
    expect(
      LocalAuthRepository(await SharedPreferences.getInstance()).current,
      isA<Guest>(),
    );

    await repo.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(events, [isA<Guest>(), isA<SignedOut>()]);
    expect(
      LocalAuthRepository(await SharedPreferences.getInstance()).current,
      isA<SignedOut>(),
    );
  });

  test('email, Google и сброс пароля недоступны локально', () async {
    final repo = LocalAuthRepository(await SharedPreferences.getInstance());

    for (final call in <Future<void> Function()>[
      () => repo.signInWithEmail('a@b.c', 'secret1'),
      () => repo.register('a@b.c', 'secret1'),
      repo.signInWithGoogle,
      () => repo.resetPassword('a@b.c'),
    ]) {
      await expectLater(
        call(),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Вход по email недоступен',
          ),
        ),
      );
    }
  });
}
