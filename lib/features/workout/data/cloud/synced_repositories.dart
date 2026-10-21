import 'dart:async';

import '../../domain/body.dart';
import '../../domain/exercise.dart';
import '../../domain/program.dart';
import '../../domain/repositories.dart';
import '../../domain/workout.dart';
import '../json_mappers.dart';
import 'user_cloud.dart';

// Локальная запись — первой и с ожиданием; облако — без ожидания сервера
// (офлайн-очередь Firestore). Ошибка облака, в том числе синхронная, глотается.
void _fire(Future<void> Function() write) {
  try {
    unawaited(write().catchError((Object _) {}));
  } on Object {
    // Облако недоступно — данные остаются локально.
  }
}

class SyncedWorkoutRepository implements WorkoutRepository {
  SyncedWorkoutRepository(this._local, this._cloud);

  final WorkoutRepository _local;
  final UserCloud _cloud;

  @override
  Future<List<Workout>> all() => _local.all();

  @override
  Future<void> save(Workout workout) async {
    await _local.save(workout);
    _fire(
      () => _cloud
          .collection('workouts')
          .doc(workout.id)
          .set(workoutToJson(workout)),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    _fire(() => _cloud.collection('workouts').doc(id).delete());
  }
}

class SyncedProgramRepository implements ProgramRepository {
  SyncedProgramRepository(this._local, this._cloud);

  final ProgramRepository _local;
  final UserCloud _cloud;

  @override
  Future<List<WorkoutTemplate>> templates() => _local.templates();

  @override
  Future<void> saveTemplate(WorkoutTemplate template) async {
    await _local.saveTemplate(template);
    _fire(
      () => _cloud
          .collection('templates')
          .doc(template.id)
          .set(templateToJson(template)),
    );
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _local.deleteTemplate(id);
    _fire(() => _cloud.collection('templates').doc(id).delete());
  }

  @override
  Future<Program> program() => _local.program();

  @override
  Future<void> saveProgram(Program program) async {
    await _local.saveProgram(program);
    _fire(() => _cloud.meta('program').set(programToJson(program)));
  }
}

class SyncedNoteRepository implements NoteRepository {
  SyncedNoteRepository(this._local, this._cloud);

  final NoteRepository _local;
  final UserCloud _cloud;

  @override
  Future<String?> note(String exercise) => _local.note(exercise);

  @override
  Future<Map<String, String>> all() => _local.all();

  @override
  Future<void> setNote(String exercise, String text) async {
    await _local.setNote(exercise, text);
    _fire(() {
      final ref = _cloud.collection('notes').doc(noteDocId(exercise));
      return text.trim().isEmpty
          ? ref.delete()
          : ref.set(noteToCloudJson(exercise, text));
    });
  }
}

class SyncedBodyRepository implements BodyRepository {
  SyncedBodyRepository(this._local, this._cloud);

  final BodyRepository _local;
  final UserCloud _cloud;

  @override
  Future<List<BodyEntry>> all() => _local.all();

  @override
  Future<void> save(BodyEntry entry) async {
    await _local.save(entry);
    _fire(
      () => _cloud.collection('body').doc(entry.id).set(bodyToCloudJson(entry)),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    _fire(() => _cloud.collection('body').doc(id).delete());
  }
}

class SyncedCustomExerciseRepository implements CustomExerciseRepository {
  SyncedCustomExerciseRepository(this._local, this._cloud);

  final CustomExerciseRepository _local;
  final UserCloud _cloud;

  @override
  Future<List<Exercise>> all() => _local.all();

  @override
  Future<void> save(Exercise exercise) async {
    await _local.save(exercise);
    _fire(
      () => _cloud
          .collection('customExercises')
          .doc(exercise.id)
          .set(exerciseToJson(exercise)),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _local.delete(id);
    _fire(() => _cloud.collection('customExercises').doc(id).delete());
  }
}

class SyncedFavoriteRepository implements FavoriteRepository {
  SyncedFavoriteRepository(this._local, this._cloud);

  final FavoriteRepository _local;
  final UserCloud _cloud;

  @override
  Future<Set<String>> all() => _local.all();

  /// В облако уходит всё множество после переключения.
  @override
  Future<void> toggle(String exerciseId) async {
    await _local.toggle(exerciseId);
    final ids = await _local.all();
    _fire(() => _cloud.meta('favorites').set(favoritesToCloudJson(ids)));
  }
}
