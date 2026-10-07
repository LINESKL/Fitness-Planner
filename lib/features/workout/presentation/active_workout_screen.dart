import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show ReadContext;

import '../../../core/format.dart';
import '../../../core/theme.dart';
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
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(activeWorkoutProvider.notifier).finish();
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить тренировку')),
      );
      return;
    }
    ref.read(restTimerProvider.notifier).skip();
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

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: scheme.onPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Отдых ${formatDuration(left)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimary,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.onPrimary,
                  ),
                  onPressed: ref.read(restTimerProvider.notifier).skip,
                  child: const Text('Пропустить'),
                ),
              ],
            ),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(
              previous.isEmpty
                  ? 'Ещё не делали'
                  : 'в прошлый раз ${compactSets(previous)}',
              style: muted,
            ),
            const SizedBox(height: 12),
            DefaultTextStyle.merge(
              style: theme.textTheme.labelSmall,
              child: const _SetRow(
                number: Text('#'),
                previous: Text('ПРОШЛЫЙ'),
                weight: Center(child: Text('КГ')),
                reps: Center(child: Text('ПОВТ')),
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
                  style: muted?.copyWith(fontFeatures: tabularFigures),
                ),
                weight: _NumberField(
                  initial: set.weight == 0 ? '' : formatWeight(set.weight),
                  decimal: true,
                  onChanged: (text) {
                    if (parseWeightInput(text) case final v?) onWeight(j, v);
                  },
                ),
                reps: _NumberField(
                  initial: set.reps == 0 ? '' : '${set.reps}',
                  onChanged: (text) {
                    if (parseRepsInput(text) case final v?) onReps(j, v);
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
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontFeatures: tabularFigures),
        decoration: const InputDecoration(
          isDense: true,
          hintText: '0',
          contentPadding: EdgeInsets.symmetric(vertical: 12),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
            : null,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(6, 2, 0, 2),
      child: Row(
        children: [
          SizedBox(width: 26, child: number),
          Expanded(child: previous),
          SizedBox(width: 72, child: weight),
          SizedBox(width: 58, child: reps),
          trailing,
        ],
      ),
    );
  }
}

/// Пустое поле — 0; мусор, бесконечность и отрицательные — null (значение не меняется).
double? parseWeightInput(String text) {
  if (text.trim().isEmpty) return 0;
  final v = double.tryParse(text.trim().replaceAll(',', '.'));
  return v != null && v.isFinite && v >= 0 ? v.abs() : null;
}

int? parseRepsInput(String text) {
  if (text.trim().isEmpty) return 0;
  final v = int.tryParse(text.trim());
  return v != null && v >= 0 ? v : null;
}

/// «80 × 8, 8, 7» при одном весе, иначе «80 × 8, 82.5 × 7».
String compactSets(List<SetEntry> sets) {
  if (sets.every((s) => s.weight == sets.first.weight)) {
    return '${formatWeight(sets.first.weight)} × '
        '${sets.map((s) => s.reps).join(', ')}';
  }
  return sets.map((s) => '${formatWeight(s.weight)} × ${s.reps}').join(', ');
}
