import 'dart:io';

import 'package:fitness_planner/features/workout/data/hive/cached_exercise_repository.dart';
import 'package:fitness_planner/features/workout/domain/exercise.dart';
import 'package:fitness_planner/features/workout/domain/exercise_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';

class MockRemote extends Mock implements ExerciseRepository {}

void main() {
  late Directory dir;
  late MockRemote remote;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_cache_test');
    Hive.init(dir.path);
    remote = MockRemote();
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

  void online(List<Exercise> items) =>
      when(() => remote.fetchExercises())
          .thenAnswer((_) async => (items: items, offline: false));

  void noNetwork() => when(() => remote.fetchExercises()).thenThrow(offline);

  test('сеть есть — свежий каталог, не офлайн', () async {
    online([squat]);
    final repo = await CachedExerciseRepository.open(remote);

    final catalog = await repo.fetchExercises();

    expect(catalog.items.single.name, 'Squats');
    expect(catalog.offline, isFalse);
    verify(() => remote.fetchExercises()).called(1);
  });

  test('сети нет — каталог из кэша с пометкой офлайн', () async {
    online([squat]);
    await (await CachedExerciseRepository.open(remote)).fetchExercises();
    await Hive.close();

    noNetwork();
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
    noNetwork();
    final repo = await CachedExerciseRepository.open(remote);

    expect(repo.fetchExercises(), throwsA(same(offline)));
  });
}
