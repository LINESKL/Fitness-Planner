import 'set_entry.dart';

/// Выполнение одного упражнения в конкретную тренировку.
class ExerciseLog {
  const ExerciseLog({
    required this.exercise,
    required this.date,
    required this.sets,
  });

  final String exercise;
  final DateTime date;
  final List<SetEntry> sets;
}

double totalVolume(Iterable<SetEntry> sets) =>
    sets.fold(0.0, (sum, set) => sum + set.volume);

/// Самый тяжёлый рабочий подход; при равном весе — с большим числом повторов.
SetEntry? bestSet(Iterable<SetEntry> sets) {
  SetEntry? best;
  for (final set in sets.where((s) => !s.isWarmup)) {
    if (best == null ||
        set.weight > best.weight ||
        (set.weight == best.weight && set.reps > best.reps)) {
      best = set;
    }
  }
  return best;
}

/// Последнее по дате выполнение упражнения.
ExerciseLog? lastTime(Iterable<ExerciseLog> logs, String exercise) {
  ExerciseLog? latest;
  for (final log in logs.where((l) => l.exercise == exercise)) {
    if (latest == null || log.date.isAfter(latest.date)) latest = log;
  }
  return latest;
}

Map<String, int> sessionsPerExercise(Iterable<ExerciseLog> logs) {
  final counts = <String, int>{};
  for (final log in logs) {
    counts.update(log.exercise, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts;
}

/// Тренировки — логи, сгруппированные по календарному дню, от новых к старым.
List<List<ExerciseLog>> workoutsByDay(Iterable<ExerciseLog> logs) {
  final byDay = <DateTime, List<ExerciseLog>>{};
  for (final log in logs) {
    final day = DateTime(log.date.year, log.date.month, log.date.day);
    byDay.putIfAbsent(day, () => []).add(log);
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final day in days) byDay[day]!];
}
