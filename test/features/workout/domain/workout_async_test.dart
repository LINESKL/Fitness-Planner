import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<ExerciseLog>> load() async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return [
      ExerciseLog(
        exercise: 'Жим лёжа',
        date: DateTime(2026, 9, 27),
        sets: const [
          SetEntry(weight: 40, reps: 10, type: SetType.warmup),
          SetEntry(weight: 82.5, reps: 8),
          SetEntry(weight: 82.5, reps: 7),
        ],
      ),
    ];
  }

  group('lastTimeSummary', () {
    test('показывает рабочие подходы прошлой тренировки', () async {
      expect(
        await lastTimeSummary(load, 'Жим лёжа'),
        '82.5 кг × 8, 82.5 кг × 7',
      );
    });

    test('сообщает, что упражнение ещё не делали', () async {
      expect(await lastTimeSummary(load, 'Тяга'), 'Ещё не делали');
    });

    test('пробрасывает ошибку загрузки', () {
      expect(
        lastTimeSummary(() async => throw StateError('нет сети'), 'Жим лёжа'),
        throwsStateError,
      );
    });
  });

  group('restTimer', () {
    test('отсчитывает оставшееся время до нуля', () async {
      final ticks = await restTimer(
        const Duration(milliseconds: 30),
        tick: const Duration(milliseconds: 10),
      ).toList();

      expect(ticks, const [
        Duration(milliseconds: 20),
        Duration(milliseconds: 10),
        Duration.zero,
      ]);
    });
  });

  group('restLeft', () {
    final end = DateTime(2026, 10, 7, 18, 2);

    test('оставшееся время округляется вверх до секунды', () {
      expect(
        restLeft(end, DateTime(2026, 10, 7, 18, 0, 30, 500)),
        const Duration(seconds: 90),
      );
    });

    test('после «сворачивания» время считается от часов, а не от тиков', () {
      expect(
        restLeft(end, DateTime(2026, 10, 7, 18, 1, 50)),
        const Duration(seconds: 10),
      );
    });

    test('время вышло — null', () {
      expect(restLeft(end, end), isNull);
      expect(restLeft(end, end.add(const Duration(minutes: 5))), isNull);
    });
  });
}
