import 'package:fitness_planner/core/format.dart';
import 'package:fitness_planner/features/auth/domain/auth_repository.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/domain/body.dart';
import 'package:fitness_planner/features/workout/domain/set_entry.dart';
import 'package:fitness_planner/features/workout/domain/workout.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

class _Auth implements AuthRepository {
  _Auth(this.current, this.log);
  final List<String> log;
  @override
  AuthState current;
  @override
  Stream<AuthState> changes() => const Stream.empty();
  @override
  Future<void> signOut() async => log.add('signOut');
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Тренировка в 10:00 длиной 1,5 часа с одним подходом 100 кг × 30 (3 т).
Workout workout(DateTime day) => Workout(
  id: 'w-$day',
  title: 'x',
  startedAt: DateTime(day.year, day.month, day.day, 10),
  finishedAt: DateTime(day.year, day.month, day.day, 11, 30),
  entries: [
    const WorkoutEntry(
      exercise: 'Жим лёжа',
      sets: [SetEntry(weight: 100, reps: 30)],
    ),
  ],
);

void main() {
  late List<String> log;
  final today = DateTime.now();

  setUp(() => log = []);

  DateTime daysAgo(int n) =>
      DateTime(today.year, today.month, today.day - n, 8);

  /// Профиль на высоком экране — прокрутка не нужна.
  Future<void> open(
    WidgetTester tester, {
    AuthState auth = const Guest(),
    List<Workout> workouts = const [],
    List<BodyEntry> body = const [],
    Size size = const Size(400, 2000),
  }) async {
    final bodyRepo = InMemoryBodyRepository();
    for (final b in body) {
      await bodyRepo.save(b);
    }
    await pumpApp(
      tester,
      size: size,
      auth: _Auth(auth, log),
      overrides: [
        workoutRepositoryProvider.overrideWithValue(
          InMemoryWorkoutRepository(workouts),
        ),
        bodyRepositoryProvider.overrideWithValue(bodyRepo),
        localDataWiperProvider.overrideWithValue(() async => log.add('wipe')),
      ],
    );
    await tester.tap(navItem('Профиль'));
    await tester.pumpAndSettle();
  }

  Finder stat(String label, String value) => find.descendant(
    of: find.byKey(ValueKey('stat-$label')),
    matching: find.text(value),
  );

  group('аккаунт', () {
    testWidgets('вошедший: буква, email, подпись; выход с подтверждением', (
      tester,
    ) async {
      await open(
        tester,
        auth: const SignedIn(uid: 'u', email: 'a@b.kz'),
      );
      expect(find.text('A'), findsOneWidget);
      expect(find.text('a@b.kz'), findsOneWidget);
      expect(find.text('Синхронизация с облаком'), findsOneWidget);

      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      expect(find.text('Выйти из аккаунта?'), findsOneWidget);
      expect(
        find.text('Данные останутся в облаке и будут удалены с этого телефона'),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Выйти'),
        ),
      );
      await tester.pumpAndSettle();

      expect(log, ['signOut', 'wipe']);
    });

    testWidgets('вошедший: «Отмена» ничего не делает', (tester) async {
      await open(
        tester,
        auth: const SignedIn(uid: 'u', email: 'a@b.kz'),
      );
      await tester.tap(find.text('Выйти'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(log, isEmpty);
      expect(find.text('Выйти из аккаунта?'), findsNothing);
    });

    testWidgets('гость: «Гость», подпись и «Войти в аккаунт» без очистки', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('Гость'), findsOneWidget);
      expect(find.text('Данные только на этом телефоне'), findsOneWidget);
      expect(find.text('Выйти'), findsNothing);

      await tester.tap(find.text('Войти в аккаунт'));
      await tester.pumpAndSettle();

      expect(log, ['signOut']);
    });
  });

  group('статистика', () {
    testWidgets('считает тренировки, тоннаж, часы и лучшую серию', (
      tester,
    ) async {
      // Недели: две подряд (13 и 6 дней назад) и одиночная раньше (60 дней).
      final days = [daysAgo(60), daysAgo(13), daysAgo(6)];
      await open(tester, workouts: [for (final d in days) workout(d)]);

      expect(stat('тренировок', '3'), findsOneWidget);
      expect(stat('тоннаж', '9 т'), findsOneWidget);
      expect(stat('часов в зале', '4'), findsOneWidget); // 4,5 ч → 4
      expect(stat('лучшая серия, нед.', '2'), findsOneWidget);
      expect(
        find.text('Тренируетесь с ${formatLongDate(days.first)}'),
        findsOneWidget,
      );
    });

    testWidgets('без тренировок: нули и «Первая тренировка — впереди»', (
      tester,
    ) async {
      await open(tester);

      expect(stat('тренировок', '0'), findsOneWidget);
      expect(stat('тоннаж', '0 кг'), findsOneWidget);
      expect(stat('часов в зале', '0'), findsOneWidget);
      expect(stat('лучшая серия, нед.', '0'), findsOneWidget);
      expect(find.text('Первая тренировка — впереди'), findsOneWidget);
    });
  });

  group('тело', () {
    testWidgets('нет замеров: подсказка и кнопка «Замер»', (tester) async {
      await open(tester);

      expect(find.text('Записывайте вес раз в неделю'), findsOneWidget);
      await tester.tap(find.text('Замер'));
      await tester.pumpAndSettle();
      expect(find.text('Сохранить'), findsOneWidget);
    });

    testWidgets('последний вес, изменение за месяц и фото последнего снимка', (
      tester,
    ) async {
      await open(
        tester,
        body: [
          BodyEntry(id: 'b0', date: daysAgo(45), weightKg: 80.5),
          BodyEntry(id: 'b1', date: daysAgo(31), weightKg: 80),
          BodyEntry(
            id: 'b2',
            date: daysAgo(5),
            weightKg: 79.5,
            photoPath: '/нет/такого.jpg',
          ),
          BodyEntry(id: 'b3', date: daysAgo(0), weightKg: 78.8),
        ],
      );

      expect(find.text('78.8 кг'), findsOneWidget);
      expect(find.text('−1.2 кг за месяц'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-photo')), findsOneWidget);
    });

    testWidgets('рост веса — «+», без замера старше 30 дней — без изменения', (
      tester,
    ) async {
      await open(
        tester,
        body: [
          BodyEntry(id: 'b1', date: daysAgo(40), weightKg: 80),
          BodyEntry(id: 'b2', date: daysAgo(0), weightKg: 80.5),
        ],
      );
      expect(find.text('+0.5 кг за месяц'), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-photo')), findsNothing);
    });

    testWidgets('все замеры свежее 30 дней: изменение не показывается', (
      tester,
    ) async {
      await open(
        tester,
        body: [
          BodyEntry(id: 'b1', date: daysAgo(10), weightKg: 80),
          BodyEntry(id: 'b2', date: daysAgo(0), weightKg: 79),
        ],
      );
      expect(find.text('79 кг'), findsOneWidget);
      expect(find.textContaining('за месяц'), findsNothing);
    });
  });

  group('настройки', () {
    testWidgets('время отдыха переключается', (tester) async {
      await open(tester);
      await tester.tap(find.widgetWithText(ChoiceChip, '1:30'));
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '1:30'),
      );
      expect(chip.selected, isTrue);
    });

    testWidgets('тема переключается', (tester) async {
      await open(tester);
      await tester.tap(find.text('Тёмная'));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });
  });

  testWidgets('широкий экран: 5 пунктов боковой панели, без переполнения', (
    tester,
  ) async {
    await open(tester, size: const Size(900, 900));

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations, hasLength(5));
    expect(find.text('Статистика'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
