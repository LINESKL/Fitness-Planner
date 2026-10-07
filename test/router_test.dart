import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/pump_app.dart';

GoRouter routerOf(WidgetTester tester) =>
    GoRouter.of(tester.element(find.byType(Navigator).first));

void main() {
  testWidgets('без входа — экран входа, после входа — главная', (tester) async {
    await pumpApp(tester, signedIn: false);
    expect(find.text('Продолжить как гость'), findsOneWidget);

    await tester.tap(find.text('Продолжить как гость'));
    await tester.pumpAndSettle();

    expect(find.text('Начать тренировку'), findsOneWidget);
  });

  testWidgets('прямой переход без входа уводит на вход', (tester) async {
    await pumpApp(tester, signedIn: false);

    routerOf(tester).go('/progress');
    await tester.pumpAndSettle();

    expect(find.text('Продолжить как гость'), findsOneWidget);
  });

  testWidgets('выход из настроек возвращает на вход', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выйти'));
    await tester.pumpAndSettle();

    expect(find.text('Продолжить как гость'), findsOneWidget);
  });

  testWidgets('тренировка из истории открывается с подходами', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Прогресс'));
    await tester.pumpAndSettle();
    await tester.tap(await scrollToText(tester, '30.09.2026'));
    await tester.pumpAndSettle();

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('100 кг × 5'), findsNWidgets(3));
  });

  testWidgets('неизвестная тренировка — «Тренировка не найдена»', (
    tester,
  ) async {
    await pumpApp(tester);

    routerOf(tester).go('/progress/workout/nope');
    await tester.pumpAndSettle();

    expect(find.text('Тренировка не найдена'), findsOneWidget);
  });

  testWidgets('карточка упражнения показывает прошлый результат', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(navItem('Упражнения'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Жим лёжа'));
    await tester.pumpAndSettle();

    expect(find.text('Грудь'), findsOneWidget);
    expect(find.text('80 кг × 8, 80 кг × 8, 80 кг × 7'), findsOneWidget);
  });

  testWidgets('вкладка сохраняет экран при переключении', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Прогресс'));
    await tester.pumpAndSettle();
    await tester.tap(await scrollToText(tester, '30.09.2026'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.textContaining('30.09.2026'), findsOneWidget);
  });

  testWidgets('четыре вкладки, программа открывается', (tester) async {
    await pumpApp(tester);

    for (final tab in ['Сегодня', 'Программа', 'Прогресс', 'Упражнения']) {
      expect(navItem(tab), findsOneWidget, reason: tab);
    }
    await tester.tap(navItem('Программа'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Программа'), findsOneWidget);
  });

  group('адаптивность', () {
    testWidgets('телефон — нижняя панель', (tester) async {
      await pumpApp(tester, size: const Size(400, 800));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('планшет или альбомная ориентация — боковая панель', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(1100, 700));

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(navItem('Прогресс'));
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
    });
  });
}
