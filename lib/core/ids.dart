import 'dart:math';

final _random = Random();

/// Короткий уникальный id: время в микросекундах + случайный хвост.
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '${_random.nextInt(1 << 20).toRadixString(36)}';
