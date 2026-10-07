import 'package:fitness_planner/app.dart';
import 'package:fitness_planner/features/auth/data/local_auth_repository.dart';
import 'package:fitness_planner/features/auth/presentation/auth_providers.dart';
import 'package:fitness_planner/features/settings/presentation/settings_model.dart';
import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/data/local_exercise_repository.dart';
import 'package:fitness_planner/features/workout/domain/program.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' show ChangeNotifierProvider;
import 'package:shared_preferences/shared_preferences.dart';

/// Всё приложение с демо-историей, локальным каталогом и без таймера отдыха.
/// Программа для тестов: два дня из упражнений демо-истории.
const testTemplates = [
  WorkoutTemplate(
    id: 't-up',
    name: 'Верх',
    exercises: [
      TemplateExercise(exercise: 'Жим лёжа', sets: 3, repsMin: 8, repsMax: 8),
      TemplateExercise(
        exercise: 'Тяга штанги в наклоне',
        sets: 3,
        repsMin: 10,
        repsMax: 10,
      ),
    ],
  ),
  WorkoutTemplate(
    id: 't-down',
    name: 'Низ',
    exercises: [
      TemplateExercise(exercise: 'Приседания', sets: 3, repsMin: 5, repsMax: 5),
      TemplateExercise(exercise: 'Жим стоя', sets: 3, repsMin: 8, repsMax: 8),
    ],
  ),
];

Future<void> pumpApp(
  WidgetTester tester, {
  bool signedIn = true,
  Size? size,
  List<WorkoutTemplate> templates = testTemplates,
  List<Override> overrides = const [],
  int restSeconds = 0,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  SharedPreferences.setMockInitialValues({
    'rest_seconds': restSeconds,
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
        programRepositoryProvider.overrideWithValue(
          InMemoryProgramRepository(
            templates: templates,
            program: Program(templateIds: [for (final t in templates) t.id]),
          ),
        ),
        ...overrides,
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
