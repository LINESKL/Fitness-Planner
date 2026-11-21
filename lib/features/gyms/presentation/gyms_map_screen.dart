import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/overpass_gym_search.dart';
import '../domain/gym.dart';
import '../domain/location_service.dart';
import 'gym_providers.dart';

const _almaty = LatLng(43.2389, 76.8897);

class GymsMapScreen extends ConsumerStatefulWidget {
  const GymsMapScreen({super.key});

  @override
  ConsumerState<GymsMapScreen> createState() => _GymsMapScreenState();
}

class _GymsMapScreenState extends ConsumerState<GymsMapScreen>
    with WidgetsBindingObserver {
  final _map = MapController();
  bool _ready = false;
  VoidCallback? _afterReady;

  LocationResult? _location;
  LatLng _searchCenter = _almaty;
  List<Gym>? _gyms;
  String? _error;
  bool _loading = false;
  bool _locating = false;
  int _request = 0; // применяем только ответ последнего поиска

  LatLng? get _user => switch (_location) {
    Located(:final lat, :final lon) => LatLng(lat, lon),
    _ => null,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Вернулись из системных настроек — перепроверяем геолокацию.
    if (state == AppLifecycleState.resumed && _location is! Located) {
      _locate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _map.dispose();
    super.dispose();
  }

  /// Камеру можно двигать только после первой отрисовки карты.
  void _camera(VoidCallback op) => _ready ? op() : _afterReady = op;

  Future<void> _locate() async {
    if (_locating) return;
    _locating = true;
    try {
      final result = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      setState(() => _location = result);
      final user = _user;
      if (user == null) return await _search(_searchCenter);
      _camera(() => _map.move(user, 15));
      await _search(user);
    } finally {
      _locating = false;
    }
  }

  Future<void> _search(LatLng center) async {
    final id = ++_request;
    setState(() {
      _searchCenter = center;
      _loading = true;
      _error = null;
    });
    try {
      final gyms = await ref
          .read(gymSearchProvider)
          .nearby(center.latitude, center.longitude);
      if (!mounted || id != _request) return;
      setState(() {
        _gyms = gyms;
        _loading = false;
      });
      _fit(gyms);
    } on GymLoadException catch (e) {
      if (!mounted || id != _request) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _fit(List<Gym> gyms) {
    if (gyms.isEmpty) return;
    final points = [?_user, for (final g in gyms) LatLng(g.lat, g.lon)];
    // Одна точка — нулевая область, fit выдаст бесконечный зум.
    if (points.toSet().length == 1) {
      return _camera(() => _map.move(points[0], 15));
    }
    _camera(
      () => _map.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(48),
        ),
      ),
    );
  }

  void _showGym(Gym gym) {
    final user = _user;
    final meters = const Distance()(
      user ?? _searchCenter,
      LatLng(gym.lat, gym.lon),
    );
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _GymSheet(gym: gym, distance: formatDistance(meters)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.read(locationServiceProvider);
    final mine = ref.watch(myGymProvider).value;
    final user = _user;
    final gyms = _gyms ?? const <Gym>[];

    final banner = switch (_location) {
      LocationDenied() => (
        'Без геолокации ищем по центру карты',
        'Разрешить',
        _locate,
      ),
      LocationDeniedForever() => (
        'Без геолокации ищем по центру карты',
        'Открыть настройки',
        location.openAppSettings,
      ),
      LocationOff() => (
        'Геолокация выключена',
        'Включить',
        location.openLocationSettings,
      ),
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Залы рядом')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _almaty,
              initialZoom: 13,
              onMapReady: () {
                _ready = true;
                _afterReady?.call();
                _afterReady = null;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'kz.aliar.fitness_planner',
                tileProvider: ref.watch(tileProviderProvider),
              ),
              MarkerLayer(
                markers: [
                  if (user != null)
                    Marker(
                      point: user,
                      width: 20,
                      height: 20,
                      child: Container(
                        key: const ValueKey('me'),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  for (final g in gyms)
                    _gymMarker(g, selected: g.id == mine?.id),
                ],
              ),
              const SimpleAttributionWidget(source: Text('© OpenStreetMap')),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (banner != null)
                  MaterialBanner(
                    content: Text(banner.$1),
                    actions: [
                      TextButton(onPressed: banner.$3, child: Text(banner.$2)),
                    ],
                  ),
                if (_error != null)
                  MaterialBanner(
                    content: Text(_error!),
                    actions: [
                      TextButton(
                        onPressed: () => _search(_searchCenter),
                        child: const Text('Повторить'),
                      ),
                    ],
                  )
                else if (_gyms != null && gyms.isEmpty && !_loading)
                  const MaterialBanner(
                    content: Text('Рядом залов не нашлось'),
                    actions: [SizedBox.shrink()],
                  ),
              ],
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            left: 16,
            bottom: 32,
            child: Row(
              spacing: 8,
              children: [
                if (user != null)
                  FloatingActionButton.small(
                    heroTag: null,
                    tooltip: 'Моё место',
                    onPressed: () => _map.move(user, 15),
                    child: const Icon(Icons.my_location),
                  ),
                FilledButton.icon(
                  onPressed: () => _search(_map.camera.center),
                  icon: const Icon(Icons.search),
                  label: const Text('Искать здесь'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Marker _gymMarker(Gym g, {required bool selected}) {
    final size = selected ? 48.0 : 36.0;
    return Marker(
      point: LatLng(g.lat, g.lon),
      width: size,
      height: size,
      child: GestureDetector(
        key: ValueKey('gym-${g.id}'),
        onTap: () => _showGym(g),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.deepOrange,
            shape: BoxShape.circle,
            border: selected ? Border.all(color: Colors.white, width: 3) : null,
          ),
          child: Icon(
            Icons.fitness_center,
            color: Colors.white,
            size: size * 0.55,
          ),
        ),
      ),
    );
  }
}

class _GymSheet extends ConsumerWidget {
  const _GymSheet({required this.gym, required this.distance});

  final Gym gym;
  final String distance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMine = ref.watch(myGymProvider).value?.id == gym.id;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(gym.name, style: Theme.of(context).textTheme.titleLarge),
            if (gym.address != null) Text(gym.address!),
            Text(distance),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isMine
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        try {
                          await ref.read(myGymProvider.notifier).set(gym);
                        } on Object {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Не удалось сохранить зал'),
                            ),
                          );
                          return;
                        }
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Зал сохранён')),
                        );
                        navigator.pop();
                      },
                child: Text(isMine ? 'Это мой зал' : 'Мой зал'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
