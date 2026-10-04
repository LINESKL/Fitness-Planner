import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/auth/data/local_auth_repository.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/settings/presentation/settings_model.dart';
import 'features/workout/data/hive/cached_exercise_repository.dart';
import 'features/workout/data/hive/hive_workout_repository.dart';
import 'features/workout/data/remote_exercise_repository.dart';
import 'features/workout/data/wger/wger_api.dart';
import 'features/workout/presentation/workout_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();
  final workouts = await HiveWorkoutRepository.open();
  final exercises = await CachedExerciseRepository.open(
    RemoteExerciseRepository(WgerApi.create()),
  );

  runApp(
    ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(workouts),
        exerciseRepositoryProvider.overrideWithValue(exercises),
        authRepositoryProvider.overrideWithValue(LocalAuthRepository(prefs)),
      ],
      child: ChangeNotifierProvider(
        create: (_) => SettingsModel(prefs),
        child: const FitnessPlannerApp(),
      ),
    ),
  );
}
