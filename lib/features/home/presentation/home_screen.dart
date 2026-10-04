import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../workout/data/sample_data.dart';
import '../../workout/domain/exercise_log.dart';
import '../../workout/domain/set_entry.dart';
import '../../workout/presentation/workout_store.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onStartWorkout});

  final VoidCallback onStartWorkout;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();
    final last = workoutsByDay(store.history).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StartCard(onStart: onStartWorkout, inProgress: store.active != null),
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
  const _StartCard({required this.onStart, required this.inProgress});

  final VoidCallback onStart;
  final bool inProgress;

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
                  inProgress ? 'Тренировка идёт' : 'Готов к тренировке?',
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
                  label: Text(
                    inProgress ? 'Продолжить тренировку' : 'Начать тренировку',
                  ),
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
