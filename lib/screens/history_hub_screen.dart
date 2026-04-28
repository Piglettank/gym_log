import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/log_repository.dart';
import '../services/export_service.dart';
import 'exercise_history_list_screen.dart';
import 'history_screen.dart';

class HistoryHubScreen extends StatelessWidget {
  final LogRepository repository;
  final ExportService exportService;

  const HistoryHubScreen({
    super.key,
    required this.repository,
    required this.exportService,
  });

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
                    'History',
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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: () => _openLogHistory(context),
                  child: const Text('Log history'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _openExerciseHistory(context),
                  child: const Text('Exercise history'),
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  onPressed: () => _showExportSheet(context),
                  child: const Text('Export'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExportSheet(BuildContext context) async {
    final format = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Export JSON'),
                onTap: () => Navigator.pop(sheetContext, 'json'),
              ),
              ListTile(
                title: const Text('Export CSV'),
                onTap: () => Navigator.pop(sheetContext, 'csv'),
              ),
            ],
          ),
        );
      },
    );
    if (format == null || !context.mounted) return;
    await exportService.exportFullData(context, repository, format);
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
