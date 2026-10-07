import 'exercise_log.dart';
import 'set_entry.dart';

/// Статистика календарной недели (с понедельника) и объём предыдущей.
typedef WeekStats = ({int workouts, double volume, double previousVolume});

WeekStats weekStats(Iterable<ExerciseLog> logs, DateTime now) {
  final start = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final previousStart = DateTime(start.year, start.month, start.day - 7);

  final days = <DateTime>{};
  var volume = 0.0;
  var previousVolume = 0.0;
  for (final log in logs) {
    if (!log.date.isBefore(start)) {
      days.add(DateTime(log.date.year, log.date.month, log.date.day));
      volume += totalVolume(log.sets);
    } else if (!log.date.isBefore(previousStart)) {
      previousVolume += totalVolume(log.sets);
    }
  }
  return (
    workouts: days.length,
    volume: volume,
    previousVolume: previousVolume,
  );
}

/// «+12% к прошлой»; null, если прошлой недели не было.
String? volumeChange(double volume, double previous) {
  if (previous <= 0) return null;
  final percent = ((volume - previous) / previous * 100).round();
  return '${percent >= 0 ? '+' : '−'}${percent.abs()}% к прошлой';
}

/// 640 кг, 8.4 т, 12 т.
String formatTonnage(double kg) => kg < 1000
    ? '${formatWeight(kg)} кг'
    : '${formatWeight(double.parse((kg / 1000).toStringAsFixed(1)))} т';
