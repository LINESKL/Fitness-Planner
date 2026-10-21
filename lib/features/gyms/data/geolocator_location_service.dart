import 'package:geolocator/geolocator.dart';

import '../domain/location_service.dart';

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationResult> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationOff();
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.deniedForever:
        return const LocationDeniedForever();
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return const LocationDenied();
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        break;
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return Located(p.latitude, p.longitude);
    } catch (_) {
      // Таймаут, выключенный сервис и т.п. — считаем геолокацию недоступной.
      return const LocationOff();
    }
  }

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
