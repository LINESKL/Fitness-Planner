import 'exercise.dart';

/// Страница каталога; [offline] — показана сохранённая копия, сеть недоступна;
/// [nextOffset] — откуда грузить следующую страницу, null — страниц больше нет.
typedef ExerciseCatalog = ({
  List<Exercise> items,
  bool offline,
  int? nextOffset,
});

abstract interface class ExerciseRepository {
  /// Бросает [ExerciseLoadException], если страницу не удалось получить.
  Future<ExerciseCatalog> fetchExercises({int offset = 0});
}

class ExerciseLoadException implements Exception {
  const ExerciseLoadException(this.message);

  /// Текст для пользователя.
  final String message;

  @override
  String toString() => 'ExerciseLoadException: $message';
}
