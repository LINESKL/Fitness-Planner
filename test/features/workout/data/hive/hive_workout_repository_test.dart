import 'dart:io';

import 'package:fitness_planner/features/workout/data/hive/hive_workout_repository.dart';
import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(dir.path);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  final log = ExerciseLog(
    exercise: 'Жим лёжа',
    date: DateTime(2026, 10, 4, 18, 30),
    sets: const [
      SetEntry(weight: 40, reps: 10, isWarmup: true),
      SetEntry(weight: 82.5, reps: 8),
    ],
  );

  test('новая база — пустая история', () async {
    final repo = await HiveWorkoutRepository.open();

    expect(await repo.loadHistory(), isEmpty);
  });

  test('история переживает перезапуск', () async {
    await (await HiveWorkoutRepository.open()).addLogs([log]);
    await Hive.close();

    final history = await (await HiveWorkoutRepository.open()).loadHistory();

    final restored = history.single;
    expect(restored.exercise, 'Жим лёжа');
    expect(restored.date, DateTime(2026, 10, 4, 18, 30));
    expect(restored.sets.map((s) => (s.weight, s.reps, s.isWarmup)), [
      (40.0, 10, true),
      (82.5, 8, false),
    ]);
  });

  test('целый вес из базы читается как double', () async {
    final repo = await HiveWorkoutRepository.open();
    await repo.addLogs([
      ExerciseLog(
        exercise: 'Присед',
        date: DateTime(2026, 10, 4),
        sets: const [SetEntry(weight: 100, reps: 5)],
      ),
    ]);

    final set = (await repo.loadHistory()).single.sets.single;
    expect(set.volume, 500);
  });
}
