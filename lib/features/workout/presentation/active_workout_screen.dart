import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../domain/exercise_log.dart';
import '../domain/set_entry.dart';

/// Активная тренировка: по карточке на упражнение с таблицей подходов.
class ActiveWorkoutScreen extends StatefulWidget {
  ActiveWorkoutScreen({
    super.key,
    this.plan = sampleTodayPlan,
    List<ExerciseLog>? history,
  }) : history = history ?? sampleHistory;

  final List<String> plan;
  final List<ExerciseLog> history;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  /// Выполненные подходы: (номер упражнения, номер подхода).
  final _done = <(int, int)>{};

  void _toggle((int, int) set) => setState(() {
    if (!_done.remove(set)) _done.add(set);
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировка'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Завершить'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (i, name) in widget.plan.indexed)
            _ExerciseCard(
              name: name,
              previous:
                  lastTime(
                    widget.history,
                    name,
                  )?.sets.where((s) => !s.isWarmup).toList() ??
                  const [],
              isDone: (j) => _done.contains((i, j)),
              onToggle: (j) => _toggle((i, j)),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Добавить упражнение'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.name,
    required this.previous,
    required this.isDone,
    required this.onToggle,
  });

  final String name;
  final List<SetEntry> previous;
  final bool Function(int set) isDone;
  final void Function(int set) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // Без истории — одна пустая строка, чтобы было куда записать первый подход.
    final rows = previous.isEmpty ? 1 : previous.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (previous.isEmpty) Text('Ещё не делали', style: muted),
            const SizedBox(height: 8),
            DefaultTextStyle.merge(
              style: muted,
              child: const _SetRow(
                number: Text('#'),
                previous: Text('Прошлый'),
                weight: Text('кг'),
                reps: Text('Повт'),
                trailing: SizedBox(width: 48),
              ),
            ),
            for (var j = 0; j < rows; j++)
              _SetRow(
                highlighted: isDone(j),
                number: Text('${j + 1}'),
                previous: Text(
                  previous.isEmpty
                      ? '—'
                      : '${formatWeight(previous[j].weight)} × ${previous[j].reps}',
                  style: muted,
                ),
                weight: Text(
                  previous.isEmpty ? '—' : formatWeight(previous[j].weight),
                ),
                reps: Text(previous.isEmpty ? '—' : '${previous[j].reps}'),
                trailing: Checkbox(
                  value: isDone(j),
                  onChanged: (_) => onToggle(j),
                ),
              ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Добавить подход'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Строка таблицы подходов: # · Прошлый · кг · Повт · отметка.
class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.number,
    required this.previous,
    required this.weight,
    required this.reps,
    required this.trailing,
    this.highlighted = false,
  });

  final Widget number;
  final Widget previous;
  final Widget weight;
  final Widget reps;
  final Widget trailing;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlighted
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          SizedBox(width: 28, child: number),
          Expanded(child: previous),
          SizedBox(width: 56, child: weight),
          SizedBox(width: 44, child: reps),
          trailing,
        ],
      ),
    );
  }
}
