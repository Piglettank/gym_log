class LogField {
  const LogField({
    required this.id,
    required this.label,
    this.unit,
    this.decimals = 0,
    this.step,
    this.initial,
  });

  final String id;
  final String label;
  final String? unit;
  final int decimals;
  final double? step;
  final double? initial;
}
