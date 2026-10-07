import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ids.dart';
import '../data/in_memory_repositories.dart';
import '../data/remote_exercise_repository.dart';
import '../data/sample_data.dart';
import '../data/wger/wger_api.dart';
import '../domain/active_workout.dart';
import '../domain/exercise_log.dart';
import '../domain/exercise_repository.dart';
import '../domain/program.dart';
import '../domain/progress_rules.dart';
import '../domain/set_entry.dart';
import '../domain/repositories.dart';
import '../domain/workout.dart';
import '../domain/workout_async.dart';

// DI: реализации подставляются здесь, в тестах — через overrides.
final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => InMemoryWorkoutRepository.fromLogs(sampleHistory),
);

final programRepositoryProvider = Provider<ProgramRepository>(
  (ref) => InMemoryProgramRepository(),
);

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => InMemoryNoteRepository(),
);

final bodyRepositoryProvider = Provider<BodyRepository>(
  (ref) => InMemoryBodyRepository(),
);

final customExerciseRepositoryProvider = Provider<CustomExerciseRepository>(
  (ref) => InMemoryCustomExerciseRepository(),
);

final activeWorkoutStoreProvider = Provider<ActiveWorkoutStore>(
  (ref) => InMemoryActiveWorkoutStore(),
);

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => RemoteExerciseRepository(WgerApi.create()),
);

final exercisesProvider = FutureProvider<ExerciseCatalog>(
  (ref) => ref.watch(exerciseRepositoryProvider).fetchExercises(),
  // Повтор — по кнопке на экране ошибки, без фоновых попыток.
  retry: (_, _) => null,
);

/// Завершённые тренировки, от старых к новым.
final workoutsProvider = AsyncNotifierProvider<WorkoutsNotifier, List<Workout>>(
  WorkoutsNotifier.new,
);

class WorkoutsNotifier extends AsyncNotifier<List<Workout>> {
  @override
  Future<List<Workout>> build() async =>
      (await ref.watch(workoutRepositoryProvider).all())
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

  Future<void> save(Workout workout) async {
    await ref.read(workoutRepositoryProvider).save(workout);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(workoutRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

/// Плоские логи всех тренировок — для функций истории (`lastTime` и др.).
final historyProvider = FutureProvider<List<ExerciseLog>>(
  (ref) async => [
    for (final w in await ref.watch(workoutsProvider.future)) ...w.logs,
  ],
);

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutNotifier, ActiveWorkout?>(
      ActiveWorkoutNotifier.new,
    );

class ActiveWorkoutNotifier extends Notifier<ActiveWorkout?> {
  @override
  ActiveWorkout? build() => null;

  /// Без [plan] повторяет упражнения последней тренировки. Идущую не сбрасывает.
  Future<void> start({List<String>? plan, DateTime? now}) async {
    if (state != null) return;
    final history = await ref.read(historyProvider.future);
    state = ActiveWorkout.start(
      startedAt: now ?? DateTime.now(),
      plan:
          plan ??
          [
            for (final log
                in workoutsByDay(history).firstOrNull ?? const <ExerciseLog>[])
              log.exercise,
          ],
      history: history,
    );
  }

  /// Тренировка по дню программы. Идущую не сбрасывает.
  Future<void> startTemplate(WorkoutTemplate template, {DateTime? now}) async {
    if (state != null) return;
    final history = await ref.read(historyProvider.future);
    state = ActiveWorkout.fromTemplate(
      template,
      history,
      now ?? DateTime.now(),
    );
  }

  /// Пустая тренировка: упражнения добавляются по ходу.
  void startEmpty({DateTime? now}) {
    state ??= ActiveWorkout.empty(now ?? DateTime.now());
  }

  void update(ActiveWorkout Function(ActiveWorkout workout) change) {
    final current = state;
    if (current != null) state = change(current);
  }

  Future<void> addExercise(String name) async {
    final history = await ref.read(historyProvider.future);
    update((w) => w.addExercise(name, history));
  }

  Future<void> replaceExercise(int index, String name) async {
    final history = await ref.read(historyProvider.future);
    update((w) => w.replaceExercise(index, name, history));
  }

  /// «Готово» по текущему подходу. Возвращает рекорд, если он побит.
  Future<RecordEvent?> completeCurrent(Duration rest) async {
    final current = state;
    final set = current?.currentSet;
    final exercise = current?.currentExercise;
    if (current == null || set == null || exercise == null) return null;

    final workouts = await ref.read(workoutsProvider.future);
    final entry = SetEntry(
      weight: set.weight,
      reps: set.reps,
      type: set.type,
      rpe: set.rpe,
    );
    final record = isNewRecord(entry, recordsFor(exercise.name, workouts))
        ? (exercise: exercise.name, set: entry, date: current.startedAt)
        : null;
    update((w) => w.completeCurrent(now: clock.now(), rest: rest));
    return record;
  }

  /// Сначала сохраняет, потом закрывает: при ошибке записи тренировка не теряется.
  /// Возвращает сохранённую тренировку или null, если сохранять нечего.
  Future<Workout?> finish({DateTime? now}) async {
    final current = state;
    if (current == null) return null;
    final workout = current.toWorkout(newId(), now ?? clock.now());
    if (workout.entries.isNotEmpty) {
      await ref.read(workoutsProvider.notifier).save(workout);
    }
    state = null;
    return workout.entries.isEmpty ? null : workout;
  }
}

/// Оставшийся отдых идущей тренировки; null — отдыха нет.
/// Тикает раз в секунду от `restEndsAt`, а не считает тики.
final restLeftProvider = NotifierProvider<RestLeftNotifier, Duration?>(
  RestLeftNotifier.new,
);

class RestLeftNotifier extends Notifier<Duration?> {
  @override
  Duration? build() {
    final endsAt = ref.watch(
      activeWorkoutProvider.select((w) => w?.restEndsAt),
    );
    if (endsAt == null) return null;

    void finishRest() => ref
        .read(activeWorkoutProvider.notifier)
        .update((w) => w.restEndsAt == endsAt ? w.skipRest() : w);

    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = restLeft(endsAt, clock.now());
      if (state == null) {
        timer.cancel();
        finishRest();
      }
    });
    ref.onDispose(timer.cancel);
    final left = restLeft(endsAt, clock.now());
    // Отдых уже вышел (например, приложение было закрыто) — сразу к подходу.
    if (left == null) Future.microtask(finishRest);
    return left;
  }
}

/// Заметка к упражнению («сиденье на 4»).
final noteProvider = FutureProvider.family<String?, String>(
  (ref, exercise) => ref.watch(noteRepositoryProvider).note(exercise),
);
