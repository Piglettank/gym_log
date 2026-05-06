import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/log_repository.dart';
import '../services/sync_service.dart';
import '../widgets/ambient_clock.dart';
import 'exercise_history_list_screen.dart';
import 'history_screen.dart';
import 'sync_screen.dart';

class HistoryHubScreen extends StatelessWidget {
  final LogRepository repository;
  final SyncService syncService;

  const HistoryHubScreen({
    super.key,
    required this.repository,
    required this.syncService,
  });

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
    final items = <_MenuItem>[
      _MenuItem(icon: Icons.history_rounded, label: 'Log history', onTap: () => _openLogHistory(context)),
      _MenuItem(icon: Icons.fitness_center_rounded, label: 'Exercise history', onTap: () => _openExerciseHistory(context)),
      _MenuItem(icon: Icons.sync_rounded, label: 'Sync data', onTap: () => _openSync(context)),
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
          itemCount: 1 + items.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Menu',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              );
            }
            final item = items[index - 1];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: Theme.of(context).textTheme.titleSmall,
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

  void _openSync(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => SyncScreen(
          repository: repository,
          syncService: syncService,
        ),
      ),
    );
  }

  void _openLogHistory(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          repository: repository,
        ),
      ),
    );
  }

  void _openExerciseHistory(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => ExerciseHistoryListScreen(
          repository: repository,
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
