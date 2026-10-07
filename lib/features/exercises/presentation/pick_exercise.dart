import 'package:flutter/material.dart';

import 'exercises_screen.dart';

/// Открывает каталог в режиме выбора; возвращает название или null.
Future<String?> pickExercise(BuildContext context) =>
    Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Выбор упражнения')),
          body: ExercisesScreen(
            onSelected: (e) => Navigator.of(context).pop(e.name),
          ),
        ),
      ),
    );
