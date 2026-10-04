import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'home_shell.dart';

class FitnessPlannerApp extends StatelessWidget {
  const FitnessPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Planner',
      theme: lightTheme,
      darkTheme: darkTheme,
      home: const HomeShell(),
    );
  }
}
