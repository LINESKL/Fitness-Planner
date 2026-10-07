import '../domain/set_entry.dart';

/// «80 × 8, 8, 7» при одном весе, иначе «80 × 8, 82.5 × 7».
String compactSets(List<SetEntry> sets) {
  if (sets.every((s) => s.weight == sets.first.weight)) {
    final weight = sets.first.weight;
    return '${weight == 0 ? 'свой вес' : formatWeight(weight)} × '
        '${sets.map((s) => s.reps).join(', ')}';
  }
  return sets.map((s) => '${formatWeight(s.weight)} × ${s.reps}').join(', ');
}

/// «82.5 кг» или «свой вес» для упражнений без отягощения.
String formatLoad(double weight) =>
    weight == 0 ? 'свой вес' : '${formatWeight(weight)} кг';
