import 'dart:convert';

import 'package:fitness_planner/features/workout/data/json_mappers.dart';
import 'package:fitness_planner/features/workout/domain/active_workout.dart';
import 'package:fitness_planner/features/workout/domain/body.dart';
import 'package:fitness_planner/features/workout/domain/exercise.dart';
import 'package:fitness_planner/features/workout/domain/program.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Через JSON-строку — как это пойдёт в Hive и Firestore.
T roundTrip<T>(
  Map<String, Object?> json,
  T Function(Map<String, Object?>) read,
) => read(jsonDecode(jsonEncode(json)) as Map<String, Object?>);

void main() {
  test('тренировка со всеми типами подходов и RPE', () {
    final workout = Workout(
      id: 'w1',
      title: 'Ноги',
      templateId: 't1',
      startedAt: DateTime(2026, 10, 7, 18),
      finishedAt: DateTime(2026, 10, 7, 19),
      entries: const [
        WorkoutEntry(
          exercise: 'Присед',
          sets: [
            SetEntry(weight: 60, reps: 8, type: SetType.warmup),
            SetEntry(weight: 100, reps: 5, rpe: 8.5),
            SetEntry(weight: 100, reps: 4, type: SetType.failure),
            SetEntry(weight: 80, reps: 8, type: SetType.drop),
          ],
        ),
      ],
    );

    final back = roundTrip(workoutToJson(workout), workoutFromJson);

    expect((back.id, back.title, back.templateId), ('w1', 'Ноги', 't1'));
    expect(
      (back.startedAt, back.finishedAt),
      (workout.startedAt, workout.finishedAt),
    );
    expect(
      back.entries.single.sets.map((s) => (s.weight, s.reps, s.type, s.rpe)),
      [
        (60.0, 8, SetType.warmup, null),
        (100.0, 5, SetType.normal, 8.5),
        (100.0, 4, SetType.failure, null),
        (80.0, 8, SetType.drop, null),
      ],
    );
  });

  test('шаблон и программа', () {
    const template = WorkoutTemplate(
      id: 't1',
      name: 'Ноги',
      exercises: [
        TemplateExercise(exercise: 'Присед', sets: 4, repsMin: 5, repsMax: 5),
      ],
    );

    final back = roundTrip(templateToJson(template), templateFromJson);
    final program = roundTrip(
      programToJson(const Program(templateIds: ['t1', 't2'])),
      programFromJson,
    );

    expect(back.name, 'Ноги');
    final e = back.exercises.single;
    expect((e.exercise, e.sets, e.repsMin, e.repsMax), ('Присед', 4, 5, 5));
    expect(program.templateIds, ['t1', 't2']);
  });

  test('замер тела с необязательными полями', () {
    final full = BodyEntry(
      id: 'b1',
      date: DateTime(2026, 10, 7),
      weightKg: 78.4,
      waistCm: 80,
      chestCm: 101.5,
    );
    final light = BodyEntry(
      id: 'b2',
      date: DateTime(2026, 10, 8),
      weightKg: 78,
    );

    final a = roundTrip(bodyToJson(full), bodyFromJson);
    final b = roundTrip(bodyToJson(light), bodyFromJson);

    expect((a.weightKg, a.waistCm, a.chestCm), (78.4, 80.0, 101.5));
    expect((b.weightKg, b.waistCm, b.chestCm), (78.0, null, null));
  });

  test('упражнение', () {
    const e = Exercise(id: 'custom-1', name: 'Махи', muscleGroup: 'Плечи');

    final back = roundTrip(exerciseToJson(e), exerciseFromJson);

    expect(
      (back.id, back.name, back.muscleGroup, back.imageUrl),
      ('custom-1', 'Махи', 'Плечи', null),
    );
  });

  test('идущая тренировка: курсор, фаза, отдых, цель и флаги', () {
    final now = DateTime(2026, 10, 7, 18);
    final active = ActiveWorkout(
      startedAt: now,
      title: 'Ноги',
      templateId: 't1',
      cursor: (exercise: 0, set: 1),
      phase: WorkoutPhase.rest,
      restEndsAt: now.add(const Duration(seconds: 90)),
      exercises: const [
        ActiveExercise(
          name: 'Присед',
          target: (min: 5, max: 5),
          sets: [
            WorkoutSet(weight: 102.5, reps: 5, done: true, increased: true),
            WorkoutSet(weight: 102.5, reps: 5, type: SetType.failure, rpe: 9),
          ],
        ),
      ],
    );

    final back = roundTrip(activeWorkoutToJson(active), activeWorkoutFromJson);

    expect(
      (back.title, back.templateId, back.cursor, back.phase),
      ('Ноги', 't1', (exercise: 0, set: 1), WorkoutPhase.rest),
    );
    expect(back.restEndsAt, active.restEndsAt);
    final ex = back.exercises.single;
    expect(ex.target, (min: 5, max: 5));
    expect(ex.sets.map((s) => (s.done, s.increased, s.type, s.rpe)), [
      (true, true, SetType.normal, null),
      (false, false, SetType.failure, 9.0),
    ]);
  });
}
