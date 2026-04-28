import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/exercise_catalog.dart';
import '../data/log_repository.dart';
import '../models/exercise_definition.dart';
import 'exercise_progress_screen.dart';

class ExerciseHistoryListScreen extends StatefulWidget {
  final LogRepository repository;

  const ExerciseHistoryListScreen({super.key, required this.repository});

  @override
  State<ExerciseHistoryListScreen> createState() => _ExerciseHistoryListScreenState();
}

class _ExerciseHistoryListScreenState extends State<ExerciseHistoryListScreen> {
  List<ExerciseDefinition> _orderedExercises = List<ExerciseDefinition>.from(kExerciseCatalog);
  Map<String, int> _logCounts = {};

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
                    'Exercises',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white24),
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
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
          itemCount: 1 + _orderedExercises.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Exercise history',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }
            final exercise = _orderedExercises[index - 1];
            final theme = Theme.of(context);
            final n = _logCounts[exercise.id] ?? 0;
            final subtitle = n == 0
                ? 'No logs'
                : n == 1
                ? '1 log'
                : '$n logs';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _openExercise(exercise),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(exercise.emoji, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              exercise.name,
                              style: theme.textTheme.titleSmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _load() async {
    final all = await widget.repository.loadAllEntries();
    final counts = <String, int>{};
    for (final e in all) {
      counts[e.exerciseId] = (counts[e.exerciseId] ?? 0) + 1;
    }
    if (!mounted) return;
    setState(() {
      _logCounts = counts;
      _orderedExercises = exercisesSortedByLogCountDesc(counts);
    });
  }

  Future<void> _openExercise(ExerciseDefinition exercise) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) =>
            ExerciseProgressScreen(repository: widget.repository, exercise: exercise),
      ),
    );
    await _load();
  }
}
