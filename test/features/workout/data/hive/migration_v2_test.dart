import 'dart:io';

import 'package:fitness_planner/features/workout/data/hive/legacy_logs.dart';
import 'package:fitness_planner/features/workout/data/hive/migration_v2.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('migration');
    Hive.init(dir.path);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  ExerciseLog log(String exercise, DateTime date) => ExerciseLog(
    exercise: exercise,
    date: date,
    sets: const [SetEntry(weight: 80, reps: 8)],
  );

  test('логи одного дня становятся одной тренировкой', () async {
    final old = await LegacyLogsBox.open();
    await old.addLogs([
      log('Жим', DateTime(2026, 10, 1, 18)),
      log('Тяга', DateTime(2026, 10, 1, 18, 30)),
      log('Присед', DateTime(2026, 10, 3, 19)),
    ]);
    final target = InMemoryWorkoutRepository();
    final prefs = await SharedPreferences.getInstance();

    await migrateToV2(old: old, target: target, prefs: prefs);

    final workouts = await target.all();
    expect(workouts.length, 2);
    expect(workouts.firstWhere((w) => w.startedAt.day == 1).entries.length, 2);
    expect(prefs.getBool(migratedV2Key), isTrue);
  });

  test(
    'повторный запуск ничего не дублирует и не трогает новые данные',
    () async {
      final old = await LegacyLogsBox.open();
      await old.addLogs([log('Жим', DateTime(2026, 10, 1, 18))]);
      final target = InMemoryWorkoutRepository();
      final prefs = await SharedPreferences.getInstance();

      await migrateToV2(old: old, target: target, prefs: prefs);
      final id = (await target.all()).single.id;
      await target.delete(id);
      await migrateToV2(old: old, target: target, prefs: prefs);

      expect(await target.all(), isEmpty);
    },
  );

  test('пустой старый бокс — только флаг', () async {
    final target = InMemoryWorkoutRepository();
    final prefs = await SharedPreferences.getInstance();

    await migrateToV2(
      old: await LegacyLogsBox.open(),
      target: target,
      prefs: prefs,
    );

    expect(await target.all(), isEmpty);
    expect(prefs.getBool(migratedV2Key), isTrue);
  });
}
