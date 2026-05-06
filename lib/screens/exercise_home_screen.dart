import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/exercise_catalog.dart';
import '../data/log_repository.dart';
import '../models/exercise_definition.dart';
import '../widgets/ambient_clock.dart';
import 'log_exercise_screen.dart';

class ExerciseHomeScreen extends StatefulWidget {
  final LogRepository repository;

  const ExerciseHomeScreen({
    super.key,
    required this.repository,
  });

  @override
  State<ExerciseHomeScreen> createState() => _ExerciseHomeScreenState();
}

class _ExerciseHomeScreenState extends State<ExerciseHomeScreen> {
  List<ExerciseDefinition> _orderedExercises = List<ExerciseDefinition>.from(kExerciseCatalog);

  @override
  void initState() {
    super.initState();
    _refresh();
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
            return _activeScaffold(context, shape);
          },
        );
      },
    );
  }

  Widget _activeScaffold(BuildContext context, WearShape shape) {
    final horizontal = shape == WearShape.round ? 20.0 : 12.0;
    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
          itemCount: 1 + _orderedExercises.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Exercises',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              );
            }
            final exercise = _orderedExercises[index - 1];
            return _ExerciseTile(
              exercise: exercise,
              onTap: () => _openLog(exercise),
            );
          },
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final all = await widget.repository.loadAllEntries();
    if (!mounted) {
      return;
    }
    final counts = <String, int>{};
    for (final e in all) {
      counts[e.exerciseId] = (counts[e.exerciseId] ?? 0) + 1;
    }
    setState(() {
      _orderedExercises = exercisesSortedByLogCountDesc(counts);
    });
  }

  Future<void> _openLog(ExerciseDefinition exercise) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LogExerciseScreen(
          definition: exercise,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _refresh();
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.onTap,
  });

  final ExerciseDefinition exercise;
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
                child: Text(
                  exercise.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
