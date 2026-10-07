import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SetEntry', () {
    test('объём рабочего подхода = вес × повторы', () {
      expect(const SetEntry(weight: 80, reps: 8).volume, 640);
    });

    test('отказ и дроп-сет входят в объём, rpe хранится', () {
      const failure = SetEntry(
        weight: 80,
        reps: 6,
        type: SetType.failure,
        rpe: 9.5,
      );
      expect(failure.volume, 480);
      expect(failure.rpe, 9.5);
      expect(failure.isWarmup, isFalse);
      expect(
        const SetEntry(weight: 60, reps: 10, type: SetType.drop).volume,
        600,
      );
    });

    test('разминочный подход не входит в объём', () {
      expect(
        const SetEntry(weight: 40, reps: 10, type: SetType.warmup).volume,
        0,
      );
    });

    test('1ПМ по Эпли', () {
      expect(
        const SetEntry(weight: 90, reps: 10).oneRepMax,
        closeTo(120, 0.001),
      );
    });

    test('1ПМ для одного повтора равен весу', () {
      expect(const SetEntry(weight: 120, reps: 1).oneRepMax, 120);
    });
  });

  group('parseSet', () {
    test('разбирает "80x8"', () {
      final set = parseSet('80x8');
      expect(set?.weight, 80);
      expect(set?.reps, 8);
    });

    test('принимает пробелы, запятую, кириллическую х и знак ×', () {
      expect(parseSet(' 82,5 х 5 ')?.weight, 82.5);
      expect(parseSet('82.5×5')?.reps, 5);
      expect(parseSet('60*12')?.reps, 12);
    });

    test('возвращает null на некорректном вводе', () {
      for (final input in ['', 'abc', '80x', 'x8', '80x0', '-5x5', '80x8x2']) {
        expect(parseSet(input), isNull, reason: input);
      }
    });
  });

  group('formatWeight', () {
    test('целый вес без дробной части', () => expect(formatWeight(80), '80'));
    test(
      'дробный вес с одним знаком',
      () => expect(formatWeight(82.5), '82.5'),
    );
  });
}
