import 'package:shared_core/shared_core.dart' as shared;

/// Shared cart / checkout line subtitle from customizations + notes.
String lineCustomizationSummary(shared.OrderItem line) {
  final parts = <String>[];

  final raw = line.customizations;
  if (raw.isNotEmpty) {
    final groups = raw['groups'];
    if (groups is List) {
      for (final e in groups) {
        if (e is! Map) continue;
        final m = Map<String, dynamic>.from(e);
        final name = (m['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final group = (m['group'] ?? '').toString().trim();
        if (group.toLowerCase() == 'size') continue;
        final price = (m['price'] is num)
            ? (m['price'] as num).toDouble()
            : 0.0;
        final label = group.isNotEmpty ? '$group: $name' : name;
        if (price > 0) {
          parts.add('$label (+\$${price.toStringAsFixed(2)})');
        } else {
          parts.add(label);
        }
      }
    }
  }

  final si = line.specialInstructions?.trim();
  if (si != null && si.isNotEmpty) {
    parts.add('Note: $si');
  }

  return parts.join(' · ');
}
