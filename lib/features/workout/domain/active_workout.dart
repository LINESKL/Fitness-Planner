import 'exercise_log.dart';
import 'program.dart';
import 'progress_rules.dart';
import 'set_entry.dart';
import 'workout.dart';

/// Подход в идущей тренировке: значения можно править, пока он не сохранён.
class WorkoutSet {
  const WorkoutSet({
    required this.weight,
    required this.reps,
    this.done = false,
    this.type = SetType.normal,
    this.rpe,
    this.increased = false,
  });

  final double weight;
  final int reps;
  final bool done;
  final SetType type;
  final double? rpe;

  /// Вес поднят подсказкой прогрессии (+2.5 кг к прошлому разу).
  final bool increased;

  WorkoutSet copyWith({
    double? weight,
    int? reps,
    bool? done,
    SetType? type,
    double? rpe,
    bool? increased,
  }) => WorkoutSet(
    weight: weight ?? this.weight,
    reps: reps ?? this.reps,
    done: done ?? this.done,
    type: type ?? this.type,
    rpe: rpe ?? this.rpe,
    increased: increased ?? this.increased,
  );
}

class ActiveExercise {
  const ActiveExercise({required this.name, required this.sets, this.target});

  /// Подходы по прошлому разу с правилом прогрессии; [count] — число подходов
  /// (по умолчанию — сколько было рабочих в прошлый раз, минимум один).
  factory ActiveExercise.fromHistory(
    String name,
    Iterable<ExerciseLog> history, {
    int? count,
    ({int min, int max})? target,
  }) {
    final previous = [
      for (final s in lastTime(history, name)?.sets ?? const <SetEntry>[])
        if (!s.isWarmup) s,
    ];
    final total = count ?? (previous.isEmpty ? 1 : previous.length);
    return ActiveExercise(
      name: name,
      target: target,
      sets: [
        for (var i = 0; i < total; i++)
          switch (suggestSet(previous: previous, index: i, target: target)) {
            final s => WorkoutSet(
              weight: s.weight,
              reps: s.reps,
              increased: s.increased,
            ),
          },
      ],
    );
  }

  final String name;
  final List<WorkoutSet> sets;

  /// Диапазон повторов из шаблона дня.
  final ({int min, int max})? target;

  ActiveExercise withSets(List<WorkoutSet> sets) =>
      ActiveExercise(name: name, sets: sets, target: target);
}

enum WorkoutPhase { set, rest, finished }

typedef SetCursor = ({int exercise, int set});

/// Идущая тренировка в фокус-режиме: курсор на текущем подходе, фаза и отдых.
/// Неизменяемая: каждое действие возвращает новую копию.
class ActiveWorkout {
  const ActiveWorkout({
    required this.startedAt,
    required this.exercises,
    this.title = 'Тренировка',
    this.templateId,
    this.cursor = (exercise: 0, set: 0),
    this.phase = WorkoutPhase.set,
    this.restEndsAt,
  });

  factory ActiveWorkout.fromTemplate(
    WorkoutTemplate template,
    Iterable<ExerciseLog> history,
    DateTime now,
  ) => ActiveWorkout(
    startedAt: now,
    title: template.name,
    templateId: template.id,
    exercises: [
      for (final e in template.exercises)
        ActiveExercise.fromHistory(
          e.exercise,
          history,
          count: e.sets,
          target: (min: e.repsMin, max: e.repsMax),
        ),
    ],
  );

  factory ActiveWorkout.empty(DateTime now) =>
      ActiveWorkout(startedAt: now, exercises: const []);

  /// Свободная тренировка из списка упражнений (повтор прошлой).
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
  final String title;
  final String? templateId;
  final List<ActiveExercise> exercises;
  final SetCursor cursor;
  final WorkoutPhase phase;
  final DateTime? restEndsAt;

  ActiveExercise? get currentExercise =>
      cursor.exercise < exercises.length ? exercises[cursor.exercise] : null;

