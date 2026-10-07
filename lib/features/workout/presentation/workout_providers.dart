import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_workout_repository.dart';
import '../data/remote_exercise_repository.dart';
import '../data/sample_data.dart';
import '../data/wger/wger_api.dart';
import '../domain/active_workout.dart';
import '../domain/exercise_log.dart';
import '../domain/exercise_repository.dart';
import '../domain/workout_repository.dart';
import '../domain/workout_async.dart';

// DI: реализации подставляются здесь, в тестах — через overrides.
final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => InMemoryWorkoutRepository(sampleHistory),
);

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => RemoteExerciseRepository(WgerApi.create()),
);

final exercisesProvider = FutureProvider<ExerciseCatalog>(
  (ref) => ref.watch(exerciseRepositoryProvider).fetchExercises(),
  // Повтор — по кнопке на экране ошибки, без фоновых попыток.
  retry: (_, _) => null,
);

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<ExerciseLog>>(
      HistoryNotifier.new,
    );

class HistoryNotifier extends AsyncNotifier<List<ExerciseLog>> {
  @override
  Future<List<ExerciseLog>> build() =>
      ref.watch(workoutRepositoryProvider).loadHistory();

  Future<void> add(List<ExerciseLog> logs) async {
    if (logs.isEmpty) return;
    await ref.read(workoutRepositoryProvider).addLogs(logs);
    ref.invalidateSelf();
    await future;
  }
}

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

  void update(ActiveWorkout Function(ActiveWorkout workout) change) {
    final current = state;
    if (current != null) state = change(current);
  }

  Future<void> addExercise(String name) async {
    final history = await ref.read(historyProvider.future);
    update((w) => w.addExercise(name, history));
  }

  /// Сначала сохраняет, потом закрывает: при ошибке записи тренировка не теряется.
  Future<void> finish({DateTime? now}) async {
    final current = state;
    if (current == null) return;
    await ref
        .read(historyProvider.notifier)
        .add(current.toLogs(now ?? DateTime.now()));
    state = null;
  }
}

/// Сколько осталось отдыхать; null — таймер не идёт.
final restTimerProvider = NotifierProvider<RestTimerNotifier, Duration?>(
  RestTimerNotifier.new,
);

class RestTimerNotifier extends Notifier<Duration?> {
  StreamSubscription<Duration>? _subscription;

  @override
  Duration? build() {
    ref.onDispose(() => _subscription?.cancel());
    return null;
  }

  /// Перезапускает отсчёт; нулевая длительность — таймер выключен.
  void start(Duration total) {
    _subscription?.cancel();
    if (total <= Duration.zero) {
      state = null;
      return;
    }
    state = total;
    _subscription = restTimer(total)
        .listen((left) => state = left > Duration.zero ? left : null);
  }

  void skip() {
    _subscription?.cancel();
    state = null;
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

    final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = restLeft(endsAt, clock.now());
      if (state == null) timer.cancel();
    });
    ref.onDispose(timer.cancel);
    return restLeft(endsAt, clock.now());
  }
}
