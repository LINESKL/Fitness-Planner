import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ids.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/max_width.dart';
import '../../../core/widgets/message_view.dart';
import '../../exercises/presentation/pick_exercise.dart';
import '../../workout/domain/program.dart';
import 'program_providers.dart';
import 'program_screen.dart';

/// Редактор дня сплита; [templateId] == 'new' — новый день.
class TemplateEditorScreen extends ConsumerStatefulWidget {
  const TemplateEditorScreen({super.key, required this.templateId});

  final String templateId;

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  static const _maxSets = 10;
  static const _maxReps = 50;

  late final bool _isNew = widget.templateId == 'new';
  late final WorkoutTemplate? _original = _isNew
      ? null
      : ref
            .read(templatesProvider)
            .value
            ?.where((t) => t.id == widget.templateId)
            .firstOrNull;
  late final _name = TextEditingController(text: _original?.name ?? '');
  late final _exercises = [...?_original?.exercises];
  String? _nameError;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Шаг ±1 считается от текущего значения: быстрые нажатия не теряются.
  void _change(int i, {int sets = 0, int repsMin = 0, int repsMax = 0}) {
    final e = _exercises[i];
    final max = (e.repsMax + repsMax).clamp(e.repsMin, _maxReps);
    final min = (e.repsMin + repsMin).clamp(1, max);
    setState(
      () => _exercises[i] = TemplateExercise(
        exercise: e.exercise,
        sets: (e.sets + sets).clamp(1, _maxSets),
        repsMin: min,
        repsMax: max,
      ),
    );
  }

  Future<void> _add() async {
    final name = await pickExercise(context);
    if (name == null) return;
    setState(
      () => _exercises.add(
        TemplateExercise(exercise: name, sets: 3, repsMin: 8, repsMax: 12),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Введите название');
      return;
    }
    setState(() => _saving = true);
    final template = WorkoutTemplate(
      id: _original?.id ?? newId(),
      name: name,
      exercises: _exercises,
    );
    await ref.read(templatesProvider.notifier).save(template);
    if (_isNew) {
      final program = await ref.read(programProvider.future);
      await ref
          .read(programProvider.notifier)
          .save(Program(templateIds: [...program.templateIds, template.id]));
    }
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final original = _original!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить день «${original.name}»?'),
        content: const Text('Прошлые тренировки останутся в истории.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final program = await ref.read(programProvider.future);
    await ref
        .read(programProvider.notifier)
        .save(
          Program(
            templateIds: [
              for (final id in program.templateIds)
                if (id != original.id) id,
            ],
          ),
        );
    await ref.read(templatesProvider.notifier).delete(original.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isNew && _original == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const MessageView(icon: Icons.search_off, text: 'День не найден'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Новый день' : 'День'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Удалить день',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Сохранить'),
          ),
        ],
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                labelText: 'Название дня',
                hintText: 'Грудь + трицепс',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            for (final (i, e) in _exercises.indexed) ...[
              _ExerciseEditor(
                exercise: e,
                onRemove: () => setState(() => _exercises.removeAt(i)),
                onSets: (d) => _change(i, sets: d),
                onRepsMin: (d) => _change(i, repsMin: d),
                onRepsMax: (d) => _change(i, repsMax: d),
              ),
              const SizedBox(height: 10),
            ],
            OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Добавить упражнение'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseEditor extends StatelessWidget {
  const _ExerciseEditor({
    required this.exercise,
    required this.onRemove,
    required this.onSets,
    required this.onRepsMin,
    required this.onRepsMax,
  });

  final TemplateExercise exercise;
  final VoidCallback onRemove;
  final ValueChanged<int> onSets;
  final ValueChanged<int> onRepsMin;
  final ValueChanged<int> onRepsMax;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = exercise;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(e.exercise, style: theme.textTheme.titleMedium),
                ),
                Text(
                  formatTarget(e),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontFeatures: tabularFigures,
                  ),
                ),
                IconButton(
                  tooltip: 'Убрать упражнение',
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _Counter(
                  label: 'Подходы',
                  value: e.sets,
                  onChanged: onSets,
                  less: 'Меньше подходов',
                  more: 'Больше подходов',
                ),
                _Counter(
                  label: 'Повторы от',
                  value: e.repsMin,
                  onChanged: onRepsMin,
                  less: 'Меньше минимум повторов',
                  more: 'Больше минимум повторов',
                ),
                _Counter(
                  label: 'до',
                  value: e.repsMax,
                  onChanged: onRepsMax,
                  less: 'Меньше максимум повторов',
                  more: 'Больше максимум повторов',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.less,
    required this.more,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String less;
  final String more;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          tooltip: less,
          icon: const Icon(Icons.remove),
          onPressed: () => onChanged(-1),
        ),
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontFeatures: tabularFigures,
          ),
        ),
        IconButton(
          tooltip: more,
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(1),
        ),
      ],
    );
  }
}
