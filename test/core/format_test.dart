import 'package:fitness_planner/core/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('дата с ведущими нулями', () {
    expect(formatDate(DateTime(2026, 9, 7)), '07.09.2026');
  });
}
