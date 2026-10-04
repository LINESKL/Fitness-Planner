import 'exercise_log.dart';

/// Где хранится история тренировок — решает слой data.
abstract interface class WorkoutRepository {
  Future<List<ExerciseLog>> loadHistory();
  Future<void> addLogs(List<ExerciseLog> logs);
}
