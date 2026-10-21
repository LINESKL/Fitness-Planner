/// Спортзал из OpenStreetMap; [id] — `osm-<type>-<id>`.
class Gym {
  const Gym({
    required this.id,
    required this.name,
    this.address,
    required this.lat,
    required this.lon,
  });

  final String id;
  final String name;
  final String? address;
  final double lat;
  final double lon;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'lat': lat,
    'lon': lon,
  };

  static Gym fromJson(Map<String, Object?> json) => Gym(
    id: json['id']! as String,
    name: json['name']! as String,
    address: json['address'] as String?,
    lat: (json['lat']! as num).toDouble(),
    lon: (json['lon']! as num).toDouble(),
  );
}

class GymLoadException implements Exception {
  const GymLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Поиск залов вокруг точки, ближайшие первыми.
abstract interface class GymSearch {
  Future<List<Gym>> nearby(double lat, double lon);
}
