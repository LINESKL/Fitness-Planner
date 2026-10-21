import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/exercises/presentation/custom_exercise_screen.dart';
import '../features/exercises/presentation/exercise_details_screen.dart';
import '../features/exercises/presentation/exercises_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/program/presentation/program_screen.dart';
import '../features/program/presentation/template_editor_screen.dart';
import '../features/progress/presentation/body_entry_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/progress/presentation/workout_details_screen.dart';
import '../features/workout/presentation/active_workout_screen.dart';
import '../features/workout/presentation/workout_plan_screen.dart';
import '../features/workout/presentation/workout_summary_screen.dart';
import '../home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  final signedIn = ValueNotifier(ref.read(authProvider) is! SignedOut);
  ref.listen(authProvider, (_, v) => signedIn.value = v is! SignedOut);

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/',
    refreshListenable: signedIn,
    // Без входа доступен только /login; после входа /login уводит на главную.
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/login';
      if (!signedIn.value) return atLogin ? null : '/login';
      return atLogin ? '/' : null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/workout',
        name: 'workout',
        builder: (_, _) => const ActiveWorkoutScreen(),
        routes: [
          GoRoute(
            path: 'plan',
            name: 'workoutPlan',
            builder: (_, _) => const WorkoutPlanScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/summary/:workoutId',
        name: 'workoutSummary',
        builder: (_, state) =>
            WorkoutSummaryScreen(workoutId: state.pathParameters['workoutId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/program',
                name: 'program',
                builder: (_, _) => const ProgramScreen(),
                routes: [
                  GoRoute(
                    path: ':templateId',
                    name: 'templateEditor',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => TemplateEditorScreen(
                      templateId: state.pathParameters['templateId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                name: 'progress',
                builder: (_, _) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'body/new',
                    name: 'bodyEntryNew',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const BodyEntryScreen(),
                  ),
                  GoRoute(
                    path: 'workout/:workoutId',
                    name: 'workoutDetails',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => WorkoutDetailsScreen(
                      workoutId: state.pathParameters['workoutId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/exercises',
                name: 'exercises',
                builder: (context, _) => ExercisesScreen(
                  onSelected: (e) => context.pushNamed(
                    'exerciseDetails',
                    pathParameters: {'id': e.id},
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'edit/:id',
                    name: 'exerciseEditor',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) =>
                        CustomExerciseScreen(id: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'exerciseDetails',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) =>
                        ExerciseDetailsScreen(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    signedIn.dispose();
  });
  return router;
});
