import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_repositories.dart';
import '../data/remote_exercise_repository.dart';
import '../data/sample_data.dart';
import '../data/wger/wger_api.dart';
import '../domain/active_workout.dart';
import '../domain/body.dart';
import '../domain/exercise.dart';
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

final favoriteRepositoryProvider = Provider<FavoriteRepository>(
  (ref) => InMemoryFavoriteRepository(),
);

/// Id избранных упражнений.
final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

class FavoritesNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() => ref.watch(favoriteRepositoryProvider).all();

  Future<void> toggle(String exerciseId) async {
    await ref.read(favoriteRepositoryProvider).toggle(exerciseId);
    ref.invalidateSelf();
    await future;
  }
}

final activeWorkoutStoreProvider = Provider<ActiveWorkoutStore>(
  (ref) => InMemoryActiveWorkoutStore(),
);

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => RemoteExerciseRepository(WgerApi.create()),
);

/// Свои упражнения пользователя.
final customExercisesProvider =
    AsyncNotifierProvider<CustomExercisesNotifier, List<Exercise>>(
      CustomExercisesNotifier.new,
    );

class CustomExercisesNotifier extends AsyncNotifier<List<Exercise>> {
  @override
  Future<List<Exercise>> build() =>
      ref.watch(customExerciseRepositoryProvider).all();

  Future<void> save(Exercise exercise) async {
    await ref.read(customExerciseRepositoryProvider).save(exercise);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(customExerciseRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

/// Каталог: свои упражнения первыми, затем встроенные и wger.
final exercisesProvider = FutureProvider<ExerciseCatalog>(
  (ref) async {
    final custom = await ref.watch(customExercisesProvider.future);
    final catalog = await ref
        .watch(exerciseRepositoryProvider)
        .fetchExercises();
    return (items: [...custom, ...catalog.items], offline: catalog.offline);
  },
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

/// Идущая тренировка, восстановленная при запуске (main подставляет из хранилища).
final initialActiveWorkoutProvider = Provider<ActiveWorkout?>((ref) => null);

class ActiveWorkoutNotifier extends Notifier<ActiveWorkout?> {
  @override
  ActiveWorkout? build() {
    // Каждое изменение сразу в хранилище: тренировка переживает перезапуск.
    listenSelf((_, next) => ref.read(activeWorkoutStoreProvider).save(next));
    return ref.read(initialActiveWorkoutProvider);
  }

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
    // Сравниваем и с уже сделанными сегодня подходами: иначе «рекорд» на каждом.
    final before = recordsFor(exercise.name, [
      ...workouts,
      current.toWorkout('current', clock.now()),
    ]);
    final record = isNewRecord(entry, before)
        ? (exercise: exercise.name, set: entry, date: current.startedAt)
        : null;
    update((w) => w.completeCurrent(now: clock.now(), rest: rest));
    return record;
  }

  /// Отменить без сохранения.
  void cancel() => state = null;

  Future<Workout?>? _finishing;

  /// Сначала сохраняет, потом закрывает: при ошибке записи тренировка не теряется.
  /// Возвращает сохранённую тренировку или null, если сохранять нечего.
  /// Повторный вызов во время сохранения ждёт первый, а id из времени начала
  /// не даёт дубля даже после убийства процесса между записью и очисткой.
  Future<Workout?> finish({DateTime? now}) =>
      _finishing ??= _finish(now).whenComplete(() => _finishing = null);

  Future<Workout?> _finish(DateTime? now) async {
    final current = state;
    if (current == null) return null;
    final workout = current.toWorkout(
      'w-${current.startedAt.microsecondsSinceEpoch}',
      now ?? clock.now(),
    );
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

/// Замеры тела, от старых к новым.
final bodyEntriesProvider =
    AsyncNotifierProvider<BodyEntriesNotifier, List<BodyEntry>>(
      BodyEntriesNotifier.new,
    );

class BodyEntriesNotifier extends AsyncNotifier<List<BodyEntry>> {
  @override
  Future<List<BodyEntry>> build() async =>
      (await ref.watch(bodyRepositoryProvider).all())
        ..sort((a, b) => a.date.compareTo(b.date));

  Future<void> save(BodyEntry entry) async {
    await ref.read(bodyRepositoryProvider).save(entry);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(bodyRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

/// Группа мышц по названию упражнения: встроенный каталог, wger, свои; иначе «Другое».
final muscleGroupOfProvider = Provider<String Function(String exercise)>((ref) {
  final groups = {
    for (final e in sampleExercises) e.name: e.muscleGroup,
    for (final e
        in ref.watch(exercisesProvider).value?.items ?? const <Exercise>[])
      e.name: e.muscleGroup,
  };
  return (name) => groups[name] ?? 'Другое';
});
