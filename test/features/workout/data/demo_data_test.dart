import 'package:fitness_planner/features/workout/data/demo_data.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/data/sample_data.dart';
import 'package:fitness_planner/features/workout/domain/program.dart';
import 'package:fitness_planner/features/workout/domain/progress_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 7, 12);

  test('пример: три дня сплита, месяц истории, рост весов, замеры', () async {
    final workouts = InMemoryWorkoutRepository();
    final program = InMemoryProgramRepository();
    final body = InMemoryBodyRepository();

    await loadDemo(workouts, program, body, now);

    final templates = await program.templates();
    expect(templates.map((t) => t.name).toSet(), {
      'Грудь + трицепс',
      'Спина + бицепс',
      'Ноги',
    });
    expect((await program.program()).templateIds.length, 3);

    final history = await workouts.all();
    expect(history.length, greaterThanOrEqualTo(10));
    expect(history.every((w) => w.finishedAt.isBefore(now)), isTrue);
    expect(history.every((w) => w.templateId != null), isTrue);

    history.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final firstBench = recordsFor('Жим лёжа', history.take(3).toList());
    final allBench = recordsFor('Жим лёжа', history);
    expect(allBench.bestWeight, greaterThan(firstBench.bestWeight));

    expect((await body.all()).length, greaterThanOrEqualTo(4));
  });

  test('все упражнения примера есть во встроенном каталоге', () async {
    final program = InMemoryProgramRepository();
    await loadDemo(
      InMemoryWorkoutRepository(),
      program,
      InMemoryBodyRepository(),
      now,
    );
    final catalog = {for (final e in sampleExercises) e.name};

    final used = {
      for (final WorkoutTemplate t in await program.templates())
        for (final e in t.exercises) e.exercise,
    };
    expect(
      catalog.containsAll(used),
      isTrue,
      reason: '${used.difference(catalog)}',
    );
  });

  test('пример дописывает дни к своей программе, без дублей', () async {
    final program = InMemoryProgramRepository(
      templates: const [
        WorkoutTemplate(id: 'mine', name: 'Мой день', exercises: []),
      ],
      program: const Program(templateIds: ['mine']),
    );

    await loadDemo(
      InMemoryWorkoutRepository(),
      program,
      InMemoryBodyRepository(),
      now,
    );
    await loadDemo(
      InMemoryWorkoutRepository(),
      program,
      InMemoryBodyRepository(),
      now,
    );

    final ids = (await program.program()).templateIds;
    expect(ids.first, 'mine');
    expect(ids.length, 4);
  });
}
