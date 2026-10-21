import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:fitness_planner/core/push_service.dart';
import 'package:fitness_planner/features/workout/data/cloud/user_cloud.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMessaging implements PushMessaging {
  FakeMessaging({this.granted = true, this.currentToken = 't1'});

  final bool granted;
  final String? currentToken;
  final refresh = StreamController<String>.broadcast();
  final messages =
      StreamController<({String? title, String? body})>.broadcast();

  @override
  Future<bool> requestPermission() async => granted;
  @override
  Future<String?> token() async => currentToken;
  @override
  Stream<String> tokenRefresh() => refresh.stream;
  @override
  Stream<({String? title, String? body})> foreground() => messages.stream;
}

void main() {
  late FakeFirebaseFirestore db;
  late UserCloud cloud;
  late List<String> shown;

  setUp(() {
    db = FakeFirebaseFirestore();
    cloud = UserCloud(db.collection('users').doc('u1'));
    shown = [];
  });

  Future<Map<String, dynamic>?> userDoc() async =>
      (await db.collection('users').doc('u1').get()).data();

  test('разрешение дано: токен пишется в users/u1', () async {
    await PushService(FakeMessaging()).start(cloud, shown.add);
    final data = await userDoc();
    expect(data!['fcmToken'], 't1');
    expect(data.containsKey('tokenUpdatedAt'), isTrue);
  });

  test('обновление токена перезаписывает fcmToken', () async {
    final m = FakeMessaging();
    await PushService(m).start(cloud, shown.add);
    m.refresh.add('t2');
    await pumpEventQueue();
    expect((await userDoc())!['fcmToken'], 't2');
  });

  test('отказ в разрешении: ничего не пишется, без исключений', () async {
    await PushService(FakeMessaging(granted: false)).start(cloud, shown.add);
    expect(await userDoc(), isNull);
  });

  test('сообщение на переднем плане показывается', () async {
    final m = FakeMessaging();
    await PushService(m).start(cloud, shown.add);
    m.messages.add((title: 'Заголовок', body: 'текст'));
    m.messages.add((title: 'Только заголовок', body: null));
    m.messages.add((title: null, body: null));
    await pumpEventQueue();
    expect(shown, ['Заголовок — текст', 'Только заголовок']);
  });

  test('повторный start и stop отменяют старые подписки', () async {
    final m = FakeMessaging();
    final service = PushService(m);
    await service.start(cloud, shown.add);
    await service.start(cloud, shown.add);
    m.messages.add((title: 'a', body: null));
    await pumpEventQueue();
    expect(shown, ['a']);
    await service.stop();
    m.messages.add((title: 'b', body: null));
    await pumpEventQueue();
    expect(shown, ['a']);
  });
}
