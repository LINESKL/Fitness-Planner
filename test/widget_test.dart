import 'package:fitness_planner/core/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('стартует на главной', (tester) async {
    await pumpApp(tester);

    expect(find.text('Начать тренировку'), findsOneWidget);
    expect(find.text('Верх'), findsOneWidget);
  });

  testWidgets('светлая и тёмная тема', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });

  testWidgets('вкладка Прогресс показывает тренировки', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Прогресс'));
    await tester.pumpAndSettle();

    expect(find.text('30.09.2026'), findsOneWidget);
    expect(find.text('20.09.2026'), findsOneWidget);
  });

  testWidgets('вкладка Упражнения показывает каталог', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Упражнения'));
    await tester.pumpAndSettle();

    expect(find.text('Подтягивания'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('«Начать тренировку» открывает экран тренировки', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Жим лёжа'), findsOneWidget);
  });

  testWidgets('завершённая тренировка появляется в истории', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();
    await tester.tap(navItem('Прогресс'));
    await tester.pumpAndSettle();

    expect(find.text(formatDate(DateTime.now())), findsOneWidget);
  });

  testWidgets('после выхода назад тренировку можно продолжить', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Продолжить тренировку'), findsOneWidget);
  });

  testWidgets('тема из настроек применяется к приложению', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Светлая'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });

  testWidgets('«Загрузить пример» добавляет программу и историю', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Загрузить пример'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Загрузить'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final workouts = await container.read(workoutsProvider.future);
    final program = await container.read(programRepositoryProvider).program();
    expect(workouts.length, greaterThan(10));
    expect(program.templateIds.length, 3);
    expect(find.text('Пример загружен'), findsOneWidget);
  });
}
