import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/exercises/presentation/exercise_details_screen.dart';
import '../features/exercises/presentation/exercises_screen.dart';
import '../features/history/presentation/history_screen.dart';
import '../features/history/presentation/workout_details_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/workout/presentation/active_workout_screen.dart';
import '../home_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>();
  final signedIn = ValueNotifier(ref.read(authProvider));
  ref.listen(authProvider, (_, value) => signedIn.value = value);

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
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ActiveWorkoutScreen(),
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
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: 'settings',
                    parentNavigatorKey: rootKey,
                    builder: (_, _) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                builder: (_, _) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':day',
                    name: 'workoutDetails',
                    parentNavigatorKey: rootKey,
                    builder: (_, state) => WorkoutDetailsScreen(
                      dayKey: state.pathParameters['day']!,
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
