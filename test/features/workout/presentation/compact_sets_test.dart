import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/presentation/set_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('один вес — «80 × 8, 8, 7», разный — по подходам', () {
    expect(
      compactSets(const [
        SetEntry(weight: 80, reps: 8),
        SetEntry(weight: 80, reps: 7),
      ]),
      '80 × 8, 7',
    );
    expect(
      compactSets(const [
        SetEntry(weight: 80, reps: 8),
        SetEntry(weight: 82.5, reps: 7),
      ]),
      '80 × 8, 82.5 × 7',
    );
  });

  test('без отягощения — «свой вес»', () {
    expect(
      compactSets(const [
        SetEntry(weight: 0, reps: 9),
        SetEntry(weight: 0, reps: 8),
      ]),
      'свой вес × 9, 8',
    );
    expect(formatLoad(0), 'свой вес');
    expect(formatLoad(82.5), '82.5 кг');
  });
}
