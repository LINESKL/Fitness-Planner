import 'package:flutter/material.dart';

import '../../../core/format.dart';
import '../../workout/domain/exercise_log.dart';
import '../../workout/domain/set_entry.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.history});

  final List<ExerciseLog> history;

  @override
  Widget build(BuildContext context) {
    final workouts = workoutsByDay(history);

    return ListView.builder(
      itemCount: workouts.length,
      itemBuilder: (context, i) {
        final logs = workouts[i];
        final volume = totalVolume(logs.expand((l) => l.sets));

        return ListTile(
          leading: const Icon(Icons.event_note),
          title: Text(formatDate(logs.first.date)),
          subtitle: Text(logs.map((l) => l.exercise).join(', ')),
          trailing: Text('${formatWeight(volume)} кг'),
        );
      },
    );
  }
}
