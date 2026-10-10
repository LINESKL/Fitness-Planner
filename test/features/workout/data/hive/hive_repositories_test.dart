import 'dart:io';

import 'package:fitness_planner/features/workout/data/hive/hive_repositories.dart';
import 'package:fitness_planner/features/workout/domain/active_workout.dart';
import 'package:fitness_planner/features/workout/domain/body.dart';
import 'package:fitness_planner/features/workout/domain/exercise.dart';
import 'package:fitness_planner/features/workout/domain/program.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_v2');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  /// Закрыть всё и открыть заново — как перезапуск приложения.
  Future<void> restart() => Hive.close();

  Workout workout(String id, int day) => Workout(
    id: id,
    title: 'Ноги',
    startedAt: DateTime(2026, 10, day, 18),
    finishedAt: DateTime(2026, 10, day, 19),
    entries: const [
      WorkoutEntry(exercise: 'Присед', sets: [SetEntry(weight: 100, reps: 5)]),
    ],
  );

  test(
    'тренировки: сохранить, перезаписать, удалить, пережить перезапуск',
    () async {
      final repo = await HiveWorkoutRepository.open();
      await repo.save(workout('a', 1));
      await repo.save(workout('b', 2));
      await repo.save(workout('a', 3));
      await repo.delete('b');
      await restart();

      final all = await (await HiveWorkoutRepository.open()).all();

      expect(all.single.id, 'a');
      expect(all.single.startedAt.day, 3);
    },
  );

  test('программа и шаблоны', () async {
    final repo = await HiveProgramRepository.open();
    expect((await repo.program()).templateIds, isEmpty);

    await repo.saveTemplate(
      const WorkoutTemplate(id: 't1', name: 'Ноги', exercises: []),
    );
    await repo.saveTemplate(
      const WorkoutTemplate(id: 't2', name: 'Спина', exercises: []),
    );
    await repo.saveProgram(const Program(templateIds: ['t2', 't1']));
    await repo.deleteTemplate('t1');
    await restart();

    final again = await HiveProgramRepository.open();
    expect((await again.templates()).map((t) => t.name), ['Спина']);
    expect((await again.program()).templateIds, ['t2', 't1']);
  });

  test('заметки к упражнениям', () async {
    final repo = await HiveNoteRepository.open();
    await repo.setNote('Присед', 'стойка шире');
    await repo.setNote('Жим', 'лопатки');
    await repo.setNote('Жим', '');
    await restart();

    final again = await HiveNoteRepository.open();
    expect(await again.note('Присед'), 'стойка шире');
    expect(await again.note('Жим'), isNull);
  });

  test('замеры тела', () async {
    final repo = await HiveBodyRepository.open();
    await repo.save(
      BodyEntry(id: 'b1', date: DateTime(2026, 10, 1), weightKg: 79),
    );
    await repo.save(
      BodyEntry(id: 'b2', date: DateTime(2026, 10, 7), weightKg: 78.4),
    );
    await repo.delete('b1');
    await restart();

    final all = await (await HiveBodyRepository.open()).all();
    expect(all.single.weightKg, 78.4);
  });

  test('свои упражнения', () async {
    final repo = await HiveCustomExerciseRepository.open();
    await repo.save(
      const Exercise(id: 'custom-1', name: 'Махи', muscleGroup: 'Плечи'),
    );
    await restart();

    final all = await (await HiveCustomExerciseRepository.open()).all();
    expect(all.single.name, 'Махи');
  });

  test('идущая тренировка: сохранить, восстановить, очистить', () async {
    final store = await HiveActiveWorkoutStore.open();
    expect(await store.load(), isNull);

    await store.save(
      ActiveWorkout(
        startedAt: DateTime(2026, 10, 7, 18),
        title: 'Ноги',
        cursor: (exercise: 0, set: 1),
        exercises: const [
          ActiveExercise(
            name: 'Присед',
            sets: [
              WorkoutSet(weight: 100, reps: 5, done: true),
              WorkoutSet(weight: 100, reps: 5),
            ],
          ),
        ],
      ),
    );
    await restart();

    final again = await HiveActiveWorkoutStore.open();
    expect((await again.load())?.cursor, (exercise: 0, set: 1));
    await again.save(null);
    expect(await again.load(), isNull);
  });

  test(
    'повреждённая идущая тренировка — null и очистка, без падения',
    () async {
      final box = await Hive.openBox<Map>(HiveActiveWorkoutStore.boxName);
      await box.put('current', {'title': 'Ноги', 'cursor': 'мусор'});

      final store = HiveActiveWorkoutStore(box);

      expect(await store.load(), isNull);
      expect(box.isEmpty, isTrue);
    },
  );

  test('избранное: переключение и перезапуск', () async {
    final repo = await HiveFavoriteRepository.open();
    await repo.toggle('local-1');
    await repo.toggle('wger-7');
    await repo.toggle('local-1');
    await restart();

    expect(await (await HiveFavoriteRepository.open()).all(), {'wger-7'});
  });
}
