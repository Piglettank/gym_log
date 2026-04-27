/// Display order for known log field ids (weight/distance/time/reps/sets).
const _displayOrder = [
  'weightKg',
  'distanceKm',
  'durationSec',
  'durationMin',
  'reps',
  'sets',
];

String formatLogValuesSummary(Map<String, double> values) {
  if (values.isEmpty) return '';
  final parts = <String>[];
  final used = <String>{};

  for (final id in _displayOrder) {
    final v = values[id];
    if (v != null) {
      parts.add(_formatKnownField(id, v));
      used.add(id);
    }
  }

  for (final e in values.entries) {
    if (!used.contains(e.key)) {
      parts.add('${e.key}: ${_formatLogNumber(e.value)}');
    }
  }

  return parts.join(' | ');
}

String _formatKnownField(String id, double v) {
  final n = _formatLogNumber(v);
  switch (id) {
    case 'weightKg':
      return '$n kg';
    case 'reps':
      return '$n reps';
    case 'sets':
      return '$n sets';
    case 'distanceKm':
      return '$n km';
    case 'durationMin':
      return '$n min';
    case 'durationSec':
      return '$n sec';
    default:
      return '$id: $n';
  }
}

String _formatLogNumber(double v) {
  if (v == v.roundToDouble()) return v.round().toString();
  return v.toString();
}
