import 'package:fitness_planner/features/workout/data/remote_exercise_repository.dart';
import 'package:fitness_planner/features/workout/data/wger/wger_api.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/pump_app.dart';

/// Замер для недели 10: открыть каталог wger и пролистать его.
/// flutter drive --profile --driver=test_driver/perf_driver.dart \
///   --target=integration_test/catalog_perf_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('каталог wger: загрузка и прокрутка', (tester) async {
    await pumpApp(
      tester,
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(
          RemoteExerciseRepository(WgerApi.create()),
        ),
      ],
    );

    await binding.watchPerformance(() async {
      final started = DateTime.now();
      await tester.tap(navItem('Упражнения'));
      // Сеть: ждём, пока уйдёт индикатор загрузки.
      do {
        await tester.pump(const Duration(milliseconds: 50));
      } while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty);
      binding.reportData = {
        ...?binding.reportData,
        'catalog_ready_ms': DateTime.now().difference(started).inMilliseconds,
      };

      for (var i = 0; i < 6; i++) {
        await tester.fling(
          find.byType(ListView).first,
          const Offset(0, -1500),
          4000,
        );
        await tester.pumpAndSettle();
      }
    }, reportKey: 'catalog');
  });
}
