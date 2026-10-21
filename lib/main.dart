import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/presentation/auth_providers.dart';
import 'features/settings/presentation/settings_model.dart';
import 'features/workout/data/cloud/synced_repositories.dart';
import 'features/workout/data/hive/cached_exercise_repository.dart';
import 'features/workout/data/hive/hive_repositories.dart';
import 'features/workout/data/hive/legacy_logs.dart';
import 'features/workout/data/hive/migration_v2.dart';
import 'features/workout/data/cloud/cloud_sync.dart';
import 'features/workout/data/remote_exercise_repository.dart';
import 'features/workout/data/wger/wger_api.dart';
import 'features/workout/presentation/workout_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();
  final workouts = await HiveWorkoutRepository.open();
  await migrateToV2(
    old: await LegacyLogsBox.open(),
    target: workouts,
    prefs: prefs,
  );
  final program = await HiveProgramRepository.open();
  final notes = await HiveNoteRepository.open();
  final body = await HiveBodyRepository.open();
  final customExercises = await HiveCustomExerciseRepository.open();
  final favorites = await HiveFavoriteRepository.open();
  final activeWorkout = await HiveActiveWorkoutStore.open();
  final restoredWorkout = await activeWorkout.load();
  final exercises = await CachedExerciseRepository.open(
    RemoteExerciseRepository(WgerApi.create()),
  );

  runApp(
    ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWith(
          (ref) => syncedOr(ref, workouts, SyncedWorkoutRepository.new),
        ),
        programRepositoryProvider.overrideWith(
          (ref) => syncedOr(ref, program, SyncedProgramRepository.new),
        ),
        noteRepositoryProvider.overrideWith(
          (ref) => syncedOr(ref, notes, SyncedNoteRepository.new),
        ),
        bodyRepositoryProvider.overrideWith(
          (ref) => syncedOr(ref, body, SyncedBodyRepository.new),
        ),
        customExerciseRepositoryProvider.overrideWith(
          (ref) => syncedOr(
            ref,
            customExercises,
            SyncedCustomExerciseRepository.new,
          ),
        ),
        favoriteRepositoryProvider.overrideWith(
          (ref) => syncedOr(ref, favorites, SyncedFavoriteRepository.new),
        ),
        firestoreProvider.overrideWithValue(FirebaseFirestore.instance),
        localDataProvider.overrideWithValue(
          LocalData(
            workouts: workouts,
            program: program,
            body: body,
            customExercises: customExercises,
            notes: notes,
            favorites: favorites,
          ),
        ),
        localDataWiperProvider.overrideWithValue(clearSyncedBoxes),
        activeWorkoutStoreProvider.overrideWithValue(activeWorkout),
        initialActiveWorkoutProvider.overrideWithValue(restoredWorkout),
        exerciseRepositoryProvider.overrideWithValue(exercises),
        authRepositoryProvider.overrideWithValue(
          FirebaseAuthRepository(FirebaseAuth.instance, prefs),
        ),
      ],
      child: ChangeNotifierProvider(
        create: (_) => SettingsModel(prefs),
        child: const FitnessPlannerApp(),
      ),
    ),
  );
}
