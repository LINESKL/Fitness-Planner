import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import 'sample_data.dart';

/// Встроенный каталог упражнений.
class LocalExerciseRepository implements ExerciseRepository {
  const LocalExerciseRepository();

  @override
  Future<List<Exercise>> fetchExercises() async => sampleExercises;
}
