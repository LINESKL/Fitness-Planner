import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../workout/domain/body.dart';
import '../../workout/presentation/workout_providers.dart';
import 'progress_screen.dart';

/// Вес тела: график и замеры.
class BodyTab extends ConsumerWidget {
  const BodyTab({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, BodyEntry e) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить замер от ${formatDate(e.date)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(bodyEntriesProvider.notifier).delete(e.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(bodyEntriesProvider).value ?? const <BodyEntry>[];
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        OutlinedButton.icon(
          onPressed: () => context.pushNamed('bodyEntryNew'),
          icon: const Icon(Icons.add),
          label: const Text('Замер'),
        ),
        const SizedBox(height: 12),
        if (entries.length >= 2) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
              child: SizedBox(
                height: 180,
                child: _WeightChart(entries: entries),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Записывайте вес раз в неделю — здесь появится график',
              textAlign: TextAlign.center,
              style: muted,
            ),
          ),
        for (final e in entries.reversed)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                '${formatKg(e.weightKg)} кг',
                style: const TextStyle(fontFeatures: tabularFigures),
              ),
              subtitle: Text(
                [
                  formatDate(e.date),
                  if (e.waistCm != null) 'талия ${formatKg(e.waistCm!)} см',
                  if (e.chestCm != null) 'грудь ${formatKg(e.chestCm!)} см',
                ].join(' · '),
              ),
              trailing: IconButton(
                tooltip: 'Удалить замер',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref, e),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({required this.entries});

  final List<BodyEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final first = entries.first.date;
    final spots = [
      for (final e in entries)
        FlSpot(e.date.difference(first).inHours / 24, e.weightKg),
    ];
    final weights = entries.map((e) => e.weightKg);
    final min = weights.reduce((a, b) => a < b ? a : b);
    final max = weights.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: (min - 1).floorToDouble(),
        maxY: (max + 1).ceilToDouble(),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(),
          rightTitles: AxisTitles(),
          bottomTitles: AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 36),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: scheme.primary,
            barWidth: 3,
            isCurved: true,
            preventCurveOverShooting: true,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
