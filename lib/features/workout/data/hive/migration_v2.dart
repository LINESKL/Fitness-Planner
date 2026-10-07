import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories.dart';
import '../../domain/workout.dart';
import 'legacy_logs.dart';

const migratedV2Key = 'migrated_v2';

/// Переносит историю недели 6 (плоские логи) в тренировки. Выполняется один раз.
Future<void> migrateToV2({
  required LegacyLogsBox old,
  required WorkoutRepository target,
  required SharedPreferences prefs,
}) async {
  if (prefs.getBool(migratedV2Key) ?? false) return;
  for (final workout in workoutsFromLogs(await old.loadHistory())) {
    await target.save(workout);
  }
  await prefs.setBool(migratedV2Key, true);
}
