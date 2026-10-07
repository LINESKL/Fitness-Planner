import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../helpers/pump_app.dart';

Workout upper(String id, DateTime start, int minutes, double bench) => Workout(
  id: id,
  title: 'Верх',
  templateId: 't-up',
  startedAt: start,
  finishedAt: start.add(Duration(minutes: minutes)),
  entries: [
    WorkoutEntry(
      exercise: 'Жим лёжа',
      sets: [
        const SetEntry(weight: 40, reps: 10, type: SetType.warmup),
        for (var i = 0; i < 3; i++) SetEntry(weight: bench, reps: 8),
      ],
    ),
  ],
);

Future<void> openSummary(WidgetTester tester, List<Workout> workouts, String id) async {
  await pumpApp(
    tester,
    overrides: [
      workoutRepositoryProvider.overrideWithValue(InMemoryWorkoutRepository(workouts)),
    ],
  );
  GoRouter.of(tester.element(find.byType(Navigator).first)).go('/summary/$id');
  await tester.pumpAndSettle();
}

void main() {
  final earlier = upper('a', DateTime(2026, 10, 1, 18), 62, 80);
  final latest = upper('b', DateTime(2026, 10, 4, 18), 58, 82.5);

  testWidgets('длительность, объём, подходы', (tester) async {
    await openSummary(tester, [earlier, latest], 'b');

    expect(find.text('Тренировка готова'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);
    expect(find.text('2 т'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('новые рекорды тренировки', (tester) async {
    await openSummary(tester, [earlier, latest], 'b');

    expect(find.text('НОВЫЕ РЕКОРДЫ'), findsOneWidget);
    expect(find.text('82.5 × 8'), findsOneWidget);
  });

  testWidgets('сравнение с прошлым разом этого дня', (tester) async {
    await openSummary(tester, [earlier, latest], 'b');

    expect(find.text('К ПРОШЛОМУ «ВЕРХ»'), findsOneWidget);
    expect(find.text('+60 кг'), findsOneWidget);
    expect(find.text('−4 мин'), findsOneWidget);
  });

  testWidgets('первая тренировка дня — без сравнения и рекордов', (
    tester,
  ) async {
    await openSummary(tester, [earlier], 'a');

    expect(find.textContaining('К ПРОШЛОМУ'), findsNothing);
    expect(find.text('НОВЫЕ РЕКОРДЫ'), findsNothing);
  });

  testWidgets('«Готово» возвращает на «Сегодня»', (tester) async {
    await openSummary(tester, [earlier, latest], 'b');
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Сегодня'), findsOneWidget);
  });
}
