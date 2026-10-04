import 'exercise.dart';

/// Каталог упражнений; [offline] — показана сохранённая копия, сеть недоступна.
typedef ExerciseCatalog = ({List<Exercise> items, bool offline});

abstract interface class ExerciseRepository {
  /// Бросает [ExerciseLoadException], если каталог не удалось получить.
  Future<ExerciseCatalog> fetchExercises();
}

class ExerciseLoadException implements Exception {
  const ExerciseLoadException(this.message);

  /// Текст для пользователя.
  final String message;

  @override
  String toString() => 'ExerciseLoadException: $message';
}
