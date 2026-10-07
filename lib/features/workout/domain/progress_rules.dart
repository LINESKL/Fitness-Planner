import 'exercise_log.dart';
import 'set_entry.dart';
import 'stats.dart';
import 'workout.dart';

/// Шаг прибавки веса, кг.
const progressionStep = 2.5;

/// Что подставить в подход [index]: вес и повторы из прошлого раза,
/// +2.5 кг, если в прошлый раз всё выполнено (цель — верх диапазона [target];
/// без шаблона — повторы не просели относительно первого подхода).
({double weight, int reps, bool increased}) suggestSet({
  required List<SetEntry> previous,
  required int index,
  ({int min, int max})? target,
}) {
  final working = [
    for (final s in previous)
      if (!s.isWarmup) s,
  ];
  if (working.isEmpty) {
    return (weight: 0, reps: target?.min ?? 0, increased: false);
  }

  final base = working[index < working.length ? index : working.length - 1];
  final goal = target?.max ?? working.first.reps;
  final completed = working.every((s) => s.reps >= goal);
  if (!completed || base.weight <= 0) {
    return (weight: base.weight, reps: base.reps, increased: false);
  }
  return (
    weight: base.weight + progressionStep,
    reps: target?.min ?? base.reps,
    increased: true,
  );
}

/// Личные рекорды по упражнению (без разминки).
class ExerciseRecords {
  const ExerciseRecords({
    required this.bestWeight,
    required this.bestOneRepMax,
    required this.bestVolume,
  });

  final double bestWeight;
  final double bestOneRepMax;

  /// Лучший объём упражнения за одну тренировку.
  final double bestVolume;

  bool get isEmpty => bestOneRepMax <= 0;
}

ExerciseRecords recordsFor(String exercise, List<Workout> workouts) {
  var weight = 0.0, oneRepMax = 0.0, volume = 0.0;
  for (final w in workouts) {
    for (final e in w.entries.where((e) => e.exercise == exercise)) {
      var sessionVolume = 0.0;
      for (final s in e.sets.where((s) => !s.isWarmup && s.reps > 0)) {
        if (s.weight > weight) weight = s.weight;
        if (s.oneRepMax > oneRepMax) oneRepMax = s.oneRepMax;
        sessionVolume += s.volume;
      }
      if (sessionVolume > volume) volume = sessionVolume;
    }
  }
  return ExerciseRecords(
    bestWeight: weight,
    bestOneRepMax: oneRepMax,
    bestVolume: volume,
  );
}

/// Рекорд — 1ПМ выше прежнего. Без истории рекорд не объявляется:
/// иначе каждый первый подход нового упражнения был бы «рекордом».
bool isNewRecord(SetEntry set, ExerciseRecords before) =>
    !set.isWarmup &&
    set.reps > 0 &&
    !before.isEmpty &&
    set.oneRepMax > before.bestOneRepMax;

/// Рабочие подходы текущей календарной недели по группам мышц.
Map<String, int> muscleLoad(
  List<Workout> workouts,
  DateTime now,
  String Function(String exercise) groupOf,
) {
  final start = weekStart(now);
  final load = <String, int>{};
  for (final w in workouts.where((w) => !w.startedAt.isBefore(start))) {
    for (final e in w.entries) {
      final count = e.sets.where((s) => !s.isWarmup).length;
      if (count > 0) {
        load.update(
          groupOf(e.exercise),
          (n) => n + count,
          ifAbsent: () => count,
        );
      }
    }
  }
  return load;
}

/// Сколько недель подряд были тренировки; текущая пустая неделя серию не рвёт.
int weekStreak(List<Workout> workouts, DateTime now) {
  final weeks = {for (final w in workouts) weekStart(w.startedAt)};
  var week = weekStart(now);
  if (!weeks.contains(week)) {
    week = DateTime(week.year, week.month, week.day - 7);
  }

  var streak = 0;
  while (weeks.contains(week)) {
    streak++;
    week = DateTime(week.year, week.month, week.day - 7);
  }
  return streak;
}

typedef RecordEvent = ({String exercise, SetEntry set, DateTime date});

/// Все рекорды по порядку: подход, чей 1ПМ превысил лучший прежний результат
/// упражнения. Первые результаты упражнения рекордами не считаются.
List<RecordEvent> recordHistory(List<Workout> workouts) {
  final best = <String, double>{};
  final events = <RecordEvent>[];
  final sorted = [...workouts]
    ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  for (final w in sorted) {
    for (final e in w.entries) {
      final sets = e.sets.where((s) => !s.isWarmup && s.reps > 0);
      if (sets.isEmpty) continue;
      final top = sets.reduce((a, b) => a.oneRepMax >= b.oneRepMax ? a : b);
      final previous = best[e.exercise];
      if (previous != null && top.oneRepMax > previous) {
        events.add((exercise: e.exercise, set: top, date: w.startedAt));
      }
      if (previous == null || top.oneRepMax > previous) {
        best[e.exercise] = top.oneRepMax;
      }
    }
  }
  return events;
}

RecordEvent? latestRecord(List<Workout> workouts) =>
    recordHistory(workouts).lastOrNull;

/// Лучший подход (по 1ПМ) каждого упражнения и когда он был; свежие рекорды первыми.
List<RecordEvent> personalBests(List<Workout> workouts) {
  final best = <String, RecordEvent>{};
  for (final w in workouts) {
    for (final e in w.entries) {
      for (final s in e.sets.where((s) => !s.isWarmup && s.reps > 0)) {
        final current = best[e.exercise];
        if (current == null || s.oneRepMax > current.set.oneRepMax) {
          best[e.exercise] = (exercise: e.exercise, set: s, date: w.startedAt);
        }
      }
    }
  }
  return best.values.toList()..sort((a, b) => b.date.compareTo(a.date));
}

enum ExerciseMetric { oneRepMax, bestWeight, volume }

/// Ряд для графика: точка на каждую тренировку с упражнением, по возрастанию даты.
List<({DateTime date, double value})> exerciseSeries(
  String exercise,
  List<Workout> workouts,
  ExerciseMetric metric,
) {
  final points = <({DateTime date, double value})>[];
  for (final w in workouts) {
    final sets = [
      for (final e in w.entries.where((e) => e.exercise == exercise))
        for (final s in e.sets)
          if (!s.isWarmup && s.reps > 0) s,
    ];
    if (sets.isEmpty) continue;
    final value = switch (metric) {
      ExerciseMetric.oneRepMax =>
        sets.map((s) => s.oneRepMax).reduce((a, b) => a > b ? a : b),
      ExerciseMetric.bestWeight =>
        sets.map((s) => s.weight).reduce((a, b) => a > b ? a : b),
      ExerciseMetric.volume => totalVolume(sets),
    };
    points.add((date: w.startedAt, value: value));
  }
  return points..sort((a, b) => a.date.compareTo(b.date));
}
