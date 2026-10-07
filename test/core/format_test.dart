import 'package:fitness_planner/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('дата с ведущими нулями', () {
    expect(formatDate(DateTime(2026, 9, 7)), '07.09.2026');
  });

  test('таймер в формате м:сс', () {
    expect(formatDuration(const Duration(seconds: 90)), '1:30');
    expect(formatDuration(const Duration(seconds: 5)), '0:05');
  });

  test('ключ дня для адреса', () {
    expect(formatDayKey(DateTime(2026, 9, 7, 18, 30)), '2026-09-07');
  });

  test('русские формы множественного числа', () {
    String w(int n) => pluralRu(n, 'тренировка', 'тренировки', 'тренировок');
    expect(
      [w(1), w(2), w(5), w(11), w(21), w(22), w(14), w(0)],
      [
        'тренировка',
        'тренировки',
        'тренировок',
        'тренировок',
        'тренировка',
        'тренировки',
        'тренировок',
        'тренировок',
      ],
    );
  });

  test('длинная дата по-русски', () {
    expect(formatLongDate(DateTime(2026, 10, 7)), 'среда, 7 октября');
    expect(formatLongDate(DateTime(2026, 3, 1)), 'воскресенье, 1 марта');
  });
}
