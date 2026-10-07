import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' show ReadContext;

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/max_width.dart';
import '../../../core/widgets/text_input_dialog.dart';
import '../../exercises/presentation/pick_exercise.dart';
import '../../settings/presentation/settings_model.dart';
import '../domain/active_workout.dart';
import '../domain/exercise_log.dart';
import '../domain/progress_rules.dart';
import '../domain/set_entry.dart';
import 'elapsed_text.dart';
import 'set_format.dart';
import 'workout_providers.dart';

const setTypeNames = {
  SetType.normal: 'Обычный',
  SetType.warmup: 'Разминка',
  SetType.failure: 'До отказа',
  SetType.drop: 'Дроп-сет',
};

/// Идущая тренировка в фокус-режиме: подход → отдых → следующий подход.
class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  static Future<void> addExercise(BuildContext context, WidgetRef ref) async {
    final name = await pickExercise(context);
    if (name != null) {
      await ref.read(activeWorkoutProvider.notifier).addExercise(name);
    }
  }

  /// «Завершить» из шапки: если остались подходы — переспросить.
  Future<void> _confirmFinish(BuildContext context, WidgetRef ref) async {
    final workout = ref.read(activeWorkoutProvider);
    final left = workout == null
        ? 0
        : workout.exercises.expand((e) => e.sets).where((s) => !s.done).length;
    if (left > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Завершить тренировку?'),
          content: Text(
            'Не сделано подходов: $left\nСохранятся только выполненные.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Продолжить'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Завершить'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    await _finish(context, ref);
  }

  Future<void> _finish(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await ref.read(activeWorkoutProvider.notifier).finish();
      if (!context.mounted) return;
      if (saved == null) {
        context.goNamed('home');
      } else {
        context.pushReplacementNamed(
          'workoutSummary',
          pathParameters: {'workoutId': saved.id},
        );
      }
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить тренировку')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    ref.listen(restLeftProvider, (previous, next) {
      if (previous != null && next == null) HapticFeedback.heavyImpact();
    });
    // После «Завершить» экран ещё виден на время анимации закрытия.
    if (workout == null) return const Scaffold();

    final exerciseCount = workout.exercises.length;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workout.title, style: const TextStyle(fontSize: 20)),
            ElapsedText(
              since: workout.startedAt,
              suffix: exerciseCount == 0
                  ? ''
                  : ' · ${workout.cursor.exercise + 1}/$exerciseCount',
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'План тренировки',
            icon: const Icon(Icons.format_list_bulleted),
            onPressed: () => context.pushNamed('workoutPlan'),
          ),
          TextButton(
            onPressed: () => _confirmFinish(context, ref),
            child: const Text('Завершить'),
          ),
        ],
      ),
      body: SafeArea(
        child: MaxWidth(
          width: 560,
          child: switch (workout.phase) {
            _ when exerciseCount == 0 => _EmptyView(
              onAdd: () => addExercise(context, ref),
            ),
            WorkoutPhase.set => _SetView(workout: workout),
            WorkoutPhase.rest => _RestView(workout: workout),
            WorkoutPhase.finished => _FinishedView(
              onFinish: () => _finish(context, ref),
            ),
          },
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Добавьте первое упражнение',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Добавить упражнение'),
        ),
      ],
    ),
  );
}

/// Текущий подход: вес и повторы уже подставлены, главное действие — «Готово».
class _SetView extends ConsumerWidget {
  const _SetView({required this.workout});

  final ActiveWorkout workout;

