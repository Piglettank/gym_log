import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../data/log_repository.dart';
import '../models/exercise_definition.dart';
import '../models/log_field.dart';
import '../models/workout_log_entry.dart';
import '../util/log_entry_format.dart';

class LogExerciseScreen extends StatefulWidget {
  final ExerciseDefinition definition;
  final LogRepository repository;
  final WorkoutLogEntry? existingEntry;

  const LogExerciseScreen({
    super.key,
    required this.definition,
    required this.repository,
    this.existingEntry,
  });

  @override
  State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
  static const _uuid = Uuid();
  static const _touchSize = 68.0;
  static const _holdArmMs = 320;

  final Map<String, double> _values = {};

  Timer? _holdArmTimer;
  Timer? _holdTickTimer;
  LogField? _holdField;
  int _holdSign = 1;
  bool _holdPointerDown = false;
  bool _holdRepeating = false;
  int _holdTickIndex = 0;
  String? _pressedStepperKey;
  WorkoutLogEntry? _personalBestEntry;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEntry;
    for (final f in widget.definition.fields) {
      final fromLog = existing?.values[f.id];
      _values[f.id] = fromLog ?? f.initial ?? _defaultInitial(f);
    }
    _loadPersonalBest();
  }

  Future<void> _loadPersonalBest() async {
    final all = await widget.repository.loadEntriesForExercise(widget.definition.id);
    if (!mounted) {
      return;
    }
    final best = _entryWithBestPrimary(all, widget.definition);
    setState(() {
      _personalBestEntry = best;
      if (widget.existingEntry == null && best != null) {
        final bestWeight = best.values['weightKg'];
        if (bestWeight != null && _values.containsKey('weightKg')) {
          _values['weightKg'] = bestWeight;
        }
      }
    });
  }

  @override
  void dispose() {
    _disarmHoldRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = widget.existingEntry != null
        ? 'Edit ${widget.definition.name}'
        : widget.definition.name;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 22, 8, 28),
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                heading,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_personalBestEntry != null) ...[
              const SizedBox(height: 8),
              _personalBestLabel(theme),
              const SizedBox(height: 4),
              Text(
                formatLogValuesSummary(_personalBestEntry!.values),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 14),
            for (final field in widget.definition.fields) ...[
              SizedBox(
                width: double.infinity,
                child: Text(
                  field.unit != null
                      ? '${field.label} (${field.unit})'
                      : field.label,
                  style: theme.textTheme.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _holdStepperButton(theme, field, -1, Icons.remove),
                  Expanded(
                    child: Text(
                      _formatValue(field, _values[field.id]!),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  _holdStepperButton(theme, field, 1, Icons.add),
                ],
              ),
              const SizedBox(height: 10),
            ],
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(
                widget.existingEntry != null ? 'Update log' : 'Save log',
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Same primary field order as [ExerciseProgressScreen] trend chart.
  LogField? _primaryFieldForExercise(ExerciseDefinition ex) {
    const priority = ['weightKg', 'distanceKm', 'durationSec', 'durationMin', 'reps', 'sets'];
    for (final id in priority) {
      for (final f in ex.fields) {
        if (f.id == id) return f;
      }
    }
    return ex.fields.isNotEmpty ? ex.fields.first : null;
  }

  /// Best effort on the primary metric; ties go to the most recent log.
  WorkoutLogEntry? _entryWithBestPrimary(
    List<WorkoutLogEntry> all,
    ExerciseDefinition ex,
  ) {
    final field = _primaryFieldForExercise(ex);
    if (field == null || all.isEmpty) return null;
    WorkoutLogEntry? best;
    double? bestVal;
    for (final e in all) {
      final v = e.values[field.id];
      if (v == null) continue;
      if (bestVal == null || v > bestVal) {
        bestVal = v;
        best = e;
      } else if (v == bestVal && best != null) {
        if (e.loggedAt.isAfter(best.loggedAt)) {
          best = e;
        }
      }
    }
    return best;
  }

  Widget _personalBestLabel(ThemeData theme) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
    return Text(
      'Personal best',
      textAlign: TextAlign.center,
      style: style,
    );
  }

  double _defaultInitial(LogField f) {
    switch (f.id) {
      case 'sets':
      case 'reps':
        return 1;
      case 'durationSec':
        return 30;
      case 'durationMin':
        return 10;
      case 'distanceKm':
        return 1;
      default:
        return 0;
    }
  }

  double _stepFor(LogField f) {
    if (f.step != null) return f.step!;
    if (f.decimals >= 2) return 0.1;
    if (f.decimals == 1) return 0.5;
    return 1;
  }

  double _minFor(LogField f) {
    if (f.id == 'weightKg') return 0;
    if (f.id == 'sets' || f.id == 'reps') return 1;
    return 0;
  }

  double _roundToFieldDecimals(double v, LogField f) {
    if (f.decimals <= 0) return v.roundToDouble();
    final m = math.pow(10, f.decimals).toDouble();
    return (v * m).round() / m;
  }

  void _nudge(LogField field, int sign) {
    final step = _stepFor(field);
    final min = _minFor(field);
    final before = _values[field.id]!;
    final raw = before + sign * step;
    final rounded = _roundToFieldDecimals(raw, field);
    final next = rounded.clamp(min, 99999);
    if (next == before) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _values[field.id] = next.toDouble();
    });
  }

  Widget _holdStepperButton(ThemeData theme, LogField field, int sign, IconData icon) {
    final stepperKey = '${field.id}:$sign';
    final pressed = _pressedStepperKey == stepperKey;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _onStepperPointerDown(field, sign),
      onPointerUp: (_) => _onStepperPointerUp(field, sign),
      onPointerCancel: (_) => _onStepperPointerUp(field, sign),
      child: SizedBox(
        width: _touchSize,
        height: _touchSize,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: _touchSize,
          height: _touchSize,
          decoration: BoxDecoration(
            color: pressed
                ? theme.colorScheme.onSurface.withValues(alpha: 0.12)
                : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: AnimatedScale(
            scale: pressed ? 0.88 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: AnimatedOpacity(
              opacity: pressed ? 0.55 : 1,
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              child: Center(
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSurface,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onStepperPointerDown(LogField field, int sign) {
    _disarmHoldRepeat();
    HapticFeedback.selectionClick();
    setState(() {
      _pressedStepperKey = '${field.id}:$sign';
    });
    _holdPointerDown = true;
    _holdRepeating = false;
    _holdField = field;
    _holdSign = sign;
    _holdTickIndex = 0;
    _holdArmTimer = Timer(const Duration(milliseconds: _holdArmMs), () {
      if (!_holdPointerDown || !mounted) return;
      if (_holdField != field || _holdSign != sign) return;
      _holdRepeating = true;
      _holdTickIndex = 0;
      _scheduleHoldTick();
    });
  }

  void _onStepperPointerUp(LogField field, int sign) {
    _holdArmTimer?.cancel();
    _holdArmTimer = null;
    _holdTickTimer?.cancel();
    _holdTickTimer = null;
    final wasQuickTap = !_holdRepeating;
    _holdPointerDown = false;
    _holdRepeating = false;
    _holdField = null;
    setState(() {
      _pressedStepperKey = null;
    });
    if (wasQuickTap) {
      _nudge(field, sign);
    }
  }

  void _scheduleHoldTick() {
    _holdTickTimer?.cancel();
    if (!_holdPointerDown || !_holdRepeating || _holdField == null) return;
    _nudge(_holdField!, _holdSign);
    _holdTickIndex++;
    final delayMs = _holdRepeatDelayMs(_holdTickIndex);
    _holdTickTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      _scheduleHoldTick();
    });
  }

  int _holdRepeatDelayMs(int tickIndex) {
    const startMs = 200;
    const minMs = 20;
    const acceleration = 12;
    return math.max(minMs, startMs - tickIndex * acceleration);
  }

  void _disarmHoldRepeat() {
    _holdArmTimer?.cancel();
    _holdArmTimer = null;
    _holdTickTimer?.cancel();
    _holdTickTimer = null;
    _holdPointerDown = false;
    _holdRepeating = false;
    _holdField = null;
    _pressedStepperKey = null;
  }

  String _formatValue(LogField field, double v) {
    if (field.decimals <= 0) return v.round().toString();
    return v.toStringAsFixed(field.decimals);
  }

  bool _isValueValid(LogField field, double v) {
    switch (field.id) {
      case 'weightKg':
        return v >= 0;
      case 'sets':
      case 'reps':
        return v >= 1;
      case 'distanceKm':
      case 'durationMin':
      case 'durationSec':
        return v > 0;
      default:
        return v > 0;
    }
  }

  Future<void> _save() async {
    for (final field in widget.definition.fields) {
      final v = _values[field.id]!;
      if (!_isValueValid(field, v)) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Set a valid ${field.label}')));
        return;
      }
    }

    final values = Map<String, double>.from(_values);
    final existing = widget.existingEntry;
    if (existing != null) {
      await widget.repository.updateEntry(
        WorkoutLogEntry(
          id: existing.id,
          exerciseId: existing.exerciseId,
          loggedAt: existing.loggedAt,
          values: values,
        ),
      );
    } else {
      await widget.repository.addEntry(
        WorkoutLogEntry(
          id: _uuid.v4(),
          exerciseId: widget.definition.id,
          loggedAt: DateTime.now().toUtc(),
          values: values,
        ),
      );
    }
    if (!mounted) return;
    if (existing == null) {
      final theme = Theme.of(context);
      final overlay = Overlay.of(context, rootOverlay: true);
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) {
          return Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 120,
                  height: 120,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    'Exercise logged!',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
      overlay.insert(entry);
      Future<void>.delayed(const Duration(seconds: 2), entry.remove);
    } else {
      Navigator.of(context).pop(false);
    }
  }
}
