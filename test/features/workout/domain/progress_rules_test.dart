import 'package:fitness_planner/features/workout/domain/progress_rules.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:flutter_test/flutter_test.dart';

List<SetEntry> sets(double weight, List<int> reps) => [
  for (final r in reps) SetEntry(weight: weight, reps: r),
];

Workout workout(
  DateTime day,
  Map<String, List<SetEntry>> entries, {
  String id = 'w',
}) => Workout(
  id: id,
  title: 'x',
  startedAt: day,
  finishedAt: day.add(const Duration(hours: 1)),
  entries: [
    for (final e in entries.entries)
      WorkoutEntry(exercise: e.key, sets: e.value),
  ],
);

void main() {
  group('suggestSet', () {
    test('все повторы до верха диапазона — +2.5 кг и низ диапазона', () {
      final s = suggestSet(
        previous: sets(80, [10, 10, 10]),
        index: 0,
        target: (min: 8, max: 10),
      );
      expect((s.weight, s.reps, s.increased), (82.5, 8, true));
    });

    test('не добрал до верха диапазона — тот же вес и прошлые повторы', () {
      final s = suggestSet(
        previous: sets(80, [10, 9, 8]),
        index: 1,
        target: (min: 8, max: 10),
      );
      expect((s.weight, s.reps, s.increased), (80.0, 9, false));
    });

    test('без шаблона: повторы не просели — +2.5 кг', () {
      final s = suggestSet(previous: sets(100, [5, 5, 5]), index: 2);
      expect((s.weight, s.reps, s.increased), (102.5, 5, true));
    });

    test('без шаблона: повторы просели — тот же вес', () {
      final s = suggestSet(previous: sets(100, [5, 5, 4]), index: 2);
      expect((s.weight, s.reps, s.increased), (100.0, 4, false));
    });

    test('свой вес (0 кг) — без прибавки', () {
      final s = suggestSet(
        previous: sets(0, [12, 12, 12]),
        index: 0,
        target: (min: 8, max: 12),
      );
      expect((s.weight, s.reps, s.increased), (0.0, 12, false));
    });

    test('подходов в прошлый раз меньше — берётся последний', () {
      final s = suggestSet(previous: sets(100, [5, 4]), index: 3);
      expect((s.weight, s.reps), (100.0, 4));
    });

    test('разминка в прошлый раз не учитывается', () {
      final s = suggestSet(
        previous: [
          const SetEntry(weight: 60, reps: 8, type: SetType.warmup),
          ...sets(100, [5, 5]),
        ],
        index: 0,
      );
      expect((s.weight, s.increased), (102.5, true));
    });

    test('истории нет — пусто, повторы из цели', () {
      final s = suggestSet(previous: [], index: 0, target: (min: 8, max: 10));
      expect((s.weight, s.reps, s.increased), (0.0, 8, false));
    });
  });

  group('рекорды', () {
    final history = [
      workout(DateTime(2026, 9, 1), {
        'Жим': [
          const SetEntry(weight: 120, reps: 1, type: SetType.warmup),
          ...sets(80, [8, 8]),
        ],
      }),
      workout(DateTime(2026, 9, 8), {
        'Жим': sets(85, [5, 5]),
      }),
    ];

    test('лучший вес, 1ПМ и объём без разминки', () {
      final r = recordsFor('Жим', history);

      expect(r.bestWeight, 85);
      expect(r.bestOneRepMax, closeTo(80 * (1 + 8 / 30), 0.001));
      expect(r.bestVolume, 1280);
    });

    test('новый рекорд — 1ПМ выше прежнего', () {
      final before = recordsFor('Жим', history);

      expect(isNewRecord(const SetEntry(weight: 90, reps: 5), before), isTrue);
      expect(isNewRecord(const SetEntry(weight: 80, reps: 8), before), isFalse);
      expect(
        isNewRecord(
          const SetEntry(weight: 200, reps: 1, type: SetType.warmup),
          before,
        ),
        isFalse,
      );
    });

    test('без истории рекорд не объявляется', () {
      expect(
        isNewRecord(
          const SetEntry(weight: 50, reps: 5),
          recordsFor('Жим', const []),
        ),
        isFalse,
      );
    });
  });

  test('нагрузка по мышцам — рабочие подходы текущей недели', () {
    final now = DateTime(2026, 10, 7);
    final load = muscleLoad(
      [
        workout(DateTime(2026, 10, 6), {
          'Присед': [
            const SetEntry(weight: 60, reps: 8, type: SetType.warmup),
            ...sets(100, [5, 5, 5]),
          ],
          'Жим': sets(80, [8, 8]),
          'Непонятное': sets(10, [10]),
        }),
        workout(DateTime(2026, 9, 30), {
          'Присед': sets(100, [5, 5]),
        }),
      ],
      now,
      (name) => const {'Присед': 'Ноги', 'Жим': 'Грудь'}[name] ?? 'Другое',
    );

    expect(load, {'Ноги': 3, 'Грудь': 2, 'Другое': 1});
  });

  group('серия недель', () {
    final now = DateTime(2026, 10, 7); // среда

    test('считает подряд идущие недели с тренировками', () {
      expect(
        weekStreak([
          workout(DateTime(2026, 10, 5), {}),
          workout(DateTime(2026, 9, 29), {}),
          workout(DateTime(2026, 9, 22), {}),
          workout(DateTime(2026, 9, 8), {}),
        ], now),
        3,
      );
    });

    test('текущая неделя пока пустая — считаем от прошлой', () {
      expect(
        weekStreak([
          workout(DateTime(2026, 10, 2), {}),
          workout(DateTime(2026, 9, 24), {}),
        ], now),
        2,
      );
    });

    test('пропущенная прошлая неделя — серия 0', () {
      expect(weekStreak([workout(DateTime(2026, 9, 22), {})], now), 0);
    });
  });

  group('latestRecord', () {
    test('последний момент, когда 1ПМ упражнения превысил прежний', () {
      final r = latestRecord([
        workout(DateTime(2026, 9, 1), {
          'Жим': sets(80, [8]),
          'Присед': sets(100, [5]),
        }, id: 'a'),
        workout(DateTime(2026, 9, 8), {
          'Жим': sets(85, [6]),
          'Присед': sets(95, [5]),
        }, id: 'b'),
        workout(DateTime(2026, 9, 15), {
          'Жим': sets(80, [8]),
        }, id: 'c'),
      ]);

      expect(r?.exercise, 'Жим');
      expect((r?.set.weight, r?.set.reps), (85.0, 6));
      expect(r?.date, DateTime(2026, 9, 8));
    });

    test('первые результаты рекордами не считаются', () {
      expect(
        latestRecord([
          workout(DateTime(2026, 9, 1), {
            'Жим': sets(80, [8]),
          }),
        ]),
        isNull,
      );
    });
  });

  test('personalBests — лучший подход каждого упражнения с датой', () {
    final bests = personalBests([
      workout(DateTime(2026, 9, 1), {
        'Жим': sets(80, [8]),
        'Присед': sets(100, [5]),
      }, id: 'a'),
      workout(DateTime(2026, 9, 8), {
        'Жим': sets(85, [6]),
      }, id: 'b'),
      workout(DateTime(2026, 9, 15), {
        'Жим': sets(80, [8]),
      }, id: 'c'),
    ]);

    expect(bests.map((b) => b.exercise), ['Жим', 'Присед']);
    expect((bests.first.set.weight, bests.first.set.reps), (85.0, 6));
    expect(bests.first.date, DateTime(2026, 9, 8));
    expect(bests.last.date, DateTime(2026, 9, 1));
  });

  group('exerciseSeries', () {
    final history = [
      workout(DateTime(2026, 9, 8), {
        'Жим': sets(85, [5, 4]),
      }, id: 'b'),
      workout(DateTime(2026, 9, 1), {
        'Жим': [
          const SetEntry(weight: 120, reps: 1, type: SetType.warmup),
          ...sets(80, [8, 8]),
        ],
        'Присед': sets(100, [5]),
      }, id: 'a'),
      workout(DateTime(2026, 9, 15), {
        'Присед': sets(100, [5]),
      }, id: 'c'),
    ];

    test('точка на каждую тренировку с упражнением, по дате', () {
      final series = exerciseSeries('Жим', history, ExerciseMetric.bestWeight);

      expect(series.map((p) => (p.date.day, p.value)), [(1, 80.0), (8, 85.0)]);
    });

    test('1ПМ — лучший подход тренировки, объём — сумма без разминки', () {
      final oneRm = exerciseSeries('Жим', history, ExerciseMetric.oneRepMax);
      final volume = exerciseSeries('Жим', history, ExerciseMetric.volume);

      expect(oneRm.first.value, closeTo(80 * (1 + 8 / 30), 0.001));
      expect(volume.map((p) => p.value), [1280.0, 765.0]);
    });
  });

  group('упражнения со своим весом', () {
    final history = [
      workout(DateTime(2026, 9, 1), {
        'Подтягивания': sets(0, [8, 7]),
      }, id: 'a'),
      workout(DateTime(2026, 9, 8), {
        'Подтягивания': sets(0, [10, 8]),
      }, id: 'b'),
    ];

    test('рекорд — больше повторов', () {
      final before = recordsFor('Подтягивания', history);

      expect(isNewRecord(const SetEntry(weight: 0, reps: 11), before), isTrue);
      expect(isNewRecord(const SetEntry(weight: 0, reps: 10), before), isFalse);
    });

    test('лучший подход и история рекордов по повторам', () {
      final best = personalBests(history).single;

      expect((best.set.reps, best.date), (10, DateTime(2026, 9, 8)));
      expect(recordHistory(history).single.set.reps, 10);
    });

    test('подход с отягощением лучше любого без', () {
      final before = recordsFor('Подтягивания', history);

      expect(isNewRecord(const SetEntry(weight: 5, reps: 3), before), isTrue);
    });

    test('ряд «повторы» — лучший подход тренировки', () {
      final series = exerciseSeries(
        'Подтягивания',
        history,
        ExerciseMetric.reps,
      );

      expect(series.map((p) => p.value), [8.0, 10.0]);
    });
  });
}
