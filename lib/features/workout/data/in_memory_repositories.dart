import '../domain/active_workout.dart';
import '../domain/body.dart';
import '../domain/exercise.dart';
import '../domain/exercise_log.dart';
import '../domain/program.dart';
import '../domain/repositories.dart';
import '../domain/workout.dart';

// Хранилища в памяти: значения по умолчанию для тестов и до инициализации Hive.

class InMemoryWorkoutRepository implements WorkoutRepository {
  InMemoryWorkoutRepository([List<Workout> seed = const []])
    : _items = {for (final w in seed) w.id: w};

  /// Из плоских логов старого формата — тренировки по дням.
  InMemoryWorkoutRepository.fromLogs(Iterable<ExerciseLog> logs)
    : this(workoutsFromLogs(logs));

  final Map<String, Workout> _items;

  @override
  Future<List<Workout>> all() async => [..._items.values];

  @override
  Future<void> save(Workout workout) async => _items[workout.id] = workout;

  @override
  Future<void> delete(String id) async => _items.remove(id);
}

class InMemoryProgramRepository implements ProgramRepository {
  InMemoryProgramRepository({
    List<WorkoutTemplate> templates = const [],
    Program program = const Program(templateIds: []),
  }) : _templates = {for (final t in templates) t.id: t},
       _program = program; // ignore: prefer_initializing_formals

  final Map<String, WorkoutTemplate> _templates;
  Program _program;

  @override
  Future<List<WorkoutTemplate>> templates() async => [..._templates.values];

  @override
  Future<void> saveTemplate(WorkoutTemplate template) async =>
      _templates[template.id] = template;

  @override
  Future<void> deleteTemplate(String id) async => _templates.remove(id);

  @override
  Future<Program> program() async => _program;

  @override
  Future<void> saveProgram(Program program) async => _program = program;
}

class InMemoryNoteRepository implements NoteRepository {
  final _notes = <String, String>{};

  @override
  Future<String?> note(String exercise) async => _notes[exercise];

  @override
  Future<void> setNote(String exercise, String text) async =>
      text.trim().isEmpty
      ? _notes.remove(exercise)
      : _notes[exercise] = text.trim();
}

class InMemoryBodyRepository implements BodyRepository {
  final _items = <String, BodyEntry>{};

  @override
  Future<List<BodyEntry>> all() async => [..._items.values];

  @override
  Future<void> save(BodyEntry entry) async => _items[entry.id] = entry;

  @override
  Future<void> delete(String id) async => _items.remove(id);
}

class InMemoryCustomExerciseRepository implements CustomExerciseRepository {
  final _items = <String, Exercise>{};

  @override
  Future<List<Exercise>> all() async => [..._items.values];

  @override
  Future<void> save(Exercise exercise) async => _items[exercise.id] = exercise;

  @override
  Future<void> delete(String id) async => _items.remove(id);
}

class InMemoryActiveWorkoutStore implements ActiveWorkoutStore {
  ActiveWorkout? _current;

  @override
  Future<ActiveWorkout?> load() async => _current;

  @override
  Future<void> save(ActiveWorkout? workout) async => _current = workout;
}
