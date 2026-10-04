import 'dart:io';

import 'package:fitness_planner/features/workout/data/hive/cached_exercise_repository.dart';
import 'package:fitness_planner/features/workout/domain/exercise.dart';
import 'package:fitness_planner/features/workout/domain/exercise_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

class FakeRemote implements ExerciseRepository {
  Object response = const <Exercise>[];

  @override
  Future<ExerciseCatalog> fetchExercises() async {
    final r = response;
    if (r is Exception) throw r;
    return (items: r as List<Exercise>, offline: false);
  }
}

void main() {
  late Directory dir;
  late FakeRemote remote;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_cache_test');
    Hive.init(dir.path);
    remote = FakeRemote();
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  const squat = Exercise(
    id: 'wger-7',
    name: 'Squats',
    muscleGroup: 'Ноги',
    imageUrl: 'https://wger.de/a.png',
  );
  const offline = ExerciseLoadException('Нет подключения к интернету');

  test('сеть есть — свежий каталог, не офлайн', () async {
    remote.response = [squat];
    final repo = await CachedExerciseRepository.open(remote);

    final catalog = await repo.fetchExercises();

    expect(catalog.items.single.name, 'Squats');
    expect(catalog.offline, isFalse);
  });

  test('сети нет — каталог из кэша с пометкой офлайн', () async {
    remote.response = [squat];
    await (await CachedExerciseRepository.open(remote)).fetchExercises();
    await Hive.close();

    remote.response = offline;
    final catalog = await (await CachedExerciseRepository.open(remote))
        .fetchExercises();

    final cached = catalog.items.single;
    expect(catalog.offline, isTrue);
    expect(
      (cached.id, cached.name, cached.muscleGroup, cached.imageUrl),
      ('wger-7', 'Squats', 'Ноги', 'https://wger.de/a.png'),
    );
  });

  test('сети нет и кэша нет — исходная ошибка', () async {
    remote.response = offline;
    final repo = await CachedExerciseRepository.open(remote);

    expect(repo.fetchExercises(), throwsA(same(offline)));
  });
}
