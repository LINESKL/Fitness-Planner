/// Тип подхода: разминка не идёт в объём и рекорды, остальные — идут.
enum SetType { normal, warmup, failure, drop }

/// Один подход: вес в кг, количество повторов, тип и тяжесть (RPE 1–10).
class SetEntry {
  const SetEntry({
    required this.weight,
    required this.reps,
    this.type = SetType.normal,
    this.rpe,
  });

  final double weight;
  final int reps;
  final SetType type;
  final double? rpe;

  bool get isWarmup => type == SetType.warmup;

  /// Тоннаж подхода; разминка не считается.
  double get volume => isWarmup ? 0 : weight * reps;

  /// Оценочный максимум на один повтор по формуле Эпли.
  double get oneRepMax => reps == 1 ? weight : weight * (1 + reps / 30);
}

final _setPattern = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*[xXхХ×*]\s*(\d+)\s*$');

/// Разбирает строку вида "80x8" или "82,5 х 5". Возвращает null, если ввод некорректен.
SetEntry? parseSet(String input) {
  final match = _setPattern.firstMatch(input);
  if (match == null) return null;

  final weight = double.parse(match.group(1)!.replaceAll(',', '.'));
  final reps = int.parse(match.group(2)!);
  if (reps == 0) return null;

  return SetEntry(weight: weight, reps: reps);
}

/// 80.0 → "80", 82.5 → "82.5".
String formatWeight(double kg) =>
    kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toString();
