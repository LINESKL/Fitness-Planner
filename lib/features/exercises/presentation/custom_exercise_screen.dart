import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ids.dart';
import '../../../core/widgets/max_width.dart';
import '../../workout/domain/exercise.dart';
import '../../workout/presentation/workout_providers.dart';

const muscleGroups = [
  'Грудь',
  'Спина',
  'Ноги',
  'Плечи',
  'Руки',
  'Пресс',
  'Икры',
  'Кардио',
  'Другое',
];

/// Своё упражнение: создание ([id] == 'new') и правка. Возвращает сохранённое.
class CustomExerciseScreen extends ConsumerStatefulWidget {
  const CustomExerciseScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CustomExerciseScreen> createState() =>
      _CustomExerciseScreenState();
}

class _CustomExerciseScreenState extends ConsumerState<CustomExerciseScreen> {
  late final Exercise? _original = ref
      .read(customExercisesProvider)
      .value
      ?.where((e) => e.id == widget.id)
      .firstOrNull;
  late final _name = TextEditingController(text: _original?.name ?? '');
  late String _group = _original?.muscleGroup ?? 'Другое';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final taken = (ref.read(exercisesProvider).value?.items ?? const [])
        .where((e) => e.id != _original?.id)
        .any((e) => e.name.toLowerCase() == name.toLowerCase());
    setState(
      () => _error = name.isEmpty
          ? 'Введите название'
          : taken
          ? 'Такое упражнение уже есть'
          : null,
    );
    if (_error != null) return;

    final exercise = Exercise(
      id: _original?.id ?? 'custom-${newId()}',
      name: name,
      muscleGroup: _group,
    );
    await ref.read(customExercisesProvider.notifier).save(exercise);
    if (mounted) context.pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_original == null ? 'Новое упражнение' : 'Упражнение'),
        actions: [TextButton(onPressed: _save, child: const Text('Сохранить'))],
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _name,
              autofocus: _original == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Название',
                hintText: 'Тяга гантели в наклоне',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 20),
            Text('Группа мышц', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final group in muscleGroups)
                  ChoiceChip(
                    label: Text(group),
                    selected: _group == group,
                    onSelected: (_) => setState(() => _group = group),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
