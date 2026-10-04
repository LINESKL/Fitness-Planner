import 'package:flutter/widgets.dart';

import 'workout_store.dart';

/// Делает [WorkoutStore] доступным всему дереву и перестраивает зависящие виджеты.
class WorkoutScope extends InheritedNotifier<WorkoutStore> {
  const WorkoutScope({
    super.key,
    required WorkoutStore store,
    required super.child,
  }) : super(notifier: store);

  static WorkoutStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WorkoutScope>()!.notifier!;
}
