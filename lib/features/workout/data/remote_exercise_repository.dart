import '../domain/exercise_repository.dart';
import 'sample_data.dart';
import 'wger/wger_api.dart';
import 'wger/wger_dto.dart';

/// Встроенные русские упражнения (на первой странице) + страница wger без их повторов.
class RemoteExerciseRepository implements ExerciseRepository {
  RemoteExerciseRepository(this._api);

  final WgerApi _api;

  @override
  Future<ExerciseCatalog> fetchExercises({int offset = 0}) async {
    final page = await _api.fetchExercises(offset: offset);
    final seen = {for (final e in sampleExercises) e.name.toLowerCase()};
    final items = [
      if (offset == 0) ...sampleExercises,
      for (final dto in page.items)
        if (dto.toExercise() case final e? when seen.add(e.name.toLowerCase()))
          e,
    ];
    return (
      items: items,
      offline: false,
      nextOffset: page.hasMore ? offset + wgerPageSize : null,
    );
  }
}
