import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/message_view.dart';
import '../../workout/domain/progress_rules.dart';
import '../../workout/domain/workout.dart';
import '../../workout/presentation/set_format.dart';
import '../../workout/presentation/workout_providers.dart';
import 'progress_screen.dart';

/// Лучший подход каждого упражнения; свежие рекорды первыми.
class RecordsTab extends ConsumerWidget {
  const RecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider).value ?? const <Workout>[];
    final bests = personalBests(workouts);
    final theme = Theme.of(context);

    if (bests.isEmpty) {
      return const MessageView(
        icon: Icons.emoji_events_outlined,
        text: 'Рекорды появятся после первых тренировок',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: bests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = bests[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.exercise, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        b.set.weight == 0
                            ? formatDate(b.date)
                            : '1ПМ ≈ ${formatKg(b.set.oneRepMax)} кг · ${formatDate(b.date)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatSet(b.set),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
