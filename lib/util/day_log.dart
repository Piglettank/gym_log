import '../models/workout_log_entry.dart';

/// Local calendar days that have at least one log, newest first.
List<DateTime> distinctLocalDaysNewestFirst(List<WorkoutLogEntry> entries) {
  final days = <DateTime>{};
  for (final e in entries) {
    final l = e.loggedAt.toLocal();
    days.add(DateTime(l.year, l.month, l.day));
  }
  final out = days.toList()..sort((a, b) => b.compareTo(a));
  return out;
}
