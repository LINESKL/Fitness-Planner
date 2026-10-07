import 'package:hive_ce/hive_ce.dart';

import '../../domain/active_workout.dart';
import '../../domain/body.dart';
import '../../domain/exercise.dart';
import '../../domain/program.dart';
import '../../domain/repositories.dart';
import '../../domain/workout.dart';
import '../json_mappers.dart';

Json _json(Map map) => Map<String, Object?>.from(map);

class HiveWorkoutRepository implements WorkoutRepository {
  HiveWorkoutRepository(this._box);

  static const boxName = 'workouts_v2';

  static Future<HiveWorkoutRepository> open() async =>
      HiveWorkoutRepository(await Hive.openBox<Map>(boxName));

  final Box<Map> _box;

  @override
  Future<List<Workout>> all() async => [
    for (final j in _box.values) workoutFromJson(_json(j)),
  ];

  @override
  Future<void> save(Workout workout) =>
      _box.put(workout.id, workoutToJson(workout));

  @override
  Future<void> delete(String id) => _box.delete(id);
}

class HiveProgramRepository implements ProgramRepository {
  HiveProgramRepository(this._templates, this._program);

  static const templatesBox = 'templates';
  static const programBox = 'program';
  static const _programKey = 'program';

  static Future<HiveProgramRepository> open() async => HiveProgramRepository(
    await Hive.openBox<Map>(templatesBox),
    await Hive.openBox<Map>(programBox),
  );

  final Box<Map> _templates;
  final Box<Map> _program;

  @override
  Future<List<WorkoutTemplate>> templates() async => [
    for (final j in _templates.values) templateFromJson(_json(j)),
  ];

  @override
  Future<void> saveTemplate(WorkoutTemplate template) =>
      _templates.put(template.id, templateToJson(template));

  @override
  Future<void> deleteTemplate(String id) => _templates.delete(id);

  @override
  Future<Program> program() async => switch (_program.get(_programKey)) {
    final Map j => programFromJson(_json(j)),
    _ => const Program(templateIds: []),
  };

  @override
  Future<void> saveProgram(Program program) =>
      _program.put(_programKey, programToJson(program));
}

class HiveNoteRepository implements NoteRepository {
  HiveNoteRepository(this._box);

  static const boxName = 'notes';

  static Future<HiveNoteRepository> open() async =>
      HiveNoteRepository(await Hive.openBox<String>(boxName));

  final Box<String> _box;

  @override
  Future<String?> note(String exercise) async => _box.get(exercise);

  @override
  Future<void> setNote(String exercise, String text) => text.trim().isEmpty
      ? _box.delete(exercise)
      : _box.put(exercise, text.trim());
}

class HiveBodyRepository implements BodyRepository {
  HiveBodyRepository(this._box);

  static const boxName = 'body';

  static Future<HiveBodyRepository> open() async =>
      HiveBodyRepository(await Hive.openBox<Map>(boxName));

  final Box<Map> _box;

  @override
  Future<List<BodyEntry>> all() async => [
    for (final j in _box.values) bodyFromJson(_json(j)),
  ];

  @override
  Future<void> save(BodyEntry entry) => _box.put(entry.id, bodyToJson(entry));

  @override
  Future<void> delete(String id) => _box.delete(id);
}

class HiveCustomExerciseRepository implements CustomExerciseRepository {
  HiveCustomExerciseRepository(this._box);

  static const boxName = 'custom_exercises';

  static Future<HiveCustomExerciseRepository> open() async =>
      HiveCustomExerciseRepository(await Hive.openBox<Map>(boxName));

  final Box<Map> _box;

  @override
  Future<List<Exercise>> all() async => [
    for (final j in _box.values) exerciseFromJson(_json(j)),
  ];

  @override
  Future<void> save(Exercise exercise) =>
      _box.put(exercise.id, exerciseToJson(exercise));

  @override
  Future<void> delete(String id) => _box.delete(id);
}

class HiveActiveWorkoutStore implements ActiveWorkoutStore {
  HiveActiveWorkoutStore(this._box);

  static const boxName = 'active_workout';
  static const _key = 'current';

  static Future<HiveActiveWorkoutStore> open() async =>
      HiveActiveWorkoutStore(await Hive.openBox<Map>(boxName));

  final Box<Map> _box;

  /// Повреждённая запись не должна ронять запуск: она удаляется, тренировки нет.
  @override
  Future<ActiveWorkout?> load() async {
    final raw = _box.get(_key);
    if (raw == null) return null;
    try {
      return activeWorkoutFromJson(_json(raw));
    } on Object {
      await _box.delete(_key);
      return null;
    }
  }

  @override
  Future<void> save(ActiveWorkout? workout) => workout == null
      ? _box.delete(_key)
      : _box.put(_key, activeWorkoutToJson(workout));
}
