import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fitness_planner/features/gyms/data/my_gym_repositories.dart';
import 'package:fitness_planner/features/gyms/domain/gym.dart';
import 'package:fitness_planner/features/gyms/domain/location_service.dart';
import 'package:fitness_planner/features/gyms/presentation/gym_providers.dart';
import 'package:fitness_planner/features/gyms/presentation/gyms_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

const _iron = Gym(
  id: 'osm-node-1',
  name: 'Iron Gym',
  address: 'ул. Абая 1',
  lat: 43.241,
  lon: 76.891,
);
const _bare = Gym(
  id: 'osm-node-2',
  name: 'Без адреса',
  lat: 43.242,
  lon: 76.892,
);

final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Тайлы без сети: прозрачный пиксель.
class _FakeTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(Uint8List.fromList(_pixel));
}

class _FakeLocation implements LocationService {
  _FakeLocation(this.results);
  final List<LocationResult> results;
  int calls = 0;
  int appSettings = 0;
  int locationSettings = 0;

  @override
  Future<LocationResult> current() async =>
      results[calls++ < results.length ? calls - 1 : results.length - 1];
  @override
  Future<void> openAppSettings() async => appSettings++;
  @override
  Future<void> openLocationSettings() async => locationSettings++;
}

class _FakeSearch implements GymSearch {
  _FakeSearch(this.handler);
  final Future<List<Gym>> Function(double lat, double lon) handler;
  final calls = <(double, double)>[];

  @override
  Future<List<Gym>> nearby(double lat, double lon) {
    calls.add((lat, lon));
    return handler(lat, lon);
  }
}

