import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

/// День «Верх»: жим лёжа 3 × 8 (в прошлый раз 80 × 8, 8, 7), тяга 3 × 10.
Future<void> startUpperDay(
  WidgetTester tester, {
  int restSeconds = 0,
  List<Override> overrides = const [],
}) async {
  await pumpApp(tester, restSeconds: restSeconds, overrides: overrides);
  await tester.tap(find.text('Начать тренировку'));
  await tester.pumpAndSettle();
}

Future<void> done(WidgetTester tester) async {
  await tester.tap(find.text('Готово'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('экран подхода: упражнение, номер подхода, прошлый раз', (
    tester,
  ) async {
    await startUpperDay(tester);

    expect(find.text('Жим лёжа'), findsOneWidget);
    expect(
      find.text('подход 1 из 3 · в прошлый раз 80 × 8, 8, 7'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('weight-value')), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('8'), findsWidgets);
  });

  testWidgets('степперы: вес шагом 2.5, повторы шагом 1', (tester) async {
    await startUpperDay(tester);

    await tester.tap(find.byTooltip('Больше вес'));
    await tester.tap(find.byTooltip('Меньше повторов'));
    await tester.pump();

    final set = containerOf(tester).read(activeWorkoutProvider)!.currentSet!;
    expect((set.weight, set.reps), (82.5, 7));
    expect(find.text('82.5'), findsOneWidget);
  });

  testWidgets('вес с клавиатуры: запятая принимается, мусор — нет', (
    tester,
  ) async {
    await startUpperDay(tester);

    Future<void> enterWeight(String text) async {
      await tester.tap(find.byKey(const Key('weight-value')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), text);
      await tester.tap(find.text('ОК'));
      await tester.pumpAndSettle();
    }

    await enterWeight('85,5');
    expect(find.text('85.5'), findsOneWidget);
    await enterWeight('abc');
    expect(find.text('85.5'), findsOneWidget);
  });

  testWidgets('«Готово» → отдых → по таймеру следующий подход', (tester) async {
    await startUpperDay(tester, restSeconds: 3);
    await done(tester);

    expect(find.text('ОТДЫХ'), findsOneWidget);
    expect(find.text('0:03'), findsOneWidget);
    expect(find.text('Жим лёжа · подход 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.text('подход 2 из 3 · в прошлый раз 80 × 8, 8, 7'),
      findsOneWidget,
    );
  });

  testWidgets('отдых: +15 с и «Пропустить отдых»', (tester) async {
    await startUpperDay(tester, restSeconds: 90);
    await done(tester);

    await tester.tap(find.text('+15 с'));
    await tester.pump();
    expect(find.text('1:45'), findsOneWidget);

    await tester.tap(find.text('Пропустить отдых'));
    await tester.pumpAndSettle();
    expect(find.text('ОТДЫХ'), findsNothing);
    expect(find.text('Готово'), findsOneWidget);
  });

  testWidgets('кружок выполненного подхода открывает его для правки', (
    tester,
  ) async {
    await startUpperDay(tester);
    await done(tester);
    expect(find.textContaining('подход 2 из 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Подход 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('подход 1 из 3'), findsOneWidget);
  });

  testWidgets('тип подхода и RPE сохраняются в тренировку', (tester) async {
    await startUpperDay(tester);
    await tester.tap(find.text('Тип'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Разминка'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('RPE 8'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Разминка · RPE 8'), findsOneWidget);
    final set = containerOf(tester).read(activeWorkoutProvider)!.currentSet!;
    expect((set.type, set.rpe), (SetType.warmup, 8.0));
  });

  testWidgets('заметка к упражнению сохраняется и показывается', (
    tester,
  ) async {
    final notes = InMemoryNoteRepository();
    await startUpperDay(
      tester,
      overrides: [noteRepositoryProvider.overrideWithValue(notes)],
    );
    await tester.tap(find.text('Заметка'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'лопатки сведены');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Заметка: лопатки сведены'), findsOneWidget);
    expect(await notes.note('Жим лёжа'), 'лопатки сведены');
  });

  testWidgets('новый рекорд объявляется после «Готово»', (tester) async {
    await startUpperDay(tester);
    await tester.tap(find.byTooltip('Больше вес'));
    await tester.pump();
    await done(tester);

    expect(find.text('Новый рекорд · Жим лёжа 82.5 × 8'), findsOneWidget);
  });

  testWidgets('все подходы → завершение → итоги, тренировка сохранена', (
    tester,
  ) async {
    await startUpperDay(tester);
    for (var i = 0; i < 6; i++) {
      await done(tester);
    }

    expect(find.text('Все подходы сделаны'), findsOneWidget);
    await tester.tap(find.text('Завершить тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Тренировка готова'), findsOneWidget);
    final c = containerOf(tester);
    expect(c.read(activeWorkoutProvider), isNull);
    final saved = (await c.read(workoutsProvider.future)).last;
    expect(saved.title, 'Верх');
    expect(saved.workingSets, 6);
  });

  testWidgets('«Ещё подход» после конца тренировки', (tester) async {
    await startUpperDay(tester);
    for (var i = 0; i < 6; i++) {
      await done(tester);
    }
    await tester.tap(find.text('Ещё подход'));
    await tester.pumpAndSettle();

    expect(find.textContaining('подход 4 из 4'), findsOneWidget);
  });

  testWidgets('«Завершить» в шапке спрашивает и сохраняет только сделанное', (
    tester,
  ) async {
    await startUpperDay(tester);
    await done(tester);
    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Не сделано подходов: 5'), findsOneWidget);
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(activeWorkoutProvider), isNotNull);

    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Завершить'));
    await tester.pumpAndSettle();

    final saved = (await containerOf(tester).read(workoutsProvider.future))
        .last;
    expect(saved.workingSets, 1);
    expect(find.text('Тренировка готова'), findsOneWidget);
  });
}
