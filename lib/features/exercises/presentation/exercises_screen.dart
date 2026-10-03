import 'package:flutter/material.dart';

import '../../workout/data/sample_data.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

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
              );
            },
          ),
        ),
      ],
    );
  }
}
