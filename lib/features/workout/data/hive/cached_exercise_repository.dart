import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

import '../../domain/exercise.dart';
import '../../domain/exercise_repository.dart';

/// Offline-first обёртка: успешный ответ сохраняет, при ошибке сети отдаёт сохранённое.
class CachedExerciseRepository implements ExerciseRepository {
  CachedExerciseRepository(this._remote, this._box);

  static const boxName = 'exercise_cache';
  static const _key = 'catalog';

  static Future<CachedExerciseRepository> open(
    ExerciseRepository remote,
  ) async =>
      CachedExerciseRepository(remote, await Hive.openBox<String>(boxName));

  final ExerciseRepository _remote;
  final Box<String> _box;

  @override
  Future<ExerciseCatalog> fetchExercises() async {
    try {
      final catalog = await _remote.fetchExercises();
      await _box.put(
        _key,
        jsonEncode([for (final e in catalog.items) _toJson(e)]),
      );
      return catalog;
    } on ExerciseLoadException {
      final cached = _box.get(_key);
      if (cached == null) rethrow;
      return (
        items: [
          for (final json in jsonDecode(cached) as List)
            _fromJson(json as Map<String, dynamic>),
        ],
        offline: true,
      );
    }
  }

  static Map<String, Object?> _toJson(Exercise e) => {
    'id': e.id,
    'name': e.name,
    'muscleGroup': e.muscleGroup,
    'imageUrl': e.imageUrl,
  };

  static Exercise _fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    muscleGroup: json['muscleGroup'] as String,
    imageUrl: json['imageUrl'] as String?,
  );
}
