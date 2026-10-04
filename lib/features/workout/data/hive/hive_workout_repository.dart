import 'package:hive_ce/hive_ce.dart';

import '../../domain/exercise_log.dart';
import '../../domain/set_entry.dart';
import '../../domain/workout_repository.dart';

/// История тренировок в Hive: одна запись бокса — одно упражнение тренировки.
class HiveWorkoutRepository implements WorkoutRepository {
  HiveWorkoutRepository(this._box);

  static const boxName = 'workouts';

  static Future<HiveWorkoutRepository> open() async =>
      HiveWorkoutRepository(await Hive.openBox<Map>(boxName));

  final Box<Map> _box;

  @override
  Future<List<ExerciseLog>> loadHistory() async => [
    for (final json in _box.values) _fromJson(json),
  ];

  @override
  Future<void> addLogs(List<ExerciseLog> logs) =>
      _box.addAll([for (final log in logs) _toJson(log)]);

  static Map<String, Object> _toJson(ExerciseLog log) => {
    'exercise': log.exercise,
    'date': log.date.toIso8601String(),
    'sets': [
      for (final s in log.sets)
        {'weight': s.weight, 'reps': s.reps, 'warmup': s.isWarmup},
    ],
  };

  static ExerciseLog _fromJson(Map json) => ExerciseLog(
    exercise: json['exercise'] as String,
    date: DateTime.parse(json['date'] as String),
    sets: [
      for (final s in (json['sets'] as List).cast<Map>())
        SetEntry(
          weight: (s['weight'] as num).toDouble(),
          reps: s['reps'] as int,
          isWarmup: s['warmup'] as bool,
        ),
    ],
  );
}
