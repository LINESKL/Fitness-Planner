import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:fitness_planner/features/auth/presentation/auth_providers.dart';
import 'package:fitness_planner/features/workout/data/cloud/synced_repositories.dart';
import 'package:fitness_planner/features/workout/data/cloud/user_cloud.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/repositories.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth implements AuthRepository {
  _FakeAuth(this.current);
  @override
  final AuthState current;
  @override
  Stream<AuthState> changes() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

ProviderContainer container(AuthState auth, {bool withFirestore = true}) =>
    ProviderContainer.test(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(_FakeAuth(auth)),
        if (withFirestore)
          firestoreProvider.overrideWithValue(FakeFirebaseFirestore()),
        workoutRepositoryProvider.overrideWith(
          (ref) => syncedOr<WorkoutRepository>(
            ref,
            InMemoryWorkoutRepository(),
            SyncedWorkoutRepository.new,
          ),
        ),
      ],
    );

void main() {
  test('SignedIn + firestore: репозиторий облачный', () {
    final c = container(const SignedIn(uid: 'u1'));
    expect(c.read(workoutRepositoryProvider), isA<SyncedWorkoutRepository>());
    expect(c.read(userCloudProvider), isA<UserCloud>());
  });

  test('Guest: локальный', () {
    final c = container(const Guest());
    expect(c.read(userCloudProvider), isNull);
    expect(c.read(workoutRepositoryProvider), isA<InMemoryWorkoutRepository>());
  });

  test('SignedIn без firestore: локальный', () {
    final c = container(const SignedIn(uid: 'u1'), withFirestore: false);
    expect(c.read(workoutRepositoryProvider), isA<InMemoryWorkoutRepository>());
  });
}
