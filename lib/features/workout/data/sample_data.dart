import '../domain/exercise.dart';
import '../domain/exercise_log.dart';
import '../domain/set_entry.dart';

// Статичные данные недели 2; с недели 5–6 их заменят API и Hive.

const sampleExercises = [
  Exercise(name: 'Жим лёжа', muscleGroup: 'Грудь'),
  Exercise(name: 'Тяга штанги в наклоне', muscleGroup: 'Спина'),
  Exercise(name: 'Подтягивания', muscleGroup: 'Спина'),
  Exercise(name: 'Приседания', muscleGroup: 'Ноги'),
  Exercise(name: 'Румынская тяга', muscleGroup: 'Ноги'),
  Exercise(name: 'Жим стоя', muscleGroup: 'Плечи'),
  Exercise(name: 'Сгибания на бицепс', muscleGroup: 'Руки'),
];

List<SetEntry> _sets(double weight, List<int> reps) => [
  for (final r in reps) SetEntry(weight: weight, reps: r),
];

const _warmup = SetEntry(weight: 40, reps: 10, isWarmup: true);

final sampleHistory = [
  ExerciseLog(
    exercise: 'Жим лёжа',
    date: DateTime(2026, 9, 20, 18),
    sets: [
      _warmup,
      ..._sets(77.5, [8, 8, 8]),
    ],
  ),
  ExerciseLog(
    exercise: 'Тяга штанги в наклоне',
    date: DateTime(2026, 9, 20, 18, 30),
    sets: _sets(67.5, [10, 10, 10]),
  ),
  ExerciseLog(
    exercise: 'Приседания',
    date: DateTime(2026, 9, 23, 19),
    sets: _sets(95, [5, 5, 5]),
  ),
  ExerciseLog(
    exercise: 'Жим стоя',
    date: DateTime(2026, 9, 23, 19, 30),
    sets: _sets(47.5, [8, 8, 7]),
  ),
  ExerciseLog(
    exercise: 'Жим лёжа',
    date: DateTime(2026, 9, 27, 18),
    sets: [
      _warmup,
      ..._sets(80, [8, 8, 7]),
    ],
  ),
  ExerciseLog(
    exercise: 'Тяга штанги в наклоне',
    date: DateTime(2026, 9, 27, 18, 30),
    sets: _sets(70, [10, 10, 9]),
  ),
  ExerciseLog(
    exercise: 'Приседания',
    date: DateTime(2026, 9, 30, 19),
    sets: _sets(100, [5, 5, 5]),
  ),
  ExerciseLog(
    exercise: 'Жим стоя',
    date: DateTime(2026, 9, 30, 19, 30),
    sets: _sets(50, [8, 8, 8]),
  ),
];
