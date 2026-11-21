import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ошибки Flutter и асинхронные ошибки уходят в Crashlytics; в debug сбор выключен.
Future<void> setupCrashReporting() async {
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Тестовый сбой из профиля. Обёртка, чтобы Firebase не трогался до вызова.
final crashProvider = Provider<void Function()>(
  (ref) =>
      () => FirebaseCrashlytics.instance.crash(),
);
