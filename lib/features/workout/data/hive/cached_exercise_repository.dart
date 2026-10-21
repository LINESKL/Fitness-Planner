import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

import '../../domain/exercise.dart';
import '../../domain/exercise_repository.dart';

/// Offline-first обёртка: загруженные страницы сохраняет, без сети отдаёт сохранённое.
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
  Future<ExerciseCatalog> fetchExercises({int offset = 0}) async {
    try {
      final page = await _remote.fetchExercises(offset: offset);
      // Первая страница начинает кэш заново, следующие дописываются.
      await _save([if (offset > 0) ..._cached() ?? const [], ...page.items]);
      return page;
    } on ExerciseLoadException {
      final cached = _cached();
      if (offset > 0 || cached == null) rethrow;
      return (items: cached, offline: true, nextOffset: null);
    }
  }

  List<Exercise>? _cached() => switch (_box.get(_key)) {
    final String json => [
      for (final e in jsonDecode(json) as List)
        _fromJson(e as Map<String, dynamic>),
    ],
    _ => null,
  };

  Future<void> _save(List<Exercise> items) =>
      _box.put(_key, jsonEncode([for (final e in items) _toJson(e)]));

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
