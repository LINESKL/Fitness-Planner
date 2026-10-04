import 'exercise.dart';

abstract interface class ExerciseRepository {
  Future<List<Exercise>> fetchExercises();
}
