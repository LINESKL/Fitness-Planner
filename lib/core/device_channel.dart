import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Свой Platform Channel: код на Kotlin в android/.../MainActivity.kt.
/// Нет нативной стороны (iOS, тесты) — методы тихо ничего не делают.
class DeviceChannel {
  const DeviceChannel();

  static const name = 'kz.aliar.fitness_planner/device';
  static const _channel = MethodChannel(name);

  /// Заряд батареи, %; null — узнать не удалось.
  Future<int?> batteryLevel() async {
    try {
      return await _channel.invokeMethod<int>('batteryLevel');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Не гасить экран (во время тренировки).
  Future<void> keepScreenOn(bool on) async {
    try {
      await _channel.invokeMethod<void>('keepScreenOn', on);
    } on PlatformException {
      // Экран погаснет по таймауту — не критично.
    } on MissingPluginException {
      // Нет нативной стороны.
    }
  }
}

final deviceChannelProvider = Provider<DeviceChannel>(
  (ref) => const DeviceChannel(),
);
