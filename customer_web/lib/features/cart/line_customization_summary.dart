import 'package:shared_core/shared_core.dart' as shared;

/// Shared cart / checkout line subtitle from customizations + notes.
String lineCustomizationSummary(shared.OrderItem line) {
  final parts = <String>[];
  final raw = line.customizations;

  if (raw.isNotEmpty) {
    // Preferred: written at add-to-cart (extras / changes only + size/structure).
    final summary = raw['cartSummary'];
    if (summary is List && summary.isNotEmpty) {
      for (final e in summary) {
        final s = e.toString().trim();
        if (s.isNotEmpty) parts.add(s);
      }
    } else {
      // Fallback POS map without cartSummary.
      final labels = <String, String>{};
      final rawL = raw['optionLabels'];
      if (rawL is Map) {
        rawL.forEach((k, v) {
          labels[k.toString()] = v.toString();
        });
      }
      String nameOf(String id) => labels[id] ?? id;

      final size = raw['size']?.toString().trim();
      if (size != null && size.isNotEmpty) parts.add(size);

      for (final key in ['crust', 'cook', 'cut']) {
        final id = raw[key]?.toString().trim();
        if (id != null && id.isNotEmpty) {
          parts.add('$key: ${nameOf(id)}');
        }
      }

      void addList(String key, String prefix) {
        final list = raw[key];
        if (list is! List) return;
        for (final e in list) {
          final id = e.toString().trim();
          if (id.isEmpty) continue;
          parts.add(prefix.isEmpty ? nameOf(id) : '$prefix${nameOf(id)}');
        }
      }

      addList('toppings', '');
      addList('cheeses', 'Cheese: ');
      addList('sauces', 'Sauce: ');

      final halves = raw['wingHalves'];
      if (halves is Map) {
        final a = halves['a']?.toString().trim();
        final b = halves['b']?.toString().trim();
        if (a != null && a.isNotEmpty) {
          parts.add('Half 1: ${nameOf(a)}');
        }
        if (b != null && b.isNotEmpty) {
          parts.add('Half 2: ${nameOf(b)}');
        }
      }

      // Legacy groups payload (pre POS-map cart lines).
      final groups = raw['groups'];
      if (groups is List) {
        for (final e in groups) {
          if (e is! Map) continue;
          final m = Map<String, dynamic>.from(e);
          final name = (m['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          final group = (m['group'] ?? '').toString().trim();
          if (group.toLowerCase() == 'size') continue;
          final isDefault = m['isDefault'] == true;
          if (isDefault) continue;
          parts.add(group.isNotEmpty ? '$group: $name' : name);
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
