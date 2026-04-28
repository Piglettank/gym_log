const _monthNamesWritten = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Written date, e.g. `4 January 2026, 14:05` (local time).
String formatExerciseHistoryDateTime(DateTime atUtc) {
  final l = atUtc.toLocal();
  final month = _monthNamesWritten[l.month - 1];
  final h = l.hour.toString().padLeft(2, '0');
  final mi = l.minute.toString().padLeft(2, '0');
  return '${l.day} $month ${l.year}, $h:$mi';
}

/// Heading for a log-history group: `15 April` or `Today` (local calendar day).
String formatLogHistoryDayHeader(DateTime localDay) {
  final l = localDay;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(l.year, l.month, l.day);
  if (that == today) {
    return 'Today';
  }
  final month = _monthNamesWritten[l.month - 1];
  return '${l.day} $month';
}

/// Time only (local) for a log line, e.g. `14:05`.
String formatLogTimeOfDay(DateTime atUtc) {
  final l = atUtc.toLocal();
  final h = l.hour.toString().padLeft(2, '0');
  final mi = l.minute.toString().padLeft(2, '0');
  return '$h:$mi';
}
