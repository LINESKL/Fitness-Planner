import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/geolocator_location_service.dart';
import '../data/my_gym_repositories.dart';
import '../data/overpass_gym_search.dart';
import '../domain/gym.dart';
import '../domain/location_service.dart';
import '../domain/my_gym_repository.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

final gymSearchProvider = Provider<GymSearch>(
  (ref) => OverpassGymSearch.create(),
);

/// Источник тайлов карты; в тестах подменяется на пустой.
final tileProviderProvider = Provider<TileProvider>(
  (ref) => NetworkTileProvider(),
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
