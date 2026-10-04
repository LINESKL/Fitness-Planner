import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/message_view.dart';
import '../../workout/domain/exercise.dart';
import '../../workout/presentation/workout_providers.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key, this.onSelected});

  /// Если задан, экран работает как выбор упражнения.
  final ValueChanged<Exercise>? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск упражнения',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: switch (ref.watch(exercisesProvider)) {
            AsyncData(:final value) => ListView.builder(
              itemCount: value.length,
              itemBuilder: (context, i) {
                final exercise = value[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(exercise.name[0])),
                  title: Text(exercise.name),
                  subtitle: Text(exercise.muscleGroup),
                  onTap: onSelected == null
                      ? null
                      : () => onSelected!(exercise),
                );
              },
            ),
            AsyncError() => MessageView(
              icon: Icons.error_outline,
              text: 'Не удалось загрузить упражнения',
              actionLabel: 'Повторить',
              onAction: () => ref.invalidate(exercisesProvider),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ],
    );
  }
}
