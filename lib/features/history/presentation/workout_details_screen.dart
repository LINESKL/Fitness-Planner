import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/widgets/max_width.dart';
import '../../../core/widgets/message_view.dart';
import '../../workout/domain/exercise_log.dart';
import '../../workout/domain/set_entry.dart';
import '../../workout/presentation/workout_providers.dart';

/// Тренировка одного дня; [dayKey] — «2026-09-30».
class WorkoutDetailsScreen extends ConsumerWidget {
  const WorkoutDetailsScreen({super.key, required this.dayKey});

  final String dayKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).value ?? const <ExerciseLog>[];
    final logs = workoutsByDay(history)
        .where((day) => formatDayKey(day.first.date) == dayKey)
        .firstOrNull;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(logs == null ? 'Тренировка' : formatDate(logs.first.date)),
      ),
      body: logs == null
          ? const MessageView(
              icon: Icons.event_busy,
              text: 'Тренировка не найдена',
            )
          : MaxWidth(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Объём: ${formatWeight(totalVolume(logs.expand((l) => l.sets)))} кг',
                    style: text.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final log in logs)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.exercise, style: text.titleMedium),
                            const SizedBox(height: 8),
                            for (final set in log.sets)
                              Text(
                                '${formatWeight(set.weight)} кг × ${set.reps}'
                                '${set.isWarmup ? ' (разминка)' : ''}',
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
