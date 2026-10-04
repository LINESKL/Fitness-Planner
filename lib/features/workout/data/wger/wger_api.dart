import 'package:dio/dio.dart';

import '../../domain/exercise_repository.dart';
import 'wger_dto.dart';

const wgerBaseUrl = 'https://wger.de/api/v2/';

/// Клиент открытого API wger.de: справочник упражнений, ключ не нужен.
class WgerApi {
  WgerApi(this._dio);

  factory WgerApi.create() => WgerApi(
    Dio(
      BaseOptions(
        baseUrl: wgerBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    ),
  );

  final Dio _dio;

  /// Весь каталог одним запросом: поиска по имени на сервере нет, ищем на устройстве.
  Future<List<WgerExerciseDto>> fetchExercises() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'exerciseinfo/',
        queryParameters: {'limit': 1000},
      );
      final results = response.data?['results'];
      if (results is! List) {
        throw const ExerciseLoadException('Сервер вернул неожиданный ответ');
      }
      return [for (final json in results) ?_parse(json)];
    } on DioException catch (e) {
      throw ExerciseLoadException(_messageFor(e));
    }
  }

  /// Одна битая запись не должна ронять весь каталог.
  static WgerExerciseDto? _parse(Object? json) {
    try {
      return WgerExerciseDto.fromJson(json! as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  static String _messageFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => 'Сервер не отвечает, попробуйте позже',
    DioExceptionType.connectionError => 'Нет подключения к интернету',
    DioExceptionType.badResponse =>
      'Ошибка сервера (${e.response?.statusCode})',
    _ => 'Не удалось загрузить упражнения',
  };
}
