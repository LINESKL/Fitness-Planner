import 'package:flutter/material.dart';

import '../../workout/data/sample_data.dart';
import '../../workout/domain/exercise.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key, this.onSelected});

  /// Если задан, экран работает как выбор упражнения.
  final ValueChanged<Exercise>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Поиск упражнения',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sampleExercises.length,
            itemBuilder: (context, i) {
              final exercise = sampleExercises[i];
              return ListTile(
                leading: CircleAvatar(child: Text(exercise.name[0])),
                title: Text(exercise.name),
                subtitle: Text(exercise.muscleGroup),
                onTap: onSelected == null ? null : () => onSelected!(exercise),
              );
            },
          ),
        ),
      ],
    );
  }
}
