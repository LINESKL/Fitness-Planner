import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show ReadContext;

import '../../../core/format.dart';
import '../../exercises/presentation/exercises_screen.dart';
import '../../settings/presentation/settings_model.dart';
import '../domain/active_workout.dart';
import '../domain/exercise_log.dart';
import '../domain/set_entry.dart';
import 'workout_providers.dart';

/// Активная тренировка: по карточке на упражнение с таблицей подходов.
class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  Future<void> _pickExercise(BuildContext context, WidgetRef ref) async {
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
    if (name != null) {
      await ref.read(activeWorkoutProvider.notifier).addExercise(name);
    }
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    ref.read(restTimerProvider.notifier).skip();
    await ref.read(activeWorkoutProvider.notifier).finish();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    final history = ref.watch(historyProvider).value ?? const <ExerciseLog>[];
    final notifier = ref.read(activeWorkoutProvider.notifier);
    // После «Завершить» экран ещё виден на время анимации закрытия.
    if (workout == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировка'),
        actions: [
          TextButton(
            onPressed: () => _finish(context, ref),
            child: const Text('Завершить'),
          ),
        ],
      ),
      bottomNavigationBar: const _RestTimerBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (i, exercise) in workout.exercises.indexed)
            _ExerciseCard(
              key: ValueKey(i),
              exercise: exercise,
              previous: [
                for (final s
                    in lastTime(history, exercise.name)?.sets ??
                        const <SetEntry>[])
                  if (!s.isWarmup) s,
              ],
              onToggle: (j) {
                final becomesDone = !exercise.sets[j].done;
                notifier.update((w) => w.toggleDone(i, j));
                if (becomesDone) {
                  ref
                      .read(restTimerProvider.notifier)
                      .start(
                        Duration(
                          seconds: context.read<SettingsModel>().restSeconds,
                        ),
                      );
                }
              },
              onWeight: (j, v) =>
                  notifier.update((w) => w.updateSet(i, j, weight: v)),
              onReps: (j, v) =>
                  notifier.update((w) => w.updateSet(i, j, reps: v)),
              onAddSet: () => notifier.update((w) => w.addSet(i)),
            ),
          if (workout.exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Добавьте первое упражнение',
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _pickExercise(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Добавить упражнение'),
          ),
        ],
      ),
    );
  }
}

class _RestTimerBar extends ConsumerWidget {
  const _RestTimerBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = ref.watch(restTimerProvider);
    if (left == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: scheme.onTertiaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Отдых ${formatDuration(left)}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: scheme.onTertiaryContainer),
                ),
              ),
              TextButton(
                onPressed: ref.read(restTimerProvider.notifier).skip,
                child: const Text('Пропустить'),
              ),
            ],
          ),
        ),
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
