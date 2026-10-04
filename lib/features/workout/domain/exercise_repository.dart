import 'exercise.dart';

abstract interface class ExerciseRepository {
  /// Бросает [ExerciseLoadException], если каталог не удалось получить.
  Future<List<Exercise>> fetchExercises();
}

class ExerciseLoadException implements Exception {
  const ExerciseLoadException(this.message);

  /// Текст для пользователя.
  final String message;

  @override
  String toString() => 'ExerciseLoadException: $message';
}
