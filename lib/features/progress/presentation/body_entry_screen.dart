import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ids.dart';
import '../../../core/widgets/max_width.dart';
import '../../workout/domain/body.dart';
import '../../workout/presentation/workout_providers.dart';

/// Новый замер: вес обязателен, талия и грудь — по желанию.
class BodyEntryScreen extends ConsumerStatefulWidget {
  const BodyEntryScreen({super.key});

  @override
  ConsumerState<BodyEntryScreen> createState() => _BodyEntryScreenState();
}

class _BodyEntryScreenState extends ConsumerState<BodyEntryScreen> {
  final _weight = TextEditingController();
  final _waist = TextEditingController();
  final _chest = TextEditingController();
  String? _weightError;
  String? _waistError;
  String? _chestError;

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _chest.dispose();
    super.dispose();
  }

  /// null — пусто; NaN — не число.
  static double? _parse(String text) {
    if (text.trim().isEmpty) return null;
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    return v != null && v.isFinite && v > 0 ? v : double.nan;
  }

  Future<void> _save() async {
    final weight = _parse(_weight.text);
    final waist = _parse(_waist.text);
    final chest = _parse(_chest.text);
    setState(() {
      _weightError = weight == null
          ? 'Введите вес'
          : weight.isNaN
          ? 'Неверное число'
          : null;
      _waistError = waist?.isNaN ?? false ? 'Неверное число' : null;
      _chestError = chest?.isNaN ?? false ? 'Неверное число' : null;
    });
    if (_weightError != null || _waistError != null || _chestError != null) {
      return;
    }
    await ref
        .read(bodyEntriesProvider.notifier)
        .save(
          BodyEntry(
            id: newId(),
            date: DateTime.now(),
            weightKg: weight!,
            waistCm: waist,
            chestCm: chest,
          ),
        );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    TextField field(
      TextEditingController c,
      String label,
      String? error, {
      bool autofocus = false,
    }) => TextField(
      controller: c,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, errorText: error),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый замер'),
        actions: [TextButton(onPressed: _save, child: const Text('Сохранить'))],
      ),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            field(_weight, 'Вес, кг', _weightError, autofocus: true),
            const SizedBox(height: 12),
            field(_waist, 'Талия, см', _waistError),
            const SizedBox(height: 12),
            field(_chest, 'Грудь, см', _chestError),
          ],
        ),
      ),
    );
  }
}
