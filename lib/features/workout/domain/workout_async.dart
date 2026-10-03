import 'exercise_log.dart';
import 'set_entry.dart';

/// Строка «в прошлый раз» для упражнения: "82.5 кг × 8, 82.5 кг × 7".
Future<String> lastTimeSummary(
  Future<List<ExerciseLog>> Function() loadLogs,
  String exercise,
) async {
  final log = lastTime(await loadLogs(), exercise);
  if (log == null) return 'Ещё не делали';

  return log.sets
      .where((s) => !s.isWarmup)
      .map((s) => '${formatWeight(s.weight)} кг × ${s.reps}')
      .join(', ');
}

/// Обратный отсчёт отдыха: каждое событие — сколько осталось.
Stream<Duration> restTimer(
  Duration total, {
  Duration tick = const Duration(seconds: 1),
}) {
  final count = total.inMicroseconds ~/ tick.inMicroseconds;
  return Stream.periodic(tick, (i) => total - tick * (i + 1)).take(count);
}
