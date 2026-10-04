import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fitness_planner/features/workout/data/remote_exercise_repository.dart';
import 'package:fitness_planner/features/workout/data/wger/wger_api.dart';
import 'package:fitness_planner/features/workout/data/wger/wger_dto.dart';
import 'package:fitness_planner/features/workout/domain/exercise_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> exerciseJson({
  int id = 1,
  String category = 'Chest',
  List<(int, String)> names = const [(2, 'Bench Press')],
  List<(String, bool)> images = const [],
}) => {
  'id': id,
  'category': {'id': 11, 'name': category},
  'translations': [
    for (final (language, name) in names)
      {'language': language, 'name': name, 'description': ''},
  ],
  'images': [
    for (final (url, isMain) in images) {'image': url, 'is_main': isMain},
  ],
  'muscles': [],
};

/// Отдаёт заготовленный ответ вместо сети.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

WgerApi apiWith(FakeAdapter adapter) => WgerApi(
  Dio(BaseOptions(baseUrl: wgerBaseUrl))..httpClientAdapter = adapter,
);

void main() {
  group('WgerExerciseDto', () {
    test('берёт русское имя, если оно есть', () {
      final e = WgerExerciseDto.fromJson(
        exerciseJson(names: [(2, 'Squats'), (5, 'Приседания')]),
      ).toExercise();

      expect(e?.name, 'Приседания');
    });

    test('без русского — английское имя', () {
      expect(
        WgerExerciseDto.fromJson(exerciseJson()).toExercise()?.name,
        'Bench Press',
      );
    });

    test('без ru и en — упражнение пропускается', () {
      expect(
        WgerExerciseDto.fromJson(exerciseJson(names: [(1, 'Bankdrücken')]))
            .toExercise(),
        isNull,
      );
    });

    test('категория переводится, неизвестная остаётся как есть', () {
      expect(
        WgerExerciseDto.fromJson(exerciseJson()).toExercise()?.muscleGroup,
        'Грудь',
      );
      expect(
        WgerExerciseDto.fromJson(exerciseJson(category: 'Neck'))
            .toExercise()
            ?.muscleGroup,
        'Neck',
      );
    });

    test('картинка — главная, иначе первая', () {
      final e = WgerExerciseDto.fromJson(
        exerciseJson(images: [('a.png', false), ('b.png', true)]),
      ).toExercise();

      expect(e?.imageUrl, 'b.png');
      expect(e?.id, 'wger-1');
    });
  });

  group('WgerApi', () {
    test('запрашивает exerciseinfo и разбирает results', () async {
      final adapter = FakeAdapter(
        (_) => jsonBody({
          'count': 1,
          'results': [exerciseJson()],
        }),
      );

      final list = await apiWith(adapter).fetchExercises();

      expect(list.single.id, 1);
      expect(adapter.last?.path, 'exerciseinfo/');
      expect(adapter.last?.queryParameters['limit'], 1000);
    });

    test('нет сети — ExerciseLoadException с понятным текстом', () async {
      final adapter = FakeAdapter(
        (o) => throw DioException.connectionError(
          requestOptions: o,
          reason: 'offline',
        ),
      );

      expect(
        apiWith(adapter).fetchExercises(),
        throwsA(
          isA<ExerciseLoadException>().having(
            (e) => e.message,
            'message',
            'Нет подключения к интернету',
          ),
        ),
      );
    });

    test('ошибка сервера — код в сообщении', () async {
      final adapter = FakeAdapter((_) => jsonBody({'detail': 'x'}, 503));

      expect(
        apiWith(adapter).fetchExercises(),
        throwsA(
          isA<ExerciseLoadException>().having(
            (e) => e.message,
            'message',
            contains('503'),
          ),
        ),
      );
    });
  });

  test('репозиторий: встроенные первыми, дубли по имени убраны', () async {
    final adapter = FakeAdapter(
      (_) => jsonBody({
        'results': [
          exerciseJson(id: 7, names: [(5, 'приседания')]),
          exerciseJson(id: 8, names: [(2, 'Deadlift')], category: 'Back'),
        ],
      }),
    );

    final list = await RemoteExerciseRepository(apiWith(adapter))
        .fetchExercises();

    expect(list.first.name, 'Жим лёжа');
    expect(list.where((e) => e.name.toLowerCase() == 'приседания').length, 1);
    expect(list.last.name, 'Deadlift');
  });
}