  WorkoutSet? get currentSet {
    final sets = currentExercise?.sets;
    return sets != null && cursor.set < sets.length ? sets[cursor.set] : null;
  }

  ActiveWorkout _copy({
    List<ActiveExercise>? exercises,
    SetCursor? cursor,
    WorkoutPhase? phase,
    DateTime? restEndsAt,
    bool clearRest = false,
  }) => ActiveWorkout(
    startedAt: startedAt,
    title: title,
    templateId: templateId,
    exercises: exercises ?? this.exercises,
    cursor: cursor ?? this.cursor,
    phase: phase ?? this.phase,
    restEndsAt: clearRest ? null : (restEndsAt ?? this.restEndsAt),
  );

  /// Подходы по порядку, начиная сразу после [from], с переходом в начало.
  static Iterable<SetCursor> _after(
    List<ActiveExercise> exercises,
    SetCursor from,
  ) sync* {
    final all = [
      for (var e = 0; e < exercises.length; e++)
        for (var s = 0; s < exercises[e].sets.length; s++)
          (exercise: e, set: s),
    ];
    final start = all.indexOf(from);
    for (var i = 1; i <= all.length; i++) {
      yield all[(start + i) % all.length];
    }
  }

  static SetCursor? _nextUndone(
    List<ActiveExercise> exercises,
    SetCursor from,
  ) {
    if (exercises.every((e) => e.sets.every((s) => s.done))) return null;
    return _after(
      exercises,
      from,
    ).firstWhere((c) => !exercises[c.exercise].sets[c.set].done);
  }

  /// «Готово»: подход выполнен, курсор — к следующему невыполненному,
  /// отдых [rest] (ноль — без отдыха); после последнего — [WorkoutPhase.finished].
  ActiveWorkout completeCurrent({
    required DateTime now,
    required Duration rest,
  }) {
    if (currentSet == null) return this;
    final updated = _setsUpdated(
      cursor.exercise,
      (sets) => [
        for (final (i, s) in sets.indexed)
          i == cursor.set ? s.copyWith(done: true) : s,
      ],
    );
    final next = _nextUndone(updated, cursor);
    if (next == null) {
      return _copy(
        exercises: updated,
        phase: WorkoutPhase.finished,
        clearRest: true,
      );
    }
    final resting = rest > Duration.zero;
    return _copy(
      exercises: updated,
      cursor: next,
      phase: resting ? WorkoutPhase.rest : WorkoutPhase.set,
      restEndsAt: resting ? now.add(rest) : null,
      clearRest: !resting,
    );
  }

  ActiveWorkout skipRest() => phase == WorkoutPhase.rest
      ? _copy(phase: WorkoutPhase.set, clearRest: true)
      : this;

  ActiveWorkout extendRest(Duration delta) =>
      restEndsAt == null ? this : _copy(restEndsAt: restEndsAt!.add(delta));

  /// Перейти к подходу (в том числе к выполненному — чтобы поправить).
  ActiveWorkout goTo(int exercise, int set) => _copy(
    cursor: (exercise: exercise, set: set),
    phase: WorkoutPhase.set,
    clearRest: true,
  );

  /// Копия последнего подхода; после конца тренировки он сразу текущий.
  ActiveWorkout addSet(int exercise) {
    final sets = exercises[exercise].sets;
    final added = _setsUpdated(
      exercise,
      (sets) => [
        ...sets,
        (sets.isEmpty
                ? const WorkoutSet(weight: 0, reps: 0)
                : sets.last.copyWith(done: false, increased: false))
            .copyWith(done: false),
      ],
    );
    if (phase != WorkoutPhase.finished) return _copy(exercises: added);
    return _copy(
      exercises: added,
      cursor: (exercise: exercise, set: sets.length),
      phase: WorkoutPhase.set,
    );
  }

