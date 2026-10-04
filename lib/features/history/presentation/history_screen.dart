import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/widgets/message_view.dart';
import '../../workout/domain/exercise_log.dart';
import '../../workout/domain/set_entry.dart';
import '../../workout/presentation/workout_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(historyProvider)) {
      AsyncData(:final value) when value.isEmpty => const MessageView(
        icon: Icons.event_note,
        text: 'Здесь появятся завершённые тренировки',
      ),
      AsyncData(:final value) => _HistoryList(workouts: workoutsByDay(value)),
      AsyncError() => MessageView(
        icon: Icons.error_outline,
        text: 'Не удалось загрузить историю',
        actionLabel: 'Повторить',
        onAction: () => ref.invalidate(historyProvider),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.workouts});

  final List<List<ExerciseLog>> workouts;

  @override
  Widget build(BuildContext context) {
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
          onTap: () => context.pushNamed(
            'workoutDetails',
            pathParameters: {'day': formatDayKey(logs.first.date)},
          ),
        );
      },
    );
  }
}
