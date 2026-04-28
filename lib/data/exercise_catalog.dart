import '../models/exercise_definition.dart';
import '../models/log_field.dart';

/// Add or edit exercises here. Each exercise defines which fields appear when logging.
const List<ExerciseDefinition> kExerciseCatalog = [
  ExerciseDefinition(
    id: 'barbell_curl',
    name: 'Barbell curl',
    emoji: '💪',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
      LogField(id: 'weightKg', label: 'Weight', unit: 'kg', decimals: 1, step: 2.5, initial: 0),
    ],
  ),
  ExerciseDefinition(
    id: 'push_ups',
    name: 'Push-ups',
    emoji: '💪',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
    ],
  ),
  ExerciseDefinition(
    id: 'bench_press',
    name: 'Bench press',
    emoji: '🏋️',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
      LogField(id: 'weightKg', label: 'Weight', unit: 'kg', decimals: 1, step: 2.5, initial: 0),
    ],
  ),
  ExerciseDefinition(
    id: 'squat',
    name: 'Squat',
    emoji: '🦵',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
      LogField(id: 'weightKg', label: 'Weight', unit: 'kg', decimals: 1, step: 2.5, initial: 0),
    ],
  ),
  ExerciseDefinition(
    id: 'bulgarian_squat',
    name: 'Bulgarian squat',
    emoji: '🦶',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
      LogField(id: 'weightKg', label: 'Weight', unit: 'kg', decimals: 1, step: 2.5, initial: 0),
    ],
  ),
  ExerciseDefinition(
    id: 'running',
    name: 'Running',
    emoji: '🏃',
    fields: [
      LogField(id: 'distanceKm', label: 'Distance', unit: 'km', decimals: 2, step: 0.1, initial: 1),
      LogField(id: 'durationMin', label: 'Time', unit: 'min', decimals: 0, step: 1, initial: 10),
    ],
  ),
  ExerciseDefinition(
    id: 'challenge',
    name: 'Challenge',
    emoji: '👥',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
      LogField(id: 'weightKg', label: 'Weight', unit: 'kg', decimals: 1, step: 2.5, initial: 0),
    ],
  ),
  ExerciseDefinition(
    id: 'plank',
    name: 'Plank',
    emoji: '⏱️',
    fields: [
      LogField(id: 'durationSec', label: 'Hold', unit: 'sec', decimals: 0, step: 5, initial: 30),
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
    ],
  ),
  ExerciseDefinition(
    id: 'side_plank',
    name: 'Side plank',
    emoji: '🤸',
    fields: [
      LogField(id: 'durationSec', label: 'Hold', unit: 'sec', decimals: 0, step: 5, initial: 30),
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
    ],
  ),
  ExerciseDefinition(
    id: 'back_lifts',
    name: 'Back lifts',
    emoji: '🦴',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
      LogField(id: 'weightKg', label: 'Weight', unit: 'kg', decimals: 1, step: 2.5, initial: 0),
    ],
  ),
  ExerciseDefinition(
    id: 'pull_ups',
    name: 'Pull-ups',
    emoji: '🧗',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
    ],
  ),
  ExerciseDefinition(
    id: 'dips',
    name: 'Dips',
    emoji: '💪',
    fields: [
      LogField(id: 'sets', label: 'Sets', decimals: 0, step: 1, initial: 1),
      LogField(id: 'reps', label: 'Reps', decimals: 0, step: 1, initial: 8),
      LogField(id: 'weightKg', label: 'Added', unit: 'kg', decimals: 1, step: 2.5, initial: 0),
    ],
  ),
];

ExerciseDefinition? exerciseById(String id) {
  for (final e in kExerciseCatalog) {
    if (e.id == id) return e;
  }
  return null;
}

final _catalogIndexById = {
  for (var i = 0; i < kExerciseCatalog.length; i++) kExerciseCatalog[i].id: i,
};

/// Highest total log count first; ties keep default catalog order.
List<ExerciseDefinition> exercisesSortedByLogCountDesc(Map<String, int> countsByExerciseId) {
  final list = List<ExerciseDefinition>.from(kExerciseCatalog);
  list.sort((a, b) {
    final ca = countsByExerciseId[a.id] ?? 0;
    final cb = countsByExerciseId[b.id] ?? 0;
    if (cb != ca) return cb.compareTo(ca);
    return _catalogIndexById[a.id]!.compareTo(_catalogIndexById[b.id]!);
  });
  return list;
}
