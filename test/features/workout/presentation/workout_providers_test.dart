import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bench = ExerciseLog(
    exercise: 'Жим лёжа',
    date: DateTime(2026, 9, 27),
    sets: const [SetEntry(weight: 80, reps: 8)],
  );
  final squat = ExerciseLog(
    exercise: 'Приседания',
    date: DateTime(2026, 9, 20),
    sets: const [SetEntry(weight: 100, reps: 5)],
  );

  ProviderContainer containerWith(List<ExerciseLog> history) =>
      ProviderContainer.test(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(
            InMemoryWorkoutRepository.fromLogs(history),
          ),
        ],
      );

  ActiveWorkoutNotifier workout(ProviderContainer c) =>
      c.read(activeWorkoutProvider.notifier);

  test('история загружается из репозитория', () async {
    final c = containerWith([bench]);

    final history = await c.read(historyProvider.future);
    expect(history.single.exercise, 'Жим лёжа');
    expect(history.single.date, bench.date);
  });

  test('start повторяет упражнения последней тренировки', () async {
    final c = containerWith([squat, bench]);

    await workout(c).start();

    expect(c.read(activeWorkoutProvider)?.exercises.map((e) => e.name), [
      'Жим лёжа',
    ]);
  });

  test('без истории start даёт пустую тренировку', () async {
    final c = containerWith([]);

    await workout(c).start();

    expect(c.read(activeWorkoutProvider)?.exercises, isEmpty);
  });

  test('повторный start не сбрасывает идущую тренировку', () async {
    final c = containerWith([bench]);
    await workout(c).start(plan: ['Жим лёжа']);
    workout(c).update(
      (w) => w.completeCurrent(now: DateTime(2026, 10, 4), rest: Duration.zero),
    );

    await workout(c).start(plan: ['Приседания']);

    expect(c.read(activeWorkoutProvider)?.exercises.single.name, 'Жим лёжа');
  });

  test('addExercise берёт прошлые подходы из истории с прогрессией', () async {
    final c = containerWith([bench]);
    await workout(c).start(plan: []);

    await workout(c).addExercise('Жим лёжа');

    // В прошлый раз 80 × 8 выполнено полностью — подсказка +2.5 кг.
    expect(
      c.read(activeWorkoutProvider)?.exercises.single.sets.single.weight,
      82.5,
    );
  });

  test(
    'finish сохраняет отмеченное в историю и закрывает тренировку',
    () async {
      final c = containerWith([bench]);
      await workout(c).start(plan: ['Жим лёжа']);
      workout(c).update(
        (w) =>
            w.completeCurrent(now: DateTime(2026, 10, 4), rest: Duration.zero),
      );

      await workout(c).finish(now: DateTime(2026, 10, 4, 19));

      expect(c.read(activeWorkoutProvider), isNull);
      final workouts = await c.read(workoutsProvider.future);
      expect(workouts.length, 2);
      expect(workouts.last.finishedAt, DateTime(2026, 10, 4, 19));
      expect(workouts.last.entries.single.exercise, 'Жим лёжа');
    },
  );

  test('finish без отметок не трогает историю', () async {
    final c = containerWith([bench]);
    await workout(c).start(plan: ['Жим лёжа']);

    await workout(c).finish();

    expect((await c.read(workoutsProvider.future)).length, 1);
  });

  test('update без тренировки ничего не делает', () {
    final c = containerWith([]);

    workout(c).update((w) => w.addSet(0));

    expect(c.read(activeWorkoutProvider), isNull);
  });
}
