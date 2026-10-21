import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

class _Auth implements AuthRepository {
  _Auth(this.current, this.log);
  final List<String> log;
  @override
  AuthState current;
  @override
  Stream<AuthState> changes() => const Stream.empty();
  @override
  Future<void> signOut() async => log.add('signOut');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late List<String> log;

  setUp(() => log = []);

  Future<void> open(WidgetTester tester, AuthState state) async {
    await pumpApp(
      tester,
      auth: _Auth(state, log),
      overrides: [
        localDataWiperProvider.overrideWithValue(() async => log.add('wipe')),
      ],
    );
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'вошедший: виден email, «Выйти» → подтверждение → очистка и выход',
    (tester) async {
      await open(tester, const SignedIn(uid: 'u', email: 'a@b.kz'));
      expect(find.text('Аккаунт: a@b.kz'), findsOneWidget);

      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      expect(find.text('Выйти из аккаунта?'), findsOneWidget);
      expect(
        find.text('Данные останутся в облаке и будут удалены с этого телефона'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Выйти'),
        ),
      );
      await tester.pumpAndSettle();

      expect(log, ['signOut', 'wipe']);
    },
  );

  testWidgets('вошедший: «Отмена» ничего не делает', (tester) async {
    await open(tester, const SignedIn(uid: 'u', email: 'a@b.kz'));
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(log, isEmpty);
    expect(find.text('Выйти из аккаунта?'), findsNothing);
  });

  testWidgets('гость: «Войти в аккаунт» без очистки', (tester) async {
    await open(tester, const Guest());
    expect(find.text('Выйти'), findsNothing);
    await tester.tap(find.text('Войти в аккаунт'));
    await tester.pumpAndSettle();

    expect(log, ['signOut']);
  });
}
