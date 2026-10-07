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
}
