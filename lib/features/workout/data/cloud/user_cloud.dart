import 'package:cloud_firestore/cloud_firestore.dart';

/// Облако одного пользователя: users/{uid}.
class UserCloud {
  UserCloud(this.user);

  final DocumentReference<Map<String, dynamic>> user;

  CollectionReference<Map<String, dynamic>> collection(String name) =>
      user.collection(name);

  /// Служебные документы: `meta/program`, `meta/favorites`.
  DocumentReference<Map<String, dynamic>> meta(String name) =>
      user.collection('meta').doc(name);
}

/// Id документа заметки: `/` в названии нельзя, заменяем на «∕».
String noteDocId(String exercise) => exercise.replaceAll('/', '∕');

/// Облачный вид заметки и избранного — общий для записи и слияния.
Map<String, Object?> noteToCloudJson(String exercise, String text) => {
  'exercise': exercise,
  'text': text.trim(),
};

Map<String, Object?> favoritesToCloudJson(Iterable<String> ids) => {
  'ids': ids.toList()..sort(),
};
