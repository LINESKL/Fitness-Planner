import 'exercise_log.dart';
import 'set_entry.dart';

/// Упражнение внутри завершённой тренировки.
class WorkoutEntry {
  const WorkoutEntry({required this.exercise, required this.sets});

  final String exercise;
  final List<SetEntry> sets;
}

/// Завершённая тренировка: день программы (или свободная), время и упражнения.
class Workout {
  const Workout({
    required this.id,
    required this.title,
    required this.startedAt,
    required this.finishedAt,
    required this.entries,
    this.templateId,
  });

  final String id;
  final String title;
  final String? templateId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<WorkoutEntry> entries;

  /// Плоские логи для функций истории (`lastTime`, `totalVolume`…).
  List<ExerciseLog> get logs => [
    for (final e in entries)
      ExerciseLog(exercise: e.exercise, date: startedAt, sets: e.sets),
  ];

  Duration get duration => finishedAt.difference(startedAt);

  double get volume => totalVolume(entries.expand((e) => e.sets));

  int get workingSets =>
      entries.expand((e) => e.sets).where((s) => !s.isWarmup).length;
}
