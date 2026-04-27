import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/workout_log_entry.dart';
import '../models/workout_session.dart';

class _Storage {
  _Storage({required this.sessions, required this.entries});

  final List<WorkoutSession> sessions;
  final List<WorkoutLogEntry> entries;

  Map<String, dynamic> toJson() => {
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory _Storage.fromJson(Map<String, dynamic> json) {
    final sessionList = json['sessions'] as List<dynamic>? ?? [];
    final entryList = json['entries'] as List<dynamic>? ?? [];
    return _Storage(
      sessions: sessionList
          .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      entries: entryList
          .map((e) => WorkoutLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LogRepository {
  static const _legacyKey = 'workout_logs_v1';
  static const _storageKey = 'gym_log_storage_v2';
  static const _uuid = Uuid();

  Future<_Storage> _readStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      return _Storage.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }
    return _migrateFromLegacy(prefs);
  }

  Future<_Storage> _migrateFromLegacy(SharedPreferences prefs) async {
    final legacy = prefs.getString(_legacyKey);
    if (legacy == null || legacy.isEmpty) {
      return _Storage(sessions: [], entries: []);
    }
    final list = jsonDecode(legacy) as List<dynamic>;
    final entries = list
        .map((e) => WorkoutLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    final session = WorkoutSession(
      id: _uuid.v4(),
      startedAt: entries.isEmpty
          ? DateTime.now().toUtc()
          : entries
              .map((e) => e.loggedAt)
              .reduce((a, b) => a.isBefore(b) ? a : b),
    );
    final migrated = entries
        .map(
          (e) => WorkoutLogEntry(
            id: e.id,
            sessionId: e.sessionId.isEmpty ? session.id : e.sessionId,
            exerciseId: e.exerciseId,
            loggedAt: e.loggedAt,
            values: e.values,
          ),
        )
        .toList();
    final storage = _Storage(sessions: [session], entries: migrated);
    await _writeStorage(prefs, storage);
    await prefs.remove(_legacyKey);
    return storage;
  }

  Future<void> _writeStorage(SharedPreferences prefs, _Storage storage) async {
    await prefs.setString(_storageKey, jsonEncode(storage.toJson()));
  }

  Future<void> _save(_Storage storage) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeStorage(prefs, storage);
  }

  /// Newest session first (for log history).
  Future<List<WorkoutSession>> loadSessions() async {
    final s = await _readStorage();
    final copy = List<WorkoutSession>.from(s.sessions);
    copy.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(copy);
  }

  Future<List<WorkoutLogEntry>> loadAllEntries() async {
    final s = await _readStorage();
    return List.unmodifiable(s.entries);
  }

  Future<List<WorkoutLogEntry>> loadEntriesForSession(String sessionId) async {
    final s = await _readStorage();
    final list =
        s.entries.where((e) => e.sessionId == sessionId).toList();
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return List.unmodifiable(list);
  }

  /// Newest log first (same as session log history).
  Future<List<WorkoutLogEntry>> loadEntriesForExercise(String exerciseId) async {
    final s = await _readStorage();
    final list =
        s.entries.where((e) => e.exerciseId == exerciseId).toList();
    list.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return List.unmodifiable(list);
  }

  Future<void> addSession(WorkoutSession session) async {
    final s = await _readStorage();
    s.sessions.add(session);
    await _save(s);
  }

  /// Persists the session if it is not already stored (e.g. first log of a new workout).
  Future<void> ensureSession(WorkoutSession session) async {
    final s = await _readStorage();
    if (s.sessions.any((x) => x.id == session.id)) return;
    s.sessions.add(session);
    await _save(s);
  }

  /// At most one log per exercise per session: replaces any existing row before insert.
  Future<void> addEntry(WorkoutLogEntry entry) async {
    final s = await _readStorage();
    s.entries.removeWhere(
      (e) =>
          e.sessionId == entry.sessionId &&
          e.exerciseId == entry.exerciseId,
    );
    s.entries.insert(0, entry);
    await _save(s);
  }

  /// Prefer the newest log if legacy data had duplicates.
  Future<WorkoutLogEntry?> findEntryForSessionExercise(
    String sessionId,
    String exerciseId,
  ) async {
    final s = await _readStorage();
    WorkoutLogEntry? best;
    for (final e in s.entries) {
      if (e.sessionId != sessionId || e.exerciseId != exerciseId) continue;
      if (best == null || e.loggedAt.isAfter(best.loggedAt)) {
        best = e;
      }
    }
    return best;
  }

  Future<void> updateEntry(WorkoutLogEntry entry) async {
    final s = await _readStorage();
    s.entries.removeWhere(
      (e) =>
          e.sessionId == entry.sessionId &&
          e.exerciseId == entry.exerciseId &&
          e.id != entry.id,
    );
    final i = s.entries.indexWhere((e) => e.id == entry.id);
    if (i < 0) {
      s.entries.insert(0, entry);
    } else {
      s.entries[i] = entry;
    }
    await _save(s);
  }

  Future<WorkoutSession?> sessionById(String id) async {
    final s = await _readStorage();
    for (final session in s.sessions) {
      if (session.id == id) return session;
    }
    return null;
  }
}
