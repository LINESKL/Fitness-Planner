import 'gym.dart';

/// Выбранный пользователем зал («Мой зал»); null — не выбран.
abstract interface class MyGymRepository {
  Future<Gym?> get();
  Future<void> set(Gym? gym);
}
