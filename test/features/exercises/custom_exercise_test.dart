import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

Future<InMemoryCustomExerciseRepository> openCatalog(
  WidgetTester tester,
) async {
  final repo = InMemoryCustomExerciseRepository();
  await pumpApp(
    tester,
    overrides: [customExerciseRepositoryProvider.overrideWithValue(repo)],
  );
  await tester.tap(navItem('Упражнения'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> createExercise(
  WidgetTester tester,
  String name,
  String group,
) async {
  await tester.tap(find.text('Своё упражнение'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), name);
  await tester.tap(find.text(group));
  await tester.tap(find.text('Сохранить'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('название обязательно и не должно повторяться', (tester) async {
    await openCatalog(tester);
    await tester.tap(find.text('Своё упражнение'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Введите название'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'жим лёжа');
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Такое упражнение уже есть'), findsOneWidget);
  });

  testWidgets('новое упражнение сохраняется и стоит первым в каталоге', (
    tester,
  ) async {
    final repo = await openCatalog(tester);
    await createExercise(tester, 'Махи на скамье', 'Плечи');

    final saved = (await repo.all()).single;
    expect((saved.name, saved.muscleGroup), ('Махи на скамье', 'Плечи'));
    final first = tester.getTopLeft(find.text('Махи на скамье'));
    final builtIn = tester.getTopLeft(find.text('Жим лёжа'));
    expect(first.dy, lessThan(builtIn.dy));
  });

  testWidgets('своё упражнение можно переименовать и удалить', (tester) async {
    final repo = await openCatalog(tester);
    await createExercise(tester, 'Махи на скамье', 'Плечи');
    await tester.tap(find.text('Махи на скамье'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Изменить упражнение'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Махи сидя');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Махи сидя'), findsOneWidget);

    await tester.tap(find.byTooltip('Удалить упражнение'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(await repo.all(), isEmpty);
    expect(find.text('Махи сидя'), findsNothing);
  });

  testWidgets('встроенное упражнение не редактируется', (tester) async {
    await openCatalog(tester);
    await tester.tap(find.text('Жим лёжа'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Изменить упражнение'), findsNothing);
  });

  testWidgets('созданное из выбора в тренировке сразу добавляется', (
    tester,
  ) async {
    await pumpApp(tester, templates: const []);
    await tester.tap(find.text('Пустая тренировка'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить упражнение'));
    await tester.pumpAndSettle();
    await createExercise(tester, 'Гиперэкстензия', 'Спина');

    final active = containerOf(tester).read(activeWorkoutProvider)!;
    expect(active.exercises.single.name, 'Гиперэкстензия');
  });
}
