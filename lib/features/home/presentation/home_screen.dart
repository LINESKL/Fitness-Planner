import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../workout/data/sample_data.dart';
import '../../workout/domain/exercise_log.dart';
import '../../workout/domain/set_entry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.history,
    required this.onStartWorkout,
  });

  final List<ExerciseLog> history;
  final VoidCallback onStartWorkout;

  @override
  Widget build(BuildContext context) {
    final last = workoutsByDay(history).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StartCard(onStart: onStartWorkout),
        const SizedBox(height: 16),
        if (last != null) _LastWorkoutCard(logs: last),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.directions_walk),
            title: Text('— шагов'),
            subtitle: Text('Сегодня'),
          ),
        ),
      ],
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      color: scheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.fitness_center,
              size: 120,
              color: scheme.onPrimaryContainer.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Готов к тренировке?',
                  style: text.titleLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  sampleTodayPlan.join(' · '),
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Начать тренировку'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LastWorkoutCard extends StatelessWidget {
  const _LastWorkoutCard({required this.logs});

  final List<ExerciseLog> logs;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final volume = totalVolume(logs.expand((l) => l.sets));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Последняя тренировка', style: text.titleMedium),
                ),
                Text(formatDate(logs.first.date), style: text.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            for (final log in logs)
              Text(
                '${log.exercise} — '
                '${log.sets.where((s) => !s.isWarmup).length} подх.',
              ),
            const SizedBox(height: 8),
            Text('Объём: ${formatWeight(volume)} кг', style: text.labelLarge),
          ],
        ),
      ),
    );
  }
}
