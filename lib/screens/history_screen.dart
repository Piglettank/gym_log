import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/log_repository.dart';
import '../models/workout_session.dart';
import '../util/session_format.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final LogRepository repository;

  const HistoryScreen({
    super.key,
    required this.repository,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<WorkoutSession> _sessions = [];
  Map<String, int> _entryCounts = {};
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
                    'Log history',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log history'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontal),
                    child: Text(
                      'No sessions yet.\nStart a new session from the home screen.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final count = _entryCounts[session.id] ?? 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _openSession(session),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 22,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formatSessionStartLocal(
                                        session.startedAt,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    Text(
                                      '$count ${count == 1 ? 'log' : 'logs'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _load() async {
    final sessions = await widget.repository.loadSessions();
    final allEntries = await widget.repository.loadAllEntries();
    final counts = <String, int>{};
    for (final e in allEntries) {
      counts[e.sessionId] = (counts[e.sessionId] ?? 0) + 1;
    }
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _entryCounts = counts;
      _loading = false;
    });
  }

  Future<void> _openSession(WorkoutSession session) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SessionDetailScreen(
          repository: widget.repository,
          session: session,
        ),
      ),
    );
    await _load();
  }
}
