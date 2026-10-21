import 'dart:async';

import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:fitness_planner/features/auth/presentation/auth_providers.dart';
import 'package:fitness_planner/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Записывает вызовы; может бросить ошибку или подвесить запрос на Completer.
class FakeAuthRepository implements AuthRepository {
  final calls = <String>[];
  AuthException? error;
  Completer<void>? hold;

  Future<void> _run(String call) async {
    calls.add(call);
    if (hold != null) await hold!.future;
    if (error != null) throw error!;
  }

  @override
  AuthState get current => const SignedOut();
  @override
  Stream<AuthState> changes() => const Stream.empty();
  @override
  Future<void> continueAsGuest() => _run('guest');
  @override
  Future<void> signInWithEmail(String e, String p) => _run('signIn $e $p');
  @override
  Future<void> register(String e, String p) => _run('register $e $p');
  @override
  Future<void> signInWithGoogle() => _run('google');
  @override
  Future<void> resetPassword(String e) => _run('reset $e');
  @override
  Future<void> signOut() => _run('signOut');
}

Future<FakeAuthRepository> pumpLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final repo = FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  return repo;
}

Future<void> fill(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
  await tester.enterText(find.widgetWithText(TextField, 'Пароль'), password);
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pump();
}

void main() {
  testWidgets('пустой email и email без @ — «Неверный email»', (tester) async {
    final repo = await pumpLogin(tester);
    await fill(tester, '', 'secret1');
    await tapText(tester, 'Войти');
    expect(find.text('Неверный email'), findsOneWidget);
    await fill(tester, 'abc', 'secret1');
    await tapText(tester, 'Войти');
    expect(find.text('Неверный email'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('короткий пароль — «Пароль — минимум 6 символов»', (
    tester,
  ) async {
    final repo = await pumpLogin(tester);
    await fill(tester, 'a@b.kz', '12345');
    await tapText(tester, 'Войти');
    expect(find.text('Пароль — минимум 6 символов'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('«Войти» вызывает signInWithEmail', (tester) async {
    final repo = await pumpLogin(tester);
    await fill(tester, ' a@b.kz ', 'secret1');
    await tapText(tester, 'Войти');
    expect(repo.calls, ['signIn a@b.kz secret1']);
  });

  testWidgets('переключатель режима: регистрация и обратно', (tester) async {
    final repo = await pumpLogin(tester);
    await tapText(tester, 'Нет аккаунта? Зарегистрироваться');
    expect(find.text('Создать аккаунт'), findsOneWidget);
    await fill(tester, 'a@b.kz', 'secret1');
    await tapText(tester, 'Создать аккаунт');
    expect(repo.calls, ['register a@b.kz secret1']);

    await tapText(tester, 'Уже есть аккаунт? Войти');
    expect(find.text('Создать аккаунт'), findsNothing);
    expect(find.text('Нет аккаунта? Зарегистрироваться'), findsOneWidget);
  });

  testWidgets('ошибка показывается под формой, поля не очищаются', (
    tester,
  ) async {
    final repo = await pumpLogin(tester);
    repo.error = const AuthException('Нет подключения к интернету');
    await fill(tester, 'a@b.kz', 'secret1');
    await tapText(tester, 'Войти');
    await tester.pump();
    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    expect(find.text('a@b.kz'), findsOneWidget);
    final password = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Пароль'),
    );
    expect(password.controller!.text, 'secret1');

    repo.error = null;
    await tapText(tester, 'Войти');
    await tester.pump();
    expect(find.text('Нет подключения к интернету'), findsNothing);
  });

  testWidgets('«Забыли пароль?» с email отправляет письмо', (tester) async {
    final repo = await pumpLogin(tester);
    await fill(tester, 'a@b.kz', '');
    await tapText(tester, 'Забыли пароль?');
    await tester.pump();
    expect(repo.calls, ['reset a@b.kz']);
    expect(find.text('Письмо для сброса пароля отправлено'), findsOneWidget);
  });

  testWidgets('«Забыли пароль?» без email — «Введите email»', (tester) async {
    final repo = await pumpLogin(tester);
    await tapText(tester, 'Забыли пароль?');
    expect(find.text('Введите email'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('Google и гость вызывают свои методы', (tester) async {
    final repo = await pumpLogin(tester);
    await tapText(tester, 'Войти через Google');
    await tapText(tester, 'Продолжить как гость');
    expect(repo.calls, ['google', 'guest']);
  });

  testWidgets('во время запроса кнопки неактивны и виден индикатор', (
    tester,
  ) async {
    final repo = await pumpLogin(tester);
    repo.hold = Completer<void>();
    await fill(tester, 'a@b.kz', 'secret1');
    await tapText(tester, 'Войти');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    for (final b in tester.widgetList<ButtonStyleButton>(
      find.bySubtype<ButtonStyleButton>(),
    )) {
      expect(b.onPressed, isNull);
    }

    repo.hold!.complete();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
