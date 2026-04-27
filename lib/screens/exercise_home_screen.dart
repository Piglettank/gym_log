import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/exercise_catalog.dart';
import '../data/log_repository.dart';
import '../models/exercise_definition.dart';
import '../models/workout_session.dart';
import '../util/session_format.dart';
import 'log_exercise_screen.dart';

class ExerciseHomeScreen extends StatefulWidget {
  final WorkoutSession session;
  final LogRepository repository;

  const ExerciseHomeScreen({
    super.key,
    required this.session,
    required this.repository,
  });

  @override
  State<ExerciseHomeScreen> createState() => _ExerciseHomeScreenState();
}

class _ExerciseHomeScreenState extends State<ExerciseHomeScreen> {
  int _logCount = 0;
  bool _loading = true;
  Set<String> _loggedExerciseIds = {};

  @override
  void initState() {
    super.initState();
    _refreshCount();
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
                    'Gym Log',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white24,
                        ),
                  ),
                ),
              );
            }
            return _activeScaffold(context, shape);
          },
        );
      },
    );
  }

  Widget _activeScaffold(BuildContext context, WearShape shape) {
    final horizontal =
        shape == WearShape.round ? 20.0 : 12.0;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
        itemCount: kExerciseCatalog.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _sessionSummaryCard(context);
          }
          final exercise = kExerciseCatalog[index - 1];
          return _ExerciseTile(
            exercise: exercise,
            logged: _loggedExerciseIds.contains(exercise.id),
            onTap: () => _openLog(exercise),
          );
        },
      ),
    );
  }

  Widget _sessionSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Session', style: theme.textTheme.titleSmall),
            Text(
              formatSessionStartLocal(widget.session.startedAt),
              style: theme.textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!_loading)
              Text(
                '$_logCount ${_logCount == 1 ? 'log' : 'logs'}',
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshCount() async {
    final logs =
        await widget.repository.loadEntriesForSession(widget.session.id);
    if (!mounted) return;
    setState(() {
      _logCount = logs.length;
      _loggedExerciseIds = {for (final e in logs) e.exerciseId};
      _loading = false;
    });
  }

  Future<void> _openLog(ExerciseDefinition exercise) async {
    final existing = await widget.repository.findEntryForSessionExercise(
      widget.session.id,
      exercise.id,
    );
    if (!mounted) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LogExerciseScreen(
          definition: exercise,
          repository: widget.repository,
          session: widget.session,
          existingEntry: existing,
        ),
      ),
    );
    if (saved == true) {
      await _refreshCount();
    }
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.logged,
    required this.onTap,
  });

  final ExerciseDefinition exercise;
  final bool logged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Text(
                exercise.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (logged)
                      Text(
                        'Logged — tap to edit',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                logged
                    ? Icons.edit_note_rounded
                    : Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
