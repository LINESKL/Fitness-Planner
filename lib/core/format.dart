String _two(int n) => n.toString().padLeft(2, '0');

/// 27.09.2026
String formatDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

/// 1:30
String formatDuration(Duration d) =>
    '${d.inMinutes}:${_two(d.inSeconds.remainder(60))}';

/// 2026-09-30 — день в адресе экрана.
String formatDayKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// Форма слова по числу: 1 тренировка, 2 тренировки, 5 тренировок.
String pluralRu(int n, String one, String few, String many) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return one;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return few;
  return many;
}
