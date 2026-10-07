import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/max_width.dart';
import '../../../core/widgets/message_view.dart';
import '../domain/progress_rules.dart';
import '../domain/stats.dart';
import '../domain/workout.dart';
import 'workout_providers.dart';
import 'set_format.dart';

/// Итоги сразу после «Завершить»: время, объём, рекорды, сравнение с прошлым разом.
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider).value ?? const <Workout>[];
    final workout = workouts.where((w) => w.id == workoutId).firstOrNull;

    return Scaffold(
      body: SafeArea(
        child: workout == null
            ? const MessageView(
                icon: Icons.event_busy,
                text: 'Тренировка не найдена',
              )
            : MaxWidth(
                width: 560,
                child: _Summary(workout: workout, all: workouts),
              ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.workout, required this.all});

  final Workout workout;
  final List<Workout> all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final records = [
      for (final r in recordHistory(all))
        if (r.date == workout.startedAt) r,
    ];
    final previous = all
        .where(
          (w) =>
              w.templateId != null &&
              w.templateId == workout.templateId &&
              w.startedAt.isBefore(workout.startedAt),
        )
        .fold<Workout?>(
          null,
          (best, w) =>
              best == null || w.startedAt.isAfter(best.startedAt) ? w : best,
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 34,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          child: const Icon(Icons.check, size: 36),
        ),
        const SizedBox(height: 12),
        Text(
          'Тренировка готова',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '${workout.title} · ${formatLongDate(workout.startedAt)}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _Metric(value: '${workout.duration.inMinutes}', label: 'минут'),
            const SizedBox(width: 8),
            _Metric(value: formatTonnage(workout.volume), label: 'объём'),
            const SizedBox(width: 8),
            _Metric(value: '${workout.workingSets}', label: 'подходов'),
          ],
        ),
        if (records.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'НОВЫЕ РЕКОРДЫ',
            rows: [
              for (final r in records) (r.exercise, formatSet(r.set), true),
            ],
          ),
        ],
        if (previous != null) ...[
          const SizedBox(height: 12),
          _Section(
            title: 'К ПРОШЛОМУ «${workout.title.toUpperCase()}»',
            rows: [
              (
                'Объём',
                _signedTonnage(workout.volume - previous.volume),
                false,
              ),
              (
                'Время',
                _signedMinutes(
                  workout.duration.inMinutes - previous.duration.inMinutes,
                ),
                false,
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => context.goNamed('home'),
          child: const Text('Готово'),
        ),
      ],
    );
  }

  static String _signedTonnage(double kg) =>
      '${kg < 0 ? '−' : '+'}${formatTonnage(kg.abs())}';

  static String _signedMinutes(int minutes) =>
      '${minutes < 0 ? '−' : '+'}${minutes.abs()} мин';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFeatures: tabularFigures,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;

  /// (подпись, значение, акцент)
  final List<(String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            for (final (label, value, accent) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(label)),
                    Text(
                      value,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent ? theme.colorScheme.primary : null,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
