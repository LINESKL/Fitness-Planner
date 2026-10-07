import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../program/presentation/program_providers.dart';
import '../../workout/domain/active_workout.dart';
import '../../workout/domain/program.dart';
import '../../workout/domain/progress_rules.dart';
import '../../workout/domain/set_entry.dart';
import '../../workout/domain/stats.dart';
import '../../workout/domain/workout.dart';
import '../../workout/presentation/workout_providers.dart';

/// «Сегодня»: что делать сейчас, неделя и серия, объём и свежий рекорд.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _startTemplate(
    BuildContext context,
    WidgetRef ref,
    WorkoutTemplate template,
  ) async {
    await ref.read(activeWorkoutProvider.notifier).startTemplate(template);
    if (context.mounted) await context.pushNamed('workout');
  }

  Future<void> _startEmpty(BuildContext context, WidgetRef ref) async {
    ref.read(activeWorkoutProvider.notifier).startEmpty();
    await context.pushNamed('workout');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider).value ?? const <Workout>[];
    final active = ref.watch(activeWorkoutProvider);
    final days = ref.watch(programDaysProvider).value ?? const [];
    final next = ref.watch(nextTemplateProvider).value;
    final program = ref.watch(programProvider).value;
    final now = DateTime.now();
    final week = weekStats([for (final w in workouts) ...w.logs], now);
    final record = latestRecord(workouts);

    final position = next == null || program == null
        ? null
        : dayPosition(program, days, next.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Text(
          formatLongDate(now).toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 12),
        switch ((active, next)) {
          (final ActiveWorkout a, _) => _PlanCard(
            caption: 'СЕЙЧАС',
            title: a.title,
            subtitle: a.exercises.map((e) => e.name).join(' · '),
            action: 'Продолжить тренировку',
            onAction: () => context.pushNamed('workout'),
          ),
          (null, final WorkoutTemplate t) => _PlanCard(
            caption: position == null
                ? 'ПО ПЛАНУ'
                : 'ПО ПЛАНУ · ДЕНЬ ${position.index} ИЗ ${position.total}',
            title: t.name,
            subtitle: t.exercises.map((e) => e.exercise).join(' · '),
            action: 'Начать тренировку',
            onAction: () => _startTemplate(context, ref, t),
            secondary: 'Другой день или пустая',
            onSecondary: () => _chooseDayOrEmpty(context, ref),
          ),
          _ => _PlanCard(
            caption: 'ПРОГРАММА',
            title: 'Создайте программу',
            subtitle: 'Дни сплита с упражнениями — приложение подскажет, какой следующий',
            action: 'Создать программу',
            onAction: () => context.goNamed('program'),
            secondary: 'Пустая тренировка',
            onSecondary: () => _startEmpty(context, ref),
          ),
        },
        const SizedBox(height: 12),
        _WeekCard(workouts: workouts, now: now),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  label: 'ОБЪЁМ',
                  value: formatTonnage(week.volume),
                  caption:
                      volumeChange(week.volume, week.previousVolume) ??
                      'за эту неделю',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: record == null
                    ? _StatCard(
                        label: 'ЗА НЕДЕЛЮ',
                        value: '${week.workouts}',
                        accent: true,
                        caption: pluralRu(
                          week.workouts,
                          'тренировка',
                          'тренировки',
                          'тренировок',
                        ),
                      )
                    : _StatCard(
                        label: 'РЕКОРД',
                        value:
                            '${formatWeight(record.set.weight)} × ${record.set.reps}',
                        accent: true,
                        caption: record.exercise,
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Шторка: дни программы и «Пустая тренировка».
  Future<void> _chooseDayOrEmpty(BuildContext context, WidgetRef ref) async {
    final days = ref.read(programDaysProvider).value ?? const [];
    final choice = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final day in days)
              ListTile(
                title: Text(day.name),
                subtitle: Text(
                  day.exercises.map((e) => e.exercise).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => Navigator.pop(context, day),
              ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Пустая тренировка'),
              onTap: () => Navigator.pop(context, 'empty'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (choice) {
      case final WorkoutTemplate t:
        await _startTemplate(context, ref, t);
      case 'empty':
        await _startEmpty(context, ref);
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.caption,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onAction,
    this.secondary,
    this.onSecondary,
  });

  final String caption;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback onAction;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(caption, style: theme.textTheme.labelSmall),
            const SizedBox(height: 6),
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(action),
            ),
            if (secondary != null)
              Center(
                child: TextButton(
                  onPressed: onSecondary,
                  child: Text(secondary!),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.workouts, required this.now});

  final List<Workout> workouts;
  final DateTime now;

  static const _names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final start = weekStart(now);
    final trained = {
      for (final w in workouts)
        if (!w.startedAt.isBefore(start)) w.startedAt.weekday,
    };
    final streak = weekStreak(workouts, now);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('ЭТА НЕДЕЛЯ', style: theme.textTheme.labelSmall),
                ),
                if (streak > 0)
                  Text(
                    'серия $streak ${pluralRu(streak, 'неделя', 'недели', 'недель')}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var d = 1; d <= 7; d++) ...[
                  if (d > 1) const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _names[d - 1],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: trained.contains(d)
                                ? scheme.primary
                                : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: d == now.weekday && !trained.contains(d)
                                ? Border.all(color: scheme.primary, width: 2)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: tabularFigures,
                color: accent ? theme.colorScheme.primary : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
