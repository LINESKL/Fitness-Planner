import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/max_width.dart';
import '../../../core/widgets/message_view.dart';
import '../../workout/domain/set_entry.dart';
import '../../workout/domain/stats.dart';
import '../../workout/domain/workout.dart';
import '../../workout/presentation/set_format.dart';
import '../../workout/presentation/workout_providers.dart';

const setTypeLabels = {
  SetType.normal: '',
  SetType.warmup: 'разминка',
  SetType.failure: 'до отказа',
  SetType.drop: 'дроп-сет',
};

class WorkoutDetailsScreen extends ConsumerWidget {
  const WorkoutDetailsScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider);
    final workout = workouts.value?.where((w) => w.id == workoutId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(workout?.title ?? 'Тренировка')),
      body: switch ((workouts, workout)) {
        (_, final Workout w) => _Details(workout: w),
        (AsyncLoading(), _) => const Center(child: CircularProgressIndicator()),
        _ => const MessageView(
          icon: Icons.event_busy,
          text: 'Тренировка не найдена',
        ),
      },
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = text.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${formatLongDate(workout.startedAt)} · ${workout.duration.inMinutes} мин',
            style: muted,
          ),
          const SizedBox(height: 12),
          Text('ОБЪЁМ', style: text.labelSmall),
          Text(
            formatTonnage(workout.volume),
            style: text.headlineMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontFeatures: tabularFigures,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in workout.entries) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.exercise, style: text.titleMedium),
                    const SizedBox(height: 8),
                    for (final set in entry.sets)
                      Text(
                        [
                          '${formatLoad(set.weight)} × ${set.reps}',
                          if (set.type != SetType.normal)
                            setTypeLabels[set.type],
                          if (set.rpe != null) 'RPE ${formatWeight(set.rpe!)}',
                        ].join(' · '),
                        style: const TextStyle(fontFeatures: tabularFigures),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
