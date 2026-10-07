import 'package:fitness_planner/features/workout/domain/active_workout.dart';
import 'package:fitness_planner/features/workout/domain/program.dart';
import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final history = [
    ExerciseLog(
      exercise: 'Жим лёжа',
      date: DateTime(2026, 9, 27),
      sets: const [
        SetEntry(weight: 40, reps: 10, type: SetType.warmup),
        SetEntry(weight: 80, reps: 8),
        SetEntry(weight: 80, reps: 7),
      ],
    ),
  ];
  final started = DateTime(2026, 10, 4, 18);

  ActiveWorkout start([
    List<String> plan = const ['Жим лёжа', 'Подтягивания'],
  ]) => ActiveWorkout.start(startedAt: started, plan: plan, history: history);

  test('предзаполняет подходы рабочими подходами прошлого раза', () {
    final bench = start().exercises.first;

    expect(bench.name, 'Жим лёжа');
    expect(bench.sets.map((s) => (s.weight, s.reps, s.done)), [
      (80.0, 8, false),
      (80.0, 7, false),
    ]);
  });

  test('упражнение без истории получает один пустой подход', () {
    final pullUps = start().exercises.last;

    expect(pullUps.sets.map((s) => (s.weight, s.reps)), [(0.0, 0)]);
  });

  test('addExercise добавляет упражнение в конец с прошлыми подходами', () {
    final workout = start(const []).addExercise('Жим лёжа', history);

    expect(workout.exercises.single.sets.length, 2);
  });

  test('addSet копирует последний подход без отметки', () {
    final workout = start().toggleDone(0, 1).addSet(0);

    final sets = workout.exercises.first.sets;
    expect(sets.length, 3);
    expect(
      (sets.last.weight, sets.last.reps, sets.last.done),
      (80.0, 7, false),
    );
  });

  test('updateSet меняет только переданные поля', () {
    final workout = start().updateSet(0, 0, weight: 82.5);

    final set = workout.exercises.first.sets.first;
    expect((set.weight, set.reps), (82.5, 8));
  });

  test('toggleDone переключает отметку туда и обратно', () {
    final once = start().toggleDone(0, 0);
    final twice = once.toggleDone(0, 0);

    expect(once.exercises.first.sets.first.done, isTrue);
    expect(twice.exercises.first.sets.first.done, isFalse);
  });

  test('исходный объект не меняется', () {
    final original = start();
    original.updateSet(0, 0, weight: 100).toggleDone(0, 0).addSet(1);

    expect(original.exercises.first.sets.first.weight, 80);
    expect(original.exercises.first.sets.first.done, isFalse);
    expect(original.exercises.last.sets.length, 1);
  });

  group('toLogs', () {
    final finished = DateTime(2026, 10, 4, 19);

    test('сохраняет только отмеченные подходы', () {
      final logs = start().toggleDone(0, 1).toLogs(finished);

      expect(logs.single.exercise, 'Жим лёжа');
      expect(logs.single.date, finished);
      expect(logs.single.sets.map((s) => (s.weight, s.reps)), [(80.0, 7)]);
    });

    test('без отметок — пустой список', () {
      expect(start().toLogs(finished), isEmpty);
    });

    test('отмеченный подход с нулём повторов не сохраняется', () {
      expect(start().toggleDone(1, 0).toLogs(finished), isEmpty);
    });
  });

  group('фокус-режим', () {
    const rest = Duration(seconds: 90);
    final now = DateTime(2026, 10, 7, 18);
    const legs = WorkoutTemplate(
      id: 't-legs',
      name: 'Ноги',
      exercises: [
        TemplateExercise(exercise: 'Жим лёжа', sets: 4, repsMin: 6, repsMax: 8),
        TemplateExercise(
          exercise: 'Подтягивания',
          sets: 2,
          repsMin: 8,
          repsMax: 10,
        ),
      ],
    );

    ActiveWorkout fromTemplate() =>
        ActiveWorkout.fromTemplate(legs, history, now);

    test('из шаблона: подходов как в шаблоне, значения по прогрессии', () {
      final w = fromTemplate();
      final bench = w.exercises.first.sets;

      expect(w.title, 'Ноги');
      expect(w.templateId, 't-legs');
      expect(bench.length, 4);
      // В прошлый раз 80 × 8, 7 при цели 8: не всё выполнено — тот же вес.
      expect(bench.map((s) => (s.weight, s.reps)), [
        (80.0, 8),
        (80.0, 7),
        (80.0, 7),
        (80.0, 7),
      ]);
      expect(w.exercises.last.sets.map((s) => (s.weight, s.reps)), [
        (0.0, 8),
        (0.0, 8),
      ]);
      expect((w.cursor, w.phase), ((exercise: 0, set: 0), WorkoutPhase.set));
    });

    test('«Готово» отмечает подход, включает отдых и двигает курсор', () {
      final w = fromTemplate().completeCurrent(now: now, rest: rest);

      expect(w.exercises.first.sets.first.done, isTrue);
      expect(w.phase, WorkoutPhase.rest);
      expect(w.restEndsAt, now.add(rest));
      expect(w.cursor, (exercise: 0, set: 1));
    });

    test('после последнего подхода упражнения — следующее упражнение', () {
      var w = fromTemplate();
      for (var i = 0; i < 4; i++) {
        w = w.completeCurrent(now: now, rest: rest).skipRest();
      }

      expect(w.cursor, (exercise: 1, set: 0));
      expect(w.phase, WorkoutPhase.set);
    });

    test('после всех подходов — finished, отдыха нет', () {
      var w = fromTemplate();
      for (var i = 0; i < 6; i++) {
        w = w.completeCurrent(now: now, rest: rest);
      }

      expect(w.phase, WorkoutPhase.finished);
      expect(w.restEndsAt, isNull);
    });

    test('пропущенный подход догоняется после остальных', () {
      final w = fromTemplate()
          .goTo(0, 1)
          .completeCurrent(now: now, rest: rest)
          .goTo(1, 1)
          .completeCurrent(now: now, rest: Duration.zero);

      // Курсор ищет вперёд, потом возвращается к пропущенным.
      expect(w.cursor, (exercise: 0, set: 0));
      expect(w.phase, WorkoutPhase.set);
    });

    test('отдых: продлить и пропустить', () {
      final w = fromTemplate().completeCurrent(now: now, rest: rest);

      expect(
        w.extendRest(const Duration(seconds: 15)).restEndsAt,
        now.add(const Duration(seconds: 105)),
      );
      expect(w.skipRest().phase, WorkoutPhase.set);
      expect(w.skipRest().restEndsAt, isNull);
    });

    test('правка выполненного подхода: вес, тип и RPE', () {
      final w = fromTemplate()
          .completeCurrent(now: now, rest: rest)
          .editSet(0, 0, weight: 82.5, type: SetType.failure, rpe: 9);

      final set = w.exercises.first.sets.first;
      expect(
        (set.weight, set.type, set.rpe, set.done),
        (82.5, SetType.failure, 9.0, true),
      );
    });

    test('«ещё подход» после конца тренировки становится текущим', () {
      var w = fromTemplate();
      for (var i = 0; i < 6; i++) {
        w = w.completeCurrent(now: now, rest: rest);
      }
      w = w.addSet(1);

      expect(w.cursor, (exercise: 1, set: 2));
      expect(w.phase, WorkoutPhase.set);
    });

    test('перестановка упражнений — курсор следует за своим упражнением', () {
      final w = fromTemplate().moveExercise(0, 1);

      expect(w.exercises.map((e) => e.name), ['Подтягивания', 'Жим лёжа']);
      expect(w.cursor, (exercise: 1, set: 0));
    });

    test('удаление текущего упражнения — курсор на следующее', () {
      final w = fromTemplate().removeExercise(0);

      expect(w.exercises.single.name, 'Подтягивания');
      expect(w.cursor, (exercise: 0, set: 0));
    });

    test('замена упражнения сохраняет число подходов и цель', () {
      final w = fromTemplate().replaceExercise(1, 'Жим лёжа', history);

      expect(w.exercises.last.name, 'Жим лёжа');
      expect(w.exercises.last.sets.length, 2);
      expect(w.exercises.last.target, (min: 8, max: 10));
    });

    test('пустая тренировка: без упражнений, затем добавленное — текущее', () {
      final empty = ActiveWorkout.empty(now);
      final w = empty.addExercise('Жим лёжа', history);

      expect(empty.exercises, isEmpty);
      expect(w.cursor, (exercise: 0, set: 0));
      expect(w.phase, WorkoutPhase.set);
    });

    test('toWorkout — только выполненные подходы с повторами, с типом', () {
      final w = fromTemplate()
          .editSet(0, 0, type: SetType.warmup)
          .completeCurrent(now: now, rest: rest)
          .completeCurrent(now: now, rest: rest)
          .toWorkout('w1', now.add(const Duration(hours: 1)));

      expect(w.title, 'Ноги');
      expect(w.templateId, 't-legs');
      expect(w.entries.single.sets.map((s) => (s.reps, s.type)), [
        (8, SetType.warmup),
        (7, SetType.normal),
      ]);
    });
  });
}
