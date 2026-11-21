import 'dart:convert';
import 'dart:typed_data';

import 'package:fitness_planner/features/gyms/domain/gym.dart';
import 'package:fitness_planner/features/gyms/domain/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

/// Тайлы без сети: прозрачный пиксель.
class FakeTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(Uint8List.fromList(_pixel));
}

class FakeLocation implements LocationService {
  FakeLocation(this.results);
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

class FakeSearch implements GymSearch {
  FakeSearch(this.handler);
  final Future<List<Gym>> Function(double lat, double lon) handler;
  final calls = <(double, double)>[];

  @override
  Future<List<Gym>> nearby(double lat, double lon) {
    calls.add((lat, lon));
    return handler(lat, lon);
  }
}
