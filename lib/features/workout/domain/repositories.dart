import 'active_workout.dart';
import 'body.dart';
import 'exercise.dart';
import 'program.dart';
import 'workout.dart';

// Интерфейсы хранилищ. Реализации — в data/ (Hive, память), подставляются через DI.

abstract interface class WorkoutRepository {
  Future<List<Workout>> all();

  /// Создаёт или заменяет тренировку с тем же id.
  Future<void> save(Workout workout);
  Future<void> delete(String id);
}

abstract interface class ProgramRepository {
  Future<List<WorkoutTemplate>> templates();
  Future<void> saveTemplate(WorkoutTemplate template);
  Future<void> deleteTemplate(String id);
  Future<Program> program();
  Future<void> saveProgram(Program program);
}

abstract interface class NoteRepository {
  Future<String?> note(String exercise);

  /// Пустой текст удаляет заметку.
  Future<void> setNote(String exercise, String text);
}

abstract interface class BodyRepository {
  Future<List<BodyEntry>> all();
  Future<void> save(BodyEntry entry);
  Future<void> delete(String id);
}

abstract interface class CustomExerciseRepository {
  Future<List<Exercise>> all();
  Future<void> save(Exercise exercise);
  Future<void> delete(String id);
}

/// Идущая тренировка переживает перезапуск приложения.
abstract interface class ActiveWorkoutStore {
  Future<ActiveWorkout?> load();

  /// null — очистить.
  Future<void> save(ActiveWorkout? workout);
}

/// Избранные упражнения (по id).
abstract interface class FavoriteRepository {
  Future<Set<String>> all();

  /// Добавить, если нет; убрать, если есть.
  Future<void> toggle(String exerciseId);
}
