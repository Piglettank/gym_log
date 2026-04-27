import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/log_repository.dart';
import '../models/workout_session.dart';
import '../services/export_service.dart';
import 'exercise_home_screen.dart';
import 'history_hub_screen.dart';

class SessionHubScreen extends StatelessWidget {
  final LogRepository repository;
  final ExportService exportService;

  const SessionHubScreen({
    super.key,
    required this.repository,
    required this.exportService,
  });

  static const _uuid = Uuid();

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
            return _active(context, shape);
          },
        );
      },
    );
  }

  Widget _active(BuildContext context, WearShape shape) {
    final horizontal = shape == WearShape.round ? 20.0 : 16.0;
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Log'),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 20,
                  ),
                ),
                onPressed: () => _startNewSession(context),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_circle_rounded,
                      size: 44,
                      color: onPrimary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'New session',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onPrimary,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _openHistory(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'History',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewSession(BuildContext context) async {
    final session = WorkoutSession(
      id: _uuid.v4(),
      startedAt: DateTime.now().toUtc(),
    );
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ExerciseHomeScreen(
          session: session,
          repository: repository,
        ),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => HistoryHubScreen(
          repository: repository,
          exportService: exportService,
        ),
      ),
    );
  }
}
