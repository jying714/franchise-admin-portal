import 'package:flutter/material.dart';

/// A utility class for reusable form field validators
class FormValidators {
  /// Ensures that the field is not null or empty
  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  /// Ensures the value is a valid positive number (for decimals or ints)
  static String? nonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a number.';
    }

    final number = double.tryParse(value.trim());
    if (number == null || number < 0) {
      return 'Must be 0 or greater.';
    }

    return null;
  }

  /// Ensures that a dropdown or multiselect has a value
  static String? requiredDropdown(dynamic value) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      return 'Please make a selection.';
    }
    return null;
  }

  /// Ensures that a list has at least one value (for tag or chip-based inputs)
  static String? requireAtLeastOne(List<dynamic>? items) {
    if (items == null || items.isEmpty) {
      return 'At least one must be selected.';
    }
    return null;
  }

  /// Ensures price format is valid (e.g., two decimal places)
  static String? validPriceFormat(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a price.';
    }

    final number = double.tryParse(value.trim());
    if (number == null || number < 0) {
      return 'Must be a valid non-negative price.';
    }

    final parts = value.trim().split('.');
    if (parts.length == 2 && parts[1].length > 2) {
      return 'Max 2 decimal places allowed.';
    }

    return null;
  }

  /// Ensures the string length doesn't exceed a threshold
  static String? maxLength(String? value, int limit) {
    if (value != null && value.length > limit) {
      return 'Maximum $limit characters allowed.';
    }
    return null;
  }

  /// Optional field: if not empty, must be a valid number
  static String? optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final number = double.tryParse(value.trim());
    if (number == null) return 'Must be a valid number.';
    return null;
  }
}
