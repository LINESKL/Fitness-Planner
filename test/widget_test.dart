import 'package:fitness_planner/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder navItem(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('стартует на главной', (tester) async {
    await tester.pumpWidget(const FitnessPlannerApp());

    expect(find.text('Начать тренировку'), findsOneWidget);
    expect(find.text('Последняя тренировка'), findsOneWidget);
  });

  testWidgets('светлая и тёмная тема', (tester) async {
    await tester.pumpWidget(const FitnessPlannerApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });

  testWidgets('вкладка История показывает тренировки по дням', (tester) async {
    await tester.pumpWidget(const FitnessPlannerApp());
    await tester.tap(navItem('История'));
    await tester.pumpAndSettle();

    expect(find.text('30.09.2026'), findsOneWidget);
    expect(find.text('20.09.2026'), findsOneWidget);
  });

  testWidgets('вкладка Упражнения показывает каталог', (tester) async {
    await tester.pumpWidget(const FitnessPlannerApp());
    await tester.tap(navItem('Упражнения'));
    await tester.pumpAndSettle();

    expect(find.text('Подтягивания'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
