import '../domain/body.dart';
import '../domain/program.dart';
import '../domain/repositories.dart';
import '../domain/set_entry.dart';
import '../domain/workout.dart';

// «Загрузить пример»: сплит из трёх дней, четыре недели истории с ростом весов
// и замеры тела — чтобы показать приложение без месяца реальных тренировок.

typedef _Plan = ({String exercise, int sets, int min, int max, double start});

const _days = <(String, String, List<_Plan>)>[
  (
    'demo-push',
    'Грудь + трицепс',
    [
      (exercise: 'Жим лёжа', sets: 4, min: 6, max: 8, start: 70),
      (
        exercise: 'Жим гантелей на наклонной',
        sets: 3,
        min: 8,
        max: 10,
        start: 24,
      ),
      (exercise: 'Разводка гантелей', sets: 3, min: 10, max: 12, start: 12),
      (exercise: 'Французский жим', sets: 3, min: 8, max: 10, start: 25),
      (exercise: 'Разгибания на блоке', sets: 3, min: 10, max: 12, start: 30),
    ],
  ),
  (
    'demo-pull',
    'Спина + бицепс',
    [
      (exercise: 'Подтягивания', sets: 4, min: 6, max: 10, start: 0),
      (exercise: 'Тяга штанги в наклоне', sets: 4, min: 6, max: 8, start: 60),
      (exercise: 'Тяга верхнего блока', sets: 3, min: 10, max: 12, start: 50),
      (exercise: 'Сгибания на бицепс', sets: 3, min: 8, max: 10, start: 30),
      (exercise: 'Молотки', sets: 3, min: 10, max: 12, start: 14),
    ],
  ),
  (
    'demo-legs',
    'Ноги',
    [
      (exercise: 'Приседания', sets: 4, min: 5, max: 5, start: 90),
      (exercise: 'Румынская тяга', sets: 3, min: 8, max: 10, start: 70),
      (exercise: 'Жим ногами', sets: 3, min: 10, max: 12, start: 160),
      (exercise: 'Выпады', sets: 3, min: 10, max: 10, start: 16),
      (exercise: 'Икры стоя', sets: 4, min: 12, max: 15, start: 60),
    ],
  ),
];

Future<void> loadDemo(
  WorkoutRepository workouts,
  ProgramRepository program,
  BodyRepository body,
  DateTime now,
) async {
  for (final (id, name, plan) in _days) {
    await program.saveTemplate(
      WorkoutTemplate(
        id: id,
        name: name,
        exercises: [
          for (final p in plan)
            TemplateExercise(
              exercise: p.exercise,
              sets: p.sets,
              repsMin: p.min,
              repsMax: p.max,
            ),
        ],
      ),
    );
  }
  await program.saveProgram(
    Program(templateIds: [for (final (id, _, _) in _days) id]),
  );

  // Пн / Ср / Пт четырёх прошедших недель; день сплита идёт по кругу,
  // каждый следующий круг — +2.5 кг (подтягивания — +1 повтор).
  final monday = DateTime(
    now.year,
    now.month,
    now.day - (now.weekday - 1) - 28,
  );
  var session = 0;
  for (var week = 0; week < 5; week++) {
    for (final offset in const [0, 2, 4]) {
      final start = DateTime(
        monday.year,
        monday.month,
        monday.day + week * 7 + offset,
        18,
      );
      final finish = start.add(const Duration(minutes: 55));
      if (!finish.isBefore(now)) continue;

      final (id, name, plan) = _days[session % _days.length];
      final cycle = session ~/ _days.length;
      session++;
      await workouts.save(
        Workout(
          id: 'demo-w$session',
          title: name,
          templateId: id,
          startedAt: start,
          finishedAt: finish,
          entries: [
            for (final p in plan)
              WorkoutEntry(
                exercise: p.exercise,
                sets: [
                  if (p.start >= 40)
                    SetEntry(
                      weight: p.start / 2,
                      reps: 10,
                      type: SetType.warmup,
                    ),
                  for (var i = 0; i < p.sets; i++)
                    SetEntry(
                      weight: p.start == 0 ? 0 : p.start + cycle * 2.5,
                      reps: p.start == 0
                          ? (p.min + cycle).clamp(p.min, p.max)
                          // Последний подход иногда не добирает — как в жизни.
                          : (i == p.sets - 1 && cycle.isOdd ? p.min : p.max),
                    ),
                ],
              ),
          ],
        ),
      );
    }
  }

  for (var week = 0; week < 5; week++) {
    final date = DateTime(monday.year, monday.month, monday.day + week * 7, 8);
    if (date.isAfter(now)) continue;
    await body.save(
      BodyEntry(
        id: 'demo-b$week',
        date: date,
        weightKg: 79.2 - week * 0.2,
        waistCm: 82 - week * 0.3,
      ),
    );
  }
}
