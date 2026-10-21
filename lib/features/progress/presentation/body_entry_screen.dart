import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../../core/ids.dart';
import '../../../core/widgets/max_width.dart';
import '../../workout/domain/body.dart';
import '../../workout/presentation/workout_providers.dart';
import '../data/photo_picker.dart';

/// Новый замер: вес обязателен, талия, грудь и фото — по желанию.
class BodyEntryScreen extends ConsumerStatefulWidget {
  const BodyEntryScreen({super.key});

  @override
  ConsumerState<BodyEntryScreen> createState() => _BodyEntryScreenState();
}

class _BodyEntryScreenState extends ConsumerState<BodyEntryScreen> {
  final _weight = TextEditingController();
  final _waist = TextEditingController();
  final _chest = TextEditingController();
  final _id = newId();
  String? _photo;
  String? _weightError;
  String? _waistError;
  String? _chestError;
  bool _saving = false;

  /// Снимок, который не попал в сохранённый замер, не должен копиться на диске.
  void _dropPhoto() {
    final photo = _photo;
    if (photo == null) return;
    _photo = null;
    File(photo).delete().ignore();
  }

  @override
  void dispose() {
    if (!_saving) _dropPhoto();
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

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final path = await ref.read(photoPickerProvider).pick(source, _id);
      if (path != null && mounted) setState(() => _photo = path);
    } on PhotoPickException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Не удалось открыть камеру'
                : 'Не удалось открыть галерею',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
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
    setState(() => _saving = true);
    await ref
        .read(bodyEntriesProvider.notifier)
        .save(
          BodyEntry(
            id: _id,
            date: DateTime.now(),
            weightKg: weight!,
            waistCm: waist,
            chestCm: chest,
            photoPath: _photo,
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
        actions: [
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
            field(_weight, 'Вес, кг', _weightError, autofocus: true),
            const SizedBox(height: 12),
            field(_waist, 'Талия, см', _waistError),
            const SizedBox(height: 12),
            field(_chest, 'Грудь, см', _chestError),
            const SizedBox(height: 20),
            if (_photo case final photo?)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(photo),
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      cacheHeight: 720,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 240,
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Убрать фото',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_dropPhoto),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Камера'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Галерея'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
