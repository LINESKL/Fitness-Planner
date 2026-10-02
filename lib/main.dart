import 'package:flutter/material.dart';

void main() => runApp(const FitnessPlannerApp());

class FitnessPlannerApp extends StatelessWidget {
  const FitnessPlannerApp({super.key});

  static const _seed = Colors.deepOrange;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Planner',
      theme: ThemeData(colorSchemeSeed: _seed),
      darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark),
      home: const Scaffold(
        body: Center(child: Text('Hello, Fitness Planner!')),
      ),
    );
  }
}
