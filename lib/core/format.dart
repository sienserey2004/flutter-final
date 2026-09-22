/// Currency & date helpers. Null-safe; never parses null.
String formatPrice(num? value) {
  if (value == null) return '—';
  return '\$${value.toStringAsFixed(2)}';
}

String formatCount(int? value) {
  final v = value ?? 0;
  if (v < 1000) return '$v';
  if (v < 1000000) {
    final k = v / 1000;
    return '${k.toStringAsFixed(v % 1000 == 0 ? 0 : 1)}k';
  }
  final m = v / 1000000;
  return '${m.toStringAsFixed(1)}M';
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return iso;
  return '${parsed.day} ${_months[parsed.month - 1]} ${parsed.year}';
}

DateTime? parseServerDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final normalised = raw.endsWith('Z') || raw.contains(RegExp(r'[+-]\d\d:?\d\d$'))
      ? raw
      : '${raw}Z';
  return DateTime.tryParse(normalised)?.toLocal();
}

String formatOrderDate(DateTime? d) {
  if (d == null) return '—';
  return '${d.day} ${_months[d.month - 1]} ${d.year}';
}

String formatOrderDateTime(DateTime? d) {
  if (d == null) return '—';
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '${d.day} ${_months[d.month - 1]} ${d.year} · $hour:$minute';
}

String pluralize(int n, String singular, [String? plural]) =>
    n == 1 ? '$n $singular' : '$n ${plural ?? '${singular}s'}';