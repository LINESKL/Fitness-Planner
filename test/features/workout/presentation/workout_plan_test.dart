import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

List<String> names(WidgetTester tester) => [
  for (final e in containerOf(tester).read(activeWorkoutProvider)!.exercises)
    e.name,
];

/// Тренировка «Верх» (жим 3 × 8, тяга 3 × 10), один подход жима сделан, открыт план.
Future<void> openPlan(WidgetTester tester) async {
  await pumpApp(tester);
  await tester.tap(find.text('Начать тренировку'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Готово'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('План тренировки'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('упражнения с прогрессом подходов', (tester) async {
    await openPlan(tester);

    expect(find.text('1/3'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('нажатие переходит к первому невыполненному подходу', (
    tester,
  ) async {
    await openPlan(tester);
    await tester.tap(find.text('Тяга штанги в наклоне'));
    await tester.pumpAndSettle();

    expect(find.textContaining('подход 1 из 3'), findsOneWidget);
    expect(containerOf(tester).read(activeWorkoutProvider)!.cursor, (
      exercise: 1,
      set: 0,
    ));
  });

  testWidgets('перетаскивание меняет порядок', (tester) async {
    await openPlan(tester);
    await tester.drag(
      find.byIcon(Icons.drag_indicator).first,
      const Offset(0, 200),
    );
    await tester.pumpAndSettle();

    expect(names(tester), ['Тяга штанги в наклоне', 'Жим лёжа']);
  });

  testWidgets('добавить, заменить и удалить упражнение', (tester) async {
    await openPlan(tester);

    await tester.tap(find.text('Упражнение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Приседания'));
    await tester.pumpAndSettle();
    expect(names(tester).last, 'Приседания');

    await tester.tap(find.byTooltip('Действия').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Заменить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Румынская тяга'));
    await tester.pumpAndSettle();
    expect(names(tester).last, 'Румынская тяга');

    await tester.tap(find.byTooltip('Действия').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(names(tester), ['Жим лёжа', 'Тяга штанги в наклоне']);
  });
}
