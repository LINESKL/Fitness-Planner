import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geolocator_location_service.dart';
import '../data/my_gym_repositories.dart';
import '../domain/gym.dart';
import '../domain/location_service.dart';
import '../domain/my_gym_repository.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

final myGymRepositoryProvider = Provider<MyGymRepository>(
  (ref) => InMemoryMyGymRepository(),
);

/// Выбранный зал; `set(null)` — сбросить.
final myGymProvider = AsyncNotifierProvider<MyGymNotifier, Gym?>(
  MyGymNotifier.new,
);

class MyGymNotifier extends AsyncNotifier<Gym?> {
  @override
  Future<Gym?> build() => ref.read(myGymRepositoryProvider).get();

  Future<void> set(Gym? gym) async {
    await ref.read(myGymRepositoryProvider).set(gym);
    ref.invalidateSelf();
  }
}
