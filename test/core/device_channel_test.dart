import 'package:fitness_planner/core/device_channel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const channel = MethodChannel(DeviceChannel.name);

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('заряд и экран — вызовы уходят в Kotlin по каналу', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'batteryLevel' ? 42 : null;
    });

    expect(await const DeviceChannel().batteryLevel(), 42);
    await const DeviceChannel().keepScreenOn(true);

    expect(
      [for (final c in calls) (c.method, c.arguments)],
      [('batteryLevel', null), ('keepScreenOn', true)],
    );
  });

  test('нет нативной стороны (iOS, тесты) — null и без ошибок', () async {
    expect(await const DeviceChannel().batteryLevel(), isNull);
    await const DeviceChannel().keepScreenOn(true);
  });

  test('ошибка на нативной стороне — null', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'UNAVAILABLE'),
    );

    expect(await const DeviceChannel().batteryLevel(), isNull);
  });
}
