/// Результат запроса геопозиции.
sealed class LocationResult {
  const LocationResult();
}

final class Located extends LocationResult {
  const Located(this.lat, this.lon);
  final double lat, lon;
}

/// Сервис геолокации выключен (или позицию получить не удалось).
final class LocationOff extends LocationResult {
  const LocationOff();
}

/// Отказ, можно спросить снова.
final class LocationDenied extends LocationResult {
  const LocationDenied();
}

final class LocationDeniedForever extends LocationResult {
  const LocationDeniedForever();
}

abstract interface class LocationService {
  /// Проверить сервис → разрешение (запросить при отказе) → позиция.
  Future<LocationResult> current();
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}
