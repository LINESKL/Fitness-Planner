import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/stats.dart';
import 'package:flutter_test/flutter_test.dart';

ExerciseLog log(DateTime date, {double weight = 100, int reps = 10}) =>
    ExerciseLog(
      exercise: 'Присед',
      date: date,
      sets: [SetEntry(weight: weight, reps: reps)],
    );

void main() {
  // Среда, 7 октября 2026; неделя начинается в понедельник 5-го.
  final now = DateTime(2026, 10, 7, 20);

  test('считает дни с тренировками и объём текущей недели', () {
    final stats = weekStats([
      log(DateTime(2026, 10, 5, 9)),
      log(DateTime(2026, 10, 5, 19)),
      log(DateTime(2026, 10, 7, 18)),
    ], now);

    expect(stats.workouts, 2);
    expect(stats.volume, 3000);
  });

  test('прошлая неделя идёт в previousVolume, более старое не учитывается', () {
    final stats = weekStats([
      log(DateTime(2026, 10, 4, 23, 59)),
      log(DateTime(2026, 9, 28)),
      log(DateTime(2026, 9, 27, 23)),
    ], now);

    expect(stats.workouts, 0);
    expect(stats.volume, 0);
    expect(stats.previousVolume, 2000);
  });

  test('пустая история — нули', () {
    final stats = weekStats([], now);

    expect((stats.workouts, stats.volume, stats.previousVolume), (0, 0.0, 0.0));
  });

  group('volumeChange', () {
    test('рост и падение в процентах', () {
      expect(volumeChange(1120, 1000), '+12% к прошлой');
      expect(volumeChange(950, 1000), '−5% к прошлой');
    });

    test('без прошлой недели — null', () {
      expect(volumeChange(500, 0), isNull);
    });
  });

  test('тоннаж: до тонны — кг, дальше — тонны с одним знаком', () {
    expect(formatTonnage(640), '640 кг');
    expect(formatTonnage(8420), '8.4 т');
    expect(formatTonnage(12000), '12 т');
  });
}
