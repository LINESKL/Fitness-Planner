import 'package:fitness_planner/app.dart';
import 'package:fitness_planner/core/format.dart';
import 'package:fitness_planner/features/settings/presentation/settings_model.dart';
import 'package:fitness_planner/features/workout/data/local_exercise_repository.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(WidgetTester tester) async {
  // Таймер отдыха выключен, чтобы тесты не ждали его.
  SharedPreferences.setMockInitialValues({'rest_seconds': 0});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(
          const LocalExerciseRepository(),
        ),
      ],
      child: ChangeNotifierProvider(
        create: (_) => SettingsModel(prefs),
        child: const FitnessPlannerApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder navItem(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('стартует на главной', (tester) async {
    await pumpApp(tester);

    expect(find.text('Начать тренировку'), findsOneWidget);
    expect(find.text('Последняя тренировка'), findsOneWidget);
  });

  testWidgets('светлая и тёмная тема', (tester) async {
    await pumpApp(tester);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });

  testWidgets('вкладка История показывает тренировки по дням', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('История'));
    await tester.pumpAndSettle();

    expect(find.text('30.09.2026'), findsOneWidget);
    expect(find.text('20.09.2026'), findsOneWidget);
  });

  testWidgets('вкладка Упражнения показывает каталог', (tester) async {
    await pumpApp(tester);
    await tester.tap(navItem('Упражнения'));
    await tester.pumpAndSettle();

    expect(find.text('Подтягивания'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('«Начать тренировку» открывает экран тренировки', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    expect(find.text('Тренировка'), findsOneWidget);
    expect(find.text('Приседания'), findsOneWidget);
  });

  testWidgets('завершённая тренировка появляется в истории', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();
    await tester.tap(navItem('История'));
    await tester.pumpAndSettle();

    expect(find.text(formatDate(DateTime.now())), findsOneWidget);
  });

  testWidgets('после выхода назад тренировку можно продолжить', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Продолжить тренировку'), findsOneWidget);
  });

  testWidgets('тёмная тема из настроек применяется к приложению', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
