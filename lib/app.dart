import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'features/settings/presentation/settings_model.dart';
import 'home_shell.dart';

class FitnessPlannerApp extends StatelessWidget {
  const FitnessPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Planner',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: context.watch<SettingsModel>().themeMode,
      home: const HomeShell(),
    );
  }
}
