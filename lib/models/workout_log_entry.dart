class WorkoutLogEntry {
  WorkoutLogEntry({
    required this.id,
    required this.exerciseId,
    required this.loggedAt,
    required this.values,
  });

  final String id;
  final String exerciseId;
  final DateTime loggedAt;
  final Map<String, double> values;

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'loggedAt': loggedAt.toIso8601String(),
        'values': values.map((k, v) => MapEntry(k, v)),
      };

  factory WorkoutLogEntry.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    final values = <String, double>{};
    if (rawValues is Map) {
      for (final e in rawValues.entries) {
        final v = e.value;
        if (v is num) {
          values[e.key.toString()] = v.toDouble();
        }
      }
    }
    return WorkoutLogEntry(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      values: values,
    );
  }
}
