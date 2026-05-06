import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/log_repository.dart';
import '../services/sync_service.dart';
import '../widgets/ambient_clock.dart';
import '../widgets/watch_hub_action_face.dart';
import 'exercise_home_screen.dart';
import 'history_hub_screen.dart';

class SessionHubScreen extends StatelessWidget {
  final LogRepository repository;
  final SyncService syncService;

  const SessionHubScreen({super.key, required this.repository, required this.syncService});

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
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WatchHubActionFace(
          shape: shape,
          onNewSession: () => _openExerciseList(context),
          onHistory: () => _openHistory(context),
          newSessionContent: Align(
            alignment: const Alignment(0, -0.23),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_rounded, size: 34, color: onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Log exercise',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: onPrimary,
                      height: 1.15,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
          historyContent: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 32),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Menu',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openExerciseList(BuildContext context) async {
    if (!context.mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (context) => ExerciseHomeScreen(repository: repository)),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => HistoryHubScreen(repository: repository, syncService: syncService),
      ),
    );
  }
}
