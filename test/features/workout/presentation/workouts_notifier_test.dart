import 'package:fitness_planner/features/workout/domain/repositories.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

Workout workout(String id, DateTime startedAt) => Workout(
  id: id,
  title: 'Верх',
  startedAt: startedAt,
  finishedAt: startedAt.add(const Duration(hours: 1)),
  entries: const [],
);

void main() {
  late MockWorkoutRepository repo;
  late ProviderContainer container;

  final older = workout('w-1', DateTime(2026, 10, 1));
  final newer = workout('w-2', DateTime(2026, 10, 5));

  setUpAll(() => registerFallbackValue(older));

  setUp(() {
    repo = MockWorkoutRepository();
    when(() => repo.save(any())).thenAnswer((_) async {});
    when(() => repo.delete(any())).thenAnswer((_) async {});
    container = ProviderContainer.test(
      overrides: [workoutRepositoryProvider.overrideWithValue(repo)],
    );
  });

  test('список из репозитория — от старых к новым', () async {
    when(() => repo.all()).thenAnswer((_) async => [newer, older]);

    final list = await container.read(workoutsProvider.future);

    expect([for (final w in list) w.id], ['w-1', 'w-2']);
  });

  test('save пишет в репозиторий и перечитывает список', () async {
    when(() => repo.all()).thenAnswer((_) async => [older]);
    await container.read(workoutsProvider.future);

    when(() => repo.all()).thenAnswer((_) async => [older, newer]);
    await container.read(workoutsProvider.notifier).save(newer);

    verify(() => repo.save(newer)).called(1);
    verify(() => repo.all()).called(2);
    expect(container.read(workoutsProvider).value, hasLength(2));
  });

  test('delete удаляет по id и перечитывает список', () async {
    when(() => repo.all()).thenAnswer((_) async => [older, newer]);
    await container.read(workoutsProvider.future);

    when(() => repo.all()).thenAnswer((_) async => [newer]);
    await container.read(workoutsProvider.notifier).delete('w-1');

    verify(() => repo.delete('w-1')).called(1);
    expect(container.read(workoutsProvider).value!.single.id, 'w-2');
  });
}