  ActiveWorkout editSet(
    int exercise,
    int set, {
    double? weight,
    int? reps,
    SetType? type,
    double? rpe,
  }) => _copy(
    exercises: _setsUpdated(
      exercise,
      (sets) => [
        for (final (i, s) in sets.indexed)
          i == set
              ? s.copyWith(
                  weight: weight,
                  reps: reps,
                  type: type,
                  rpe: rpe,
                  increased: weight == null ? null : false,
                )
              : s,
      ],
    ),
  );

  ActiveWorkout addExercise(String name, Iterable<ExerciseLog> history) {
    final added = [...exercises, ActiveExercise.fromHistory(name, history)];
    if (exercises.isNotEmpty && phase != WorkoutPhase.finished) {
      return _copy(exercises: added);
    }
    return _copy(
      exercises: added,
      cursor: (exercise: added.length - 1, set: 0),
      phase: WorkoutPhase.set,
      clearRest: true,
    );
  }

  ActiveWorkout removeExercise(int index) {
    final left = [...exercises]..removeAt(index);
    if (left.isEmpty) {
      return _copy(
        exercises: left,
        cursor: (exercise: 0, set: 0),
        phase: WorkoutPhase.set,
        clearRest: true,
      );
    }
    if (index != cursor.exercise) {
      final shifted = index < cursor.exercise
          ? (exercise: cursor.exercise - 1, set: cursor.set)
          : cursor;
      return _copy(exercises: left, cursor: shifted);
    }
    // Удалили текущее: первый невыполненный подход, начиная с его места.
    final start = index < left.length ? index : 0;
    final candidates = [
      for (var e = start; e < left.length; e++)
        for (var s = 0; s < left[e].sets.length; s++) (exercise: e, set: s),
      for (var e = 0; e < start; e++)
        for (var s = 0; s < left[e].sets.length; s++) (exercise: e, set: s),
    ];
    final next = candidates
        .where((c) => !left[c.exercise].sets[c.set].done)
        .firstOrNull;
    return _copy(
      exercises: left,
      cursor: next ?? (exercise: 0, set: 0),
      phase: next == null ? WorkoutPhase.finished : WorkoutPhase.set,
      clearRest: true,
    );
  }

  /// Замена упражнения: число подходов и цель сохраняются, значения — новые.
  ActiveWorkout replaceExercise(
    int index,
    String name,
    Iterable<ExerciseLog> history,
  ) {
    final old = exercises[index];
    final copy = [...exercises];
    copy[index] = ActiveExercise.fromHistory(
      name,
      history,
      count: old.sets.length,
      target: old.target,
    );
    final onIt = cursor.exercise == index;
    return _copy(
      exercises: copy,
      cursor: onIt ? (exercise: index, set: 0) : cursor,
      phase: onIt ? WorkoutPhase.set : phase,
      clearRest: onIt,
    );
  }

  ActiveWorkout moveExercise(int from, int to) {
    final copy = [...exercises];
    final moved = copy.removeAt(from);
    copy.insert(to, moved);
    final current = exercises[cursor.exercise];
    return _copy(
      exercises: copy,
      cursor: (exercise: copy.indexOf(current), set: cursor.set),
    );
  }

  /// Завершённая тренировка: только выполненные подходы с повторами.
  Workout toWorkout(String id, DateTime finishedAt) => Workout(
    id: id,
    title: title,
    templateId: templateId,
    startedAt: startedAt,
    finishedAt: finishedAt,
    entries: [
      for (final e in exercises)
        if (e.sets.where((s) => s.done && s.reps > 0).toList() case final done
            when done.isNotEmpty)
          WorkoutEntry(
            exercise: e.name,
            sets: [
              for (final s in done)
                SetEntry(
                  weight: s.weight,
                  reps: s.reps,
                  type: s.type,
                  rpe: s.rpe,
                ),
            ],
          ),
    ],
  );

  List<ActiveExercise> _setsUpdated(
    int exercise,
    List<WorkoutSet> Function(List<WorkoutSet> sets) update,
  ) => [
    for (final (i, e) in exercises.indexed)
      i == exercise ? e.withSets(update(e.sets)) : e,
  ];
}
