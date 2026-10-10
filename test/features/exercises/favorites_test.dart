import 'package:fitness_planner/features/workout/data/in_memory_repositories.dart';
import 'package:fitness_planner/features/workout/presentation/workout_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

Future<InMemoryFavoriteRepository> openCatalog(WidgetTester tester) async {
  final repo = InMemoryFavoriteRepository();
  await pumpApp(
    tester,
    overrides: [favoriteRepositoryProvider.overrideWithValue(repo)],
  );
  await tester.tap(navItem('Упражнения'));
  await tester.pumpAndSettle();
  return repo;
}

Finder star(String exercise) => find.descendant(
  of: find.widgetWithText(ListTile, exercise),
  matching: find.byType(IconButton),
);

void main() {
  testWidgets('звёздочка добавляет в избранное и сохраняется', (tester) async {
    final repo = await openCatalog(tester);

    await tester.tap(star('Приседания'));
    await tester.pumpAndSettle();

    expect(await repo.all(), {'local-4'});
    expect(
      find.descendant(
        of: find.widgetWithText(ListTile, 'Приседания'),
        matching: find.byTooltip('Убрать из избранного'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('звёздочка не переставляет список под пальцем', (tester) async {
    await openCatalog(tester);
    final before = tester.getTopLeft(find.text('Приседания')).dy;

    await tester.tap(star('Приседания'));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('Приседания')).dy, before);
  });

  testWidgets('фильтр «Избранное» оставляет только избранные', (tester) async {
    await openCatalog(tester);
    await tester.tap(star('Приседания'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Избранное'));
    await tester.pumpAndSettle();

    expect(find.text('Приседания'), findsOneWidget);
    expect(find.text('Жим лёжа'), findsNothing);
  });

  testWidgets('пустое избранное — подсказка', (tester) async {
    await openCatalog(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Избранное'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Отметьте упражнения звёздочкой'),
      findsOneWidget,
    );
  });
}
