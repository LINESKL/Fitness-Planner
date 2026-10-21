import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitness_planner/core/push_service.dart';
import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:fitness_planner/features/auth/presentation/auth_providers.dart';
import 'package:fitness_planner/features/workout/data/cloud/cloud_sync.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/repositories.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Workout _w(String id) => Workout(
  id: id,
  title: id,
  startedAt: DateTime(2026, 1, 1, 10),
  finishedAt: DateTime(2026, 1, 1, 11),
  entries: const [],
);

class _Auth implements AuthRepository {
  _Auth(this.current);

  final controller = StreamController<AuthState>();
  @override
  AuthState current;
  @override
  Stream<AuthState> changes() => controller.stream;
  @override
  Future<void> signOut() async {
    current = const SignedOut();
    controller.add(current);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Messaging implements PushMessaging {
  int deleted = 0;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<String?> token() async => null;
  @override
  Future<void> deleteToken() async => deleted++;
  @override
  Stream<String> tokenRefresh() => const Stream.empty();
  @override
  Stream<({String? title, String? body})> foreground() => const Stream.empty();
}

/// Чтение тренировок никогда не заканчивается — слияние «зависло».
class _StuckWorkouts extends InMemoryWorkoutRepository {
  @override
  Future<List<Workout>> all() => Completer<List<Workout>>().future;
}

LocalData _local(WorkoutRepository workouts) => LocalData(
  workouts: workouts,
  program: InMemoryProgramRepository(),
  body: InMemoryBodyRepository(),
  customExercises: InMemoryCustomExerciseRepository(),
  notes: InMemoryNoteRepository(),
  favorites: InMemoryFavoriteRepository(),
);

const _pause = Duration(milliseconds: 50);

void main() {
  late FakeFirebaseFirestore fs;

  setUp(() => fs = FakeFirebaseFirestore());

  Future<SharedPreferences> prefs([Map<String, Object> values = const {}]) {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  test('выход убирает fcmToken из облака и токен с устройства', () async {
    await fs.doc('users/u1').set({'fcmToken': 't1', 'name': 'x'});
    final messaging = _Messaging();
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _Auth(const SignedIn(uid: 'u1')),
        ),
        firestoreProvider.overrideWithValue(fs),
        pushMessagingProvider.overrideWithValue(messaging),
      ],
    );
    container.read(authProvider);

    await container.read(signOutAndWipeProvider)();

    final data = (await fs.doc('users/u1').get()).data()!;
    expect(data.containsKey('fcmToken'), isFalse);
    expect(data['name'], 'x');
    expect(messaging.deleted, 1);
  });

  test('зависшее слияние не мешает очистке: ждём не дольше 5 секунд', () async {
    final log = <String>[];
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _Auth(const SignedIn(uid: 'u1')),
        ),
        firestoreProvider.overrideWithValue(fs),
        localDataProvider.overrideWithValue(_local(_StuckWorkouts())),
        localDataWiperProvider.overrideWithValue(() async => log.add('wipe')),
      ],
    );
    container.listen(cloudSyncProvider, (_, _) {});
    container.read(authProvider);
    await Future<void>.delayed(_pause);

    await container.read(signOutAndWipeProvider)();
    expect(log, ['wipe']);
  });

  test('очистка упала: данные всё равно перечитываются', () async {
    final repo = InMemoryWorkoutRepository();
    await repo.save(_w('w1'));
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _Auth(const SignedIn(uid: 'u1')),
        ),
        workoutRepositoryProvider.overrideWithValue(repo),
        localDataWiperProvider.overrideWithValue(
          () async => throw StateError('диск'),
        ),
      ],
    );
    container.read(authProvider);
    expect(await container.read(workoutsProvider.future), hasLength(1));
    await repo.delete('w1');

    await expectLater(
      container.read(signOutAndWipeProvider)(),
      throwsStateError,
    );
    expect(await container.read(workoutsProvider.future), isEmpty);
  });

  group('смена аккаунта без обычного выхода', () {
    test(
      'в телефоне данные u1, входит u2: очистка до слияния, чужое не уходит',
      () async {
        final p = await prefs({'synced_uid': 'u1'});
        final repo = InMemoryWorkoutRepository();
        await repo.save(_w('mine-u1'));
        final log = <String>[];
        final container = ProviderContainer.test(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _Auth(const SignedIn(uid: 'u2')),
            ),
            firestoreProvider.overrideWithValue(fs),
            syncPrefsProvider.overrideWithValue(p),
            localDataProvider.overrideWithValue(_local(repo)),
            localDataWiperProvider.overrideWithValue(() async {
              log.add('wipe');
              for (final w in await repo.all()) {
                await repo.delete(w.id);
              }
            }),
          ],
        );
        container.listen(cloudSyncProvider, (_, _) {});
        container.read(authProvider);
        await Future<void>.delayed(_pause);

        expect(log, ['wipe']);
        expect((await fs.collection('users/u2/workouts').get()).docs, isEmpty);
        expect(p.getString('synced_uid'), 'u2');
      },
    );

    test(
      'гость первый раз входит: данные остаются и уходят в облако',
      () async {
        final p = await prefs();
        final repo = InMemoryWorkoutRepository();
        await repo.save(_w('guest'));
        var wiped = false;
        final container = ProviderContainer.test(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _Auth(const SignedIn(uid: 'u1')),
            ),
            firestoreProvider.overrideWithValue(fs),
            syncPrefsProvider.overrideWithValue(p),
            localDataProvider.overrideWithValue(_local(repo)),
            localDataWiperProvider.overrideWithValue(() async => wiped = true),
          ],
        );
        container.listen(cloudSyncProvider, (_, _) {});
        container.read(authProvider);
        await Future<void>.delayed(_pause);

        expect(wiped, isFalse);
        expect((await fs.doc('users/u1/workouts/guest').get()).exists, isTrue);
        expect(p.getString('synced_uid'), 'u1');
      },
    );

    test('обычный выход стирает synced_uid', () async {
      final p = await prefs({'synced_uid': 'u1'});
      final container = ProviderContainer.test(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _Auth(const SignedIn(uid: 'u1')),
          ),
          syncPrefsProvider.overrideWithValue(p),
        ],
      );
      container.read(authProvider);

      await container.read(signOutAndWipeProvider)();
      expect(p.containsKey('synced_uid'), isFalse);
    });
  });
}
