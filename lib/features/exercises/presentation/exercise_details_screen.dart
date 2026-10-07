import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/max_width.dart';
import '../../../core/widgets/message_view.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../progress/presentation/progress_screen.dart' show formatKg;
import '../../workout/domain/exercise.dart';
import '../../workout/domain/progress_rules.dart';
import '../../workout/domain/set_entry.dart';
import '../../workout/domain/stats.dart';
import '../../workout/domain/workout.dart';
import '../../workout/presentation/set_format.dart';
import '../../workout/presentation/workout_providers.dart';

/// Карточка упражнения: график прогресса, рекорды, заметка, последние тренировки.
class ExerciseDetailsScreen extends ConsumerStatefulWidget {
  const ExerciseDetailsScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<ExerciseDetailsScreen> createState() =>
      _ExerciseDetailsScreenState();
}

class _ExerciseDetailsScreenState extends ConsumerState<ExerciseDetailsScreen> {
  ExerciseMetric _metric = ExerciseMetric.oneRepMax;

  static const _metricNames = {
    ExerciseMetric.oneRepMax: '1ПМ',
    ExerciseMetric.bestWeight: 'Лучший вес',
    ExerciseMetric.volume: 'Объём',
  };

  String _format(double value) => _metric == ExerciseMetric.volume
      ? formatTonnage(value)
      : '${formatKg(value)} кг';

  Future<void> _editNote(Exercise exercise, String? current) async {
    final text = await showTextInputDialog(
      context,
      title: 'Заметка · ${exercise.name}',
      initial: current ?? '',
      hint: 'Сиденье на 4, узкий хват',
      confirmLabel: 'Сохранить',
      maxLines: 3,
    );
    if (text == null) return;
    await ref.read(noteRepositoryProvider).setNote(exercise.name, text);
    ref.invalidate(noteProvider(exercise.name));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exercisesProvider);
    final exercise = catalog.value?.items
        .where((e) => e.id == widget.id)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(exercise?.name ?? 'Упражнение')),
      body: switch ((catalog, exercise)) {
        (_, final Exercise e) => _body(context, e),
        (AsyncLoading(), _) => const Center(child: CircularProgressIndicator()),
        _ => const MessageView(
          icon: Icons.search_off,
          text: 'Упражнение не найдено',
        ),
      },
    );
  }

  Widget _body(BuildContext context, Exercise exercise) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final workouts = ref.watch(workoutsProvider).value ?? const <Workout>[];
    final series = exerciseSeries(exercise.name, workouts, _metric);
    final best = personalBests(workouts)
        .where((b) => b.exercise == exercise.name)
        .firstOrNull;
    final records = recordsFor(exercise.name, workouts);
    final note = ref.watch(noteProvider(exercise.name)).value;
    final sessions = [
      for (final w in [
        ...workouts,
      ]..sort((a, b) => b.startedAt.compareTo(a.startedAt)))
        for (final e in w.entries.where((e) => e.exercise == exercise.name))
          (
            date: w.startedAt,
            sets: [
              for (final s in e.sets)
                if (!s.isWarmup) s,
            ],
          ),
    ].where((s) => s.sets.isNotEmpty).take(5).toList();

    return MaxWidth(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(exercise.muscleGroup, style: muted),
          if (exercise.imageUrl case final url?) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                url,
                height: 200,
                fit: BoxFit.contain,
                cacheHeight: 600,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (series.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Ещё не делали',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final m in ExerciseMetric.values)
                          ChoiceChip(
                            label: Text(_metricNames[m]!),
                            selected: _metric == m,
                            onSelected: (_) => setState(() => _metric = m),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _format(series.last.value),
                      key: const ValueKey('metric-value'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(height: 160, child: _SeriesChart(points: series)),
                  ],
                ),
              ),
            ),
          if (best != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _RecordCard(
                    label: 'ЛУЧШИЙ ПОДХОД',
                    value:
                        '${formatWeight(best.set.weight)} × ${best.set.reps}',
                    accent: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RecordCard(
                    label: 'МАКС. ОБЪЁМ',
                    value: formatTonnage(records.bestVolume),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: Text('ЗАМЕТКА', style: theme.textTheme.labelSmall),
              subtitle: Text(
                note ?? 'Добавить заметку',
                style: note == null
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.primary,
                      )
                    : theme.textTheme.bodyMedium,
              ),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editNote(exercise, note),
            ),
          ),
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ПОСЛЕДНИЕ ТРЕНИРОВКИ',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final s in sessions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 96,
                              child: Text(formatDate(s.date), style: muted),
                            ),
                            Expanded(
                              child: Text(
                                compactSets(s.sets),
                                style: const TextStyle(
                                  fontFeatures: tabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
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
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                color: accent ? theme.colorScheme.primary : null,
                fontFeatures: tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesChart extends StatelessWidget {
  const _SeriesChart({required this.points});

  final List<({DateTime date, double value})> points;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = points.first.date;
    final values = points.map((p) => p.value);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final pad = (max - min) * 0.15 + 1;

    return LineChart(
      LineChartData(
        minY: min - pad,
        maxY: max + pad,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (final p in points)
                FlSpot(p.date.difference(first).inHours / 24, p.value),
            ],
            color: scheme.primary,
            barWidth: 3,
            isCurved: true,
            preventCurveOverShooting: true,
            dotData: FlDotData(show: points.length < 20),
          ),
        ],
      ),
    );
  }
}
