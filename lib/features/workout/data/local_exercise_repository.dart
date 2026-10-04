import '../domain/exercise_repository.dart';
import 'sample_data.dart';

/// Встроенный каталог упражнений.
class LocalExerciseRepository implements ExerciseRepository {
  const LocalExerciseRepository();

  @override
  Future<ExerciseCatalog> fetchExercises() async =>
      (items: sampleExercises, offline: false);
}
