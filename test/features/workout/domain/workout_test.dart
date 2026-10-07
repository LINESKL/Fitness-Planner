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
}
