// ignore_for_file: subtype_of_sealed_class, мок ссылок Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitness_planner/features/workout/data/cloud/synced_repositories.dart';
import 'package:fitness_planner/features/workout/data/cloud/user_cloud.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/data/json_mappers.dart';
import 'package:fitness_planner/features/workout/domain/body.dart';
import 'package:fitness_planner/features/workout/domain/exercise.dart';
import 'package:fitness_planner/features/workout/domain/program.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDoc extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

/// Облако, у которого коллекции бросают сразу.
class _ThrowingCloud extends UserCloud {
  _ThrowingCloud(super.user);
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) =>
      throw StateError('облако недоступно');
  @override
  DocumentReference<Map<String, dynamic>> meta(String name) =>
      throw StateError('облако недоступно');
}

final _workout = Workout(
  id: 'w1',
  title: 'Грудь',
  startedAt: DateTime(2026, 1, 1, 10),
  finishedAt: DateTime(2026, 1, 1, 11),
  entries: const [
    WorkoutEntry(exercise: 'Жим', sets: [SetEntry(weight: 50, reps: 10)]),
  ],
);

void main() {
  late FakeFirebaseFirestore fs;
  late UserCloud cloud;
  setUp(() {
    fs = FakeFirebaseFirestore();
    cloud = UserCloud(fs.collection('users').doc('u1'));
  });

  Future<Map<String, dynamic>?> doc(String path) async =>
      (await fs.doc('users/u1/$path').get()).data();

  test('save тренировки: локально и в users/u1/workouts/{id}', () async {
    final local = InMemoryWorkoutRepository();
    await SyncedWorkoutRepository(local, cloud).save(_workout);
    expect((await local.all()).single.id, 'w1');
    expect(await doc('workouts/w1'), workoutToJson(_workout));
  });

  test('delete тренировки удаляет в обоих местах', () async {
    final local = InMemoryWorkoutRepository();
    final repo = SyncedWorkoutRepository(local, cloud);
    await repo.save(_workout);
    await repo.delete('w1');
    expect(await local.all(), isEmpty);
    expect(await doc('workouts/w1'), isNull);
  });

  test('замер: в облаке нет photoPath, локально есть', () async {
    final local = InMemoryBodyRepository();
    final entry = BodyEntry(
      id: 'b1',
      date: DateTime(2026, 1, 1),
      weightKg: 80,
      photoPath: '/p.jpg',
    );
    await SyncedBodyRepository(local, cloud).save(entry);
    expect((await local.all()).single.photoPath, '/p.jpg');
    final remote = await doc('body/b1');
    expect(remote, isNotNull);
    expect(remote!.containsKey('photoPath'), isFalse);
    expect(remote['weightKg'], 80);
  });

  test('заметка с «/» в названии создаёт документ', () async {
    final local = InMemoryNoteRepository();
    await SyncedNoteRepository(
      local,
      cloud,
    ).setNote('Жим / гантели', ' сиденье 4 ');
    expect(await local.note('Жим / гантели'), 'сиденье 4');
    expect(await doc('notes/Жим ∕ гантели'), {
      'exercise': 'Жим / гантели',
      'text': 'сиденье 4',
    });
  });

  test('пустая заметка удаляет документ', () async {
    final repo = SyncedNoteRepository(InMemoryNoteRepository(), cloud);
    await repo.setNote('Жим', 'a');
    await repo.setNote('Жим', '  ');
    expect(await doc('notes/Жим'), isNull);
  });

  test('избранное: ids в облаке совпадают с локальным множеством', () async {
    final local = InMemoryFavoriteRepository();
    final repo = SyncedFavoriteRepository(local, cloud);
    await repo.toggle('a');
    await repo.toggle('b');
    await repo.toggle('a');
    expect(await local.all(), {'b'});
    expect((await doc('meta/favorites'))!['ids'], ['b']);
  });

  test('программа: saveTemplate и saveProgram', () async {
    final local = InMemoryProgramRepository();
    final repo = SyncedProgramRepository(local, cloud);
    const t = WorkoutTemplate(id: 't1', name: 'A', exercises: []);
    await repo.saveTemplate(t);
    await repo.saveProgram(const Program(templateIds: ['t1']));
    expect(await doc('templates/t1'), templateToJson(t));
    expect(await doc('meta/program'), {
      'templateIds': ['t1'],
    });
    await repo.deleteTemplate('t1');
    expect(await doc('templates/t1'), isNull);
    expect(await local.templates(), isEmpty);
  });

  test('свои упражнения: save и delete', () async {
    final local = InMemoryCustomExerciseRepository();
    final repo = SyncedCustomExerciseRepository(local, cloud);
    const e = Exercise(id: 'c1', name: 'X', muscleGroup: 'Спина');
    await repo.save(e);
    expect(await doc('customExercises/c1'), exerciseToJson(e));
    await repo.delete('c1');
    expect(await doc('customExercises/c1'), isNull);
  });

  group('сбой облака не мешает локальной записи', () {
    test('синхронный бросок', () async {
      final local = InMemoryWorkoutRepository();
      final notes = InMemoryNoteRepository();
      final bad = _ThrowingCloud(fs.collection('users').doc('u1'));
      await SyncedWorkoutRepository(local, bad).save(_workout);
      await SyncedNoteRepository(notes, bad).setNote('Жим', 'a');
      expect((await local.all()).single.id, 'w1');
      expect(await notes.note('Жим'), 'a');
    });

    test('асинхронная ошибка set/delete', () async {
      final local = InMemoryWorkoutRepository();
      final d = _MockDoc();
      when(() => d.set(any())).thenAnswer((_) => Future.error(StateError('x')));
      when(d.delete).thenAnswer((_) => Future.error(StateError('x')));
      final c = _MockCollection();
      when(() => c.doc(any())).thenReturn(d);
      final bad = _MockUserCloud(c);
      final repo = SyncedWorkoutRepository(local, bad);
      await repo.save(_workout);
      await repo.delete('w1');
      await Future<void>.delayed(Duration.zero);
      expect(await local.all(), isEmpty);
      verify(() => d.set(any())).called(1);
    });
  });
}

class _MockUserCloud extends UserCloud {
  _MockUserCloud(this._c) : super(_MockDoc());
  final CollectionReference<Map<String, dynamic>> _c;
  @override
  CollectionReference<Map<String, dynamic>> collection(String name) => _c;
}
