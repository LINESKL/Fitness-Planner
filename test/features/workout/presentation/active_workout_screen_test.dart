import 'package:fitness_planner/features/workout/domain/exercise_log.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/presentation/active_workout_screen.dart';
import 'package:fitness_planner/features/workout/presentation/workout_scope.dart';
import 'package:fitness_planner/features/workout/presentation/workout_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final history = [
    ExerciseLog(
      exercise: 'Жим лёжа',
      date: DateTime(2026, 9, 27),
      sets: const [
        SetEntry(weight: 40, reps: 10, isWarmup: true),
        SetEntry(weight: 80, reps: 8),
        SetEntry(weight: 82.5, reps: 7),
      ],
    ),
  ];

  late WorkoutStore store;

  Future<void> pump(WidgetTester tester) {
    store = WorkoutStore(history: history)
      ..start(const ['Жим лёжа', 'Подтягивания']);
    return tester.pumpWidget(
      WorkoutScope(
        store: store,
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );
  }

  List<ExerciseLog> saved() => store.history.skip(history.length).toList();

  Future<void> finish(WidgetTester tester) async {
    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();
  }

  Finder field(int index) => find.byType(TextField).at(index);

  // Поля ввода тоже прокручиваемые — берём сам список.
  Future<void> scrollTo(WidgetTester tester, String text) =>
      tester.scrollUntilVisible(
        find.text(text),
        200,
        scrollable: find.byType(Scrollable).first,
      );

  testWidgets('колонка «Прошлый» — рабочие подходы прошлой тренировки', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('80 × 8'), findsOneWidget);
    expect(find.text('82.5 × 7'), findsOneWidget);
    expect(find.text('40 × 10'), findsNothing);
  });

  testWidgets('упражнение без истории — «Ещё не делали» и пустая строка', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Ещё не делали'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(3));
  });

  testWidgets('галочка отмечает подход', (tester) async {
    await pump(tester);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).last).value, isFalse);
  });

  testWidgets('«Добавить подход» копирует последний подход', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Добавить подход').first);
    await tester.pump();

    expect(find.byType(Checkbox), findsNWidgets(4));
  });

  testWidgets('завершение сохраняет только отмеченные подходы с правками', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(field(0), '82,5');
    await tester.enterText(field(1), '9');
    await tester.tap(find.byType(Checkbox).first);
    await finish(tester);

    expect(saved().single.exercise, 'Жим лёжа');
    expect(saved().single.sets.map((s) => (s.weight, s.reps)), [(82.5, 9)]);
  });

  testWidgets('мусор в поле веса не портит значение', (tester) async {
    await pump(tester);
    await tester.enterText(field(0), 'abc');
    await tester.tap(find.byType(Checkbox).first);
    await finish(tester);

    expect(saved().single.sets.single.weight, 80);
  });

  testWidgets('без отметок история не пополняется', (tester) async {
    await pump(tester);
    await finish(tester);

    expect(saved(), isEmpty);
  });

  testWidgets('«Добавить упражнение» открывает каталог и добавляет выбранное', (
    tester,
  ) async {
    await pump(tester);
    await scrollTo(tester, 'Добавить упражнение');
    await tester.tap(find.text('Добавить упражнение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Приседания'));
    await tester.pumpAndSettle();
    await scrollTo(tester, 'Приседания');

    expect(find.text('Приседания'), findsOneWidget);
  });
}
