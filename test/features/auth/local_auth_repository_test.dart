import 'package:fitness_planner/features/auth/data/local_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('по умолчанию не вошёл', () async {
    final repo = LocalAuthRepository(await SharedPreferences.getInstance());

    expect(repo.isSignedIn, isFalse);
  });

  test('вход сохраняется и сообщается подписчикам', () async {
    final repo = LocalAuthRepository(await SharedPreferences.getInstance());
    final events = <bool>[];
    repo.authStateChanges().listen(events.add);

    await repo.signIn();
    await repo.signOut();
    await Future<void>.delayed(Duration.zero);

    expect(events, [true, false]);
    expect(
      LocalAuthRepository(await SharedPreferences.getInstance()).isSignedIn,
      isFalse,
    );
  });
}
