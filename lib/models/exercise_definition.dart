import 'log_field.dart';

class ExerciseDefinition {
  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.fields,
  });

  final String id;
  final String name;
  final String emoji;
  final List<LogField> fields;
}
