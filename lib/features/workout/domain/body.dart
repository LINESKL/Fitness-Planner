/// Замер тела: вес обязателен, талия и грудь — по желанию.
class BodyEntry {
  const BodyEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.waistCm,
    this.chestCm,
  });

  final String id;
  final DateTime date;
  final double weightKg;
  final double? waistCm;
  final double? chestCm;
}
