import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/message_view.dart';
import '../../workout/domain/exercise_log.dart';
import '../../workout/domain/stats.dart';
import '../../workout/presentation/workout_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(historyProvider)) {
      AsyncData(:final value) when value.isEmpty => const MessageView(
        icon: Icons.event_note,
        text: 'Здесь появятся завершённые тренировки',
      ),
      AsyncData(:final value) => _HistoryList(workouts: workoutsByDay(value)),
      AsyncError() => MessageView(
        icon: Icons.error_outline,
        text: 'Не удалось загрузить историю',
        actionLabel: 'Повторить',
        onAction: () => ref.invalidate(historyProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.workouts});

  final List<List<ExerciseLog>> workouts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: workouts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final logs = workouts[i];
        final volume = totalVolume(logs.expand((l) => l.sets));

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.pushNamed(
              'workoutDetails',
              pathParameters: {'day': formatDayKey(logs.first.date)},
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatDate(logs.first.date),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          logs.map((l) => l.exercise).join(' · '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatTonnage(volume),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