  Future<void> _done(BuildContext context, WidgetRef ref) async {
    HapticFeedback.lightImpact();
    final messenger = ScaffoldMessenger.of(context);
    final rest = Duration(seconds: context.read<SettingsModel>().restSeconds);
    final record = await ref
        .read(activeWorkoutProvider.notifier)
        .completeCurrent(rest);
    if (record != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Новый рекорд · ${record.exercise} '
            '${formatWeight(record.set.weight)} × ${record.set.reps}',
          ),
        ),
      );
    }
  }

  Future<void> _enterWeight(
    BuildContext context,
    WidgetRef ref,
    WorkoutSet set,
  ) async {
    final text = await showTextInputDialog(
      context,
      title: 'Вес, кг',
      initial: set.weight == 0 ? '' : formatWeight(set.weight),
      hint: '0',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    final weight = text == null ? null : parseWeightInput(text);
    if (weight != null) _edit(ref, weight: weight);
  }

  void _edit(WidgetRef ref, {double? weight, int? reps}) {
    final c = workout.cursor;
    ref
        .read(activeWorkoutProvider.notifier)
        .update(
          (w) => w.editSet(c.exercise, c.set, weight: weight, reps: reps),
        );
  }

  Future<void> _chooseType(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => const _TypeSheet(),
      );

  Future<void> _editNote(
    BuildContext context,
    WidgetRef ref,
    String exercise,
    String? current,
  ) async {
    final text = await showTextInputDialog(
      context,
      title: 'Заметка · $exercise',
      initial: current ?? '',
      hint: 'Сиденье на 4, узкий хват',
      confirmLabel: 'Сохранить',
      maxLines: 3,
    );
    if (text == null) return;
    await ref.read(noteRepositoryProvider).setNote(exercise, text);
    ref.invalidate(noteProvider(exercise));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final exercise = workout.currentExercise!;
    final set = workout.currentSet!;
    final c = workout.cursor;
    final history = ref.watch(historyProvider).value ?? const <ExerciseLog>[];
    final previous = [
      for (final s
          in lastTime(history, exercise.name)?.sets ?? const <SetEntry>[])
        if (!s.isWarmup) s,
    ];
    final note = ref.watch(noteProvider(exercise.name)).value;
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Text(
          exercise.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'подход ${c.set + 1} из ${exercise.sets.length} · '
          '${previous.isEmpty ? 'ещё не делали' : 'в прошлый раз ${compactSets(previous)}'}',
          style: muted,
        ),
        if (set.increased) ...[
          const SizedBox(height: 12),
          _Banner(
            text:
                'Все повторы сделаны — сегодня +${formatWeight(progressionStep)} кг',
          ),
        ],
        if (note != null) ...[
          const SizedBox(height: 8),
          Text('Заметка: $note', style: muted),
        ],
        const SizedBox(height: 20),
        Text('ВЕС, КГ', style: theme.textTheme.labelSmall),
        const SizedBox(height: 6),
        _Stepper(
          value: formatWeight(set.weight),
          valueKey: const Key('weight-value'),
          less: 'Меньше вес',
          more: 'Больше вес',
          onLess: () => _edit(
            ref,
            weight: (set.weight - progressionStep).clamp(0, double.infinity),
          ),
          onMore: () => _edit(ref, weight: set.weight + progressionStep),
          onTapValue: () => _enterWeight(context, ref, set),
        ),
        const SizedBox(height: 12),
        Text('ПОВТОРЫ', style: theme.textTheme.labelSmall),
        const SizedBox(height: 6),
        _Stepper(
          value: '${set.reps}',
          less: 'Меньше повторов',
          more: 'Больше повторов',
          onLess: () => _edit(ref, reps: (set.reps - 1).clamp(0, 999)),
          onMore: () => _edit(ref, reps: set.reps + 1),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final (j, s) in exercise.sets.indexed)
                    _SetDot(
                      number: j + 1,
                      done: s.done,
                      current: j == c.set,
                      onTap: () => ref
                          .read(activeWorkoutProvider.notifier)
                          .update((w) => w.goTo(c.exercise, j)),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            TextButton.icon(
              onPressed: () => _chooseType(context, ref),
              icon: const Icon(Icons.tune),
              label: Text(
                set.type == SetType.normal && set.rpe == null
                    ? 'Тип'
                    : [
                        if (set.type != SetType.normal) setTypeNames[set.type],
                        if (set.rpe != null) 'RPE ${formatWeight(set.rpe!)}',
                      ].join(' · '),
              ),
            ),
            TextButton.icon(
              onPressed: () => _editNote(context, ref, exercise.name, note),
              icon: const Icon(Icons.sticky_note_2_outlined),
              label: const Text('Заметка'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          onPressed: () => _done(context, ref),
          child: const Text('Готово'),
        ),
      ],
    );
  }
}

