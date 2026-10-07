import '../domain/active_workout.dart';
import '../domain/body.dart';
import '../domain/exercise.dart';
import '../domain/program.dart';
import '../domain/set_entry.dart';
import '../domain/workout.dart';

// JSON-представление сущностей для Hive (и позже Firestore).
// Только примитивы, списки и карты — без адаптеров и кодогенерации.

typedef Json = Map<String, Object?>;

Json _cast(Object? value) => Map<String, Object?>.from(value! as Map);

List<Json> _list(Object? value) => [for (final v in value! as List) _cast(v)];

double? _double(Object? v) => (v as num?)?.toDouble();

Json setToJson(SetEntry s) => {
  'weight': s.weight,
  'reps': s.reps,
  'type': s.type.name,
  'rpe': s.rpe,
};

SetEntry setFromJson(Json j) => SetEntry(
  weight: _double(j['weight'])!,
  reps: j['reps']! as int,
  type: SetType.values.byName(j['type'] as String? ?? 'normal'),
  rpe: _double(j['rpe']),
);

Json workoutToJson(Workout w) => {
  'id': w.id,
  'title': w.title,
  'templateId': w.templateId,
  'startedAt': w.startedAt.toIso8601String(),
  'finishedAt': w.finishedAt.toIso8601String(),
  'entries': [
    for (final e in w.entries)
      {
        'exercise': e.exercise,
        'sets': [for (final s in e.sets) setToJson(s)],
      },
  ],
};

Workout workoutFromJson(Json j) => Workout(
  id: j['id']! as String,
  title: j['title']! as String,
  templateId: j['templateId'] as String?,
  startedAt: DateTime.parse(j['startedAt']! as String),
  finishedAt: DateTime.parse(j['finishedAt']! as String),
  entries: [
    for (final e in _list(j['entries']))
      WorkoutEntry(
        exercise: e['exercise']! as String,
        sets: [for (final s in _list(e['sets'])) setFromJson(s)],
      ),
  ],
);

Json templateToJson(WorkoutTemplate t) => {
  'id': t.id,
  'name': t.name,
  'exercises': [
    for (final e in t.exercises)
      {
        'exercise': e.exercise,
        'sets': e.sets,
        'repsMin': e.repsMin,
        'repsMax': e.repsMax,
      },
  ],
};

WorkoutTemplate templateFromJson(Json j) => WorkoutTemplate(
  id: j['id']! as String,
  name: j['name']! as String,
  exercises: [
    for (final e in _list(j['exercises']))
      TemplateExercise(
        exercise: e['exercise']! as String,
        sets: e['sets']! as int,
        repsMin: e['repsMin']! as int,
        repsMax: e['repsMax']! as int,
      ),
  ],
);

Json programToJson(Program p) => {'templateIds': p.templateIds};

Program programFromJson(Json j) => Program(
  templateIds: [for (final id in j['templateIds']! as List) id as String],
);

Json bodyToJson(BodyEntry b) => {
  'id': b.id,
  'date': b.date.toIso8601String(),
  'weightKg': b.weightKg,
  'waistCm': b.waistCm,
  'chestCm': b.chestCm,
};

BodyEntry bodyFromJson(Json j) => BodyEntry(
  id: j['id']! as String,
  date: DateTime.parse(j['date']! as String),
  weightKg: _double(j['weightKg'])!,
  waistCm: _double(j['waistCm']),
  chestCm: _double(j['chestCm']),
);

Json exerciseToJson(Exercise e) => {
  'id': e.id,
  'name': e.name,
  'muscleGroup': e.muscleGroup,
  'imageUrl': e.imageUrl,
};

Exercise exerciseFromJson(Json j) => Exercise(
  id: j['id']! as String,
  name: j['name']! as String,
  muscleGroup: j['muscleGroup']! as String,
  imageUrl: j['imageUrl'] as String?,
);

Json activeWorkoutToJson(ActiveWorkout w) => {
  'startedAt': w.startedAt.toIso8601String(),
  'title': w.title,
  'templateId': w.templateId,
  'cursor': [w.cursor.exercise, w.cursor.set],
  'phase': w.phase.name,
  'restEndsAt': w.restEndsAt?.toIso8601String(),
  'exercises': [
    for (final e in w.exercises)
      {
        'name': e.name,
        'target': e.target == null ? null : [e.target!.min, e.target!.max],
        'sets': [
          for (final s in e.sets)
            {
              'weight': s.weight,
              'reps': s.reps,
              'done': s.done,
              'type': s.type.name,
              'rpe': s.rpe,
              'increased': s.increased,
            },
        ],
      },
  ],
};

ActiveWorkout activeWorkoutFromJson(Json j) {
  final cursor = j['cursor']! as List;
  final restEndsAt = j['restEndsAt'] as String?;
  return ActiveWorkout(
    startedAt: DateTime.parse(j['startedAt']! as String),
    title: j['title']! as String,
    templateId: j['templateId'] as String?,
    cursor: (exercise: cursor[0] as int, set: cursor[1] as int),
    phase: WorkoutPhase.values.byName(j['phase']! as String),
    restEndsAt: restEndsAt == null ? null : DateTime.parse(restEndsAt),
    exercises: [
      for (final e in _list(j['exercises']))
        ActiveExercise(
          name: e['name']! as String,
          target: switch (e['target']) {
            [final int min, final int max] => (min: min, max: max),
            _ => null,
          },
          sets: [
            for (final s in _list(e['sets']))
              WorkoutSet(
                weight: _double(s['weight'])!,
                reps: s['reps']! as int,
                done: s['done']! as bool,
                type: SetType.values.byName(s['type']! as String),
                rpe: _double(s['rpe']),
                increased: s['increased']! as bool,
              ),
          ],
        ),
    ],
  );
}
