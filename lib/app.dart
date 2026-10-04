import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/workout/data/sample_data.dart';
import 'features/workout/presentation/workout_scope.dart';
import 'features/workout/presentation/workout_store.dart';
import 'home_shell.dart';

class FitnessPlannerApp extends StatefulWidget {
  const FitnessPlannerApp({super.key});

  @override
  State<FitnessPlannerApp> createState() => _FitnessPlannerAppState();
}

class _FitnessPlannerAppState extends State<FitnessPlannerApp> {
  final _store = WorkoutStore(history: sampleHistory);

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorkoutScope(
      store: _store,
      child: MaterialApp(
        title: 'Fitness Planner',
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const HomeShell(),
      ),
    );
  }
}
