import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:fitness_planner/features/auth/presentation/auth_providers.dart';
import 'package:fitness_planner/features/workout/data/cloud/cloud_sync.dart';
import 'package:fitness_planner/features/workout/data/cloud/user_cloud.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/data/json_mappers.dart';
import 'package:fitness_planner/features/workout/domain/body.dart';
import 'package:fitness_planner/features/workout/domain/program.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Workout _w(String id, String title) => Workout(
  id: id,
  title: title,
  startedAt: DateTime(2026, 1, 1, 10),
  finishedAt: DateTime(2026, 1, 1, 11),
  entries: const [],
);

class _Auth implements AuthRepository {
  final controller = StreamController<AuthState>();
  @override
  AuthState get current => const Guest();
  @override
  Stream<AuthState> changes() => controller.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late FakeFirebaseFirestore fs;
  late UserCloud cloud;
  late LocalData local;
  late InMemoryWorkoutRepository workouts;
  late InMemoryProgramRepository program;
  late InMemoryBodyRepository body;
  late InMemoryNoteRepository notes;
  late InMemoryFavoriteRepository favorites;

  setUp(() {
    fs = FakeFirebaseFirestore();
    cloud = UserCloud(fs.collection('users').doc('u1'));
    workouts = InMemoryWorkoutRepository();
    program = InMemoryProgramRepository();
    body = InMemoryBodyRepository();
    notes = InMemoryNoteRepository();
    favorites = InMemoryFavoriteRepository();
    local = LocalData(
      workouts: workouts,
      program: program,
      body: body,
      customExercises: InMemoryCustomExerciseRepository(),
      notes: notes,
      favorites: favorites,
    );
  });

  Future<Map<String, dynamic>?> doc(String path) async =>
      (await fs.doc('users/u1/$path').get()).data();

  Future<void> merge() => CloudSync(local, cloud).merge();

  test('тренировки: облако и телефон объединяются в обе стороны', () async {
    await cloud
        .collection('workouts')
        .doc('w1')
        .set(workoutToJson(_w('w1', 'A')));
    await workouts.save(_w('w2', 'B'));
    await merge();
    expect((await workouts.all()).map((w) => w.id).toSet(), {'w1', 'w2'});
    expect(await doc('workouts/w1'), isNotNull);
    expect(await doc('workouts/w2'), workoutToJson(_w('w2', 'B')));
  });

  test('одинаковый id: локальная копия заменена облачной', () async {
    await cloud
        .collection('workouts')
        .doc('w1')
        .set(workoutToJson(_w('w1', 'Облако')));
    await workouts.save(_w('w1', 'Телефон'));
    await merge();
    expect((await workouts.all()).single.title, 'Облако');
    expect((await doc('workouts/w1'))!['title'], 'Облако');
  });

  test('избранное: объединение попадает в оба места', () async {
    await cloud.meta('favorites').set({
      'ids': ['a'],
    });
    await favorites.toggle('b');
    await merge();
    expect(await favorites.all(), {'a', 'b'});
    expect((await doc('meta/favorites'))!['ids'], ['a', 'b']);
  });

  test('программа: есть облачная — берётся её порядок', () async {
    await cloud
        .meta('program')
        .set(programToJson(const Program(templateIds: ['t2', 't1'])));
    await program.saveProgram(const Program(templateIds: ['t1']));
    await merge();
    expect((await program.program()).templateIds, ['t2', 't1']);
  });

  test('программа: облачной нет — локальная загружается', () async {
    await program.saveProgram(const Program(templateIds: ['t1', 't3']));
    await merge();
    expect((await doc('meta/program'))!['templateIds'], ['t1', 't3']);
  });

  test('заметки идут в обе стороны, облако побеждает', () async {
    await cloud.collection('notes').doc(noteDocId('Жим')).set({
      'exercise': 'Жим',
      'text': 'облако',
    });
    await notes.setNote('Жим', 'телефон');
    await notes.setNote('Тяга/косая', 'локально');
    await merge();
    expect(await notes.note('Жим'), 'облако');
    expect(
      (await doc('notes/${noteDocId('Тяга/косая')}'))!['text'],
      'локально',
    );
  });

  test('замер из облака сохраняет локальный photoPath', () async {
    final date = DateTime(2026, 1, 1);
    await cloud
        .collection('body')
        .doc('b1')
        .set(bodyToCloudJson(BodyEntry(id: 'b1', date: date, weightKg: 79)));
    await body.save(
      BodyEntry(id: 'b1', date: date, weightKg: 80, photoPath: '/p.jpg'),
    );
    await merge();
    final e = (await body.all()).single;
    expect(e.weightKg, 79);
    expect(e.photoPath, '/p.jpg');
  });

  test('сбой облака не роняет и не трогает локальные данные', () async {
    await workouts.save(_w('w2', 'B'));
    await CloudSync(
      local,
      _BrokenCloud(fs.collection('users').doc('u1')),
    ).merge();
    expect((await workouts.all()).single.id, 'w2');
  });

  test('cloudSyncProvider: Guest → SignedIn запускает merge', () async {
    await cloud
        .collection('workouts')
        .doc('w1')
        .set(workoutToJson(_w('w1', 'A')));
    final auth = _Auth();
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        firestoreProvider.overrideWithValue(fs),
        localDataProvider.overrideWithValue(local),
      ],
    );
    container.listen(cloudSyncProvider, (_, _) {});
    container.read(authProvider);
    auth.controller.add(const SignedIn(uid: 'u1'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await workouts.all()).single.id, 'w1');
  });
}

class _BrokenCloud extends UserCloud {
  _BrokenCloud(super.user);
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      throw StateError('облако недоступно');
  @override
  DocumentReference<Map<String, dynamic>> meta(String name) =>
      throw StateError('облако недоступно');
}
