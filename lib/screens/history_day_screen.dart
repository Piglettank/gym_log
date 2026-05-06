import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/exercise_catalog.dart';
import '../data/log_repository.dart';
import '../models/exercise_definition.dart';
import '../models/workout_log_entry.dart';
import '../util/log_entry_format.dart';
import '../util/session_format.dart';
import '../widgets/ambient_clock.dart';
import 'log_exercise_screen.dart';

class HistoryDayScreen extends StatefulWidget {
  final LogRepository repository;
  final DateTime localDay;

  const HistoryDayScreen({
    super.key,
    required this.repository,
    required this.localDay,
  });

  @override
  State<HistoryDayScreen> createState() => _HistoryDayScreenState();
}

class _HistoryDayScreenState extends State<HistoryDayScreen> {
  List<WorkoutLogEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return WatchShape(
      builder: (context, shape, _) {
        return AmbientMode(
          builder: (context, mode, _) {
            if (mode == WearMode.ambient) {
              return const AmbientClock();
            }
            return _active(context, shape);
          },
        );
      },
    );
  }

  Widget _active(BuildContext context, WearShape shape) {
    final horizontal = shape == WearShape.round ? 20.0 : 12.0;
    final title = formatLogHistoryDayHeader(widget.localDay);
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        );
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      child: const Text(
                        'No logs for this day.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    for (final entry in _entries) _entryTile(context, entry),
                ],
              ),
      ),
    );
  }

  Widget _entryTile(BuildContext context, WorkoutLogEntry entry) {
    final def = exerciseById(entry.exerciseId);
    final label = def?.name ?? entry.exerciseId;
    final emoji = def?.emoji ?? '📝';
    final time = formatLogTimeOfDay(entry.loggedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: def == null ? null : () => _openEdit(context, entry, def),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatLogValuesSummary(entry.values),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    WorkoutLogEntry entry,
    ExerciseDefinition def,
  ) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LogExerciseScreen(
          definition: def,
          repository: widget.repository,
          existingEntry: entry,
        ),
      ),
    );
    if (saved != null) {
      await _load();
    }
  }

  Future<void> _load() async {
    final list =
        await widget.repository.loadEntriesForLocalDay(widget.localDay);
    if (!mounted) return;
    setState(() {
      _entries = list;
      _loading = false;
    });
  }
}
