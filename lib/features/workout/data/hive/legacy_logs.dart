import 'package:hive_ce/hive_ce.dart';

import '../../domain/exercise_log.dart';
import '../../domain/set_entry.dart';

/// Старый формат истории (неделя 6): одна запись бокса — одно упражнение.
/// Нужен только для переноса в новую модель.
class LegacyLogsBox {
  LegacyLogsBox(this._box);

  static const boxName = 'workouts';

  static Future<LegacyLogsBox> open() async =>
      LegacyLogsBox(await Hive.openBox<Map>(boxName));

  Box<Map> get box => _box;

  final Box<Map> _box;

  Future<List<ExerciseLog>> loadHistory() async => [
    for (final json in _box.values) _fromJson(json),
  ];

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
          type: s['warmup'] as bool ? SetType.warmup : SetType.normal,
        ),
    ],
  );
}
