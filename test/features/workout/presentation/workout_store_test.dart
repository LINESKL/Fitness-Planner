import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/presentation/workout_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bench = ExerciseLog(
    exercise: 'Жим лёжа',
    date: DateTime(2026, 9, 27),
    sets: const [SetEntry(weight: 80, reps: 8)],
  );

  test('start создаёт тренировку из плана и уведомляет', () {
    final store = WorkoutStore(history: [bench]);
    var notified = 0;
    store.addListener(() => notified++);

    store.start(['Жим лёжа']);

    expect(store.active?.exercises.single.sets.single.weight, 80);
    expect(notified, 1);
  });

  test('повторный start не сбрасывает идущую тренировку', () {
    final store = WorkoutStore(history: [bench])..start(['Жим лёжа']);
    store.update((w) => w.toggleDone(0, 0));

    store.start(['Приседания']);

    expect(store.active?.exercises.single.name, 'Жим лёжа');
  });

  test(
    'finish переносит отмеченные подходы в историю и закрывает тренировку',
    () {
      final store = WorkoutStore(history: [bench])..start(['Жим лёжа']);
      store.update((w) => w.toggleDone(0, 0));

      store.finish(now: DateTime(2026, 10, 4));

      expect(store.active, isNull);
      expect(store.history.length, 2);
      expect(store.history.last.date, DateTime(2026, 10, 4));
    },
  );

  test('update без идущей тренировки ничего не делает', () {
    final store = WorkoutStore();

    store.update((w) => w.addSet(0));

    expect(store.active, isNull);
  });
}
