import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/message_view.dart';
import '../../workout/domain/program.dart';
import '../../workout/domain/workout.dart';
import '../../workout/presentation/workout_providers.dart';
import 'program_providers.dart';

/// «3 × 5» или «3 × 8–10».
String formatTarget(TemplateExercise e) =>
    '${e.sets} × ${e.repsMin == e.repsMax ? e.repsMin : '${e.repsMin}–${e.repsMax}'}';

class ProgramScreen extends ConsumerStatefulWidget {
  const ProgramScreen({super.key});

  @override
  ConsumerState<ProgramScreen> createState() => _ProgramScreenState();
}

class _ProgramScreenState extends ConsumerState<ProgramScreen> {
  String? _expanded;

  void _newDay() => context.pushNamed(
    'templateEditor',
    pathParameters: {'templateId': 'new'},
  );

  Future<void> _reorder(List<WorkoutTemplate> days, int from, int to) async {
    final ids = [for (final d in days) d.id];
    ids.insert(to, ids.removeAt(from));
    await ref.read(programProvider.notifier).save(Program(templateIds: ids));
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(programDaysProvider);
    final next = ref.watch(nextTemplateProvider).value;
    final workouts = ref.watch(workoutsProvider).value ?? const <Workout>[];
    final lastDone = <String, DateTime>{};
    for (final w in workouts) {
      final id = w.templateId;
      if (id != null && !(lastDone[id]?.isAfter(w.startedAt) ?? false)) {
        lastDone[id] = w.startedAt;
      }
    }

    return days.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => MessageView(
        icon: Icons.error_outline,
        text: 'Не удалось загрузить программу',
        actionLabel: 'Повторить',
        onAction: () => ref.invalidate(programDaysProvider),
      ),
      data: (days) => days.isEmpty
          ? MessageView(
              icon: Icons.view_list_outlined,
              text: 'Добавьте первый день сплита',
              actionLabel: 'Новый день',
              onAction: _newDay,
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              buildDefaultDragHandles: false,
              itemCount: days.length,
              onReorderItem: (from, to) => _reorder(days, from, to),
              footer: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _newDay,
                    icon: const Icon(Icons.add),
                    label: const Text('Новый день'),
                  ),
                ),
              ),
              itemBuilder: (context, i) {
                final day = days[i];
                return Padding(
                  key: ValueKey(day.id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DayCard(
                    index: i,
                    day: day,
                    isNext: next?.id == day.id,
                    lastDone: lastDone[day.id],
                    expanded: _expanded == day.id,
                    onToggle: () => setState(
                      () => _expanded = _expanded == day.id ? null : day.id,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.index,
    required this.day,
    required this.isNext,
    required this.lastDone,
    required this.expanded,
    required this.onToggle,
  });

  final int index;
  final WorkoutTemplate day;
  final bool isNext;
  final DateTime? lastDone;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final count = day.exercises.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: isNext
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.drag_indicator,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '$count ${pluralRu(count, 'упражнение', 'упражнения', 'упражнений')}'
                          ' · ${lastDone == null ? 'ещё не был' : 'был ${formatDate(lastDone!)}'}',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  if (isNext)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'следующий',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 8),
                for (final e in day.exercises)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 4, 0, 4),
                    child: Row(
                      children: [
                        Expanded(child: Text(e.exercise)),
                        Text(
                          formatTarget(e),
                          style: muted?.copyWith(fontFeatures: tabularFigures),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: TextButton(
                    onPressed: () => context.pushNamed(
                      'templateEditor',
                      pathParameters: {'templateId': day.id},
                    ),
                    child: const Text('Изменить день'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
