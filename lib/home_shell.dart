import 'package:flutter/material.dart';

import 'features/exercises/presentation/exercises_screen.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/workout/data/sample_data.dart';
import 'features/workout/presentation/active_workout_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _titles = ['Главная', 'История', 'Упражнения'];

  int _index = 0;

  /// Пока без хранилища: история живёт в состоянии оболочки.
  final _history = [...sampleHistory];

  void _startWorkout() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ActiveWorkoutScreen(
        plan: sampleTodayPlan,
        history: _history,
        onFinish: (logs) => setState(() => _history.addAll(logs)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: switch (_index) {
        0 => HomeScreen(history: _history, onStartWorkout: _startWorkout),
        1 => HistoryScreen(history: _history),
        _ => const ExercisesScreen(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'История'),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Упражнения',
          ),
        ],
      ),
    );
  }
}
