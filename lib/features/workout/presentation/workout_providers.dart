import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_workout_repository.dart';
import '../data/remote_exercise_repository.dart';
import '../data/sample_data.dart';
import '../data/wger/wger_api.dart';
import '../domain/active_workout.dart';
import '../domain/exercise_log.dart';
import '../domain/exercise_repository.dart';
import '../domain/workout_repository.dart';

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

/// Строка поиска по каталогу; применяется через 300 мс после последнего ввода.
final exerciseQueryProvider =
    NotifierProvider.autoDispose<ExerciseQueryNotifier, String>(
      ExerciseQueryNotifier.new,
    );

class ExerciseQueryNotifier extends Notifier<String> {
  static const debounce = Duration(milliseconds: 300);

  Timer? _timer;

  @override
  String build() {
    ref.onDispose(() => _timer?.cancel());
    return '';
  }

  void search(String text) {
    _timer?.cancel();
    _timer = Timer(debounce, () => state = text.trim().toLowerCase());
  }
}

final filteredExercisesProvider =
    Provider.autoDispose<AsyncValue<ExerciseCatalog>>((ref) {
      final query = ref.watch(exerciseQueryProvider);
      return ref
          .watch(exercisesProvider)
          .whenData(
            (catalog) => query.isEmpty
                ? catalog
                : (
                    items: [
                      for (final e in catalog.items)
                        if (e.name.toLowerCase().contains(query) ||
                            e.muscleGroup.toLowerCase().contains(query))
                          e,
                    ],
                    offline: catalog.offline,
                  ),
          );
    });

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

  Future<void> finish({DateTime? now}) async {
    final current = state;
    if (current == null) return;
    state = null;
    await ref
        .read(historyProvider.notifier)
        .add(current.toLogs(now ?? DateTime.now()));
  }
}
