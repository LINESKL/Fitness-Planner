import 'package:fitness_planner/features/workout/domain/exercise.dart';
import 'package:fitness_planner/features/workout/domain/exercise_repository.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}

const bench = Exercise(id: '1', name: 'Жим лёжа', muscleGroup: 'Грудь');
const squat = Exercise(id: 'wger-2', name: 'Squats', muscleGroup: 'Ноги');
const squatDuplicate = Exercise(
  id: 'wger-3',
  name: 'squats',
  muscleGroup: 'Ноги',
);
const lunge = Exercise(id: 'wger-4', name: 'Lunges', muscleGroup: 'Ноги');

void main() {
  late MockExerciseRepository repo;
  late ProviderContainer container;

  void page(int offset, List<Exercise> items, {int? next}) => when(
    () => repo.fetchExercises(offset: offset),
  ).thenAnswer((_) async => (items: items, offline: false, nextOffset: next));

  List<String> names() => [
    for (final e in container.read(exercisesProvider).value!.items) e.name,
  ];

  setUp(() {
    repo = MockExerciseRepository();
    container = ProviderContainer.test(
      overrides: [exerciseRepositoryProvider.overrideWithValue(repo)],
    );
  });

  test('первая страница и сдвиг до следующей', () async {
    page(0, [bench, squat], next: 50);

    final catalog = await container.read(exercisesProvider.future);

    expect(names(), ['Жим лёжа', 'Squats']);
    expect(catalog.nextOffset, 50);
  });

  test('loadMore дописывает страницу без дублей по названию', () async {
    page(0, [bench, squat], next: 50);
    page(50, [squatDuplicate, lunge]);
    await container.read(exercisesProvider.future);

    await container.read(exercisesProvider.notifier).loadMore();

    expect(names(), ['Жим лёжа', 'Squats', 'Lunges']);
    expect(container.read(exercisesProvider).value!.nextOffset, isNull);
  });

  test('страниц больше нет — loadMore ничего не запрашивает', () async {
    page(0, [bench]);
    await container.read(exercisesProvider.future);

    await container.read(exercisesProvider.notifier).loadMore();

    verify(() => repo.fetchExercises(offset: 0)).called(1);
    verifyNoMoreInteractions(repo);
  });

  test('два loadMore подряд — один запрос', () async {
    page(0, [bench], next: 50);
    page(50, [lunge]);
    await container.read(exercisesProvider.future);
    final notifier = container.read(exercisesProvider.notifier);

    await Future.wait([notifier.loadMore(), notifier.loadMore()]);

    verify(() => repo.fetchExercises(offset: 50)).called(1);
  });

  test(
    'ошибка на следующей странице — список остаётся, подгрузка стоп',
    () async {
      page(0, [bench], next: 50);
      when(
        () => repo.fetchExercises(offset: 50),
      ).thenThrow(const ExerciseLoadException('Нет подключения к интернету'));
      await container.read(exercisesProvider.future);

      await container.read(exercisesProvider.notifier).loadMore();

      expect(names(), ['Жим лёжа']);
      expect(container.read(exercisesProvider).value!.nextOffset, isNull);
    },
  );
}
