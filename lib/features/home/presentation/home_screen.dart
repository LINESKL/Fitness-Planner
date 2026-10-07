import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../workout/domain/exercise_log.dart';
import '../../workout/domain/stats.dart';
import '../../workout/presentation/workout_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    await ref.read(activeWorkoutProvider.notifier).start();
    if (context.mounted) await context.pushNamed('workout');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).value ?? const <ExerciseLog>[];
    final last = workoutsByDay(history).firstOrNull;
    final inProgress = ref.watch(activeWorkoutProvider) != null;
    final now = DateTime.now();
    final week = weekStats(history, now);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          formatLongDate(now).toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 12),
        _StartCard(
          onStart: () => _start(context, ref),
          inProgress: inProgress,
          plan: [for (final log in last ?? const <ExerciseLog>[]) log.exercise],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'ЗА НЕДЕЛЮ',
                  value: '${week.workouts}',
                  accent: true,
                  caption: pluralRu(
                    week.workouts,
                    'тренировка',
                    'тренировки',
                    'тренировок',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'ОБЪЁМ',
                  value: formatTonnage(week.volume),
                  caption:
                      volumeChange(week.volume, week.previousVolume) ??
                      'за эту неделю',
                ),
              ),
            ],
          ),
        ),
        if (last != null) ...[
          const SizedBox(height: 12),
          _LastWorkoutCard(logs: last),
        ],
      ],
    );
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.onStart,
    required this.inProgress,
    required this.plan,
  });

  final VoidCallback onStart;
  final bool inProgress;

  /// Упражнения, с которых начнётся тренировка.
  final List<String> plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = inProgress
        ? 'Тренировка идёт'
        : plan.isEmpty
        ? 'Новая тренировка'
        : 'Повторить прошлую';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              inProgress ? 'СЕЙЧАС' : 'СЛЕДУЮЩАЯ',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              plan.isEmpty ? 'Упражнения добавите по ходу' : plan.join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                inProgress ? 'Продолжить тренировку' : 'Начать тренировку',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.caption,
    this.accent = false,
  });

  final String label;
  final String value;
  final String caption;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: tabularFigures,
                color: accent ? theme.colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LastWorkoutCard extends StatelessWidget {
  const _LastWorkoutCard({required this.logs});

  final List<ExerciseLog> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
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
                  child: Text(
                    'Последняя тренировка',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(formatDate(logs.first.date), style: muted),
              ],
            ),
            const SizedBox(height: 10),
            for (final log in logs)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(log.exercise)),
                    Text(
                      '${log.sets.where((s) => !s.isWarmup).length} подх.',
                      style: muted,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Объём ${formatTonnage(volume)}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
