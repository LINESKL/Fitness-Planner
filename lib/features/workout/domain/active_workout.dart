import 'exercise_log.dart';
import 'set_entry.dart';

/// Подход в идущей тренировке: значения можно править, пока он не сохранён.
class WorkoutSet {
  const WorkoutSet({
    required this.weight,
    required this.reps,
    this.done = false,
  });

  final double weight;
  final int reps;
  final bool done;

  WorkoutSet copyWith({double? weight, int? reps, bool? done}) => WorkoutSet(
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    done: done ?? this.done,
  );
}

class ActiveExercise {
  const ActiveExercise({required this.name, required this.sets});

  /// Подходы предзаполнены рабочими подходами прошлого раза.
  factory ActiveExercise.fromHistory(
    String name,
    Iterable<ExerciseLog> history,
  ) {
    final previous = [
      for (final s in lastTime(history, name)?.sets ?? const <SetEntry>[])
        if (!s.isWarmup) WorkoutSet(weight: s.weight, reps: s.reps),
    ];
    return ActiveExercise(
      name: name,
      sets: previous.isEmpty
          ? const [WorkoutSet(weight: 0, reps: 0)]
          : previous,
    );
  }

  final String name;
  final List<WorkoutSet> sets;
}

/// Идущая тренировка. Неизменяемая: каждое действие возвращает новую копию.
class ActiveWorkout {
  const ActiveWorkout({required this.startedAt, required this.exercises});

  factory ActiveWorkout.start({
    required DateTime startedAt,
    required List<String> plan,
    required Iterable<ExerciseLog> history,
  }) => ActiveWorkout(
    startedAt: startedAt,
    exercises: [
      for (final name in plan) ActiveExercise.fromHistory(name, history),
    ],
  );

  final DateTime startedAt;
  final List<ActiveExercise> exercises;

  ActiveWorkout addExercise(String name, Iterable<ExerciseLog> history) =>
      ActiveWorkout(
        startedAt: startedAt,
        exercises: [...exercises, ActiveExercise.fromHistory(name, history)],
      );

  ActiveWorkout addSet(int exercise) => _updateSets(
    exercise,
    (sets) => [...sets, sets.last.copyWith(done: false)],
  );

  ActiveWorkout updateSet(int exercise, int set, {double? weight, int? reps}) =>
      _updateSets(exercise, (sets) {
        final copy = [...sets];
        copy[set] = copy[set].copyWith(weight: weight, reps: reps);
        return copy;
      });

  ActiveWorkout toggleDone(int exercise, int set) =>
      _updateSets(exercise, (sets) {
        final copy = [...sets];
        copy[set] = copy[set].copyWith(done: !copy[set].done);
        return copy;
      });

  /// Сохраняются только отмеченные подходы с повторами; пустые упражнения отбрасываются.
  List<ExerciseLog> toLogs(DateTime finishedAt) => [
    for (final exercise in exercises)
      if (exercise.sets.where((s) => s.done && s.reps > 0).toList()
          case final done when done.isNotEmpty)
        ExerciseLog(
          exercise: exercise.name,
          date: finishedAt,
          sets: [
            for (final s in done) SetEntry(weight: s.weight, reps: s.reps),
          ],
        ),
  ];

  ActiveWorkout _updateSets(
    int exercise,
    List<WorkoutSet> Function(List<WorkoutSet> sets) update,
  ) {
    final copy = [...exercises];
    final target = copy[exercise];
    copy[exercise] = ActiveExercise(
      name: target.name,
      sets: update(target.sets),
    );
    return ActiveWorkout(startedAt: startedAt, exercises: copy);
  }
}
