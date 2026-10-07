import 'package:fitness_planner/features/workout/domain/program.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutTemplate template(String id) => WorkoutTemplate(
  id: id,
  name: 'День $id',
  exercises: const [
    TemplateExercise(exercise: 'Приседания', sets: 4, repsMin: 5, repsMax: 5),
  ],
);

Workout done(String? templateId, int day) => Workout(
  id: 'w$day',
  title: 'x',
  templateId: templateId,
  startedAt: DateTime(2026, 10, day),
  finishedAt: DateTime(2026, 10, day, 1),
  entries: const [],
);

void main() {
  final templates = [template('a'), template('b'), template('c')];
  const program = Program(templateIds: ['a', 'b', 'c']);

  test('без тренировок — первый день', () {
    expect(nextTemplate(program, templates, [])?.id, 'a');
  });

  test('после дня 1 — день 2, после последнего — снова первый', () {
    expect(nextTemplate(program, templates, [done('a', 1)])?.id, 'b');
    expect(
      nextTemplate(program, templates, [done('a', 1), done('c', 3)])?.id,
      'a',
    );
  });

  test('учитывается самая поздняя тренировка, а не последняя в списке', () {
    expect(
      nextTemplate(program, templates, [done('b', 5), done('a', 1)])?.id,
      'c',
    );
  });

  test('свободные тренировки и тренировки вне программы не влияют', () {
    expect(
      nextTemplate(program, templates, [
        done('a', 1),
        done(null, 2),
        done('z', 3),
      ])?.id,
      'b',
    );
  });

  test('день удалён — его тренировки пропускаются, отсутствующие id тоже', () {
    final withoutB = [template('a'), template('c')];

    expect(nextTemplate(program, withoutB, [done('a', 1)])?.id, 'c');
    expect(nextTemplate(program, withoutB, [done('b', 2)])?.id, 'a');
  });

  test('пустая программа — null', () {
    expect(nextTemplate(const Program(templateIds: []), templates, []), isNull);
  });

  test('позиция дня в программе', () {
    expect(dayPosition(program, templates, 'b'), (index: 2, total: 3));
    expect(dayPosition(program, templates, 'z'), isNull);
  });
}
