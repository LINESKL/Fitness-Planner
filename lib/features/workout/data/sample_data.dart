import '../domain/exercise.dart';
import '../domain/exercise_log.dart';
import '../domain/set_entry.dart';

// Встроенный каталог (работает без сети) и данные для тестов.

const sampleExercises = [
  Exercise(id: 'local-1', name: 'Жим лёжа', muscleGroup: 'Грудь'),
  Exercise(id: 'local-2', name: 'Тяга штанги в наклоне', muscleGroup: 'Спина'),
  Exercise(id: 'local-3', name: 'Подтягивания', muscleGroup: 'Спина'),
  Exercise(id: 'local-4', name: 'Приседания', muscleGroup: 'Ноги'),
  Exercise(id: 'local-5', name: 'Румынская тяга', muscleGroup: 'Ноги'),
  Exercise(id: 'local-6', name: 'Жим стоя', muscleGroup: 'Плечи'),
  Exercise(id: 'local-7', name: 'Сгибания на бицепс', muscleGroup: 'Руки'),
  Exercise(
    id: 'local-8',
    name: 'Жим гантелей на наклонной',
    muscleGroup: 'Грудь',
  ),
  Exercise(id: 'local-9', name: 'Разводка гантелей', muscleGroup: 'Грудь'),
  Exercise(id: 'local-10', name: 'Французский жим', muscleGroup: 'Руки'),
  Exercise(id: 'local-11', name: 'Разгибания на блоке', muscleGroup: 'Руки'),
  Exercise(id: 'local-12', name: 'Тяга верхнего блока', muscleGroup: 'Спина'),
  Exercise(id: 'local-13', name: 'Молотки', muscleGroup: 'Руки'),
  Exercise(id: 'local-14', name: 'Жим ногами', muscleGroup: 'Ноги'),
  Exercise(id: 'local-15', name: 'Выпады', muscleGroup: 'Ноги'),
  Exercise(id: 'local-16', name: 'Икры стоя', muscleGroup: 'Ноги'),
  Exercise(
    id: 'local-17',
    name: 'Махи гантелями в стороны',
    muscleGroup: 'Плечи',
  ),
  Exercise(id: 'local-18', name: 'Отжимания на брусьях', muscleGroup: 'Грудь'),
];

List<SetEntry> _sets(double weight, List<int> reps) => [
  for (final r in reps) SetEntry(weight: weight, reps: r),
];

const _warmup = SetEntry(weight: 40, reps: 10, type: SetType.warmup);

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
