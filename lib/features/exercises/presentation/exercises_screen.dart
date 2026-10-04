import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/message_view.dart';
import '../../workout/domain/exercise.dart';
import '../../workout/domain/exercise_repository.dart';
import '../../workout/presentation/workout_providers.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key, this.onSelected});

  /// Если задан, экран работает как выбор упражнения.
  final ValueChanged<Exercise>? onSelected;

  Widget _list(WidgetRef ref, List<Exercise> list) {
    if (list.isEmpty) {
      return const MessageView(
        icon: Icons.search_off,
        text: 'Ничего не нашлось',
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(exercisesProvider.future),
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) => _ExerciseTile(
          exercise: list[i],
          onTap: onSelected == null ? null : () => onSelected!(list[i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: ref.read(exerciseQueryProvider.notifier).search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по названию или группе мышц',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ref
              .watch(filteredExercisesProvider)
              .when(
                data: (catalog) => Column(
                  children: [
                    if (catalog.offline) const _OfflineBanner(),
                    Expanded(child: _list(ref, catalog.items)),
                  ],
                ),
                error: (error, _) => MessageView(
                  icon: Icons.cloud_off,
                  text: error is ExerciseLoadException
                      ? error.message
                      : 'Не удалось загрузить упражнения',
                  actionLabel: 'Повторить',
                  onAction: () => ref.invalidate(exercisesProvider),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
        ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Нет сети — показан сохранённый каталог',
        style: TextStyle(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise, this.onTap});

  final Exercise exercise;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final letter = CircleAvatar(
      child: Text(exercise.name.characters.firstOrNull ?? '?'),
    );
    final url = exercise.imageUrl;

    return ListTile(
      leading: url == null
          ? letter
          : ClipOval(
              child: Image.network(
                url,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => letter,
              ),
            ),
      title: Text(exercise.name),
      subtitle: Text(exercise.muscleGroup),
      onTap: onTap,
    );
  }
}
