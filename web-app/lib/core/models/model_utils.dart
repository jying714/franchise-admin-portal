import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customization.dart';
import '../models/nutrition_info.dart';

/// =======================
/// ModelUtils
/// =======================
/// - Robust, defensive parsing and safe conversion for all models.
/// - Use everywhere for (de)serialization of Firestore, SQLite, API, and user input.
/// =======================

// Safe list parser (with converter)
List<T> safeList<T>(dynamic raw, T Function(dynamic) convert) {
  if (raw is List) return raw.map<T>(convert).toList();
  return <T>[];
}

// Safe CSV to List<String>
List<String> splitCsv(dynamic csv) {
  if (csv == null) return <String>[];
  if (csv is String) {
    return csv
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  if (csv is List) return csv.map((e) => e.toString()).toList();
  return <String>[];
}

// Join List<String> to CSV
String joinCsv(List<String> items) => items.join(',');

// Defensive Map cast
Map<String, dynamic> safeMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return <String, dynamic>{};
}

// Date/time conversion
DateTime? safeDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  if (value is Timestamp) return value.toDate();
  return null;
}

DateTime safeDateOrNow(dynamic value) => safeDate(value) ?? DateTime.now();

// Numeric conversions
double safeDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

int safeInt(dynamic value, [int defaultValue = 0]) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

// Bool conversion
bool safeBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

// Price formatting
String formatPrice(num price) => '\$${price.toStringAsFixed(2)}';

// Defensive image field
String? safeImage(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}

// ==== CUSTOM MENU MODEL HELPERS ====

// Defensive parse for List<Customization>
List<Customization> parseCustomizations(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw.map((e) => Customization.fromFirestore(safeMap(e))).toList();
  }
  // New system: all customizations should be structured as List, not String/legacy!
  return [];
}

// Defensive parse for NutritionInfo
NutritionInfo? parseNutrition(dynamic raw) {
  if (raw == null) return null;
  return NutritionInfo.fromFirestore(safeMap(raw));
}

// ==== ADVANCED: Customization group flatten, deep search, included ingredient helpers ====

// Flatten all selectable customizations from groups (used for "included ingredients")
List<Customization> flattenCustomizations(List<Customization> groups) {
  List<Customization> flat = [];
  for (final group in groups) {
    if (group.isGroup && group.options != null) {
      flat.addAll(flattenCustomizations(group.options!));
    } else if (!group.isGroup) {
      flat.add(group);
    }
  }
  return flat;
}

/// Find a Customization option by id
Customization? findCustomizationById(List<Customization> groups, String id) {
  for (final group in groups) {
    if (group.id == id) return group;
    if (group.options != null) {
      final found = findCustomizationById(group.options!, id);
      if (found != null) return found;
    }
  }
  return null;
}
