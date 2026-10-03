import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/presentation/active_workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final history = [
    ExerciseLog(
      exercise: 'Жим лёжа',
      date: DateTime(2026, 9, 27),
      sets: const [
        SetEntry(weight: 40, reps: 10, isWarmup: true),
        SetEntry(weight: 80, reps: 8),
        SetEntry(weight: 82.5, reps: 7),
      ],
    ),
  ];

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: ActiveWorkoutScreen(
        plan: const ['Жим лёжа', 'Подтягивания'],
        history: history,
      ),
    ),
  );

  testWidgets('колонка «Прошлый» — рабочие подходы прошлой тренировки', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('80 × 8'), findsOneWidget);
    expect(find.text('82.5 × 7'), findsOneWidget);
    expect(find.text('40 × 10'), findsNothing);
  });

  testWidgets('упражнение без истории — «Ещё не делали» и пустая строка', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Ещё не делали'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));
  });

  testWidgets('галочка отмечает подход', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).last).value, isFalse);
  });
}
