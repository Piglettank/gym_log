import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/exercise_catalog.dart';
import '../data/log_repository.dart';
import '../models/workout_log_entry.dart';

class ExportService {
  Future<void> shareJson(List<WorkoutLogEntry> entries) async {
    final export = entries.map(_flatExportRow).toList();
    final pretty = const JsonEncoder.withIndent('  ').convert(export);
    await SharePlus.instance.share(
      ShareParams(text: pretty, subject: 'Gym log export'),
    );
  }

  Future<void> shareCsv(List<WorkoutLogEntry> entries) async {
    final valueKeys = <String>{};
    for (final e in entries) {
      valueKeys.addAll(e.values.keys);
    }
    final sortedValueKeys = valueKeys.toList()..sort();

    final header = [
      'loggedAt',
      'exerciseId',
      'exerciseName',
      ...sortedValueKeys,
    ];

    final buffer = StringBuffer();
    buffer.writeln(header.map(_csvQuoted).join(','));

    for (final e in entries) {
      final def = exerciseById(e.exerciseId);
      final name = def?.name ?? e.exerciseId;
      final row = <String>[
        e.loggedAt.toIso8601String(),
        e.exerciseId,
        name,
        ...sortedValueKeys.map((k) => _formatCsvValue(e.values[k])),
      ];
      buffer.writeln(row.map(_csvQuoted).join(','));
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/gym_log_export.csv');
    await file.writeAsString(buffer.toString());
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Gym log CSV',
      ),
    );
  }

  Map<String, dynamic> _flatExportRow(WorkoutLogEntry e) {
    final def = exerciseById(e.exerciseId);
    final row = <String, dynamic>{
      'loggedAt': e.loggedAt.toIso8601String(),
      'exerciseId': e.exerciseId,
      'exerciseName': def?.name ?? e.exerciseId,
    };
    final sortedKeys = e.values.keys.toList()..sort();
    for (final k in sortedKeys) {
      final v = e.values[k]!;
      row[k] = v == v.roundToDouble() ? v.round() : v;
    }
    return row;
  }

  static String _formatCsvValue(double? v) {
    if (v == null) return '';
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toString();
  }

  static String _csvQuoted(String s) => '"${s.replaceAll('"', '""')}"';

  /// Shares all stored log entries (JSON or CSV). Shows snackbars on empty / error.
  Future<void> exportFullData(
    BuildContext context,
    LogRepository repository,
    String format,
  ) async {
    final entries = await repository.loadAllEntries();
    if (!context.mounted) return;
    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to export yet')),
      );
      return;
    }
    try {
      if (format == 'json') {
        await shareJson(entries);
      } else {
        await shareCsv(entries);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}
