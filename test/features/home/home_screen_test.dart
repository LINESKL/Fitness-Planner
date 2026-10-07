import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

Workout done(String id, String templateId, DateTime day) => Workout(
  id: id,
  title: 'x',
  templateId: templateId,
  startedAt: day,
  finishedAt: day.add(const Duration(hours: 1)),
  entries: const [
    WorkoutEntry(exercise: 'Жим лёжа', sets: [SetEntry(weight: 80, reps: 8)]),
  ],
);

void main() {
  testWidgets('по плану — следующий день программы и его упражнения', (
    tester,
  ) async {
    final now = DateTime.now();
    await pumpApp(
      tester,
      overrides: [
        workoutRepositoryProvider.overrideWithValue(
          InMemoryWorkoutRepository([
            done('w1', 't-up', now.subtract(const Duration(days: 1))),
          ]),
        ),
      ],
    );

    expect(find.text('ПО ПЛАНУ · ДЕНЬ 2 ИЗ 2'), findsOneWidget);
    expect(find.text('Низ'), findsOneWidget);
    expect(find.text('Приседания · Жим стоя'), findsOneWidget);
  });

  testWidgets('«Начать» запускает день программы', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    final active = containerOf(tester).read(activeWorkoutProvider);
    expect(active?.templateId, 't-up');
    expect(active?.exercises.map((e) => e.name), [
      'Жим лёжа',
      'Тяга штанги в наклоне',
    ]);
  });

  testWidgets('«Другой день или пустая» — выбор дня', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Другой день или пустая'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Низ').last);
    await tester.pumpAndSettle();

    expect(containerOf(tester).read(activeWorkoutProvider)?.title, 'Низ');
  });

  testWidgets('пустая программа — создать или пустая тренировка', (
    tester,
  ) async {
    await pumpApp(tester, templates: const []);

    expect(find.text('Создайте программу'), findsOneWidget);
    await tester.tap(find.text('Пустая тренировка'));
    await tester.pumpAndSettle();

    final active = containerOf(tester).read(activeWorkoutProvider);
    expect(active?.exercises, isEmpty);
    expect(find.text('Добавьте первое упражнение'), findsOneWidget);
  });

  testWidgets('неделя и серия', (tester) async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    await pumpApp(
      tester,
      overrides: [
        workoutRepositoryProvider.overrideWithValue(
          InMemoryWorkoutRepository([
            done('a', 't-up', monday.add(const Duration(hours: 9))),
            done('b', 't-down', monday.subtract(const Duration(days: 5))),
          ]),
        ),
      ],
    );

    expect(find.text('серия 2 недели'), findsOneWidget);
    expect(find.text('ЭТА НЕДЕЛЯ'), findsOneWidget);
  });
}
