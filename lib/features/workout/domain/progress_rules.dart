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
