import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitness_planner/core/push_service.dart';
import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:fitness_planner/features/auth/presentation/auth_providers.dart';
import 'package:fitness_planner/features/workout/data/cloud/cloud_sync.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Auth implements AuthRepository {
  final controller = StreamController<AuthState>();
  @override
  AuthState current = const SignedIn(uid: 'u1');
  @override
  Stream<AuthState> changes() => controller.stream;
  void emit(AuthState s) {
    current = s;
    controller.add(s);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Messaging implements PushMessaging {
  final refresh = StreamController<String>.broadcast();
  int starts = 0;
  @override
  Future<bool> requestPermission() async {
    starts++;
    return true;
  }

  @override
  Future<String?> token() async => 't1';
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> tokenRefresh() => refresh.stream;
  @override
  Stream<({String? title, String? body})> foreground() => const Stream.empty();
}

void main() {
  late FakeFirebaseFirestore fs;
  late _Auth auth;
  late _Messaging messaging;
  late ProviderContainer container;

  setUp(() {
    fs = FakeFirebaseFirestore();
    auth = _Auth();
    messaging = _Messaging();
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(fs),
        pushMessagingProvider.overrideWithValue(messaging),
        localDataProvider.overrideWithValue(
          LocalData(
            workouts: InMemoryWorkoutRepository(),
            program: InMemoryProgramRepository(),
            body: InMemoryBodyRepository(),
            customExercises: InMemoryCustomExerciseRepository(),
            notes: InMemoryNoteRepository(),
            favorites: InMemoryFavoriteRepository(),
          ),
        ),
      ],
    );
  });

  Future<Object?> token(String uid) async =>
      (await fs.collection('users').doc(uid).get()).data()?['fcmToken'];

  test('push стартует после слияния для u1', () async {
    container.read(cloudSyncProvider);
    await container.read(cloudSyncProvider).idle;
    await pumpEventQueue();
    expect(await token('u1'), 't1');
  });

  test('выход останавливает push', () async {
    container.read(cloudSyncProvider);
    await container.read(cloudSyncProvider).idle;
    await pumpEventQueue();
    auth.emit(const SignedOut());
    await pumpEventQueue();
    messaging.refresh.add('late');
    await pumpEventQueue();
    expect(await token('u1'), 't1');
  });

  test(
    'смена u1 → u2: подписки u1 отменены, refresh пишет только в u2',
    () async {
      container.read(cloudSyncProvider);
      await container.read(cloudSyncProvider).idle;
      await pumpEventQueue();
      auth.emit(const SignedIn(uid: 'u2'));
      await pumpEventQueue();
      await container.read(cloudSyncProvider).idle;
      await pumpEventQueue();
      messaging.refresh.add('t2');
      await pumpEventQueue();
      expect(await token('u1'), 't1');
      expect(await token('u2'), 't2');
    },
  );
}
