import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

/// Демо-история: жим 20.09 — 77.5 × 8, 8, 8; 27.09 — 80 × 8, 8, 7.
Future<void> openExercise(WidgetTester tester, String name) async {
  await pumpApp(tester);
  await tester.tap(navItem('Упражнения'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('график, лучший подход и максимальный объём', (tester) async {
    await openExercise(tester, 'Жим лёжа');

    expect(find.text('Грудь'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('80 × 8'), findsOneWidget);
    expect(find.text('1.9 т'), findsOneWidget);
  });

  testWidgets('переключение показателя графика', (tester) async {
    await openExercise(tester, 'Жим лёжа');
    await tester.tap(find.text('Объём'));
    await tester.pumpAndSettle();

    final value = tester.widget<Text>(
      find.byKey(const ValueKey('metric-value')),
    );
    // Последняя тренировка: 80 × 8, 8, 7 = 1840 кг.
    expect(value.data, '1.8 т');
  });

  testWidgets('последние тренировки и заметка', (tester) async {
    await openExercise(tester, 'Жим лёжа');
    expect(await scrollToText(tester, '80 × 8, 8, 7'), findsOneWidget);
    expect(await scrollToText(tester, '77.5 × 8, 8, 8'), findsOneWidget);

    await tester.tap(await scrollToText(tester, 'Добавить заметку'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'лопатки сведены');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('лопатки сведены'), findsOneWidget);
  });

  testWidgets('без истории — «Ещё не делали», графика нет', (tester) async {
    await openExercise(tester, 'Подтягивания');

    expect(find.text('Ещё не делали'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('упражнение со своим весом — график повторов', (tester) async {
    Workout w(String id, int day, int reps) => Workout(
      id: id,
      title: 'x',
      startedAt: DateTime(2026, 9, day),
      finishedAt: DateTime(2026, 9, day, 1),
      entries: [
        WorkoutEntry(
          exercise: 'Подтягивания',
          sets: [SetEntry(weight: 0, reps: reps)],
        ),
      ],
    );
    await pumpApp(
      tester,
      overrides: [
        workoutRepositoryProvider.overrideWithValue(
          InMemoryWorkoutRepository([w('a', 1, 8), w('b', 8, 10)]),
        ),
      ],
    );
    await tester.tap(navItem('Упражнения'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Подтягивания'));
    await tester.pumpAndSettle();

    expect(find.text('1ПМ'), findsNothing);
    final value = tester.widget<Text>(
      find.byKey(const ValueKey('metric-value')),
    );
    expect(value.data, '10 повт.');
    // Лучший подход и строка в последних тренировках.
    expect(find.text('свой вес × 10'), findsNWidgets(2));
  });
}
