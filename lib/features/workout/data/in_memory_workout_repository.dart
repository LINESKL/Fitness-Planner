import '../domain/exercise_log.dart';
import '../domain/workout_repository.dart';

/// История в памяти: живёт до перезапуска приложения.
class InMemoryWorkoutRepository implements WorkoutRepository {
  InMemoryWorkoutRepository([List<ExerciseLog> seed = const []])
    : _logs = [...seed];

  final List<ExerciseLog> _logs;

  @override
  Future<List<ExerciseLog>> loadHistory() async => List.unmodifiable(_logs);

  @override
  Future<void> addLogs(List<ExerciseLog> logs) async => _logs.addAll(logs);
}
