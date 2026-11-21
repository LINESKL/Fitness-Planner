import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../domain/gym.dart';

const overpassUrl = 'https://overpass-api.de/api/interpreter';
const gymSearchRadiusMeters = 3000;
const _defaultName = 'Фитнес-зал';
const _failed = 'Не удалось загрузить залы';
const _userAgent =
    'kz.aliar.fitness_planner/1.0 (+https://github.com/LINESKL/Fitness-Planner)';

/// Залы из OpenStreetMap через Overpass API, ключ не нужен.
class OverpassGymSearch implements GymSearch {
  OverpassGymSearch(this._dio);

  factory OverpassGymSearch.create() => OverpassGymSearch(
    Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ),
    ),
  );

  final Dio _dio;

  @override
  Future<List<Gym>> nearby(double lat, double lon) async {
    final List<Object?> elements;
    try {
      final response = await _dio.post<Object?>(
        overpassUrl,
        data: {'data': _query(lat, lon)},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          // Правила Overpass требуют User-Agent, по которому видно приложение.
          headers: {'User-Agent': _userAgent},
        ),
      );
      final data = response.data;
      final found = data is Map ? data['elements'] : null;
      if (found is! List) throw const GymLoadException(_failed);
      elements = found;
    } on DioException catch (e) {
      throw GymLoadException(_messageFor(e));
    }

    final byId = <String, Gym>{};
    for (final element in elements) {
      final gym = _parse(element);
      if (gym != null) byId.putIfAbsent(gym.id, () => gym);
    }
    const distance = Distance();
    final origin = LatLng(lat, lon);
    double from(Gym g) => distance(origin, LatLng(g.lat, g.lon));
    return byId.values.toList()..sort((a, b) => from(a).compareTo(from(b)));
  }

  static String _query(double lat, double lon) =>
      '[out:json][timeout:25];\n'
      '(nwr["leisure"="fitness_centre"](around:$gymSearchRadiusMeters,$lat,$lon);\n'
      ' nwr["sport"="fitness"](around:$gymSearchRadiusMeters,$lat,$lon););\n'
      'out center tags;';

  static String _name(Object? raw) =>
      raw is String && raw.trim().isNotEmpty ? raw : _defaultName;

  /// Одна битая запись не должна ронять весь список.
  static Gym? _parse(Object? element) {
    try {
      final e = element! as Map;
      final center = e['center'] as Map?;
      final lat = (e['lat'] ?? center?['lat']) as num?;
      final lon = (e['lon'] ?? center?['lon']) as num?;
      if (lat == null || lon == null) return null;
      final tags = (e['tags'] as Map?) ?? const {};
      final address = [
        tags['addr:street'],
        tags['addr:housenumber'],
      ].whereType<String>().join(' ');
      return Gym(
        id: 'osm-${e['type']}-${e['id']}',
        name: _name(tags['name']),
        address: address.isEmpty ? null : address,
        lat: lat.toDouble(),
        lon: lon.toDouble(),
      );
    } on Object {
      return null;
    }
  }

  static String _messageFor(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => 'Сервер не отвечает, попробуйте позже',
    DioExceptionType.connectionError => 'Нет подключения к интернету',
    _ => _failed,
  };
}

/// «850 м» до километра, дальше «2.3 км».
String formatDistance(double meters) => meters < 1000
    ? '${meters.round()} м'
    : '${(meters / 1000).toStringAsFixed(1)} км';