Future<InMemoryMyGymRepository> _open(
  WidgetTester tester, {
  required _FakeLocation location,
  required _FakeSearch search,
  Gym? mine,
}) async {
  final repo = InMemoryMyGymRepository();
  await repo.set(mine);
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        locationServiceProvider.overrideWithValue(location),
        gymSearchProvider.overrideWithValue(search),
        tileProviderProvider.overrideWithValue(_FakeTiles()),
        myGymRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: GymsMapScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  const located = Located(43.24, 76.89);

  testWidgets('Located: поиск вокруг пользователя, метки и «Моё место»', (
    tester,
  ) async {
    final search = _FakeSearch((_, _) async => [_iron, _bare]);
    await _open(tester, location: _FakeLocation([located]), search: search);

    expect(find.text('Залы рядом'), findsOneWidget);
    expect(search.calls.last, (43.24, 76.89));
    expect(find.byKey(const ValueKey('me')), findsOneWidget);
    expect(find.byKey(const ValueKey('gym-osm-node-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('gym-osm-node-2')), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(find.text('Без геолокации ищем по центру карты'), findsNothing);
    expect(find.text('© OpenStreetMap'), findsOneWidget);
  });

  testWidgets('без геолокации: поиск по Алматы, «Моё место» скрыто', (
    tester,
  ) async {
    final search = _FakeSearch((_, _) async => [_iron]);
    await _open(
      tester,
      location: _FakeLocation([const LocationDenied()]),
      search: search,
    );

    expect(search.calls.single, (43.2389, 76.8897));
    expect(find.byIcon(Icons.my_location), findsNothing);
    expect(find.byKey(const ValueKey('me')), findsNothing);
  });

  testWidgets('LocationDenied: «Разрешить» → повторный запрос, плашка уходит', (
    tester,
  ) async {
    final location = _FakeLocation([const LocationDenied(), located]);
    final search = _FakeSearch((_, _) async => [_iron]);
    await _open(tester, location: location, search: search);

    expect(find.text('Без геолокации ищем по центру карты'), findsOneWidget);
    await tester.tap(find.text('Разрешить'));
    await tester.pumpAndSettle();

    expect(location.calls, 2);
    expect(find.text('Без геолокации ищем по центру карты'), findsNothing);
    expect(find.byKey(const ValueKey('me')), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsOneWidget);
    expect(search.calls.last, (43.24, 76.89));
  });

  testWidgets(
    'LocationDeniedForever: «Открыть настройки» → настройки и запрос',
    (tester) async {
      final location = _FakeLocation([const LocationDeniedForever(), located]);
      await _open(
        tester,
        location: location,
        search: _FakeSearch((_, _) async => []),
      );

      expect(find.text('Без геолокации ищем по центру карты'), findsOneWidget);
      await tester.tap(find.text('Открыть настройки'));
      await tester.pumpAndSettle();

      expect(location.appSettings, 1);
      expect(location.calls, 2);
      expect(find.text('Открыть настройки'), findsNothing);
    },
  );

  testWidgets('LocationOff: «Включить» → настройки геолокации и запрос', (
    tester,
  ) async {
    final location = _FakeLocation([const LocationOff(), located]);
    await _open(
      tester,
      location: location,
      search: _FakeSearch((_, _) async => []),
    );

    expect(find.text('Геолокация выключена'), findsOneWidget);
    await tester.tap(find.text('Включить'));
    await tester.pumpAndSettle();

    expect(location.locationSettings, 1);
    expect(location.calls, 2);
    expect(find.text('Геолокация выключена'), findsNothing);
  });

  testWidgets('метка → окно с названием, адресом и расстоянием; «Мой зал»', (
    tester,
  ) async {
    final search = _FakeSearch((_, _) async => [_iron, _bare]);
    final repo = await _open(
      tester,
      location: _FakeLocation([located]),
      search: search,
    );

    await tester.tap(find.byKey(const ValueKey('gym-osm-node-1')));
    await tester.pumpAndSettle();
    expect(find.text('Iron Gym'), findsOneWidget);
    expect(find.text('ул. Абая 1'), findsOneWidget);
    expect(find.textContaining(' м'), findsOneWidget);

    await tester.tap(find.text('Мой зал'));
    await tester.pumpAndSettle();

    expect((await repo.get())!.id, 'osm-node-1');
    expect(find.text('Зал сохранён'), findsOneWidget);
    expect(find.text('Мой зал'), findsNothing);
  });

  testWidgets(
    'у выбранного зала «Это мой зал» неактивна; без адреса — нет строки',
    (tester) async {
      await _open(
        tester,
        location: _FakeLocation([located]),
        search: _FakeSearch((_, _) async => [_iron, _bare]),
        mine: _iron,
      );

      await tester.tap(find.byKey(const ValueKey('gym-osm-node-1')));
      await tester.pumpAndSettle();
      final mine = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Это мой зал'),
      );
      expect(mine.onPressed, isNull);
      await tester.tapAt(const Offset(10, 10)); // закрыть окно
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('gym-osm-node-2')));
      await tester.pumpAndSettle();
      expect(find.text('Без адреса'), findsOneWidget);
      expect(find.textContaining('ул.'), findsNothing);
      expect(find.text('Мой зал'), findsOneWidget);
    },
  );

  testWidgets('«Искать здесь» ищет по центру карты', (tester) async {
    final search = _FakeSearch((_, _) async => []);
    await _open(
      tester,
      location: _FakeLocation([const LocationDenied()]),
      search: search,
    );

    await tester.drag(find.byType(FlutterMap), const Offset(200, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Искать здесь'));
    await tester.pumpAndSettle();

    expect(search.calls, hasLength(2));
    expect(search.calls.last.$2, lessThan(76.8897)); // сдвинули карту на запад
  });

  testWidgets('два «Искать здесь» во время загрузки → результат последнего', (
    tester,
  ) async {
    final pending = <Completer<List<Gym>>>[];
    final search = _FakeSearch((_, _) {
      if (pending.isEmpty) return Future.value(<Gym>[]);
      return pending.removeAt(0).future;
    });
    // Поиск №1 (старт) пустой; №2 и №3 ждут.
    final c2 = Completer<List<Gym>>(), c3 = Completer<List<Gym>>();
    await _open(
      tester,
      location: _FakeLocation([const LocationDenied()]),
      search: search,
    );
    pending.addAll([c2, c3]);

    await tester.tap(find.text('Искать здесь'));
    await tester.pump();
    await tester.tap(find.text('Искать здесь'));
    await tester.pump();
    c3.complete([_bare]);
    await tester.pump();
    c2.complete([_iron]); // запоздавший старый ответ
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('gym-osm-node-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('gym-osm-node-1')), findsNothing);
  });

  testWidgets('ошибка поиска → текст и «Повторить»', (tester) async {
    var fail = true;
    final search = _FakeSearch((_, _) async {
      if (fail) throw const GymLoadException('Нет подключения к интернету');
      return [_iron];
    });
    await _open(tester, location: _FakeLocation([located]), search: search);

    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(search.calls, hasLength(2));
    expect(find.text('Нет подключения к интернету'), findsNothing);
    expect(find.byKey(const ValueKey('gym-osm-node-1')), findsOneWidget);
  });

  testWidgets('пустой результат → «Рядом залов не нашлось»', (tester) async {
    await _open(
      tester,
      location: _FakeLocation([located]),
      search: _FakeSearch((_, _) async => []),
    );
    expect(find.text('Рядом залов не нашлось'), findsOneWidget);
  });
}
