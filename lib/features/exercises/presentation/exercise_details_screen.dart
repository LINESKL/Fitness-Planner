import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/max_width.dart';
import '../../../core/widgets/message_view.dart';
import '../../workout/domain/exercise_log.dart';
import '../../workout/domain/workout_async.dart';
import '../../workout/presentation/workout_providers.dart';

class ExerciseDetailsScreen extends ConsumerWidget {
  const ExerciseDetailsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercise = ref
        .watch(exercisesProvider)
        .value
        ?.items
        .where((e) => e.id == id)
        .firstOrNull;
    final history = ref.watch(historyProvider).value ?? const <ExerciseLog>[];
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(exercise?.name ?? 'Упражнение')),
      body: exercise == null
          ? const MessageView(
              icon: Icons.search_off,
              text: 'Упражнение не найдено',
            )
          : MaxWidth(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (exercise.imageUrl case final url?)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        height: 240,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(exercise.name, style: text.headlineSmall),
                  const SizedBox(height: 4),
                  Text(exercise.muscleGroup, style: text.titleMedium),
                  const SizedBox(height: 24),
                  Text('В прошлый раз', style: text.labelLarge),
                  const SizedBox(height: 4),
                  Text(summarizeLastTime(history, exercise.name)),
                ],
              ),
            ),
    );
  }
}
