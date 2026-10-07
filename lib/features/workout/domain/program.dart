import 'workout.dart';

/// Упражнение в шаблоне дня: сколько подходов и в каком диапазоне повторов.
class TemplateExercise {
  const TemplateExercise({
    required this.exercise,
    required this.sets,
    required this.repsMin,
    required this.repsMax,
  });

  final String exercise;
  final int sets;
  final int repsMin;
  final int repsMax;
}

/// День сплита: «Грудь + трицепс», «Ноги»…
class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.exercises,
  });

  final String id;
  final String name;
  final List<TemplateExercise> exercises;
}

/// Сплит — дни по кругу в заданном порядке.
class Program {
  const Program({required this.templateIds});

  final List<String> templateIds;
}

/// Дни программы, которые реально существуют, в порядке программы.
List<WorkoutTemplate> _days(Program program, List<WorkoutTemplate> templates) {
  final byId = {for (final t in templates) t.id: t};
  return [for (final id in program.templateIds) ?byId[id]];
}

/// Следующий день: после дня самой поздней тренировки по программе; иначе первый.
WorkoutTemplate? nextTemplate(
  Program program,
  List<WorkoutTemplate> templates,
  List<Workout> workouts,
) {
  final days = _days(program, templates);
  if (days.isEmpty) return null;

  Workout? last;
  for (final w in workouts) {
    final inProgram = days.any((d) => d.id == w.templateId);
    if (inProgram && (last == null || w.startedAt.isAfter(last.startedAt))) {
      last = w;
    }
  }
  if (last == null) return days.first;

  final index = days.indexWhere((d) => d.id == last!.templateId);
  return days[(index + 1) % days.length];
}

/// «День 2 из 3»; null — шаблона нет в программе.
({int index, int total})? dayPosition(
  Program program,
  List<WorkoutTemplate> templates,
  String templateId,
) {
  final days = _days(program, templates);
  final index = days.indexWhere((d) => d.id == templateId);
  return index < 0 ? null : (index: index + 1, total: days.length);
}
