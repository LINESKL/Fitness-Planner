import 'package:fitness_planner/features/workout/domain/active_workout.dart';
import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final history = [
    ExerciseLog(
      exercise: 'Жим лёжа',
      date: DateTime(2026, 9, 27),
      sets: const [
        SetEntry(weight: 40, reps: 10, isWarmup: true),
        SetEntry(weight: 80, reps: 8),
        SetEntry(weight: 80, reps: 7),
      ],
    ),
  ];
  final started = DateTime(2026, 10, 4, 18);

  ActiveWorkout start([
    List<String> plan = const ['Жим лёжа', 'Подтягивания'],
  ]) => ActiveWorkout.start(startedAt: started, plan: plan, history: history);

  test('предзаполняет подходы рабочими подходами прошлого раза', () {
    final bench = start().exercises.first;

    expect(bench.name, 'Жим лёжа');
    expect(bench.sets.map((s) => (s.weight, s.reps, s.done)), [
      (80.0, 8, false),
      (80.0, 7, false),
    ]);
  });

  test('упражнение без истории получает один пустой подход', () {
    final pullUps = start().exercises.last;

    expect(pullUps.sets.map((s) => (s.weight, s.reps)), [(0.0, 0)]);
  });

  test('addExercise добавляет упражнение в конец с прошлыми подходами', () {
    final workout = start(const []).addExercise('Жим лёжа', history);

    expect(workout.exercises.single.sets.length, 2);
  });

  test('addSet копирует последний подход без отметки', () {
    final workout = start().toggleDone(0, 1).addSet(0);

    final sets = workout.exercises.first.sets;
    expect(sets.length, 3);
    expect(
      (sets.last.weight, sets.last.reps, sets.last.done),
      (80.0, 7, false),
    );
  });

  test('updateSet меняет только переданные поля', () {
    final workout = start().updateSet(0, 0, weight: 82.5);

    final set = workout.exercises.first.sets.first;
    expect((set.weight, set.reps), (82.5, 8));
  });

  test('toggleDone переключает отметку туда и обратно', () {
    final once = start().toggleDone(0, 0);
    final twice = once.toggleDone(0, 0);

    expect(once.exercises.first.sets.first.done, isTrue);
    expect(twice.exercises.first.sets.first.done, isFalse);
  });

  test('исходный объект не меняется', () {
    final original = start();
    original.updateSet(0, 0, weight: 100).toggleDone(0, 0).addSet(1);

    expect(original.exercises.first.sets.first.weight, 80);
    expect(original.exercises.first.sets.first.done, isFalse);
    expect(original.exercises.last.sets.length, 1);
  });

  group('toLogs', () {
    final finished = DateTime(2026, 10, 4, 19);

    test('сохраняет только отмеченные подходы', () {
      final logs = start().toggleDone(0, 1).toLogs(finished);

      expect(logs.single.exercise, 'Жим лёжа');
      expect(logs.single.date, finished);
      expect(logs.single.sets.map((s) => (s.weight, s.reps)), [(80.0, 7)]);
    });

    test('без отметок — пустой список', () {
      expect(start().toLogs(finished), isEmpty);
    });

    test('отмеченный подход с нулём повторов не сохраняется', () {
      expect(start().toggleDone(1, 0).toLogs(finished), isEmpty);
    });
  });
}
