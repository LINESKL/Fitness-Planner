import 'package:clock/clock.dart';
import 'package:fitness_planner/features/workout/data/in_memory_workout_repository.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('отдых тикает по часам и заканчивается сам', (tester) async {
    final container = ProviderContainer.test(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(
          InMemoryWorkoutRepository(),
        ),
      ],
    );
    await container.read(activeWorkoutProvider.notifier).start(plan: ['Жим']);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Consumer(
            builder: (_, ref, _) =>
                Text('${ref.watch(restLeftProvider)?.inSeconds}'),
          ),
        ),
      ),
    );
    expect(find.text('null'), findsOneWidget);

    container
        .read(activeWorkoutProvider.notifier)
        .update(
          (w) => w
              .addSet(0)
              .completeCurrent(
                now: clock.now(),
                rest: const Duration(seconds: 3),
              ),
        );
    await tester.pump();
    expect(find.text('3'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('null'), findsOneWidget);
  });
}
