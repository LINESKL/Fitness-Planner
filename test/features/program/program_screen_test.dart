import 'package:fitness_planner/features/program/presentation/program_providers.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Future<void> openProgram(
  WidgetTester tester, {
  List<Workout> history = const [],
}) async {
  await pumpApp(
    tester,
    overrides: [
      workoutRepositoryProvider.overrideWithValue(
        InMemoryWorkoutRepository(history),
      ),
    ],
  );
  await tester.tap(navItem('Программа'));
  await tester.pumpAndSettle();
}

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

void main() {
  testWidgets('дни сплита по порядку, следующий отмечен', (tester) async {
    await openProgram(
      tester,
      history: [
        Workout(
          id: 'w',
          title: 'Верх',
          templateId: 't-up',
          startedAt: DateTime(2026, 10, 3, 18),
          finishedAt: DateTime(2026, 10, 3, 19),
          entries: const [],
        ),
      ],
    );

    final up = tester.getTopLeft(find.text('Верх'));
    final down = tester.getTopLeft(find.text('Низ'));
    expect(up.dy, lessThan(down.dy));
    expect(find.text('следующий'), findsOneWidget);
    expect(find.text('2 упражнения · был 03.10.2026'), findsOneWidget);
    expect(find.text('2 упражнения · ещё не был'), findsOneWidget);
  });

  testWidgets('нажатие раскрывает упражнения с подходами и повторами', (
    tester,
  ) async {
    await openProgram(tester);
    await tester.tap(find.text('Низ'));
    await tester.pumpAndSettle();

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('3 × 5'), findsNWidgets(1));
    expect(find.text('Изменить день'), findsOneWidget);
  });

  testWidgets('перетаскивание меняет порядок и сохраняет его', (tester) async {
    await openProgram(tester);

    await tester.drag(
      find.byIcon(Icons.drag_indicator).first,
      const Offset(0, 300),
    );
    await tester.pumpAndSettle();

    final program = await containerOf(tester).read(programProvider.future);
    expect(program.templateIds, ['t-down', 't-up']);
  });

  testWidgets('без дней — приглашение создать первый', (tester) async {
    await pumpApp(tester, templates: const []);
    await tester.tap(navItem('Программа'));
    await tester.pumpAndSettle();

    expect(find.text('Добавьте первый день сплита'), findsOneWidget);
    expect(find.text('Новый день'), findsOneWidget);
  });
}
