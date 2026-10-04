import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/workout/data/sample_data.dart';
import 'features/workout/presentation/workout_store.dart';
import 'home_shell.dart';

class FitnessPlannerApp extends StatelessWidget {
  const FitnessPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkoutStore(history: sampleHistory),
      child: MaterialApp(
        title: 'Fitness Planner',
        theme: lightTheme,
        darkTheme: darkTheme,
        home: const HomeShell(),
      ),
    );
  }
}
