import '../../domain/body.dart';
import '../../domain/exercise.dart';
import '../../domain/program.dart';
import '../../domain/repositories.dart';
import '../../domain/workout.dart';
import '../json_mappers.dart';
import 'user_cloud.dart';

/// Локальные (не обёрнутые облаком) репозитории — то, что сливается с облаком.
class LocalData {
  const LocalData({
    required this.workouts,
    required this.program,
    required this.body,
    required this.customExercises,
    required this.notes,
    required this.favorites,
  });

  final WorkoutRepository workouts;
  final ProgramRepository program;
  final BodyRepository body;
  final CustomExerciseRepository customExercises;
  final NoteRepository notes;
  final FavoriteRepository favorites;
}

/// Разовое слияние при входе: облако побеждает по id, чего нет в облаке —
/// загружается. Запись идёт в локальные репозитории напрямую, не через обёртки.
class CloudSync {
  CloudSync(this.local, this.cloud);

  final LocalData local;
  final UserCloud cloud;

  /// Сбой одного раздела (нет сети, правила) не мешает остальным и не роняет.
  Future<void> merge() async {
    for (final step in [
      _workouts,
      _templates,
      _program,
      _body,
      _customExercises,
      _notes,
      _favorites,
    ]) {
      try {
        await step();
      } on Object {
        // Локальные данные остаются как есть.
      }
    }
  }

  Future<Map<String, Map<String, dynamic>>> _cloudDocs(String name) async {
    final snap = await cloud.collection(name).get();
    return {for (final d in snap.docs) d.id: d.data()};
  }

  /// Общий ход: облачные документы → локально, локальные без пары → в облако.
  Future<void> _mergeCollection<T>({
    required String name,
    required List<T> localItems,
    required String Function(T) id,
    required Map<String, Object?> Function(T) toJson,
    required Future<void> Function(Map<String, dynamic> json) saveFromCloud,
  }) async {
    final remote = await _cloudDocs(name);
    for (final json in remote.values) {
      await saveFromCloud(json);
    }
    for (final item in localItems.where((i) => !remote.containsKey(id(i)))) {
      await cloud.collection(name).doc(id(item)).set(toJson(item));
    }
  }

  Future<void> _workouts() async => _mergeCollection<Workout>(
    name: 'workouts',
    localItems: await local.workouts.all(),
    id: (w) => w.id,
    toJson: workoutToJson,
    saveFromCloud: (j) => local.workouts.save(workoutFromJson(j)),
  );

  Future<void> _templates() async => _mergeCollection<WorkoutTemplate>(
    name: 'templates',
    localItems: await local.program.templates(),
    id: (t) => t.id,
    toJson: templateToJson,
    saveFromCloud: (j) => local.program.saveTemplate(templateFromJson(j)),
  );

  /// Порядок программы: облачный, если есть, иначе локальный уходит в облако.
  Future<void> _program() async {
    final remote = await cloud.meta('program').get();
    if (remote.exists) {
      await local.program.saveProgram(programFromJson(remote.data()!));
    } else {
      await cloud
          .meta('program')
          .set(programToJson(await local.program.program()));
    }
  }

  /// Фото живёт только на телефоне — при совпадении id берём локальное.
  Future<void> _body() async {
    final photos = {for (final b in await local.body.all()) b.id: b.photoPath};
    await _mergeCollection<BodyEntry>(
      name: 'body',
      localItems: await local.body.all(),
      id: (b) => b.id,
      toJson: bodyToCloudJson,
      saveFromCloud: (j) {
        final b = bodyFromJson(j);
        return local.body.save(
          BodyEntry(
            id: b.id,
            date: b.date,
            weightKg: b.weightKg,
            waistCm: b.waistCm,
            chestCm: b.chestCm,
            photoPath: photos[b.id],
          ),
        );
      },
    );
  }

  Future<void> _customExercises() async => _mergeCollection<Exercise>(
    name: 'customExercises',
    localItems: await local.customExercises.all(),
    id: (e) => e.id,
    toJson: exerciseToJson,
    saveFromCloud: (j) => local.customExercises.save(exerciseFromJson(j)),
  );

  Future<void> _notes() async {
    final remote = await _cloudDocs('notes');
    final cloudNotes = {
      for (final j in remote.values)
        j['exercise'] as String: j['text'] as String,
    };
    for (final e in cloudNotes.entries) {
      await local.notes.setNote(e.key, e.value);
    }
    for (final e in (await local.notes.all()).entries) {
      if (cloudNotes.containsKey(e.key)) continue;
      await cloud
          .collection('notes')
          .doc(noteDocId(e.key))
          .set(noteToCloudJson(e.key, e.value));
    }
  }

  /// Избранное — объединение, записывается в оба места.
  Future<void> _favorites() async {
    final remote = await cloud.meta('favorites').get();
    final cloudIds = {...?(remote.data()?['ids'] as List?)?.cast<String>()};
    final localIds = await local.favorites.all();
    for (final id in cloudIds.difference(localIds)) {
      await local.favorites.toggle(id);
    }
    final union = {...cloudIds, ...localIds};
    if (union.length != cloudIds.length) {
      await cloud.meta('favorites').set(favoritesToCloudJson(union));
    }
  }
}
