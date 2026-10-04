import '../domain/exercise.dart';
import '../domain/exercise_repository.dart';
import 'sample_data.dart';
import 'wger/wger_api.dart';
import 'wger/wger_dto.dart';

/// Встроенные русские упражнения + каталог wger без повторов по названию.
class RemoteExerciseRepository implements ExerciseRepository {
  RemoteExerciseRepository(this._api);

  final WgerApi _api;

  @override
  Future<List<Exercise>> fetchExercises() async {
    final remote = await _api.fetchExercises();
    final seen = {for (final e in sampleExercises) e.name.toLowerCase()};
    return [
      ...sampleExercises,
      for (final dto in remote)
        if (dto.toExercise() case final e? when seen.add(e.name.toLowerCase()))
          e,
    ];
  }
}
