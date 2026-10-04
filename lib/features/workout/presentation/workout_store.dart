import 'package:flutter/foundation.dart';

import '../domain/active_workout.dart';
import '../domain/exercise_log.dart';

/// История тренировок и идущая тренировка в одном месте.
class WorkoutStore extends ChangeNotifier {
  WorkoutStore({List<ExerciseLog> history = const []})
    : _history = [...history];

  final List<ExerciseLog> _history;
  ActiveWorkout? _active;

  List<ExerciseLog> get history => List.unmodifiable(_history);
  ActiveWorkout? get active => _active;

  /// Начинает тренировку; если она уже идёт — оставляет как есть.
  void start(List<String> plan, {DateTime? now}) {
    if (_active != null) return;
    _active = ActiveWorkout.start(
      startedAt: now ?? DateTime.now(),
      plan: plan,
      history: _history,
    );
    notifyListeners();
  }

  void update(ActiveWorkout Function(ActiveWorkout workout) change) {
    final active = _active;
    if (active == null) return;
    _active = change(active);
    notifyListeners();
  }

  void finish({DateTime? now}) {
    final active = _active;
    if (active == null) return;
    _history.addAll(active.toLogs(now ?? DateTime.now()));
    _active = null;
    notifyListeners();
  }
}
