import 'package:fitness_planner/core/device_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Настоящий канал на устройстве: ответ приходит из Kotlin (MainActivity.kt).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Kotlin отдаёт заряд и держит экран включённым', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('channel')));
    const device = DeviceChannel();

    final level = await device.batteryLevel();
    expect(level, inInclusiveRange(0, 100));

    await device.keepScreenOn(true);
    // Время проверить флаг окна снаружи: adb shell dumpsys window.
    await Future<void>.delayed(const Duration(seconds: 8));
    await device.keepScreenOn(false);
  });
}
