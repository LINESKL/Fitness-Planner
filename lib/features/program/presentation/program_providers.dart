import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workout/domain/program.dart';
import '../../workout/presentation/workout_providers.dart';

/// Шаблоны дней (все, в том числе не вошедшие в программу).
final templatesProvider =
    AsyncNotifierProvider<TemplatesNotifier, List<WorkoutTemplate>>(
      TemplatesNotifier.new,
    );

class TemplatesNotifier extends AsyncNotifier<List<WorkoutTemplate>> {
  @override
  Future<List<WorkoutTemplate>> build() =>
      ref.watch(programRepositoryProvider).templates();

  Future<void> save(WorkoutTemplate template) async {
    await ref.read(programRepositoryProvider).saveTemplate(template);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(programRepositoryProvider).deleteTemplate(id);
    ref.invalidateSelf();
    await future;
  }
}

/// Порядок дней сплита.
final programProvider = AsyncNotifierProvider<ProgramNotifier, Program>(
  ProgramNotifier.new,
);

class ProgramNotifier extends AsyncNotifier<Program> {
  @override
  Future<Program> build() => ref.watch(programRepositoryProvider).program();

  Future<void> save(Program program) async {
    await ref.read(programRepositoryProvider).saveProgram(program);
    ref.invalidateSelf();
    await future;
  }
}

/// Дни программы, которые существуют, в порядке сплита.
final programDaysProvider = FutureProvider<List<WorkoutTemplate>>((ref) async {
  final program = await ref.watch(programProvider.future);
  final byId = {
    for (final t in await ref.watch(templatesProvider.future)) t.id: t,
  };
  return [for (final id in program.templateIds) ?byId[id]];
});

/// Следующий день сплита; null — программы нет.
final nextTemplateProvider = FutureProvider<WorkoutTemplate?>((ref) async {
  return nextTemplate(
    await ref.watch(programProvider.future),
    await ref.watch(templatesProvider.future),
    await ref.watch(workoutsProvider.future),
  );
});
