import 'package:fitness_planner/app.dart';
import 'package:fitness_planner/features/auth/data/local_auth_repository.dart';
import 'package:fitness_planner/features/auth/presentation/auth_providers.dart';
import 'package:fitness_planner/features/settings/presentation/settings_model.dart';
import 'package:fitness_planner/features/workout/data/local_exercise_repository.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

/// Всё приложение с демо-историей, локальным каталогом и без таймера отдыха.
Future<void> pumpApp(
  WidgetTester tester, {
  bool signedIn = true,
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  SharedPreferences.setMockInitialValues({
    'rest_seconds': 0,
    'signed_in': signedIn,
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(
          const LocalExerciseRepository(),
        ),
        authRepositoryProvider.overrideWithValue(LocalAuthRepository(prefs)),
      ],
      child: ChangeNotifierProvider(
        create: (_) => SettingsModel(prefs),
        child: const FitnessPlannerApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder navItem(String label) => find.descendant(
  of: find.byWidgetPredicate((w) => w is NavigationBar || w is NavigationRail),
  matching: find.text(label),
);
