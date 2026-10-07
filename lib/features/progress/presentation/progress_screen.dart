import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../workout/domain/body.dart';
import '../../workout/domain/progress_rules.dart';
import '../../workout/domain/workout.dart';
import '../../workout/presentation/workout_providers.dart';
import 'body_tab.dart';
import 'records_tab.dart';
import 'workouts_list.dart';

/// «Прогресс»: обзор (календарь, мышцы, тело), рекорды, замеры тела.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Обзор'),
              Tab(text: 'Рекорды'),
              Tab(text: 'Тело'),
            ],
          ),
          Expanded(
            child: TabBarView(children: [_Overview(), RecordsTab(), BodyTab()]),
          ),
        ],
      ),
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider).value ?? const <Workout>[];
    final body = ref.watch(bodyEntriesProvider).value ?? const <BodyEntry>[];
    final recent = [...workouts]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _CalendarCard(workouts: workouts),
        const SizedBox(height: 12),
        _MuscleLoadCard(workouts: workouts),
        const SizedBox(height: 12),
        if (body.isNotEmpty) ...[
          _BodyCard(entries: body),
          const SizedBox(height: 12),
        ],
        if (recent.isNotEmpty) ...[
          Text(
            'ПОСЛЕДНИЕ ТРЕНИРОВКИ',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: 8),
          for (final w in recent.take(5)) ...[
            WorkoutTile(workout: w),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _CalendarCard extends StatefulWidget {
  const _CalendarCard({required this.workouts});

  final List<Workout> workouts;

  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  static const _weekdays = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];

  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  Future<void> _openDay(BuildContext context, List<Workout> day) async {
    if (day.isEmpty) return;
    if (day.length == 1) {
      await context.pushNamed(
        'workoutDetails',
        pathParameters: {'workoutId': day.single.id},
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final w in day)
              ListTile(
                title: Text(w.title),
                subtitle: Text('${w.duration.inMinutes} мин'),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(
                    'workoutDetails',
                    pathParameters: {'workoutId': w.id},
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final byDay = <int, List<Workout>>{};
    for (final w in widget.workouts) {
      if (w.startedAt.year == _month.year &&
          w.startedAt.month == _month.month) {
        byDay.putIfAbsent(w.startedAt.day, () => []).add(w);
      }
    }
    final count = byDay.values.fold(0, (n, l) => n + l.length);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final offset = DateTime(_month.year, _month.month).weekday - 1;

    return Card(
      key: ValueKey('month-${_month.year}-${_month.month}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Предыдущий месяц',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shift(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        formatMonth(_month),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '$count ${pluralRu(count, 'тренировка', 'тренировки', 'тренировок')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Следующий месяц',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shift(1),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              children: [
                for (final d in _weekdays)
                  Center(
                    child: Text(
                      d,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                for (var i = 0; i < offset; i++) const SizedBox.shrink(),
                for (var day = 1; day <= days; day++)
                  _DayCell(
                    key: ValueKey('day-$day'),
                    day: day,
                    trained: byDay.containsKey(day),
                    today:
                        now.year == _month.year &&
                        now.month == _month.month &&
                        now.day == day,
                    onTap: () => _openDay(context, byDay[day] ?? const []),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    super.key,
    required this.day,
    required this.trained,
    required this.today,
    required this.onTap,
  });

  final int day;
  final bool trained;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: trained ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: trained ? scheme.primary : null,
          borderRadius: BorderRadius.circular(10),
          border: today && !trained
              ? Border.all(color: scheme.primary, width: 2)
              : null,
        ),
        child: Text(
          '$day',
          style: TextStyle(
            fontFeatures: tabularFigures,
            fontWeight: trained ? FontWeight.w700 : null,
            color: trained ? scheme.onPrimary : null,
          ),
        ),
      ),
    );
  }
}

class _MuscleLoadCard extends ConsumerWidget {
  const _MuscleLoadCard({required this.workouts});

  final List<Workout> workouts;

  /// Ориентир: 10–20 рабочих подходов на группу мышц в неделю.
  static const _target = 20;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final load = muscleLoad(
      workouts,
      DateTime.now(),
      ref.watch(muscleGroupOfProvider),
    ).entries.toList()..sort((a, b) => b.value.compareTo(a.value));

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
                    'ПОДХОДЫ ЗА НЕДЕЛЮ',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                Text(
                  'ориентир 10–20',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (load.isEmpty)
              Text(
                'На этой неделе ещё не было подходов',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            for (final MapEntry(key: group, value: count) in load)
              Padding(
                key: ValueKey('load-$group-$count'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(width: 84, child: Text(group)),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (count / _target).clamp(0, 1),
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHigh,
                          color: count >= 10
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontFeatures: tabularFigures),
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

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.entries});

  /// От старых к новым.
  final List<BodyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = entries.last;
    final monthAgo = latest.date.subtract(const Duration(days: 30));
    final base = entries.firstWhere((e) => !e.date.isBefore(monthAgo));
    final delta = latest.weightKg - base.weightKg;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ВЕС ТЕЛА', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${formatKg(latest.weightKg)} кг',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                  if (identical(base, latest))
                    const SizedBox.shrink()
                  else
                    Text(
                      '${delta < 0 ? '−' : '+'}${formatKg(delta.abs())} кг за месяц',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

/// Вес с одним знаком после запятой без лишнего «.0»: 78.4, 79.
String formatKg(double kg) {
  final rounded = (kg * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
}
