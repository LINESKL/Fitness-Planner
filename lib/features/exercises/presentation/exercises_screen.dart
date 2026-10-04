import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/message_view.dart';
import '../../workout/domain/exercise.dart';
import '../../workout/domain/exercise_repository.dart';
import '../../workout/presentation/workout_providers.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key, this.onSelected});

  /// Если задан, экран работает как выбор упражнения.
  final ValueChanged<Exercise>? onSelected;

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  static const _debounce = Duration(milliseconds: 300);

  /// Поиск свой у каждого экрана: вкладка и выбор в тренировке не мешают друг другу.
  String _query = '';
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _search(String text) {
    _timer?.cancel();
    _timer = Timer(
      _debounce,
      () => setState(() => _query = text.trim().toLowerCase()),
    );
  }

  List<Exercise> _filter(List<Exercise> items) => _query.isEmpty
      ? items
      : [
          for (final e in items)
            if (e.name.toLowerCase().contains(_query) ||
                e.muscleGroup.toLowerCase().contains(_query))
              e,
        ];

  Widget _list(List<Exercise> list) {
    if (list.isEmpty) {
      return const MessageView(
        icon: Icons.search_off,
        text: 'Ничего не нашлось',
      );
    }
    final onSelected = widget.onSelected;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(exercisesProvider.future),
      child: ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, i) => _ExerciseTile(
          exercise: list[i],
          onTap: onSelected == null ? null : () => onSelected(list[i]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск по названию или группе мышц',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ref
              .watch(exercisesProvider)
              .when(
                data: (catalog) => Column(
                  children: [
                    if (catalog.offline) const _OfflineBanner(),
                    Expanded(child: _list(_filter(catalog.items))),
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
