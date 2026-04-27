class WorkoutSession {
  WorkoutSession({
    required this.id,
    required this.startedAt,
  });

  final String id;
  final DateTime startedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
    );
  }
}
