import 'dart:async';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:fitness_planner/features/auth/presentation/auth_providers.dart';
import 'package:fitness_planner/features/workout/data/cloud/cloud_sync.dart';
import 'package:fitness_planner/features/workout/data/hive/hive_repositories.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/data/json_mappers.dart';
import 'package:fitness_planner/features/workout/domain/repositories.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

Workout _w(String id) => Workout(
  id: id,
  title: id,
  startedAt: DateTime(2026, 1, 1, 10),
  finishedAt: DateTime(2026, 1, 1, 11),
  entries: const [],
);

class _Auth implements AuthRepository {
  _Auth(this.current, [this.log]);

  final List<String>? log;
  final controller = StreamController<AuthState>();
  @override
  AuthState current;
  @override
  Stream<AuthState> changes() => controller.stream;
  @override
  Future<void> signOut() async {
    log?.add('signOut');
    current = const SignedOut();
    controller.add(current);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Слияние зависает на чтении тренировок, пока не отпустят.
class _SlowWorkouts extends InMemoryWorkoutRepository {
  _SlowWorkouts(this.gate, this.log);
  final Completer<void> gate;
  final List<String> log;
  @override
  Future<List<Workout>> all() async {
    await gate.future;
    log.add('mergeDone');
    return super.all();
  }
}

LocalData _local(WorkoutRepository workouts) => LocalData(
  workouts: workouts,
  program: InMemoryProgramRepository(),
  body: InMemoryBodyRepository(),
  customExercises: InMemoryCustomExerciseRepository(),
  notes: InMemoryNoteRepository(),
  favorites: InMemoryFavoriteRepository(),
);

void main() {
  test('выход: signOut, потом конец слияния, потом очистка телефона', () async {
    final log = <String>[];
    final gate = Completer<void>();
    final fs = FakeFirebaseFirestore();
    final auth = _Auth(const SignedIn(uid: 'u1'), log);
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(fs),
        localDataProvider.overrideWithValue(_local(_SlowWorkouts(gate, log))),
        localDataWiperProvider.overrideWithValue(() async => log.add('wipe')),
      ],
    );
    container.listen(cloudSyncProvider, (_, _) {});
    container.read(authProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final done = container.read(signOutAndWipeProvider)();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(log, ['signOut'], reason: 'очистка ждёт слияние');
    gate.complete();
    await done;
    expect(log, ['signOut', 'mergeDone', 'wipe']);
  });

  test('два аккаунта по очереди: второй не видит тренировки первого', () async {
    final dir = await Directory.systemTemp.createTemp('hive_wipe');
    Hive.init(dir.path);
    addTearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });
    final workouts = await HiveWorkoutRepository.open();
    final local = LocalData(
      workouts: workouts,
      program: await HiveProgramRepository.open(),
      body: await HiveBodyRepository.open(),
      customExercises: await HiveCustomExerciseRepository.open(),
      notes: await HiveNoteRepository.open(),
      favorites: await HiveFavoriteRepository.open(),
    );
    final fs = FakeFirebaseFirestore();
    await fs
        .collection('users/u1/workouts')
        .doc('w1')
        .set(workoutToJson(_w('w1')));
    final auth = _Auth(const SignedIn(uid: 'u1'));
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(fs),
        localDataProvider.overrideWithValue(local),
        workoutRepositoryProvider.overrideWithValue(workouts),
        localDataWiperProvider.overrideWithValue(clearSyncedBoxes),
      ],
    );
    container.listen(cloudSyncProvider, (_, _) {});
    container.listen(workoutsProvider, (_, _) {});
    container.read(authProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect((await container.read(workoutsProvider.future)).single.id, 'w1');

    await container.read(signOutAndWipeProvider)();
    expect(await container.read(workoutsProvider.future), isEmpty);

    auth.controller.add(const SignedIn(uid: 'u2'));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(await container.read(workoutsProvider.future), isEmpty);
  });
}
