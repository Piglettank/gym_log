import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/exercise_catalog.dart';
import '../data/log_repository.dart';
import '../models/exercise_definition.dart';
import 'exercise_progress_screen.dart';

class ExerciseHistoryListScreen extends StatefulWidget {
  final LogRepository repository;

  const ExerciseHistoryListScreen({
    super.key,
    required this.repository,
  });

  @override
  State<ExerciseHistoryListScreen> createState() =>
      _ExerciseHistoryListScreenState();
}

class _ExerciseHistoryListScreenState extends State<ExerciseHistoryListScreen> {
  Map<String, int> _counts = {};
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
                    'Exercises',
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
        title: const Text('Exercise history'),
      ),
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
        itemCount: kExerciseCatalog.length,
        itemBuilder: (context, index) {
          final exercise = kExerciseCatalog[index];
          final count = _counts[exercise.id] ?? 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _openExercise(exercise),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
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
                            style: Theme.of(context).textTheme.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (!_loading)
                            Text(
                              '$count ${count == 1 ? 'log' : 'logs'}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final all = await widget.repository.loadAllEntries();
    final counts = <String, int>{};
    for (final e in all) {
      counts[e.exerciseId] = (counts[e.exerciseId] ?? 0) + 1;
    }
    if (!mounted) return;
    setState(() {
      _counts = counts;
      _loading = false;
    });
  }

  Future<void> _openExercise(ExerciseDefinition exercise) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ExerciseProgressScreen(
          repository: widget.repository,
          exercise: exercise,
        ),
      ),
    );
    await _load();
  }
}
