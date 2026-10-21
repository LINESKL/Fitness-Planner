import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/pump_app.dart';

/// Сквозной сценарий на устройстве: вход → тренировка по дню → итоги → прогресс.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('гость проходит тренировку «Верх» и видит её в прогрессе', (
    tester,
  ) async {
    await pumpApp(tester, signedIn: false);

    await tester.tap(find.text('Продолжить как гость'));
    await tester.pumpAndSettle();
    expect(find.text('Верх'), findsWidgets);

    await tester.tap(find.text('Начать тренировку'));
    await tester.pumpAndSettle();

    // Без отдыха: шесть подходов подряд (жим 3 + тяга 3).
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Завершить тренировку'));
    await tester.pumpAndSettle();
    expect(find.text('Тренировка готова'), findsOneWidget);
    expect(find.text('подходов'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Готово'));
    await tester.pumpAndSettle();
    await tester.tap(navItem('Прогресс'));
    await tester.pumpAndSettle();

    expect(await scrollToText(tester, 'Верх'), findsWidgets);
  });
}
