import 'package:fitness_planner/features/program/presentation/program_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

Future<void> openProgram(WidgetTester tester) async {
  await pumpApp(tester);
  await tester.tap(navItem('Программа'));
  await tester.pumpAndSettle();
}

Future<void> addExercise(WidgetTester tester, String name) async {
  await tester.tap(find.text('Добавить упражнение'));
  await tester.pumpAndSettle();
  await tester.tap(await scrollToText(tester, name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('новый день: название обязательно', (tester) async {
    await openProgram(tester);
    await tester.tap(find.text('Новый день'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pump();

    expect(find.text('Введите название'), findsOneWidget);
  });

  testWidgets('новый день сохраняется в конец программы', (tester) async {
    await openProgram(tester);
    await tester.tap(find.text('Новый день'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Плечи');
    await addExercise(tester, 'Жим стоя');

    expect(find.text('3 × 8–12'), findsOneWidget);
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final c = containerOf(tester);
    final days = await c.read(programDaysProvider.future);
    expect(days.map((d) => d.name), ['Верх', 'Низ', 'Плечи']);
    final e = days.last.exercises.single;
    expect((e.exercise, e.sets, e.repsMin, e.repsMax), ('Жим стоя', 3, 8, 12));
    expect(find.text('Плечи'), findsOneWidget);
  });

  testWidgets('подходы и диапазон повторов: минимум не выше максимума', (
    tester,
  ) async {
    await openProgram(tester);
    await tester.tap(find.text('Новый день'));
    await tester.pumpAndSettle();
    await addExercise(tester, 'Жим стоя');

    await tester.tap(find.byTooltip('Больше подходов'));
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byTooltip('Больше минимум повторов'));
    }
    await tester.pump();

    expect(find.text('4 × 12'), findsOneWidget);
  });

  testWidgets('правка существующего дня и удаление упражнения', (tester) async {
    await openProgram(tester);
    await tester.tap(find.text('Верх'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Изменить день'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Убрать упражнение').first);
    await tester.pump();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final days = await containerOf(tester).read(programDaysProvider.future);
    expect(days.first.exercises.map((e) => e.exercise), [
      'Тяга штанги в наклоне',
    ]);
  });

  testWidgets('удаление дня с подтверждением убирает его из программы', (
    tester,
  ) async {
    await openProgram(tester);
    await tester.tap(find.text('Низ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Изменить день'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Удалить день'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();

    final c = containerOf(tester);
    expect((await c.read(programProvider.future)).templateIds, ['t-up']);
    expect(find.text('Низ'), findsNothing);
  });

  testWidgets('двойное «Сохранить» создаёт один день', (tester) async {
    await openProgram(tester);
    await tester.tap(find.text('Новый день'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Плечи');
    await tester.tap(find.text('Сохранить'));
    await tester.tap(find.text('Сохранить'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final c = containerOf(tester);
    expect((await c.read(templatesProvider.future)).length, 3);
    expect((await c.read(programProvider.future)).templateIds.length, 3);
  });
}
