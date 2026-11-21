import 'dart:async';

import 'package:fitness_planner/features/gyms/data/geolocator_location_service.dart';
import 'package:fitness_planner/features/gyms/domain/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePlatform extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  bool enabled = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission afterRequest = LocationPermission.denied;
  bool positionFails = false;
  Position? lastKnown;
  int requests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => enabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return afterRequest;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => lastKnown;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (positionFails) throw TimeoutException('t');
    return Position(
      latitude: 43.2,
      longitude: 76.9,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late _FakePlatform fake;
  late GeolocatorPlatform original;

  setUp(() {
    original = GeolocatorPlatform.instance;
    fake = _FakePlatform();
    GeolocatorPlatform.instance = fake;
  });
  tearDown(() => GeolocatorPlatform.instance = original);

  test('сервис выключен — LocationOff', () async {
    fake.enabled = false;
    expect(await GeolocatorLocationService().current(), isA<LocationOff>());
  });

  test('denied, после запроса снова denied — LocationDenied', () async {
    expect(await GeolocatorLocationService().current(), isA<LocationDenied>());
    expect(fake.requests, 1);
  });

  test('deniedForever — без запроса', () async {
    fake.permission = LocationPermission.deniedForever;
    expect(
      await GeolocatorLocationService().current(),
      isA<LocationDeniedForever>(),
    );
    expect(fake.requests, 0);
  });

  test('denied, после запроса deniedForever — LocationDeniedForever', () async {
    fake.afterRequest = LocationPermission.deniedForever;
    expect(
      await GeolocatorLocationService().current(),
      isA<LocationDeniedForever>(),
    );
  });

  test('denied, после запроса whileInUse — Located', () async {
    fake.afterRequest = LocationPermission.whileInUse;
    final r = await GeolocatorLocationService().current();
    expect(r, isA<Located>());
    expect((r as Located).lat, 43.2);
    expect(r.lon, 76.9);
  });

  test('ошибка получения позиции — LocationOff', () async {
    fake.permission = LocationPermission.always;
    fake.positionFails = true;
    expect(await GeolocatorLocationService().current(), isA<LocationOff>());
  });

  test('таймаут, но есть последняя известная точка — Located', () async {
    fake.permission = LocationPermission.always;
    fake.positionFails = true;
    fake.lastKnown = Position(
      latitude: 1,
      longitude: 2,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    final r = await GeolocatorLocationService().current() as Located;
    expect((r.lat, r.lon), (1, 2));
  });
}
