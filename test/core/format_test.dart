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
}
