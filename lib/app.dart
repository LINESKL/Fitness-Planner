import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' show WatchContext;

import 'core/router.dart';
import 'core/theme.dart';
import 'features/settings/presentation/settings_model.dart';
import 'features/workout/presentation/workout_providers.dart';

class FitnessPlannerApp extends ConsumerWidget {
  const FitnessPlannerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
      cloudSyncProvider,
    ); // слияние при входе живёт, пока живо приложение
    return MaterialApp.router(
      title: 'Fitness Planner',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: context.watch<SettingsModel>().themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
