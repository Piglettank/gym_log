import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/exercise_catalog.dart';
import '../data/log_repository.dart';
import '../models/workout_log_entry.dart';
import '../models/workout_session.dart';
import '../util/log_entry_format.dart';
import '../util/session_format.dart';
import 'exercise_home_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final LogRepository repository;
  final WorkoutSession session;

  const SessionDetailScreen({
    super.key,
    required this.repository,
    required this.session,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
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
              return Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: Text(
                    'Session',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white24,
                        ),
                  ),
                ),
              );
            }
            return _active(context, shape);
          },
        );
      },
    );
  }

  Widget _active(BuildContext context, WearShape shape) {
    final horizontal = shape == WearShape.round ? 20.0 : 12.0;
    final title = formatSessionStartLocal(widget.session.startedAt);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 8),
                  child: FilledButton(
                    onPressed: _continueSession,
                    child: const Text('Continue session'),
                  ),
                ),
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: horizontal),
                            child: const Text(
                              'Nothing logged in this session yet.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            0,
                            horizontal,
                            24,
                          ),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final def = exerciseById(entry.exerciseId);
                            final label = def?.name ?? entry.exerciseId;
                            final emoji = def?.emoji ?? '📝';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formatLogValuesSummary(
                                              entry.values,
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Future<void> _continueSession() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ExerciseHomeScreen(
          session: widget.session,
          repository: widget.repository,
        ),
      ),
    );
    await _load();
  }

  Future<void> _load() async {
    final list = await widget.repository
        .loadEntriesForSession(widget.session.id);
    if (!mounted) return;
    setState(() {
      _entries = list;
      _loading = false;
    });
  }
}
