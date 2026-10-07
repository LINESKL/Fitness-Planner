import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/body.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

final now = DateTime.now();
final today = DateTime(now.year, now.month, now.day, 9);

Workout workout(
  String id,
  DateTime start,
  Map<String, List<SetEntry>> entries,
) => Workout(
  id: id,
  title: 'Тренировка $id',
  startedAt: start,
  finishedAt: start.add(const Duration(hours: 1)),
  entries: [
    for (final e in entries.entries)
      WorkoutEntry(exercise: e.key, sets: e.value),
  ],
);

List<SetEntry> sets(double w, int count, int reps) => [
  for (var i = 0; i < count; i++) SetEntry(weight: w, reps: reps),
];

Future<InMemoryBodyRepository> openProgress(
  WidgetTester tester, {
  List<Workout> workouts = const [],
  List<BodyEntry> body = const [],
}) async {
  final bodyRepo = InMemoryBodyRepository();
  for (final b in body) {
    await bodyRepo.save(b);
  }
  await pumpApp(
    tester,
    overrides: [
      workoutRepositoryProvider.overrideWithValue(
        InMemoryWorkoutRepository(workouts),
      ),
      bodyRepositoryProvider.overrideWithValue(bodyRepo),
    ],
  );
  await tester.tap(navItem('Прогресс'));
  await tester.pumpAndSettle();
  return bodyRepo;
}

/// Обзор длинный: карточки ниже календаря нужно докрутить.
Future<void> scrollTo(WidgetTester tester, Finder finder) => tester.dragUntilVisible(
  finder,
  find.byType(ListView).first,
  const Offset(0, -200),
);

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

void main() {
  testWidgets('календарь: дни с тренировками, нажатие открывает тренировку', (
    tester,
  ) async {
    await openProgress(
      tester,
      workouts: [
        workout('a', today, {'Жим лёжа': sets(80, 3, 8)}),
      ],
    );

    expect(find.textContaining('1 тренировка'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('day-${today.day}')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Тренировка a'), findsOneWidget);
  });

  testWidgets('листание месяцев', (tester) async {
    await openProgress(tester);
    await tester.tap(find.byTooltip('Предыдущий месяц'));
    await tester.pumpAndSettle();

    final previous = DateTime(now.year, now.month - 1);
    expect(
      find.byKey(ValueKey('month-${previous.year}-${previous.month}')),
      findsOneWidget,
    );
  });

  testWidgets('подходы по мышцам за неделю', (tester) async {
    await openProgress(
      tester,
      workouts: [
        workout('a', today, {
          'Жим лёжа': sets(80, 3, 8),
          'Приседания': sets(100, 4, 5),
        }),
      ],
    );

    await scrollTo(tester, find.text('ПОДХОДЫ ЗА НЕДЕЛЮ'));
    expect(find.text('ПОДХОДЫ ЗА НЕДЕЛЮ'), findsOneWidget);
    expect(find.byKey(const ValueKey('load-Грудь-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('load-Ноги-4')), findsOneWidget);
  });

  testWidgets('вес тела на обзоре', (tester) async {
    await openProgress(
      tester,
      body: [
        BodyEntry(
          id: 'b1',
          date: today.subtract(const Duration(days: 20)),
          weightKg: 79,
        ),
        BodyEntry(id: 'b2', date: today, weightKg: 78.4),
      ],
    );

    await scrollTo(tester, find.text('78.4 кг'));
    expect(find.text('78.4 кг'), findsOneWidget);
    expect(find.text('−0.6 кг за месяц'), findsOneWidget);
  });

  testWidgets('рекорды: лучший подход по каждому упражнению', (tester) async {
    await openProgress(
      tester,
      workouts: [
        workout('a', today.subtract(const Duration(days: 7)), {
          'Жим лёжа': sets(80, 1, 8),
        }),
        workout('b', today, {'Жим лёжа': sets(85, 1, 6)}),
      ],
    );
    await tester.tap(find.text('Рекорды'));
    await tester.pumpAndSettle();

    expect(find.text('Жим лёжа'), findsOneWidget);
    expect(find.text('85 × 6'), findsOneWidget);
  });

  testWidgets('тело: график, новый замер с запятой, удаление', (tester) async {
    final repo = await openProgress(
      tester,
      body: [
        BodyEntry(
          id: 'b1',
          date: today.subtract(const Duration(days: 7)),
          weightKg: 79,
        ),
        BodyEntry(
          id: 'b2',
          date: today.subtract(const Duration(days: 1)),
          weightKg: 78.6,
        ),
      ],
    );
    await tester.tap(find.text('Тело'));
    await tester.pumpAndSettle();
    expect(find.byType(LineChart), findsOneWidget);

    await tester.tap(find.text('Замер'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pump();
    expect(find.text('Введите вес'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Вес, кг'), '78,2');
    await tester.enterText(find.widgetWithText(TextField, 'Талия, см'), '81');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    final all = await repo.all();
    expect(all.length, 3);
    expect(all.any((b) => b.weightKg == 78.2 && b.waistCm == 81), isTrue);

    await tester.tap(find.byTooltip('Удалить замер').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect((await repo.all()).length, 2);
  });
}
