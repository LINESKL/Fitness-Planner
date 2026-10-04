import 'package:fitness_planner/features/exercises/presentation/exercises_screen.dart';
import 'package:fitness_planner/features/workout/domain/exercise.dart';
import 'package:fitness_planner/features/workout/domain/exercise_repository.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Отдаёт ответы по очереди; исключение в списке — бросает его.
class FakeExerciseRepository implements ExerciseRepository {
  FakeExerciseRepository(this.responses);

  final List<Object> responses;
  int calls = 0;

  @override
  Future<List<Exercise>> fetchExercises() async {
    final response =
        responses[calls < responses.length ? calls : responses.length - 1];
    calls++;
    if (response is Exception) throw response;
    return response as List<Exercise>;
  }
}

const exercises = [
  Exercise(id: '1', name: 'Жим лёжа', muscleGroup: 'Грудь'),
  Exercise(id: '2', name: 'Приседания', muscleGroup: 'Ноги'),
  Exercise(id: '3', name: 'Bench Press', muscleGroup: 'Грудь'),
];

Future<FakeExerciseRepository> pump(
  WidgetTester tester,
  List<Object> responses,
) async {
  final repo = FakeExerciseRepository(responses);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [exerciseRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: Scaffold(body: ExercisesScreen())),
    ),
  );
  return repo;
}

void main() {
  testWidgets('пока грузится — индикатор, потом список', (tester) async {
    await pump(tester, [exercises]);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Приседания'), findsOneWidget);
  });

  testWidgets('поиск срабатывает через 300 мс после ввода', (tester) async {
    await pump(tester, [exercises]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'жим');
    await tester.pump(const Duration(milliseconds: 299));
    expect(find.text('Приседания'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('Приседания'), findsNothing);
    expect(find.text('Жим лёжа'), findsOneWidget);
  });

  testWidgets('поиск по группе мышц и без учёта регистра', (tester) async {
    await pump(tester, [exercises]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ГРУДЬ');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Жим лёжа'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Приседания'), findsNothing);
  });

  testWidgets('ничего не нашлось — пустое состояние', (tester) async {
    await pump(tester, [exercises]);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'зззз');
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Ничего не нашлось'), findsOneWidget);
  });

  testWidgets('ошибка — текст и «Повторить», повтор загружает', (tester) async {
    final repo = await pump(tester, [
      const ExerciseLoadException('Нет подключения к интернету'),
      exercises,
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.text('Приседания'), findsOneWidget);
  });

  testWidgets('pull-to-refresh загружает каталог заново', (tester) async {
    final repo = await pump(tester, [exercises]);
    await tester.pumpAndSettle();

    await tester.fling(find.text('Жим лёжа'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
  });
}
