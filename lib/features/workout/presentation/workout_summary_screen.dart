import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/message_view.dart';
import 'workout_providers.dart';

/// Итоги тренировки (подробности — Task 17).
class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({super.key, required this.workoutId});

  final String workoutId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref
        .watch(workoutsProvider)
        .value
        ?.where((w) => w.id == workoutId)
        .firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: workout == null
            ? const MessageView(
                icon: Icons.event_busy,
                text: 'Тренировка не найдена',
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Тренировка готова',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(workout.title),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.goNamed('home'),
                    child: const Text('Готово'),
                  ),
                ],
              ),
      ),
    );
  }
}
