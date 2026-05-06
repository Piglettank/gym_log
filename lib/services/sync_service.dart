import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/log_repository.dart';
import '../models/workout_log_entry.dart';

class SyncService {
  static const _nameKey = 'sync_user_name';

  final _firestore = FirebaseFirestore.instance;

  Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<void> setName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  Future<void> uploadData(LogRepository repository) async {
    final name = await getName();
    if (name == null || name.isEmpty) {
      throw StateError('No sync name configured');
    }
    final entries = await repository.loadAllEntries();
    await _firestore.collection('logs').doc(name).set({
      'entries': entries.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> fetchData(LogRepository repository) async {
    final name = await getName();
    if (name == null || name.isEmpty) {
      throw StateError('No sync name configured');
    }
    final snapshot = await _firestore.collection('logs').doc(name).get();
    final data = snapshot.data();
    if (data == null) {
      await repository.replaceAllEntries([]);
      return;
    }
    final rawEntries = data['entries'] as List<dynamic>? ?? [];
    final entries = rawEntries
        .map((e) => WorkoutLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    await repository.replaceAllEntries(entries);
  }
}
