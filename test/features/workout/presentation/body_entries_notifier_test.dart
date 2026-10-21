import 'dart:io';

import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/body.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('удаление замера удаляет и файл фото', () async {
    final dir = await Directory.systemTemp.createTemp('body_photo');
    addTearDown(() => dir.delete(recursive: true));
    final photo = await File('${dir.path}/body-b1.jpg').writeAsString('jpg');
    final repo = InMemoryBodyRepository();
    await repo.save(
      BodyEntry(
        id: 'b1',
        date: DateTime(2026, 10, 20),
        weightKg: 78,
        photoPath: photo.path,
      ),
    );
    final container = ProviderContainer.test(
      overrides: [bodyRepositoryProvider.overrideWithValue(repo)],
    );
    await container.read(bodyEntriesProvider.future);

    await container.read(bodyEntriesProvider.notifier).delete('b1');

    expect(await repo.all(), isEmpty);
    expect(photo.existsSync(), isFalse);
  });

  test('файла фото уже нет — замер всё равно удаляется', () async {
    final repo = InMemoryBodyRepository();
    await repo.save(
      BodyEntry(
        id: 'b1',
        date: DateTime(2026, 10, 20),
        weightKg: 78,
        photoPath: '/нет/такого/файла.jpg',
      ),
    );
    final container = ProviderContainer.test(
      overrides: [bodyRepositoryProvider.overrideWithValue(repo)],
    );
    await container.read(bodyEntriesProvider.future);

    await container.read(bodyEntriesProvider.notifier).delete('b1');

    expect(await repo.all(), isEmpty);
  });
}
