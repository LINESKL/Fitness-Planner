import 'package:fitness_planner/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('показывает приветствие Fitness Planner', (tester) async {
    await tester.pumpWidget(const FitnessPlannerApp());

    expect(find.text('Hello, Fitness Planner!'), findsOneWidget);
  });

  testWidgets('поддерживает светлую и тёмную тему', (tester) async {
    await tester.pumpWidget(const FitnessPlannerApp());

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
  });
}
