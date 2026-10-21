import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/workout/data/cloud/user_cloud.dart';

/// Тонкая обёртка над FirebaseMessaging — чтобы подменять в тестах.
abstract interface class PushMessaging {
  Future<bool> requestPermission();
  Future<String?> token();
  Future<void> deleteToken();
  Stream<String> tokenRefresh();
  Stream<({String? title, String? body})> foreground();
}

class FirebasePushMessaging implements PushMessaging {
  final _fm = FirebaseMessaging.instance;

  @override
  Future<bool> requestPermission() async {
    final s = (await _fm.requestPermission()).authorizationStatus;
    return s == AuthorizationStatus.authorized ||
        s == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() => _fm.getToken();

  @override
  Future<void> deleteToken() => _fm.deleteToken();

  @override
  Stream<String> tokenRefresh() => _fm.onTokenRefresh;

  @override
  Stream<({String? title, String? body})> foreground() => FirebaseMessaging
      .onMessage
      .map((m) => (title: m.notification?.title, body: m.notification?.body));
}

/// main подставляет FirebasePushMessaging; в тестах null — push выключен.
final pushMessagingProvider = Provider<PushMessaging?>((ref) => null);

/// Ключ для показа сообщений поверх любого экрана.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showSnack(String text) => scaffoldMessengerKey.currentState?.showSnackBar(
  SnackBar(content: Text(text)),
);

/// Сохраняет токен устройства в users/{uid} и показывает push на переднем плане.
class PushService {
  PushService(this.messaging);

  final PushMessaging messaging;
  final _subs = <StreamSubscription<Object?>>[];

  /// Поколение: stop() и новый start() делают чужие незавершённые start устаревшими.
  var _gen = 0;

  Future<void> start(UserCloud cloud, void Function(String text) show) async {
    final cancelled = stop();
    final gen = _gen;
    await cancelled;
    bool stale() => gen != _gen;
    try {
      final granted = await messaging.requestPermission();
      if (!granted || stale()) return;
      Future<void> save(String? token) async {
        if (token == null || stale()) return;
        try {
          await cloud.user.set({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('push: токен не сохранён: $e');
        }
      }

      _subs
        ..add(messaging.tokenRefresh().listen(save, onError: _log))
        ..add(
          messaging.foreground().listen((m) {
            final text = [m.title, m.body].whereType<String>().join(' — ');
            if (text.isNotEmpty) show(text);
          }, onError: _log),
        );
      await save(await messaging.token());
    } catch (e) {
      _log(e);
    }
  }

  static void _log(Object e) => debugPrint('push: $e');

  Future<void> stop() async {
    _gen++;
    final old = List.of(_subs);
    _subs.clear();
    for (final s in old) {
      await s.cancel();
    }
  }
}
