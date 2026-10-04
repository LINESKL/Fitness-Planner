import 'package:flutter/material.dart';

import '../../exercises/presentation/exercises_screen.dart';
import '../domain/active_workout.dart';
import '../domain/exercise_log.dart';
import '../domain/set_entry.dart';

/// Активная тренировка: по карточке на упражнение с таблицей подходов.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({
    super.key,
    required this.plan,
    required this.history,
    required this.onFinish,
  });

  final List<String> plan;
  final List<ExerciseLog> history;
  final void Function(List<ExerciseLog> logs) onFinish;

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  late ActiveWorkout _workout = ActiveWorkout.start(
    startedAt: DateTime.now(),
    plan: widget.plan,
    history: widget.history,
  );

  void _update(ActiveWorkout Function(ActiveWorkout w) change) =>
      setState(() => _workout = change(_workout));

  Future<void> _pickExercise() async {
    final name = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Выбор упражнения')),
          body: ExercisesScreen(
            onSelected: (e) => Navigator.of(context).pop(e.name),
          ),
        ),
      ),
    );
    if (name != null) _update((w) => w.addExercise(name, widget.history));
  }

  void _finish() {
    widget.onFinish(_workout.toLogs(DateTime.now()));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировка'),
        actions: [
          TextButton(onPressed: _finish, child: const Text('Завершить')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (i, exercise) in _workout.exercises.indexed)
            _ExerciseCard(
              key: ValueKey(i),
              exercise: exercise,
              previous: [
                for (final s
                    in lastTime(widget.history, exercise.name)?.sets ??
                        const <SetEntry>[])
                  if (!s.isWarmup) s,
              ],
              onToggle: (j) => _update((w) => w.toggleDone(i, j)),
              onWeight: (j, v) => _update((w) => w.updateSet(i, j, weight: v)),
              onReps: (j, v) => _update((w) => w.updateSet(i, j, reps: v)),
              onAddSet: () => _update((w) => w.addSet(i)),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickExercise,
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
    super.key,
    required this.exercise,
    required this.previous,
    required this.onToggle,
    required this.onWeight,
    required this.onReps,
    required this.onAddSet,
  });

  final ActiveExercise exercise;
  final List<SetEntry> previous;
  final void Function(int set) onToggle;
  final void Function(int set, double weight) onWeight;
  final void Function(int set, int reps) onReps;
  final VoidCallback onAddSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
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
            for (final (j, set) in exercise.sets.indexed)
              _SetRow(
                highlighted: set.done,
                number: Text('${j + 1}'),
                previous: Text(
                  j < previous.length
                      ? '${formatWeight(previous[j].weight)} × ${previous[j].reps}'
                      : '—',
                  style: muted,
                ),
                weight: _NumberField(
                  initial: set.weight == 0 ? '' : formatWeight(set.weight),
                  decimal: true,
                  onChanged: (text) {
                    final v = double.tryParse(text.replaceAll(',', '.'));
                    if (v != null && v >= 0) onWeight(j, v);
                  },
                ),
                reps: _NumberField(
                  initial: set.reps == 0 ? '' : '${set.reps}',
                  onChanged: (text) {
                    final v = int.tryParse(text);
                    if (v != null && v >= 0) onReps(j, v);
                  },
                ),
                trailing: Checkbox(
                  value: set.done,
                  onChanged: (_) => onToggle(j),
                ),
              ),
            TextButton.icon(
              onPressed: onAddSet,
              icon: const Icon(Icons.add),
              label: const Text('Добавить подход'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Компактное поле для числа в таблице подходов.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.initial,
    required this.onChanged,
    this.decimal = false,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: TextFormField(
        initialValue: initial,
        onChanged: onChanged,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          hintText: '0',
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(),
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
      margin: const EdgeInsets.only(bottom: 4),
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
          SizedBox(width: 64, child: weight),
          SizedBox(width: 52, child: reps),
          trailing,
        ],
      ),
    );
  }
}
