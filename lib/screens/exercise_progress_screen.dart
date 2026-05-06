import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wear_plus/wear_plus.dart';

import '../data/log_repository.dart';
import '../models/exercise_definition.dart';
import '../models/log_field.dart';
import '../models/workout_log_entry.dart';
import '../util/log_entry_format.dart';
import '../util/session_format.dart';
import '../widgets/ambient_clock.dart';

class ExerciseProgressScreen extends StatefulWidget {
  final LogRepository repository;
  final ExerciseDefinition exercise;

  const ExerciseProgressScreen({super.key, required this.repository, required this.exercise});

  @override
  State<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends State<ExerciseProgressScreen> {
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
    final ex = widget.exercise;
    final trendBanner = _buildTrendBanner(context);
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600);
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: const Text('No logs for this exercise yet.', textAlign: TextAlign.center),
                ),
              )
            : ListView(
                padding: EdgeInsets.fromLTRB(horizontal, 4, horizontal, 24),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        ex.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                    ),
                  ),
                  ?trendBanner,
                  ..._entries.map((e) => _entryCard(context, e)),
                ],
              ),
      ),
    );
  }

  Widget? _buildTrendBanner(BuildContext context) {
    if (_entries.isEmpty) return null;
    final field = _primaryTrendField(widget.exercise);
    if (field == null) return null;

    final theme = Theme.of(context);
    final series = _recentSessionsTrendValues(field);
    final chartColor = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Trend',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(color: chartColor),
            ),
            Text(
              field.unit != null ? '${field.label} (${field.unit})' : field.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  size: Size(constraints.maxWidth, 56),
                  painter: _SessionTrendPainter(values: series, color: chartColor),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Oldest → newest, up to 10 sessions (one log per session for this exercise).
  List<double?> _recentSessionsTrendValues(LogField field) {
    final recentNewestFirst = _entries.take(10).toList();
    return [for (final e in recentNewestFirst.reversed) e.values[field.id]];
  }

  Widget _entryCard(BuildContext context, WorkoutLogEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatExerciseHistoryDateTime(entry.loggedAt),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              formatLogValuesSummary(entry.values),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  LogField? _primaryTrendField(ExerciseDefinition ex) {
    const priority = ['weightKg', 'distanceKm', 'durationSec', 'durationMin', 'reps', 'sets'];
    for (final id in priority) {
      for (final f in ex.fields) {
        if (f.id == id) return f;
      }
    }
    return ex.fields.isNotEmpty ? ex.fields.first : null;
  }

  Future<void> _load() async {
    final list = await widget.repository.loadEntriesForExercise(widget.exercise.id);
    if (!mounted) return;
    setState(() {
      _entries = list;
      _loading = false;
    });
  }
}

class _SessionTrendPainter extends CustomPainter {
  _SessionTrendPainter({required this.values, required this.color});

  final List<double?> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;

    double? minY;
    double? maxY;
    for (final v in values) {
      if (v == null) continue;
      minY = minY == null ? v : math.min(minY, v);
      maxY = maxY == null ? v : math.max(maxY, v);
    }
    if (minY == null || maxY == null) return;

    var minPadded = minY;
    var maxPadded = maxY;
    if (minPadded == maxPadded) {
      minPadded -= 1;
      maxPadded += 1;
    }

    const pad = 4.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;
    if (w <= 0 || h <= 0) return;

    double xAt(int i) => pad + (n <= 1 ? w / 2 : i * w / (n - 1));
    double yAt(double v) => pad + (maxPadded - v) / (maxPadded - minPadded) * h;

    final validIndices = <int>[];
    for (var i = 0; i < n; i++) {
      if (values[i] != null) validIndices.add(i);
    }
    if (validIndices.isEmpty) return;

    if (validIndices.length == 1) {
      final i = validIndices.single;
      canvas.drawCircle(Offset(xAt(i), yAt(values[i]!)), 3.5, Paint()..color = color);
      return;
    }

    final linePath = Path();
    for (var k = 0; k < validIndices.length; k++) {
      final i = validIndices[k];
      final ox = xAt(i);
      final oy = yAt(values[i]!);
      if (k == 0) {
        linePath.moveTo(ox, oy);
      } else {
        linePath.lineTo(ox, oy);
      }
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );

    final fillPath = Path.from(linePath);
    final lastI = validIndices.last;
    final firstI = validIndices.first;
    fillPath.lineTo(xAt(lastI), size.height - pad);
    fillPath.lineTo(xAt(firstI), size.height - pad);
    fillPath.close();
    final fillPaint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.02)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _SessionTrendPainter oldDelegate) {
    return !listEquals(oldDelegate.values, values) || oldDelegate.color != color;
  }
}
