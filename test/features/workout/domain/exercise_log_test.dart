import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const warmup = SetEntry(weight: 40, reps: 10, isWarmup: true);
  const s80x8 = SetEntry(weight: 80, reps: 8);
  const s80x6 = SetEntry(weight: 80, reps: 6);
  const s75x10 = SetEntry(weight: 75, reps: 10);

  group('totalVolume', () {
    test('суммирует рабочие подходы', () {
      expect(totalVolume([warmup, s80x8, s75x10]), 640 + 750);
    });

    test('пустой список и только разминка дают 0', () {
      expect(totalVolume([]), 0);
      expect(totalVolume([warmup]), 0);
    });
  });

  group('bestSet', () {
    test('максимальный вес, при равенстве — больше повторов', () {
      expect(bestSet([s75x10, s80x6, s80x8]), same(s80x8));
    });

    test('разминка не считается лучшим подходом', () {
      expect(bestSet([warmup]), isNull);
      expect(bestSet([]), isNull);
    });
  });

  group('lastTime', () {
    final logs = [
      ExerciseLog(
        exercise: 'Жим лёжа',
        date: DateTime(2026, 9, 20),
        sets: const [s75x10],
      ),
      ExerciseLog(
        exercise: 'Жим лёжа',
        date: DateTime(2026, 9, 27),
        sets: const [s80x8, s80x6],
      ),
      ExerciseLog(
        exercise: 'Присед',
        date: DateTime(2026, 9, 30),
        sets: const [s80x8],
      ),
      ExerciseLog(
        exercise: 'Жим лёжа',
        date: DateTime(2026, 9, 13),
        sets: const [s75x10],
      ),
    ];

    test('берёт самую позднюю дату, а не последний элемент', () {
      expect(lastTime(logs, 'Жим лёжа')?.date, DateTime(2026, 9, 27));
    });

    test('null, если упражнение ни разу не делали', () {
      expect(lastTime(logs, 'Тяга'), isNull);
    });

    test('считает тренировки по упражнениям', () {
      expect(sessionsPerExercise(logs), {'Жим лёжа': 3, 'Присед': 1});
    });
  });
}
