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

  void online(List<Exercise> items, {int offset = 0, int? next}) => when(
    () => remote.fetchExercises(offset: offset),
  ).thenAnswer((_) async => (items: items, offline: false, nextOffset: next));

  void noNetwork({int offset = 0}) =>
      when(() => remote.fetchExercises(offset: offset)).thenThrow(offline);

  test('сеть есть — свежий каталог, не офлайн', () async {
    online([squat]);
    final repo = await CachedExerciseRepository.open(remote);

    final catalog = await repo.fetchExercises();

    expect(catalog.items.single.name, 'Squats');
    expect(catalog.offline, isFalse);
    verify(() => remote.fetchExercises(offset: 0)).called(1);
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

  const lunge = Exercise(id: 'wger-9', name: 'Lunges', muscleGroup: 'Ноги');

  test('следующая страница дописывается в кэш', () async {
    online([squat], next: 50);
    online([lunge], offset: 50);
    final repo = await CachedExerciseRepository.open(remote);
    await repo.fetchExercises();
    final page = await repo.fetchExercises(offset: 50);
    expect(page.items.single.name, 'Lunges');

    noNetwork();
    final cached = await repo.fetchExercises();

    expect(cached.items.map((e) => e.name), ['Squats', 'Lunges']);
    expect(cached.nextOffset, isNull);
  });

  test('первая страница заново — кэш начинается с неё', () async {
    online([squat], next: 50);
    online([lunge], offset: 50);
    final repo = await CachedExerciseRepository.open(remote);
    await repo.fetchExercises();
    await repo.fetchExercises(offset: 50);
    await repo.fetchExercises();

    noNetwork();
    expect((await repo.fetchExercises()).items.single.name, 'Squats');
  });

  test('сети нет на следующей странице — ошибка, не кэш', () async {
    online([squat], next: 50);
    noNetwork(offset: 50);
    final repo = await CachedExerciseRepository.open(remote);
    await repo.fetchExercises();

    expect(repo.fetchExercises(offset: 50), throwsA(same(offline)));
  });
}
