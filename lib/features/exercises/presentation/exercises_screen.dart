import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/message_view.dart';
import '../../workout/domain/exercise.dart';
import '../../workout/domain/exercise_repository.dart';
import '../../workout/presentation/workout_providers.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({
    super.key,
    this.onSelected,
    this.selectCreated = false,
  });

  /// Нажатие на упражнение (во вкладке — карточка, в выборе — выбор).
  final ValueChanged<Exercise>? onSelected;

  /// Режим выбора: только что созданное своё упражнение сразу выбирается.
  final bool selectCreated;

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  static const _debounce = Duration(milliseconds: 300);

  /// Поиск свой у каждого экрана: вкладка и выбор в тренировке не мешают друг другу.
  String _query = '';
  Timer? _timer;
  bool _favoritesOnly = false;

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

  /// Поиск, фильтр «Избранное»; избранные — первыми.
  List<Exercise> _filter(List<Exercise> items, Set<String> favorites) {
    final found = [
      for (final e in items)
        if ((_query.isEmpty ||
                e.name.toLowerCase().contains(_query) ||
                e.muscleGroup.toLowerCase().contains(_query)) &&
            (!_favoritesOnly || favorites.contains(e.id)))
          e,
    ];
    return [
      ...found.where((e) => favorites.contains(e.id)),
      ...found.where((e) => !favorites.contains(e.id)),
    ];
  }

  Future<void> _create() async {
    final created = await context.pushNamed<Exercise>(
      'exerciseEditor',
      pathParameters: {'id': 'new'},
    );
    if (created != null && widget.selectCreated) {
      widget.onSelected?.call(created);
    }
  }

  Widget _list(List<Exercise> list, Set<String> favorites) {
    if (list.isEmpty) {
      return MessageView(
        icon: _favoritesOnly ? Icons.star_outline : Icons.search_off,
        text: _favoritesOnly && _query.isEmpty
            ? 'Отметьте упражнения звёздочкой — они появятся здесь'
            : 'Ничего не нашлось',
      );
    }
    final onSelected = widget.onSelected;
    return RefreshIndicator(
      onRefresh: () => ref.refresh(exercisesProvider.future),
      child: ListView.builder(
        itemCount: list.length + 1,
        itemBuilder: (context, i) => i == 0
            ? ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(Icons.add),
                ),
                title: const Text('Своё упражнение'),
                onTap: _create,
              )
            : _ExerciseTile(
                exercise: list[i - 1],
                favorite: favorites.contains(list[i - 1].id),
                onToggleFavorite: () =>
                    ref.read(favoritesProvider.notifier).toggle(list[i - 1].id),
                onTap: onSelected == null
                    ? null
                    : () => onSelected(list[i - 1]),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider).value ?? const <String>{};
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            onChanged: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Название или группа мышц',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              avatar: const Icon(Icons.star, size: 18),
              label: const Text('Избранное'),
              selected: _favoritesOnly,
              onSelected: (v) => setState(() => _favoritesOnly = v),
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
                    Expanded(
                      child: _list(
                        _filter(catalog.items, favorites),
                        favorites,
                      ),
                    ),
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
  const _ExerciseTile({
    required this.exercise,
    required this.favorite,
    required this.onToggleFavorite,
    this.onTap,
  });

  final Exercise exercise;
  final bool favorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final letter = CircleAvatar(
      backgroundColor: scheme.surfaceContainerHigh,
      foregroundColor: scheme.primary,
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
                cacheWidth: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => letter,
              ),
            ),
      title: Text(exercise.name),
      subtitle: Text(
        exercise.muscleGroup,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
      trailing: IconButton(
        tooltip: favorite ? 'Убрать из избранного' : 'В избранное',
        icon: Icon(
          favorite ? Icons.star : Icons.star_outline,
          color: favorite ? scheme.primary : scheme.onSurfaceVariant,
        ),
        onPressed: onToggleFavorite,
      ),
      onTap: onTap,
    );
  }
}
