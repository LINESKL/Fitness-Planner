import 'package:hive_ce/hive_ce.dart';

import '../domain/gym.dart';
import '../domain/my_gym_repository.dart';

class HiveMyGymRepository implements MyGymRepository {
  HiveMyGymRepository(this._box);

  static const boxName = 'my_gym';
  static const _key = 'current';

  static Future<HiveMyGymRepository> open() async =>
      HiveMyGymRepository(await Hive.openBox<Map>(boxName));

  final Box<Map> _box;

  @override
  Future<Gym?> get() async {
    final raw = _box.get(_key);
    return raw == null ? null : Gym.fromJson(Map<String, Object?>.from(raw));
  }

  @override
  Future<void> set(Gym? gym) =>
      gym == null ? _box.delete(_key) : _box.put(_key, gym.toJson());
}

class InMemoryMyGymRepository implements MyGymRepository {
  Gym? _gym;

  @override
  Future<Gym?> get() async => _gym;

  @override
  Future<void> set(Gym? gym) async => _gym = gym;
}