class _TypeSheet extends ConsumerWidget {
  const _TypeSheet();

  static const _rpeValues = [6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider);
    final set = workout?.currentSet;
    if (workout == null || set == null) return const SizedBox.shrink();
    final c = workout.cursor;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final title = Theme.of(context).textTheme.titleMedium;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тип подхода', style: title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in SetType.values)
                  ChoiceChip(
                    label: Text(setTypeNames[type]!),
                    selected: set.type == type,
                    onSelected: (_) => notifier.update(
                      (w) => w.editSet(c.exercise, c.set, type: type),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Тяжесть (RPE)', style: title),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final rpe in _rpeValues)
                  ChoiceChip(
                    label: Text('RPE ${formatWeight(rpe)}'),
                    selected: set.rpe == rpe,
                    onSelected: (_) => notifier.update(
                      (w) => w.editSet(c.exercise, c.set, rpe: rpe),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Экран отдыха: большой таймер, ±15 с, что дальше.
class _RestView extends ConsumerWidget {
  const _RestView({required this.workout});

  final ActiveWorkout workout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final left = ref.watch(restLeftProvider) ?? Duration.zero;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final next = workout.currentSet;
    final exercise = workout.currentExercise;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            'ОТДЫХ',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
          Text(
            formatDuration(left),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 80,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
              fontFeatures: tabularFigures,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ActionChip(
                label: const Text('−15 с'),
                onPressed: () => notifier.update(
                  (w) => w.extendRest(const Duration(seconds: -15)),
                ),
              ),
              const SizedBox(width: 12),
              ActionChip(
                label: const Text('+15 с'),
                onPressed: () => notifier.update(
                  (w) => w.extendRest(const Duration(seconds: 15)),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (next != null && exercise != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('СЛЕДУЮЩИЙ', style: theme.textTheme.labelSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.name} · подход ${workout.cursor.set + 1}',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      '${formatLoad(next.weight)} × ${next.reps}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => notifier.update((w) => w.skipRest()),
            child: const Text('Пропустить отдых'),
          ),
        ],
      ),
    );
  }
}

class _FinishedView extends ConsumerWidget {
  const _FinishedView({required this.onFinish});

  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(activeWorkoutProvider)!;
    final last = workout.exercises.length - 1;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.check_circle,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Все подходы сделаны',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onFinish,
            child: const Text('Завершить тренировку'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref
                .read(activeWorkoutProvider.notifier)
                .update((w) => w.addSet(last)),
            child: const Text('Ещё подход'),
          ),
          TextButton(
            onPressed: () => ActiveWorkoutScreen.addExercise(context, ref),
            child: const Text('Добавить упражнение'),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: scheme.onSecondaryContainer)),
    );
  }
}

/// «−  80  +»: крупные кнопки, значение можно ввести нажатием.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.less,
    required this.more,
    required this.onLess,
    required this.onMore,
    this.onTapValue,
    this.valueKey,
  });

  final String value;
  final String less;
  final String more;
  final VoidCallback onLess;
  final VoidCallback onMore;
  final VoidCallback? onTapValue;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget button(String tooltip, IconData icon, VoidCallback onTap) =>
        IconButton.filledTonal(
          tooltip: tooltip,
          iconSize: 28,
          style: IconButton.styleFrom(
            minimumSize: const Size(56, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: onTap,
          icon: Icon(icon),
        );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          button(less, Icons.remove, onLess),
          Expanded(
            child: InkWell(
              key: valueKey,
              onTap: onTapValue,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: tabularFigures,
                  ),
                ),
              ),
            ),
          ),
          button(more, Icons.add, onMore),
        ],
      ),
    );
  }
}

class _SetDot extends StatelessWidget {
  const _SetDot({
    required this.number,
    required this.done,
    required this.current,
    required this.onTap,
  });

  final int number;
  final bool done;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Подход $number',
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? scheme.primary : null,
            border: done
                ? null
                : Border.all(
                    color: current ? scheme.primary : scheme.outline,
                    width: 2,
                  ),
          ),
          child: done
              ? Icon(Icons.check, size: 20, color: scheme.onPrimary)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: current ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
        ),
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
