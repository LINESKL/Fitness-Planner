import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/message_view.dart';
import '../../workout/presentation/workout_providers.dart';
import 'workouts_list.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(workoutsProvider)
        .when(
          data: (workouts) => workouts.isEmpty
              ? const MessageView(
                  icon: Icons.event_note,
                  text: 'Здесь появятся завершённые тренировки',
                )
              : WorkoutsList(workouts: workouts),
          error: (_, _) => MessageView(
            icon: Icons.error_outline,
            text: 'Не удалось загрузить историю',
            actionLabel: 'Повторить',
            onAction: () => ref.invalidate(workoutsProvider),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
  }
}
