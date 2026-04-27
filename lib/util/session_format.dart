String formatSessionStartLocal(DateTime startedAtUtc) {
  final l = startedAtUtc.toLocal();
  final y = l.year.toString();
  final mo = l.month.toString().padLeft(2, '0');
  final d = l.day.toString().padLeft(2, '0');
  final h = l.hour.toString().padLeft(2, '0');
  final mi = l.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d $h:$mi';
}

const _monthNamesLower = [
  'january',
  'february',
  'march',
  'april',
  'may',
  'june',
  'july',
  'august',
  'september',
  'october',
  'november',
  'december',
];

/// Written date for exercise history, e.g. `4 april 2026, 14:05` (local time).
String formatExerciseHistoryDateTime(DateTime atUtc) {
  final l = atUtc.toLocal();
  final month = _monthNamesLower[l.month - 1];
  final h = l.hour.toString().padLeft(2, '0');
  final mi = l.minute.toString().padLeft(2, '0');
  return '${l.day} $month ${l.year}, $h:$mi';
}
