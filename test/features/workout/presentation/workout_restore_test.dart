import 'package:clock/clock.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/active_workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

ActiveWorkout inRest(DateTime restEndsAt) => ActiveWorkout(
  startedAt: restEndsAt.subtract(const Duration(minutes: 20)),
  title: 'Верх',
  templateId: 't-up',
  cursor: (exercise: 0, set: 1),
  phase: WorkoutPhase.rest,
  restEndsAt: restEndsAt,
  exercises: const [
    ActiveExercise(
      name: 'Жим лёжа',
      sets: [
        WorkoutSet(weight: 80, reps: 8, done: true),
        WorkoutSet(weight: 80, reps: 8),
      ],
    ),
  ],
);

void main() {
  test('каждое действие сохраняется, завершение очищает', () async {
    final store = InMemoryActiveWorkoutStore();
    final c = ProviderContainer.test(
      overrides: [activeWorkoutStoreProvider.overrideWithValue(store)],
    );
    final notifier = c.read(activeWorkoutProvider.notifier);

    await notifier.start(plan: ['Жим лёжа']);
    await notifier.completeCurrent(Duration.zero);
    await notifier.addExercise('Тяга');
    expect((await store.load())?.exercises.length, 2);

    await notifier.finish();
    expect(await store.load(), isNull);
  });

  testWidgets('после перезапуска — тот же подход и оставшийся отдых', (
    tester,
  ) async {
    final store = InMemoryActiveWorkoutStore();
    final saved = inRest(clock.now().add(const Duration(seconds: 30)));
    await store.save(saved);
    await pumpApp(
      tester,
      overrides: [
        activeWorkoutStoreProvider.overrideWithValue(store),
        initialActiveWorkoutProvider.overrideWithValue(saved),
      ],
    );

    expect(find.text('Продолжить тренировку'), findsOneWidget);
    await tester.tap(find.text('Продолжить тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('ОТДЫХ'), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
  });

  testWidgets('отдых вышел, пока приложение было закрыто, — сразу подход', (
    tester,
  ) async {
    final saved = inRest(clock.now().subtract(const Duration(minutes: 3)));
    await pumpApp(
      tester,
      overrides: [initialActiveWorkoutProvider.overrideWithValue(saved)],
    );
    await tester.tap(find.text('Продолжить тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('ОТДЫХ'), findsNothing);
    expect(find.textContaining('подход 2 из 2'), findsOneWidget);
  });
}
