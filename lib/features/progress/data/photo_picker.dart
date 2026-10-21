import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Камера или галерея недоступны (нет разрешения, нет камеры).
class PhotoPickException implements Exception {
  const PhotoPickException();
}

/// Фото прогресса: снимок с камеры или из галереи → копия в папке приложения.
class PhotoPicker {
  const PhotoPicker();

  /// Путь к сохранённому файлу; null — пользователь передумал.
  Future<String?> pick(ImageSource source, String id) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
    } on PlatformException {
      throw const PhotoPickException();
    }
    if (file == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/body-$id.jpg';
    await file.saveTo(path);
    return path;
  }
}

final photoPickerProvider = Provider<PhotoPicker>((ref) => const PhotoPicker());
