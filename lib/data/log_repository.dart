import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_log_entry.dart';

class _Storage {
  _Storage({required this.entries});

  final List<WorkoutLogEntry> entries;

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory _Storage.fromJson(Map<String, dynamic> json) {
    final entryList = json['entries'] as List<dynamic>? ?? [];
    return _Storage(
      entries: entryList
          .map((e) => WorkoutLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LogRepository {
  static const _storageKey = 'gym_log_storage';

  Future<List<WorkoutLogEntry>> _readEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    return _Storage.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    ).entries;
  }

  Future<void> _saveEntries(List<WorkoutLogEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_Storage(entries: entries).toJson()),
    );
  }

  Future<List<WorkoutLogEntry>> loadAllEntries() async {
    final list = List<WorkoutLogEntry>.from(await _readEntries());
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return List.unmodifiable(list);
  }

  /// Entries on this local calendar day (year, month, day only).
  Future<List<WorkoutLogEntry>> loadEntriesForLocalDay(
    DateTime localDay,
  ) async {
    final all = await _readEntries();
    final y = localDay.year;
    final mo = localDay.month;
    final d = localDay.day;
    final out = <WorkoutLogEntry>[];
    for (final e in all) {
      final l = e.loggedAt.toLocal();
      if (l.year == y && l.month == mo && l.day == d) {
        out.add(e);
      }
    }
    out.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return List.unmodifiable(out);
  }

  /// Newest first.
  Future<List<WorkoutLogEntry>> loadEntriesForExercise(
    String exerciseId,
  ) async {
    final s = await _readEntries();
    final list = s.where((e) => e.exerciseId == exerciseId).toList();
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return List.unmodifiable(list);
  }

  Future<WorkoutLogEntry?> lastLogForExerciseExcluding(
    String exerciseId, {
    String? excludeEntryId,
  }) async {
    final list = await loadEntriesForExercise(exerciseId);
    for (final e in list) {
      if (excludeEntryId != null && e.id == excludeEntryId) {
        continue;
      }
      return e;
    }
    return null;
  }

  Future<void> addEntry(WorkoutLogEntry entry) async {
    final s = List<WorkoutLogEntry>.from(await _readEntries());
    s.removeWhere((e) => e.id == entry.id);
    s.insert(0, entry);
    await _saveEntries(s);
  }

  Future<WorkoutLogEntry?> findEntryById(String id) async {
    for (final e in await _readEntries()) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<void> updateEntry(WorkoutLogEntry entry) async {
    final s = List<WorkoutLogEntry>.from(await _readEntries());
    final i = s.indexWhere((e) => e.id == entry.id);
    if (i < 0) {
      s.insert(0, entry);
    } else {
      s[i] = entry;
    }
    await _saveEntries(s);
  }

  Future<void> replaceAllEntries(List<WorkoutLogEntry> entries) async {
    await _saveEntries(entries);
  }
}
