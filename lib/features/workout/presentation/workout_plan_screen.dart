import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets/max_width.dart';
import '../../exercises/presentation/pick_exercise.dart';
import '../domain/active_workout.dart';
import 'workout_providers.dart';

/// План идущей тренировки: прогресс по упражнениям, переход, порядок, правка.
class WorkoutPlanScreen extends ConsumerWidget {
  const WorkoutPlanScreen({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, int index) async {
    final name = ref.read(activeWorkoutProvider)!.exercises[index].name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить «$name» из тренировки?'),
        content: const Text(
          'Сделанные подходы этого упражнения не сохранятся.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(activeWorkoutProvider.notifier)
          .update((w) => w.removeExercise(index));
    }
  }

  Future<void> _replace(BuildContext context, WidgetRef ref, int index) async {
    final name = await pickExercise(context);
    if (name != null) {
      await ref
          .read(activeWorkoutProvider.notifier)
          .replaceExercise(index, name);
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final name = await pickExercise(context);
    if (name != null) {
      await ref.read(activeWorkoutProvider.notifier).addExercise(name);
    }
  }

  void _open(BuildContext context, WidgetRef ref, ActiveExercise e, int i) {
    final undone = e.sets.indexWhere((s) => !s.done);
    ref
        .read(activeWorkoutProvider.notifier)
        .update((w) => w.goTo(i, undone < 0 ? 0 : undone));
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    final theme = Theme.of(context);
    if (workout == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('План тренировки')),
      body: MaxWidth(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          buildDefaultDragHandles: false,
          itemCount: workout.exercises.length,
          onReorderItem: (from, to) => ref
              .read(activeWorkoutProvider.notifier)
              .update((w) => w.moveExercise(from, to)),
          footer: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _add(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Упражнение'),
              ),
            ),
          ),
          itemBuilder: (context, i) {
            final e = workout.exercises[i];
            final done = e.sets.where((s) => s.done).length;
            final current = i == workout.cursor.exercise;
            return Padding(
              key: ObjectKey(e),
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: current
                      ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () => _open(context, ref, e, i),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.drag_indicator,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.name, style: theme.textTheme.titleMedium),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: e.sets.isEmpty
                                      ? 0
                                      : done / e.sets.length,
                                  minHeight: 6,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHigh,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$done/${e.sets.length}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: tabularFigures,
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Действия',
                          onSelected: (action) => action == 'replace'
                              ? _replace(context, ref, i)
                              : _remove(context, ref, i),
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'replace',
                              child: Text('Заменить'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Удалить'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
