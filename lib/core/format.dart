String _two(int n) => n.toString().padLeft(2, '0');

/// 27.09.2026
String formatDate(DateTime d) => '${_two(d.day)}.${_two(d.month)}.${d.year}';

/// 1:30
String formatDuration(Duration d) =>
    '${d.inMinutes}:${_two(d.inSeconds.remainder(60))}';

/// 2026-09-30 — день в адресе экрана.
String formatDayKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
