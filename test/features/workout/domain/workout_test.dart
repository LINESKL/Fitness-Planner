import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final workout = Workout(
    id: 'w1',
    title: 'Ноги',
    templateId: 't3',
    startedAt: DateTime(2026, 10, 7, 18),
    finishedAt: DateTime(2026, 10, 7, 18, 58),
    entries: const [
      WorkoutEntry(
        exercise: 'Приседания',
        sets: [
          SetEntry(weight: 60, reps: 8, type: SetType.warmup),
          SetEntry(weight: 100, reps: 5),
          SetEntry(weight: 100, reps: 5),
        ],
      ),
      WorkoutEntry(
        exercise: 'Жим ногами',
        sets: [SetEntry(weight: 200, reps: 12, type: SetType.failure)],
      ),
    ],
  );

  test('logs — по логу на упражнение с датой начала', () {
    final logs = workout.logs;

    expect(logs.map((l) => l.exercise), ['Приседания', 'Жим ногами']);
    expect(logs.every((l) => l.date == DateTime(2026, 10, 7, 18)), isTrue);
    expect(logs.first.sets.length, 3);
  });

  test('длительность', () {
    expect(workout.duration, const Duration(minutes: 58));
  });

  test('объём и рабочие подходы без разминки', () {
    expect(workout.volume, 100 * 5 * 2 + 200 * 12);
    expect(workout.workingSets, 3);
  });

  test('workoutsFromLogs — логи одного дня в одну тренировку', () {
    const set = SetEntry(weight: 50, reps: 10);
    final workouts = workoutsFromLogs([
      ExerciseLog(exercise: 'A', date: DateTime(2026, 9, 1, 18), sets: [set]),
      ExerciseLog(exercise: 'B', date: DateTime(2026, 9, 1, 19), sets: [set]),
      ExerciseLog(exercise: 'C', date: DateTime(2026, 9, 3, 9), sets: [set]),
    ]);

    expect(workouts.length, 2);
    final first = workouts.firstWhere((w) => w.startedAt.day == 1);
    expect(first.entries.map((e) => e.exercise), ['A', 'B']);
    expect(first.title, 'Тренировка');
    expect(first.startedAt, DateTime(2026, 9, 1, 18));
    expect(first.finishedAt, DateTime(2026, 9, 1, 19));
    expect(workouts.map((w) => w.id).toSet().length, 2);
  });
}
