import 'dart:io';

import 'package:fitness_planner/features/gyms/data/my_gym_repositories.dart';
import 'package:fitness_planner/features/gyms/domain/gym.dart';
import 'package:fitness_planner/features/gyms/presentation/gym_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

const _gym = Gym(
  id: 'osm-node-1',
  name: 'Iron Gym',
  address: 'ул. Абая, 1',
  lat: 43.2,
  lon: 76.9,
);

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_gym');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('Hive: пусто — null', () async {
    expect(await (await HiveMyGymRepository.open()).get(), isNull);
  });

  test('Hive: set/get, set(null) очищает', () async {
    final repo = await HiveMyGymRepository.open();
    await repo.set(_gym);
    expect((await repo.get())!.toJson(), _gym.toJson());
    await repo.set(null);
    expect(await repo.get(), isNull);
  });

  test('Hive: зал переживает переоткрытие бокса', () async {
    await (await HiveMyGymRepository.open()).set(_gym);
    await Hive.close();
    expect((await (await HiveMyGymRepository.open()).get())!.id, _gym.id);
  });

  test('myGymProvider.set перечитывает значение', () async {
    final container = ProviderContainer.test(
      overrides: [
        myGymRepositoryProvider.overrideWithValue(InMemoryMyGymRepository()),
      ],
    );
    expect(await container.read(myGymProvider.future), isNull);
    await container.read(myGymProvider.notifier).set(_gym);
    expect((await container.read(myGymProvider.future))!.id, _gym.id);
    await container.read(myGymProvider.notifier).set(null);
    expect(await container.read(myGymProvider.future), isNull);
  });
}
