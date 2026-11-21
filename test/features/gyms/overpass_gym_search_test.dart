import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fitness_planner/features/gyms/data/overpass_gym_search.dart';
import 'package:fitness_planner/features/gyms/domain/gym.dart';
import 'package:flutter_test/flutter_test.dart';

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

OverpassGymSearch searchWith(FakeAdapter adapter) =>
    OverpassGymSearch(Dio()..httpClientAdapter = adapter);

OverpassGymSearch searchReturning(Object elements) =>
    searchWith(FakeAdapter((_) => jsonBody({'elements': elements})));

DioException dioError(DioExceptionType type) =>
    DioException(requestOptions: RequestOptions(), type: type);

Future<void> expectLoadError(OverpassGymSearch search, String message) async {
  await expectLater(
    search.nearby(43.2, 76.9),
    throwsA(
      isA<GymLoadException>().having((e) => e.message, 'message', message),
    ),
  );
}

void main() {
  test('тело запроса: поле data с радиусом 3000 и обоими фильтрами', () async {
    final adapter = FakeAdapter((_) => jsonBody({'elements': []}));
    await searchWith(adapter).nearby(43.2, 76.9);

    final body = (adapter.last!.data as Map)['data'] as String;
    expect(adapter.last!.method, 'POST');
    expect(body, contains('around:3000,43.2,76.9'));
    expect(body, contains('"leisure"="fitness_centre"'));
    expect(body, contains('"sport"="fitness"'));
    expect(body, contains('out center tags;'));
  });

  test('запрос подписан User-Agent приложения (правила Overpass)', () async {
    final adapter = FakeAdapter((_) => jsonBody({'elements': []}));
    await searchWith(adapter).nearby(43.2, 76.9);

    expect(
      adapter.last!.headers['User-Agent'],
      startsWith('kz.aliar.fitness_planner'),
    );
  });

  test('node: координаты lat/lon, id osm-node-…', () async {
    final gyms = await searchReturning([
      {
        'type': 'node',
        'id': 123,
        'lat': 43.21,
        'lon': 76.91,
        'tags': {'name': 'Iron'},
      },
    ]).nearby(43.2, 76.9);

    expect(gyms.single.id, 'osm-node-123');
    expect(gyms.single.name, 'Iron');
    expect(gyms.single.lat, 43.21);
    expect(gyms.single.lon, 76.91);
  });

  test('way: координаты из center', () async {
    final gyms = await searchReturning([
      {
        'type': 'way',
        'id': 7,
        'center': {'lat': 43.22, 'lon': 76.92},
        'tags': {'name': 'Way'},
      },
    ]).nearby(43.2, 76.9);

    expect(gyms.single.id, 'osm-way-7');
    expect(gyms.single.lat, 43.22);
    expect(gyms.single.lon, 76.92);
  });

  test('элемент без координат пропускается', () async {
    final gyms = await searchReturning([
      {
        'type': 'relation',
        'id': 1,
        'tags': {'name': 'Нет координат'},
      },
    ]).nearby(43.2, 76.9);

    expect(gyms, isEmpty);
  });

  test('без name — «Фитнес-зал»', () async {
    final gyms = await searchReturning([
      {'type': 'node', 'id': 1, 'lat': 43.2, 'lon': 76.9},
    ]).nearby(43.2, 76.9);

    expect(gyms.single.name, 'Фитнес-зал');
  });

  test('пустое или пробельное name — «Фитнес-зал»', () async {
    final gyms = await searchReturning([
      {
        'type': 'node',
        'id': 1,
        'lat': 43.2,
        'lon': 76.9,
        'tags': {'name': '  '},
      },
    ]).nearby(43.2, 76.9);

    expect(gyms.single.name, 'Фитнес-зал');
  });

  test('адрес: улица + дом, только улица, иначе null', () async {
    Map<String, Object> node(int id, Map<String, String> tags) => {
      'type': 'node',
      'id': id,
      'lat': 43.2 + id / 1000,
      'lon': 76.9,
      'tags': tags,
    };
    final gyms = await searchReturning([
      node(1, {'addr:street': 'Абая', 'addr:housenumber': '10'}),
      node(2, {'addr:street': 'Абая'}),
      node(3, {'name': 'Без адреса'}),
    ]).nearby(43.2, 76.9);

    expect([for (final g in gyms) g.address], ['Абая 10', 'Абая', null]);
  });

  test('дубликат id попадает один раз', () async {
    final element = {'type': 'node', 'id': 5, 'lat': 43.2, 'lon': 76.9};
    final gyms = await searchReturning([element, element]).nearby(43.2, 76.9);

    expect(gyms, hasLength(1));
  });

  test('сортировка по расстоянию от точки запроса', () async {
    final gyms = await searchReturning([
      {'type': 'node', 'id': 1, 'lat': 43.25, 'lon': 76.9},
      {'type': 'node', 'id': 2, 'lat': 43.201, 'lon': 76.9},
      {'type': 'node', 'id': 3, 'lat': 43.21, 'lon': 76.9},
    ]).nearby(43.2, 76.9);

    expect(
      [for (final g in gyms) g.id],
      ['osm-node-2', 'osm-node-3', 'osm-node-1'],
    );
  });

  test('connectionError → «Нет подключения к интернету»', () {
    final search = searchWith(
      FakeAdapter((o) => throw dioError(DioExceptionType.connectionError)),
    );
    return expectLoadError(search, 'Нет подключения к интернету');
  });

  test('таймаут → «Сервер не отвечает, попробуйте позже»', () {
    final search = searchWith(
      FakeAdapter((o) => throw dioError(DioExceptionType.receiveTimeout)),
    );
    return expectLoadError(search, 'Сервер не отвечает, попробуйте позже');
  });

  for (final status in [429, 504]) {
    test('HTTP $status → «Не удалось загрузить залы»', () {
      final search = searchWith(
        FakeAdapter((_) => jsonBody({'remark': 'busy'}, status)),
      );
      return expectLoadError(search, 'Не удалось загрузить залы');
    });
  }

  test('HTML вместо JSON → «Не удалось загрузить залы»', () {
    final search = searchWith(
      FakeAdapter(
        (_) => ResponseBody.fromString(
          '<html>busy</html>',
          200,
          headers: {
            Headers.contentTypeHeader: ['text/html'],
          },
        ),
      ),
    );
    return expectLoadError(search, 'Не удалось загрузить залы');
  });

  test('elements не список → «Не удалось загрузить залы»', () {
    return expectLoadError(
      searchReturning({'oops': 1}),
      'Не удалось загрузить залы',
    );
  });

  test('formatDistance: метры и километры', () {
    expect(formatDistance(850), '850 м');
    expect(formatDistance(850.6), '851 м');
    expect(formatDistance(999.4), '999 м');
    expect(formatDistance(1000), '1.0 км');
    expect(formatDistance(2349), '2.3 км');
  });

  test('Gym: JSON туда-обратно', () {
    const gym = Gym(
      id: 'osm-node-1',
      name: 'Iron',
      address: 'Абая 10',
      lat: 43.2,
      lon: 76.9,
    );
    final json = gym.toJson();
    expect(json, {
      'id': 'osm-node-1',
      'name': 'Iron',
      'address': 'Абая 10',
      'lat': 43.2,
      'lon': 76.9,
    });
    final back = Gym.fromJson(json);
    expect(back.id, gym.id);
    expect(back.name, gym.name);
    expect(back.address, gym.address);
    expect(back.lat, gym.lat);
    expect(back.lon, gym.lon);
    expect(Gym.fromJson({...json, 'address': null}).address, isNull);
  });
}
